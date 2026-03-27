class_name GameplayUI
extends Control
## 游戏界面
## 显示游戏过程中的所有UI元素
##
## 设计参考：太鼓达人虹版（Taiko no Tatsujin Nijiiro）
## - 音符轨道：中央横向轨道，带渐变效果
## - 判定线：轨道右侧垂直判定线，带发光
## - 分数显示：左上角，带动画
## - 连击显示：中央下方，大字体
## - 魂槽：顶部进度条，带阈值标记
## - 分支指示：当前分支类型显示
##
## 更新：2026-03-27 - 优化动画效果

const TJAData = preload("res://src/parser/tja_data.gd")
const GameController = preload("res://src/game/game_controller.gd")
const JudgeDisplay = preload("res://src/ui/components/judge_display.gd")
const ComboDisplay = preload("res://src/ui/components/combo_display.gd")
const SoulGauge = preload("res://src/ui/components/soul_gauge.gd")
const ScoreDisplay = preload("res://src/ui/components/score_display.gd")
const LyricsDisplay = preload("res://src/ui/components/lyrics_display.gd")
const SceneTransition = preload("res://src/ui/components/scene_transition.gd")

## 信号
signal game_finished(result: Dictionary)
signal pause_requested

## 判定线X坐标（相对于屏幕中心）
const JUDGE_LINE_OFFSET: float = 200.0

## UI节点引用 - 场景中的节点
@onready var _background: ColorRect = $Background
@onready var _gogo_overlay: ColorRect = $GogoOverlay
@onready var _note_area: Control = $NoteArea
@onready var _note_area_background: ColorRect = $NoteArea/NoteAreaBackground
@onready var _judge_line: ColorRect = $NoteArea/JudgeLine
@onready var _judge_line_glow: ColorRect = $NoteArea/JudgeLine/JudgeLineGlow
@onready var _top_bar: PanelContainer = $TopBar
@onready var _pause_button: Button = $TopBar/HBoxContainer/PauseButton
@onready var _song_title_label: Label = $TopBar/HBoxContainer/SongTitleLabel
@onready var _score_label: Label = $TopBar/HBoxContainer/ScoreContainer/ScoreLabel
@onready var _combo_display: Control = $ComboDisplay
@onready var _combo_label: Label = $ComboDisplay/VBoxContainer/ComboLabel
@onready var _combo_text_label: Label = $ComboDisplay/VBoxContainer/ComboTextLabel
@onready var _judge_display: Control = $JudgeDisplay
@onready var _judge_label: Label = $JudgeDisplay/JudgeLabel
@onready var _branch_label: Label = $BranchLabel
@onready var _lyrics_display: Control = $LyricsDisplay
@onready var _lyrics_label: Label = $LyricsDisplay/LyricsLabel
@onready var _bottom_bar: PanelContainer = $BottomBar
@onready var _soul_gauge_container: Control = $BottomBar/VBoxContainer/SoulGaugeContainer
@onready var _soul_gauge_background: ColorRect = $BottomBar/VBoxContainer/SoulGaugeContainer/SoulGaugeBackground
@onready var _soul_gauge_fill: ColorRect = $BottomBar/VBoxContainer/SoulGaugeContainer/SoulGaugeFill
@onready var _soul_gauge_threshold: ColorRect = $BottomBar/VBoxContainer/SoulGaugeContainer/SoulGaugeThreshold
@onready var _soul_gauge_label: Label = $BottomBar/VBoxContainer/SoulGaugeContainer/SoulGaugeLabel
@onready var _progress_bar: ProgressBar = $BottomBar/VBoxContainer/ProgressBar

## Go-Go Time视觉效果
var _is_gogo_active: bool = false

## 分支显示
var _current_branch: int = TJAData.BranchType.NORMAL

## 歌词显示组件
var _lyrics_component: LyricsDisplay

## 游戏控制器
var _game_controller: GameController

## 活动音符列表
var _active_notes: Array[Node] = []

## 分数动画
var _current_score: int = 0
var _display_score: int = 0
var _score_tween: Tween

## 连击动画
var _current_combo: int = 0
var _combo_tween: Tween

## 魂槽动画
var _current_soul: float = 0.0
var _soul_tween: Tween

## 判定显示动画
var _judge_tween: Tween


func _ready() -> void:
	_setup_ui_style()
	_setup_game_controller()
	_connect_signals()
	_setup_threshold_line()


