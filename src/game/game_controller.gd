class_name GameController
extends Node
## 游戏控制器
## 整合所有游戏系统，控制游戏流程和音频同步

const TJAData = preload("res://src/parser/tja_data.gd")
const TJAParser = preload("res://src/parser/tja_parser.gd")
const NoteManager = preload("res://src/game/note_manager.gd")
const JudgeSystem = preload("res://src/game/judge.gd")
const ScrollSystem = preload("res://src/game/scroll.gd")

## 信号
signal game_started
signal game_ended(result: Dictionary)
signal game_paused
signal game_resumed
signal time_updated(current_time: float)
signal branch_changed(new_branch: int)  ## 分支切换信号
signal gogo_started  ## Go-Go Time开始信号
signal gogo_ended    ## Go-Go Time结束信号

## 游戏状态枚举
enum PlayState {
	IDLE,       ## 空闲
	LOADING,   ## 加载中
	READY,     ## 准备就绪
	PLAYING,   ## 游戏中
	PAUSED,    ## 暂停
	ENDING     ## 结束中
}

## 配置
@export var auto_play: bool = false  ## 自动演奏模式
@export var practice_mode: bool = false  ## 练习模式

## 子系统引用
var note_manager: NoteManager
var judge_system: JudgeSystem
var scroll_system: ScrollSystem

## 音频播放器
var music_player: AudioStreamPlayer

## 当前游戏状态
var current_state: PlayState = PlayState.IDLE

## 当前歌曲数据
var current_song: TJAData.TJASong = null
var current_course: TJAData.TJACourse = null

## 时间管理
var game_time: float = 0.0
var start_delay: float = 1.0  ## 开始延迟（秒）
var end_delay: float = 2.0    ## 结束延迟（秒）

## 音频同步
var audio_offset: float = 0.0  ## 音频偏移（秒）

## 是否已开始
var _has_started: bool = false

## 是否已结束
var _has_ended: bool = false

## 分支系统
var current_branch: int = TJAData.BranchType.NORMAL  ## 当前分支
var _branch_condition_index: int = 0  ## 当前分支条件索引
var _pending_branch_conditions: Array = []  ## 待判定的分支条件

## Go-Go Time系统
var is_gogo_time: bool = false  ## 是否在Go-Go Time中
var _gogo_sections: Array = []  ## Go-Go Time区间列表


func _ready() -> void:
	_initialize_systems()
	_setup_signals()


## 初始化子系统
func _initialize_systems() -> void:
	# 创建音符管理器
	note_manager = NoteManager.new()
	add_child(note_manager)
	
	# 创建判定系统
	judge_system = JudgeSystem.new()
	add_child(judge_system)
	
	# 创建滚动系统
	scroll_system = ScrollSystem.new()
	add_child(scroll_system)
	
	# 创建音频播放器
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	
	# 设置系统关联
	note_manager.set_scroll_system(scroll_system)
	note_manager.set_judge_system(judge_system)


## 设置信号连接
func _setup_signals() -> void:
	# 音符判定信号
	note_manager.note_judged.connect(_on_note_judged)
	note_manager.note_missed.connect(_on_note_missed)
	
	# 判定系统信号
	judge_system.score_updated.connect(_on_score_updated)
	judge_system.combo_updated.connect(_on_combo_updated)
	judge_system.judge_result.connect(_on_judge_result)
	
	# 滚动系统信号
	scroll_system.scroll_speed_changed.connect(_on_scroll_speed_changed)
	scroll_system.bpm_changed.connect(_on_bpm_changed)


## 加载歌曲
func load_song(file_path: String, course_type: TJAData.CourseType = TJAData.CourseType.ONI) -> bool:
	current_state = PlayState.LOADING
	
	# 解析TJA文件
	var parser = TJAParser.new()
	var result = parser.parse_file(file_path)
	
	if not result.success:
		push_error("解析TJA文件失败: " + result.error)
		current_state = PlayState.IDLE
		return false
	
	current_song = result.song
	
	# 获取指定难度
	current_course = current_song.get_course(course_type)
	if current_course == null:
		push_error("找不到指定难度")
		current_state = PlayState.IDLE
		return false
	
	# 加载音频
	if not _load_audio():
		push_warning("无法加载音频文件")
	
	# 初始化系统
	_initialize_game_systems()
	
	current_state = PlayState.READY
	return true


## 加载音频
func _load_audio() -> bool:
	if current_song.wave.is_empty():
		return false
	
	# 构建音频路径
	var audio_path = current_song.get_base_dir() + "/" + current_song.wave
	
	# 检查文件是否存在
	if not FileAccess.file_exists(audio_path):
		return false
	
	# 加载音频流
	var audio_stream = load(audio_path)
	if audio_stream == null:
		return false
	
	music_player.stream = audio_stream
	audio_offset = current_song.offset
	
	return true


