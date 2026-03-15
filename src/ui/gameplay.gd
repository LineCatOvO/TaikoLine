class_name GameplayUI
extends Control
## 游戏界面
## 显示游戏过程中的所有UI元素

const TJAData = preload("res://src/parser/tja_data.gd")
const GameController = preload("res://src/game/game_controller.gd")
const JudgeDisplay = preload("res://src/ui/components/judge_display.gd")
const ComboDisplay = preload("res://src/ui/components/combo_display.gd")
const SoulGauge = preload("res://src/ui/components/soul_gauge.gd")
const ScoreDisplay = preload("res://src/ui/components/score_display.gd")

## 信号
signal game_finished(result: Dictionary)
signal pause_requested

## 判定线X坐标
const JUDGE_LINE_X: float = 200.0

## UI节点引用
var _note_area: Control
var _judge_line: ColorRect
var _judge_display: JudgeDisplay
var _combo_display: ComboDisplay
var _soul_gauge: SoulGauge
var _score_display: ScoreDisplay
var _pause_button: Button
var _song_title_label: Label
var _progress_bar: ProgressBar

## 游戏控制器
var _game_controller: GameController

## 音符场景
var _note_scene: PackedScene

## 活动音符列表
var _active_notes: Array[Node] = []


func _ready() -> void:
	_setup_ui()
	_setup_game_controller()
	_connect_signals()


## 设置UI布局
func _setup_ui() -> void:
	# 设置全屏
	anchors_preset = Control.PRESET_FULL_RECT
	offset_right = 0
	offset_bottom = 0
	
	# 创建主容器
	var main_vbox = VBoxContainer.new()
	add_child(main_vbox)
	main_vbox.anchors_preset = Control.PRESET_FULL_RECT
	main_vbox.offset_right = 0
	main_vbox.offset_bottom = 0
	
	# 顶部信息栏
	_setup_top_bar(main_vbox)
	
	# 中间游戏区域
	var game_area = Control.new()
	game_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(game_area)
	
	# 音符显示区域
	_setup_note_area(game_area)
	
	# 判定线
	_setup_judge_line(game_area)
	
	# 判定显示
	_setup_judge_display(game_area)
	
	# 连击显示
	_setup_combo_display(game_area)
	
	# 底部状态栏
	_setup_bottom_bar(main_vbox)


## 设置顶部信息栏
func _setup_top_bar(parent: Control) -> void:
	var top_bar = PanelContainer.new()
	top_bar.custom_minimum_size = Vector2(0, 50)
	parent.add_child(top_bar)
	
	var hbox = HBoxContainer.new()
	top_bar.add_child(hbox)
	
	# 暂停按钮
	_pause_button = Button.new()
	_pause_button.text = "||"
	_pause_button.custom_minimum_size = Vector2(40, 30)
	_pause_button.pressed.connect(_on_pause_pressed)
	hbox.add_child(_pause_button)
	
	# 歌曲标题
	_song_title_label = Label.new()
	_song_title_label.text = "Now Playing: ---"
	_song_title_label.add_theme_font_size_override("font_size", 18)
	_song_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(_song_title_label)
	
	# 分数显示
	_score_display = ScoreDisplay.new()
	hbox.add_child(_score_display)


## 设置音符显示区域
func _setup_note_area(parent: Control) -> void:
	_note_area = Control.new()
	_note_area.name = "NoteArea"
	_note_area.anchors_preset = Control.PRESET_FULL_RECT
	parent.add_child(_note_area)


## 设置判定线
func _setup_judge_line(parent: Control) -> void:
	_judge_line = ColorRect.new()
	_judge_line.color = Color(1.0, 0.8, 0.0, 0.8)  # 金色半透明
	_judge_line.custom_minimum_size = Vector2(4, 300)
	_judge_line.position = Vector2(JUDGE_LINE_X, 100)
	parent.add_child(_judge_line)


## 设置判定显示
func _setup_judge_display(parent: Control) -> void:
	_judge_display = JudgeDisplay.new()
	_judge_display.position = Vector2(JUDGE_LINE_X - 50, 200)
	_judge_display.custom_minimum_size = Vector2(100, 50)
	parent.add_child(_judge_display)


## 设置连击显示
func _setup_combo_display(parent: Control) -> void:
	_combo_display = ComboDisplay.new()
	_combo_display.position = Vector2(50, 150)
	_combo_display.custom_minimum_size = Vector2(100, 80)
	parent.add_child(_combo_display)


## 设置底部状态栏
func _setup_bottom_bar(parent: Control) -> void:
	var bottom_bar = PanelContainer.new()
	bottom_bar.custom_minimum_size = Vector2(0, 60)
	parent.add_child(bottom_bar)
	
	var vbox = VBoxContainer.new()
	bottom_bar.add_child(vbox)
	
	# 魂槽
	_soul_gauge = SoulGauge.new()
	_soul_gauge.custom_minimum_size = Vector2(0, 25)
	vbox.add_child(_soul_gauge)
	
	# 进度条
	_progress_bar = ProgressBar.new()
	_progress_bar.custom_minimum_size = Vector2(0, 20)
	_progress_bar.max_value = 100.0
	_progress_bar.value = 0.0
	vbox.add_child(_progress_bar)


## 设置游戏控制器
func _setup_game_controller() -> void:
	_game_controller = GameController.new()
	add_child(_game_controller)
	
	# 连接游戏控制器信号
	_game_controller.game_ended.connect(_on_game_ended)
	_game_controller.score_updated.connect(_on_score_updated)
	_game_controller.combo_updated.connect(_on_combo_updated)
	_game_controller.time_updated.connect(_on_time_updated)