## 设置UI样式
func _setup_ui_style() -> void:
	# 设置背景颜色（从皮肤管理器获取）
	var bg_color := SkinManager.get_background_color()
	_background.color = bg_color
	
	# 设置音符区域背景颜色
	var note_area_color := SkinManager.get_note_area_color()
	_note_area_background.color = Color(note_area_color.r, note_area_color.g, note_area_color.b, 0.8)
	
	# 设置判定线颜色
	var judge_line_color := SkinManager.get_judge_line_color()
	_judge_line.color = Color(judge_line_color.r, judge_line_color.g, judge_line_color.b, 0.8)
	_judge_line_glow.color = Color(judge_line_color.r, judge_line_color.g, judge_line_color.b, 0.3)
	
	# 设置分数标签样式
	_score_label.add_theme_font_size_override("font_size", 28)
	_score_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))  # 金色
	
	# 设置连击标签样式
	_combo_label.add_theme_font_size_override("font_size", 48)
	_combo_label.add_theme_color_override("font_color", Color.WHITE)
	_combo_text_label.add_theme_font_size_override("font_size", 16)
	_combo_text_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	
	# 设置判定标签样式
	_judge_label.add_theme_font_size_override("font_size", 32)
	_judge_label.modulate.a = 0.0  # 初始隐藏
	
	# 设置分支标签样式
	_branch_label.add_theme_font_size_override("font_size", 16)
	
	# 设置歌词标签样式
	_lyrics_label.add_theme_font_size_override("font_size", 24)
	_lyrics_label.add_theme_color_override("font_color", Color.WHITE)
	
	# 设置魂槽标签样式
	_soul_gauge_label.add_theme_font_size_override("font_size", 14)
	_soul_gauge_label.add_theme_color_override("font_color", Color.WHITE)
	
	# 初始隐藏连击显示
	_combo_display.visible = false


## 设置阈值线位置
func _setup_threshold_line() -> void:
	# 阈值位置为80%（清除阈值）
	var threshold_ratio = 0.8
	# 等待一帧让布局完成
	await get_tree().process_frame
	var width = _soul_gauge_container.size.x
	_soul_gauge_threshold.position.x = width * threshold_ratio - 1


## 设置游戏控制器
func _setup_game_controller() -> void:
	_game_controller = GameController.new()
	add_child(_game_controller)

	# 连接游戏控制器信号
	_game_controller.game_ended.connect(_on_game_ended)
	_game_controller.score_updated.connect(_on_score_updated)
	_game_controller.combo_updated.connect(_on_combo_updated)
	_game_controller.time_updated.connect(_on_time_updated)

	# 连接Go-Go Time信号
	_game_controller.gogo_started.connect(_on_gogo_started)
	_game_controller.gogo_ended.connect(_on_gogo_ended)

	# 连接分支切换信号
	_game_controller.branch_changed.connect(_on_branch_changed)


## 连接信号
func _connect_signals() -> void:
	# 暂停按钮
	_pause_button.pressed.connect(_on_pause_pressed)
	
	# 皮肤切换信号
	SkinManager.skin_changed.connect(_on_skin_changed)


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

		# 加载歌词文件
		_load_lyrics(song)

	# 重置UI
	_reset_ui()

	# 开始游戏
	_game_controller.start_game()


## 加载歌词文件
func _load_lyrics(song: TJAData.TJASong) -> void:
	_lyrics_label.text = ""

	if song.lyrics.is_empty():
		return

	# 构建歌词文件路径
	var lyrics_path = song.get_base_dir() + "/" + song.lyrics

	# 检查文件是否存在
	if not FileAccess.file_exists(lyrics_path):
		push_warning("歌词文件不存在: " + lyrics_path)
		return

	# 创建歌词显示组件
	if _lyrics_component == null:
		_lyrics_component = LyricsDisplay.new()
	
	# 加载歌词
	if _lyrics_component.load_vtt_file(lyrics_path):
		print("歌词加载成功: " + lyrics_path)


## 重置UI
func _reset_ui() -> void:
	# 重置分数
	_current_score = 0
	_display_score = 0
	_score_label.text = "0"
	
	# 重置连击
	_current_combo = 0
	_combo_label.text = "0"
	_combo_display.visible = false
	
	# 重置魂槽
	_current_soul = 0.0
	_soul_gauge_fill.size.x = 0
	_soul_gauge_fill.color = Color(0.3, 0.6, 1.0)
	_soul_gauge_label.text = "0%"
	
	# 重置进度条
	_progress_bar.value = 0.0
	
	# 重置歌词
	_lyrics_label.text = ""
	
	# 重置分支
	_branch_label.text = ""
	_current_branch = TJAData.BranchType.NORMAL
	
	# 重置判定显示
	_judge_label.modulate.a = 0.0

	# 清除活动音符
	for note in _active_notes:
		note.queue_free()
	_active_notes.clear()
	
	# 重置Go-Go状态
	_is_gogo_active = false
	_gogo_overlay.color.a = 0.0