## 初始化游戏系统
func _initialize_game_systems() -> void:
	# 重置时间
	game_time = -start_delay
	_has_started = false
	_has_ended = false

	# 重置分支系统
	current_branch = TJAData.BranchType.NORMAL
	_branch_condition_index = 0
	_pending_branch_conditions = []

	# 重置Go-Go Time系统
	is_gogo_time = false
	_gogo_sections = []

	# 设置音频偏移
	if current_song != null:
		audio_offset = current_song.offset

	# 设置滚动系统
	scroll_system.reset()
	if current_song != null:
		scroll_system.set_offset(current_song.offset)
	if current_course != null:
		scroll_system.load_chart_data(current_course)

	# 设置判定系统
	judge_system.reset()
	if current_course != null:
		judge_system.set_total_notes(current_course.get_total_notes())
		judge_system.set_score_params(current_course.score_init, current_course.score_diff)

	# 加载音符数据
	note_manager.clear_all_notes()
	if current_course != null and current_song != null:
		note_manager.load_chart(current_course, current_song.offset)
	
	# 初始化分支条件
	_initialize_branch_conditions()
	
	# 初始化Go-Go Time区间
	_initialize_gogo_sections()


## 初始化分支条件
func _initialize_branch_conditions() -> void:
	if current_course == null or not current_course.has_branch:
		return
	
	_pending_branch_conditions = current_course.branch_conditions.duplicate()
	_branch_condition_index = 0
	
	# 计算每个分支条件的触发时间
	var current_time = current_song.offset
	for measure in current_course.measures:
		for condition in _pending_branch_conditions:
			if condition.trigger_time == 0.0:
				# 根据小节索引计算触发时间
				condition.trigger_time = current_time
		current_time += measure.get_duration()


## 初始化Go-Go Time区间
func _initialize_gogo_sections() -> void:
	_gogo_sections = []

	if current_song == null or current_course == null:
		return

	var current_time = current_song.offset
	var gogo_start: float = -1.0

	for measure in current_course.measures:
		if measure.is_gogo and gogo_start < 0:
			# Go-Go Time开始
			gogo_start = current_time
		elif not measure.is_gogo and gogo_start >= 0:
			# Go-Go Time结束
			_gogo_sections.append({"start": gogo_start, "end": current_time})
			gogo_start = -1.0
		current_time += measure.get_duration()

	# 处理最后一个Go-Go Time区间
	if gogo_start >= 0:
		_gogo_sections.append({"start": gogo_start, "end": current_time})


## 开始游戏
func start_game() -> void:
	if current_state != PlayState.READY:
		return
	
	current_state = PlayState.PLAYING
	game_started.emit()


## 暂停游戏
func pause_game() -> void:
	if current_state != PlayState.PLAYING:
		return
	
	current_state = PlayState.PAUSED
	music_player.stream_paused = true
	game_paused.emit()


## 恢复游戏
func resume_game() -> void:
	if current_state != PlayState.PAUSED:
		return
	
	current_state = PlayState.PLAYING
	music_player.stream_paused = false
	game_resumed.emit()


## 结束游戏
func end_game() -> void:
	if current_state == PlayState.ENDING or current_state == PlayState.IDLE:
		return
	
	current_state = PlayState.ENDING
	
	# 停止音乐
	music_player.stop()
	
	# 获取结果
	var result = judge_system.check_game_end()
	result.song_title = current_song.title
	result.course_type = current_course.course_type
	result.level = current_course.level
	
	# 发送结束信号
	game_ended.emit(result)
	
	current_state = PlayState.IDLE


## 重试游戏
func retry_game() -> void:
	if current_song == null or current_course == null:
		return
	
	# 停止音乐
	music_player.stop()
	
	# 重新初始化
	_initialize_game_systems()
	
	current_state = PlayState.READY


## 处理输入
func handle_input(input_type: String) -> void:
	if current_state != PlayState.PLAYING:
		return
	
	# 处理音符输入
	var result = note_manager.handle_input(input_type)
	
	# 处理判定结果
	for judge_result in result.results:
		judge_system.judge_note(
			0.0,  # 时间差已在音符中计算
			judge_result.note.note_type
		)


## 帧更新
func _process(delta: float) -> void:
	if current_state != PlayState.PLAYING:
		return

	# 更新时间
	_update_time(delta)

	# 更新滚动系统
	scroll_system.update_time(game_time)

	# 更新音符管理器
	note_manager.update(game_time)

	# 检查分支条件
	_check_branch_conditions()

	# 检查Go-Go Time状态
	_check_gogo_time()

	# 检查游戏开始
	_check_game_start()

	# 检查游戏结束
	_check_game_end()

	# 自动演奏模式
	if auto_play:
		_auto_play_update()


## 检查分支条件
func _check_branch_conditions() -> void:
	if _pending_branch_conditions.is_empty():
		return
	
	# 检查是否有需要判定的分支条件
	for i in range(_pending_branch_conditions.size()):
		var condition = _pending_branch_conditions[i]
		if condition.is_judged:
			continue
		
		# 检查是否到达触发时间
		if game_time >= condition.trigger_time:
			_evaluate_branch_condition(condition)