## 连接信号
func _connect_signals() -> void:
	# 魂槽信号
	_soul_gauge.soul_threshold_reached.connect(_on_soul_threshold_reached)


## 开始游戏
func start_game(song_path: String, course_type: int = TJAData.CourseType.ONI) -> void:
	# 加载歌曲
	if not _game_controller.load_song(song_path, course_type):
		push_error("无法加载歌曲: " + song_path)
		return
	
	# 更新歌曲标题
	var song = _game_controller.current_song
	if song:
		_song_title_label.text = "Now Playing: " + song.title
	
	# 重置UI
	_reset_ui()
	
	# 开始游戏
	_game_controller.start_game()


## 重置UI
func _reset_ui() -> void:
	_score_display.reset()
	_combo_display.reset()
	_soul_gauge.reset()
	_progress_bar.value = 0.0
	
	# 清除活动音符
	for note in _active_notes:
		note.queue_free()
	_active_notes.clear()


## 处理输入
func _input(event: InputEvent) -> void:
	if _game_controller.current_state != GameController.PlayState.PLAYING:
		return
	
	# 处理鼓面输入（红音符）
	if event.is_action_pressed("don"):
		_handle_drum_input("don")
	
	# 处理鼓边输入（蓝音符）
	if event.is_action_pressed("ka"):
		_handle_drum_input("ka")
	
	# 处理暂停
	if event.is_action_pressed("pause"):
		_on_pause_pressed()


## 处理鼓输入
func _handle_drum_input(input_type: String) -> void:
	_game_controller.handle_input(input_type)
	
	# 播放音效
	if input_type == "don":
		AudioManager.play_don()
	else:
		AudioManager.play_ka()


## 暂停按钮按下
func _on_pause_pressed() -> void:
	if _game_controller.current_state == GameController.PlayState.PLAYING:
		_game_controller.pause_game()
		_show_pause_menu()
	elif _game_controller.current_state == GameController.PlayState.PAUSED:
		_game_controller.resume_game()
		_hide_pause_menu()


## 显示暂停菜单
func _show_pause_menu() -> void:
	# 创建暂停菜单
	var pause_menu = PanelContainer.new()
	pause_menu.name = "PauseMenu"
	pause_menu.anchors_preset = Control.PRESET_CENTER
	pause_menu.custom_minimum_size = Vector2(300, 200)
	add_child(pause_menu)
	
	var vbox = VBoxContainer.new()
	pause_menu.add_child(vbox)
	
	# 标题
	var title = Label.new()
	title.text = "PAUSED"
	title.add_theme_font_size_override("font_size", 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	# 继续按钮
	var resume_btn = Button.new()
	resume_btn.text = "Resume"
	resume_btn.pressed.connect(_on_pause_pressed)
	vbox.add_child(resume_btn)
	
	# 重试按钮
	var retry_btn = Button.new()
	retry_btn.text = "Retry"
	retry_btn.pressed.connect(_on_retry_pressed)
	vbox.add_child(retry_btn)
	
	# 退出按钮
	var exit_btn = Button.new()
	exit_btn.text = "Exit"
	exit_btn.pressed.connect(_on_exit_pressed)
	vbox.add_child(exit_btn)


## 隐藏暂停菜单
func _hide_pause_menu() -> void:
	var pause_menu = get_node_or_null("PauseMenu")
	if pause_menu:
		pause_menu.queue_free()


## 重试按钮按下
func _on_retry_pressed() -> void:
	_hide_pause_menu()
	_game_controller.retry_game()
	_game_controller.start_game()
	_reset_ui()


## 退出按钮按下
func _on_exit_pressed() -> void:
	_hide_pause_menu()
	_game_controller.end_game()
	get_tree().change_scene_to_file("res://scenes/song_select.tscn")


## 游戏结束回调
func _on_game_ended(result: Dictionary) -> void:
	# 保存结果到全局状态
	GameState.current_score = result.score
	GameState.max_combo = result.max_combo
	GameState.judge_counts = {
		"良": result.perfect_count,
		"可": result.good_count,
		"不可": result.miss_count
	}
	
	# 发送信号
	game_finished.emit(result)
	
	# 切换到结果场景
	get_tree().change_scene_to_file("res://scenes/result.tscn")


## 分数更新回调
func _on_score_updated(score: int) -> void:
	_score_display.update_score(score)


## 连击更新回调
func _on_combo_updated(combo: int) -> void:
	_combo_display.update_combo(combo)


## 时间更新回调
func _on_time_updated(current_time: float) -> void:
	# 更新魂槽
	var soul_percentage = _game_controller.get_soul_percentage()
	_soul_gauge.update_soul(soul_percentage * 100.0)  # 转换为0-100范围
	
	# 更新进度条（简化实现）
	if _game_controller.current_course:
		var total_duration = _game_controller.current_course.get_total_duration()
		if total_duration > 0:
			var progress = (current_time / total_duration) * 100.0
			_progress_bar.value = clamp(progress, 0.0, 100.0)


## 魂槽达到阈值回调
func _on_soul_threshold_reached() -> void:
	# 可以添加视觉效果
	pass


## 显示判定结果
func show_judge_result(judge_type: String) -> void:
	match judge_type:
		"良":
			_judge_display.show_judge(JudgeDisplay.JudgeType.PERFECT)
		"可":
			_judge_display.show_judge(JudgeDisplay.JudgeType.GOOD)
		"不可":
			_judge_display.show_judge(JudgeDisplay.JudgeType.MISS)


## 获取游戏控制器
func get_game_controller() -> GameController:
	return _game_controller