## 处理输入
func _input(event: InputEvent) -> void:
	if _game_controller.current_state != GameController.PlayState.PLAYING:
		return

	# 处理鼓面输入（红音符）- 支持左右两侧
	if event.is_action_pressed("don_left") or event.is_action_pressed("don_right"):
		_handle_drum_input("don")

	# 处理鼓边输入（蓝音符）- 支持左右两侧
	if event.is_action_pressed("ka_left") or event.is_action_pressed("ka_right"):
		_handle_drum_input("ka")

	# 处理暂停
	if event.is_action_pressed("ui_cancel"):
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
	_animate_score(_current_score, score)
	_current_score = score


## 动画显示分数变化
func _animate_score(from: int, to: int) -> void:
	if _score_tween:
		_score_tween.kill()

	# 使用tween来动画化分数变化
	_score_tween = create_tween()
	_score_tween.tween_method(_set_display_score, from, to, 0.3)

	# 播放缩放动画
	_score_tween.set_parallel(true)
	_score_tween.tween_property(_score_label, "scale", Vector2(1.1, 1.1), 0.1)
	_score_tween.chain().tween_property(_score_label, "scale", Vector2.ONE, 0.1)


## 设置显示分数（用于动画）
func _set_display_score(score: int) -> void:
	_display_score = score
	_score_label.text = _format_score(score)


## 格式化分数显示
func _format_score(score: int) -> String:
	# 添加千位分隔符
	var score_str = str(score)
	var formatted = ""
	var count = 0

	for i in range(score_str.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			formatted = "," + formatted
		formatted = score_str[i] + formatted
		count += 1

	return formatted


## 连击更新回调
func _on_combo_updated(combo: int) -> void:
	_current_combo = combo
	_update_combo_display(combo)


## 更新连击显示
func _update_combo_display(combo: int) -> void:
	# 更新文本
	_combo_label.text = str(combo)

	# 更新可见性
	_combo_display.visible = combo > 0

	if combo > 0:
		# 播放缩放动画
		if _combo_tween:
			_combo_tween.kill()

		_combo_tween = create_tween()
		_combo_tween.set_ease(Tween.EASE_OUT)
		_combo_tween.set_trans(Tween.TRANS_BACK)

		# 弹跳缩放动画
		_combo_tween.tween_property(_combo_label, "scale", Vector2(1.25, 1.25), 0.08)
		_combo_tween.tween_property(_combo_label, "scale", Vector2.ONE, 0.12)

		# 高亮模式（50连击以上）
		if combo >= 50:
			_combo_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))  # 金色
			# 添加发光效果
			if combo % 10 == 0:
				_play_combo_milestone_effect(combo)
		elif combo >= 10:
			_combo_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))  # 浅金色
		else:
			_combo_label.add_theme_color_override("font_color", Color.WHITE)
	else:
		# 断连动画
		if _combo_tween:
			_combo_tween.kill()

		_combo_tween = create_tween()
		_combo_tween.set_ease(Tween.EASE_IN)
		_combo_tween.set_trans(Tween.TRANS_QUAD)
		_combo_tween.tween_property(_combo_label, "modulate:a", 0.0, 0.25)
		_combo_tween.tween_callback(_reset_combo_display)


## 重置连击显示
func _reset_combo_display() -> void:
	_combo_label.modulate.a = 1.0
	_combo_label.scale = Vector2.ONE


## 播放连击里程碑效果（每10连击）
## 参数 combo: 当前连击数
func _play_combo_milestone_effect(combo: int) -> void:
	# 创建脉冲效果
	var pulse_tween = create_tween()
	pulse_tween.set_ease(Tween.EASE_OUT)
	pulse_tween.set_trans(Tween.TRANS_SINE)

	# 缩放脉冲
	pulse_tween.tween_property(_combo_label, "scale", Vector2(1.4, 1.4), 0.1)
	pulse_tween.tween_property(_combo_label, "scale", Vector2.ONE, 0.15)

	# 颜色闪烁
	var color_tween = create_tween()
	color_tween.tween_property(_combo_label, "modulate:v", 1.5, 0.1)
	color_tween.tween_property(_combo_label, "modulate:v", 1.0, 0.15)