## 评估分支条件
func _evaluate_branch_condition(condition: TJAData.BranchCondition) -> void:
	var current_value: float = 0.0
	
	# 根据条件类型获取当前值
	match condition.condition_type:
		TJAData.BranchConditionType.ACCURACY:
			current_value = judge_system.get_accuracy() * 100.0
		TJAData.BranchConditionType.RENDA:
			current_value = float(judge_system.get_max_renda_count())
		TJAData.BranchConditionType.SCORE:
			current_value = float(judge_system.get_score())
	
	# 评估分支
	var new_branch = condition.evaluate(current_value)
	
	# 如果分支发生变化
	if new_branch != current_branch:
		current_branch = new_branch
		current_course.current_branch = new_branch
		
		# 通知音符管理器切换分支
		if note_manager:
			note_manager.switch_branch(new_branch)
		
		# 发送分支切换信号
		branch_changed.emit(new_branch)


## 检查Go-Go Time状态
func _check_gogo_time() -> void:
	var was_gogo = is_gogo_time
	is_gogo_time = false
	
	# 检查当前时间是否在任何Go-Go Time区间内
	for section in _gogo_sections:
		if game_time >= section.start and game_time < section.end:
			is_gogo_time = true
			break
	
	# 更新判定系统的Go-Go Time状态
	if judge_system:
		judge_system.set_gogo_time(is_gogo_time)
	
	# 发送Go-Go Time信号
	if is_gogo_time and not was_gogo:
		gogo_started.emit()
	elif not is_gogo_time and was_gogo:
		gogo_ended.emit()


## 更新时间
func _update_time(delta: float) -> void:
	game_time += delta
	time_updated.emit(game_time)


## 检查游戏开始
func _check_game_start() -> void:
	if _has_started:
		return
	
	if game_time >= 0.0:
		_has_started = true
		# 开始播放音乐
		music_player.play()
		# 调整音频位置以同步
		music_player.seek(game_time + audio_offset)


## 检查游戏结束
func _check_game_end() -> void:
	if _has_ended:
		return
	
	# 检查是否所有音符都已处理
	if note_manager.is_all_notes_processed():
		# 等待结束延迟
		if game_time >= scroll_system.get_spawn_ahead_time() + end_delay:
			_has_ended = true
			end_game()


## 自动演奏更新
func _auto_play_update() -> void:
	# 获取下一个待判定的音符
	var pending_notes = _get_pending_notes()
	
	for note_info in pending_notes:
		var time_diff = note_info.hit_time - game_time
		
		# 在完美时机自动打击
		if abs(time_diff) <= 0.001:  # 1毫秒容差
			var input_type = "don" if note_info.note.needs_don_input() else "ka"
			handle_input(input_type)


## 获取待判定音符
func _get_pending_notes() -> Array[Dictionary]:
	# 简化实现，返回空数组
	# 实际实现需要从note_manager获取
	return []


## 音符判定回调
func _on_note_judged(note, result: String) -> void:
	# 判定已在handle_input中处理
	pass


## 音符错过回调
func _on_note_missed(note) -> void:
	judge_system.judge_note(1000.0, note.note_type)  # 超出判定窗口


## 分数更新回调
func _on_score_updated(score: int) -> void:
	# 更新全局状态
	GameState.current_score = score


## 连击更新回调
func _on_combo_updated(combo: int) -> void:
	# 更新全局状态
	GameState.current_combo = combo


## 判定结果回调
func _on_judge_result(judge_type: String, note_type: int) -> void:
	# 更新全局状态
	if judge_type in GameState.judge_counts:
		GameState.judge_counts[judge_type] += 1


## 滚动速度变化回调
func _on_scroll_speed_changed(new_speed: float) -> void:
	# 可以触发视觉效果
	pass


## BPM变化回调
func _on_bpm_changed(new_bpm: float) -> void:
	# 可以触发视觉效果
	pass


## 获取当前状态
func get_state() -> PlayState:
	return current_state


## 获取当前时间
func get_current_time() -> float:
	return game_time


## 获取当前分数
func get_current_score() -> int:
	return judge_system.get_score()


## 获取当前连击
func get_current_combo() -> int:
	return judge_system.get_combo()


## 获取最大连击
func get_max_combo() -> int:
	return judge_system.get_max_combo()


## 获取判定统计
func get_judge_counts() -> Dictionary:
	return judge_system.get_judge_counts()


## 获取魂槽百分比
func get_soul_percentage() -> float:
	return judge_system.get_soul_percentage()


## 检查是否在清除状态
func is_clear_status() -> bool:
	return judge_system.is_clear_status()


## 设置滚动速度
func set_scroll_speed(speed: float) -> void:
	scroll_system.set_base_scroll_speed(speed)
	Settings.scroll_speed = speed


## 设置判定偏移
func set_judge_offset(offset_ms: float) -> void:
	# 判定偏移需要在判定计算中考虑
	Settings.judge_offset = offset_ms