## 时间更新回调
func _on_time_updated(current_time: float) -> void:
	# 更新魂槽
	var soul_percentage = _game_controller.get_soul_percentage()
	_update_soul_gauge(soul_percentage * 100.0)  # 转换为0-100范围

	# 更新进度条（简化实现）
	if _game_controller.current_course:
		var total_duration = _game_controller.current_course.get_total_duration()
		if total_duration > 0:
			var progress = (current_time / total_duration) * 100.0
			_progress_bar.value = clamp(progress, 0.0, 100.0)

	# 更新歌词显示
	if _lyrics_component:
		_lyrics_component.update(current_time)
		_lyrics_label.text = _lyrics_component.get_current_lyrics()


## 更新魂槽显示
func _update_soul_gauge(percentage: float) -> void:
	var old_soul = _current_soul
	_current_soul = clamp(percentage, 0.0, 100.0)

	# 更新标签
	_soul_gauge_label.text = "%.1f%%" % _current_soul

	# 更新填充条宽度
	var target_width = (_current_soul / 100.0) * _soul_gauge_container.size.x

	if _soul_tween:
		_soul_tween.kill()

	_soul_tween = create_tween()
	_soul_tween.set_ease(Tween.EASE_OUT)
	_soul_tween.set_trans(Tween.TRANS_QUART)
	_soul_tween.tween_property(_soul_gauge_fill, "size:x", target_width, 0.25)

	# 更新颜色
	var target_color: Color
	if _current_soul >= 80.0:
		target_color = Color(1.0, 0.8, 0.0)  # 金色（清除状态）
		# 达到清除阈值时播放特效
		if old_soul < 80.0:
			_play_soul_threshold_effect()
	elif _current_soul < 30.0:
		target_color = Color(1.0, 0.3, 0.3)  # 红色（危险状态）
		# 危险状态时添加脉冲效果
		if old_soul >= 30.0:
			_play_soul_danger_effect()
	else:
		target_color = Color(0.3, 0.6, 1.0)  # 蓝色（正常状态）

	var color_tween = create_tween()
	color_tween.set_ease(Tween.EASE_OUT)
	color_tween.set_trans(Tween.TRANS_QUAD)
	color_tween.tween_property(_soul_gauge_fill, "color", target_color, 0.2)


## 播放魂槽达到阈值特效
func _play_soul_threshold_effect() -> void:
	# 闪烁效果
	var flash_tween = create_tween()
	flash_tween.tween_property(_soul_gauge_fill, "modulate:v", 1.5, 0.1)
	flash_tween.tween_property(_soul_gauge_fill, "modulate:v", 1.0, 0.15)

	# 缩放脉冲
	var scale_tween = create_tween()
	scale_tween.tween_property(_soul_gauge_container, "scale", Vector2(1.02, 1.05), 0.1)
	scale_tween.tween_property(_soul_gauge_container, "scale", Vector2.ONE, 0.15)


## 播放魂槽危险状态特效
func _play_soul_danger_effect() -> void:
	# 红色闪烁
	var flash_tween = create_tween()
	flash_tween.tween_property(_soul_gauge_fill, "modulate:a", 0.6, 0.15)
	flash_tween.tween_property(_soul_gauge_fill, "modulate:a", 1.0, 0.15)


## 皮肤切换回调
func _on_skin_changed(skin_name: String) -> void:
	# 更新背景颜色
	var bg_color := SkinManager.get_background_color()
	_background.color = bg_color
	
	# 更新音符区域背景颜色
	var note_area_color := SkinManager.get_note_area_color()
	_note_area_background.color = Color(note_area_color.r, note_area_color.g, note_area_color.b, 0.8)
	
	# 更新判定线颜色
	var judge_line_color := SkinManager.get_judge_line_color()
	_judge_line.color = Color(judge_line_color.r, judge_line_color.g, judge_line_color.b, 0.8)
	_judge_line_glow.color = Color(judge_line_color.r, judge_line_color.g, judge_line_color.b, 0.3)

	# 如果Go-Go Time正在激活，更新判定线为高亮颜色
	if _is_gogo_active:
		var bright_color := Color(judge_line_color.r * 1.1, judge_line_color.g * 1.1, judge_line_color.b * 0.9, 1.0)
		bright_color = bright_color.clamp()
		_judge_line.color = bright_color


## Go-Go Time开始回调
func _on_gogo_started() -> void:
	_is_gogo_active = true
	# 显示Go-Go Time视觉效果
	_animate_gogo_start()


## Go-Go Time结束回调
func _on_gogo_ended() -> void:
	_is_gogo_active = false
	# 隐藏Go-Go Time视觉效果
	_animate_gogo_end()


## 分支切换回调
func _on_branch_changed(new_branch: int) -> void:
	_current_branch = new_branch
	_update_branch_display()


## Go-Go Time开始动画
func _animate_gogo_start() -> void:
	# 创建渐变动画
	var tween = create_tween()
	tween.tween_property(_gogo_overlay, "color:a", 0.15, 0.3)

	# 从SkinManager获取判定线颜色，更亮的版本
	var judge_line_color := SkinManager.get_judge_line_color()
	var bright_color := Color(judge_line_color.r * 1.1, judge_line_color.g * 1.1, judge_line_color.b * 0.9, 1.0)
	bright_color = bright_color.clamp()
	var judge_tween = create_tween()
	judge_tween.tween_property(_judge_line, "color", bright_color, 0.3)
	
	# 增强判定线发光
	var glow_tween = create_tween()
	glow_tween.tween_property(_judge_line_glow, "color:a", 0.5, 0.3)


## Go-Go Time结束动画
func _animate_gogo_end() -> void:
	# 创建渐变动画
	var tween = create_tween()
	tween.tween_property(_gogo_overlay, "color:a", 0.0, 0.3)

	# 从SkinManager获取判定线颜色，恢复原色
	var judge_line_color := SkinManager.get_judge_line_color()
	var judge_tween = create_tween()
	judge_tween.tween_property(_judge_line, "color", Color(judge_line_color.r, judge_line_color.g, judge_line_color.b, 0.8), 0.3)
	
	# 恢复判定线发光
	var glow_tween = create_tween()
	glow_tween.tween_property(_judge_line_glow, "color:a", 0.3, 0.3)


## 更新分支显示
func _update_branch_display() -> void:
	var branch_name: String
	var branch_color: Color

	match _current_branch:
		TJAData.BranchType.NORMAL:
			branch_name = "Normal"
			branch_color = Color(0.5, 0.5, 1.0)  # 蓝色
		TJAData.BranchType.EXPERT:
			branch_name = "Expert"
			branch_color = Color(1.0, 0.8, 0.0)  # 金色
		TJAData.BranchType.MASTER:
			branch_name = "Master"
			branch_color = Color(1.0, 0.3, 0.3)  # 红色
		_:
			branch_name = ""
			branch_color = Color(1.0, 1.0, 1.0)

	_branch_label.text = branch_name
	_branch_label.add_theme_color_override("font_color", branch_color)

	# 添加闪烁动画
	var tween = create_tween()
	tween.tween_property(_branch_label, "modulate:a", 0.5, 0.1)
	tween.tween_property(_branch_label, "modulate:a", 1.0, 0.1)
	tween.tween_property(_branch_label, "modulate:a", 0.5, 0.1)
	tween.tween_property(_branch_label, "modulate:a", 1.0, 0.1)


## 显示判定结果
func show_judge_result(judge_type: String) -> void:
	# 停止之前的动画
	if _judge_tween:
		_judge_tween.kill()

	# 设置文本和颜色
	match judge_type:
		"良":
			_judge_label.text = "良"
			_judge_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))  # 金色
		"可":
			_judge_label.text = "可"
			_judge_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))  # 蓝色
		"不可":
			_judge_label.text = "不可"
			_judge_label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2))  # 红色
		_:
			return

	# 重置状态
	_judge_label.modulate.a = 1.0
	_judge_label.scale = Vector2(1.3, 1.3)

	# 创建动画序列
	_judge_tween = create_tween()
	_judge_tween.set_ease(Tween.EASE_OUT)
	_judge_tween.set_trans(Tween.TRANS_BACK)

	# 缩放弹跳动画
	_judge_tween.tween_property(_judge_label, "scale", Vector2.ONE, 0.15)

	# 等待显示
	_judge_tween.tween_interval(0.35)

	# 淡出动画
	_judge_tween.set_ease(Tween.EASE_IN)
	_judge_tween.set_trans(Tween.TRANS_QUAD)
	_judge_tween.tween_property(_judge_label, "modulate:a", 0.0, 0.15)


## 获取游戏控制器
func get_game_controller() -> GameController:
	return _game_controller