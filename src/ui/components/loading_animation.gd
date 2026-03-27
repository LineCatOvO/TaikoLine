## 加载动画组件
## 功能：显示加载中的动画效果，支持多种动画样式
## 作者：TaikoLine Team
## 日期：2026-03-27

extends Control

## 加载动画类型
enum LoadingType {
	SPINNER,        ## 旋转加载
	DOTS,           ## 跳动点
	BAR,            ## 进度条
	PULSE,          ## 脉冲圆
	TAIKO_DRUM      ## 太鼓敲击
}

## 信号
signal animation_started
signal animation_stopped

## 配置
@export var loading_type: LoadingType = LoadingType.SPINNER
@export var animation_speed: float = 1.0
@export var primary_color: Color = Color(1.0, 0.3, 0.3)  ## 红色（太鼓风格）
@export var secondary_color: Color = Color(1.0, 0.8, 0.0)  ## 金色
@export var background_color: Color = Color(0, 0, 0, 0.7)
@export var show_text: bool = true
@export var loading_text: String = "Loading..."

## UI节点
var _background: ColorRect
var _animation_container: Control
var _text_label: Label

## 动画相关
var _tween: Tween
var _is_playing: bool = false
var _rotation_tween: Tween
var _dots: Array[Control] = []
var _bar_fill: ColorRect
var _pulse_circle: ColorRect
var _taiko_drum: Control

## 旋转角度
var _current_rotation: float = 0.0


func _ready() -> void:
	_setup_ui()
	_setup_animation()


## 设置UI布局
func _setup_ui() -> void:
	# 设置全屏
	anchors_preset = Control.PRESET_FULL_RECT
	offset_left = 0
	offset_right = 0
	offset_top = 0
	offset_bottom = 0

	# 背景
	_background = ColorRect.new()
	_background.color = background_color
	_background.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_background)
	_background.anchors_preset = Control.PRESET_FULL_RECT

	# 主容器（居中）
	var center_container = CenterContainer.new()
	add_child(center_container)
	center_container.anchors_preset = Control.PRESET_CENTER
	center_container.custom_minimum_size = Vector2(200, 200)

	# 动画容器
	_animation_container = Control.new()
	_animation_container.custom_minimum_size = Vector2(100, 100)
	center_container.add_child(_animation_container)

	# 文字标签
	_text_label = Label.new()
	_text_label.text = loading_text
	_text_label.add_theme_font_size_override("font_size", 20)
	_text_label.add_theme_color_override("font_color", Color.WHITE)
	_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_text_label.position = Vector2(-50, 120)
	_text_label.custom_minimum_size = Vector2(200, 30)
	center_container.add_child(_text_label)

	# 初始隐藏
	visible = false


## 设置动画
func _setup_animation() -> void:
	# 清除现有动画元素
	_clear_animation_elements()

	match loading_type:
		LoadingType.SPINNER:
			_setup_spinner()
		LoadingType.DOTS:
			_setup_dots()
		LoadingType.BAR:
			_setup_bar()
		LoadingType.PULSE:
			_setup_pulse()
		LoadingType.TAIKO_DRUM:
			_setup_taiko_drum()


## 清除动画元素
func _clear_animation_elements() -> void:
	for child in _animation_container.get_children():
		child.queue_free()
	_dots.clear()
	_bar_fill = null
	_pulse_circle = null
	_taiko_drum = null


## 设置旋转加载动画
func _setup_spinner() -> void:
	# 创建旋转的圆环
	var spinner = Control.new()
	spinner.custom_minimum_size = Vector2(80, 80)
	_animation_container.add_child(spinner)
	spinner.position = Vector2(10, 10)

	# 绘制圆弧（使用多个小方块模拟）
	for i in range(8):
		var dot = ColorRect.new()
		dot.color = primary_color if i < 4 else secondary_color
		dot.custom_minimum_size = Vector2(10, 10)
		spinner.add_child(dot)

		# 计算位置（圆形排列）
		var angle = i * PI / 4
		var radius = 30.0
		dot.position = Vector2(
			40 + cos(angle) * radius - 5,
			40 + sin(angle) * radius - 5
		)

		# 设置透明度渐变
		dot.modulate.a = 0.3 + (i % 4) * 0.2


## 设置跳动点动画
func _setup_dots() -> void:
	var container = HBoxContainer.new()
	container.alignment = BoxContainer.ALIGNMENT_CENTER
	container.custom_minimum_size = Vector2(100, 30)
	_animation_container.add_child(container)
	container.position = Vector2(0, 35)

	# 创建3个点
	for i in range(3):
		var dot = ColorRect.new()
		dot.color = primary_color
		dot.custom_minimum_size = Vector2(20, 20)
		container.add_child(dot)
		_dots.append(dot)

		# 添加间距
		if i < 2:
			var spacer = Control.new()
			spacer.custom_minimum_size = Vector2(10, 0)
			container.add_child(spacer)


## 设置进度条动画
func _setup_bar() -> void:
	# 进度条容器
	var bar_container = Control.new()
	bar_container.custom_minimum_size = Vector2(150, 20)
	_animation_container.add_child(bar_container)
	bar_container.position = Vector2(-25, 40)

	# 背景
	var bar_bg = ColorRect.new()
	bar_bg.color = Color(0.3, 0.3, 0.3)
	bar_bg.custom_minimum_size = Vector2(150, 20)
	bar_container.add_child(bar_bg)

	# 填充
	_bar_fill = ColorRect.new()
	_bar_fill.color = primary_color
	_bar_fill.custom_minimum_size = Vector2(0, 20)
	bar_container.add_child(_bar_fill)


## 设置脉冲圆动画
func _setup_pulse() -> void:
	# 创建脉冲圆
	_pulse_circle = ColorRect.new()
	_pulse_circle.color = primary_color
	_pulse_circle.custom_minimum_size = Vector2(60, 60)
	_animation_container.add_child(_pulse_circle)
	_pulse_circle.position = Vector2(20, 20)

	# 添加圆角效果（通过shader或简化处理）
	# 这里使用简化版本


## 设置太鼓敲击动画
func _setup_taiko_drum() -> void:
	_taiko_drum = Control.new()
	_taiko_drum.custom_minimum_size = Vector2(100, 100)
	_animation_container.add_child(_taiko_drum)
	_taiko_drum.position = Vector2(0, 0)

	# 太鼓主体（圆形）
	var drum_body = ColorRect.new()
	drum_body.color = primary_color
	drum_body.custom_minimum_size = Vector2(80, 80)
	_taiko_drum.add_child(drum_body)
	drum_body.position = Vector2(10, 10)

	# 太鼓中心（白色圆）
	var drum_center = ColorRect.new()
	drum_center.color = Color.WHITE
	drum_center.custom_minimum_size = Vector2(40, 40)
	_taiko_drum.add_child(drum_center)
	drum_center.position = Vector2(30, 30)

	# 鼓棒（两个小方块）
	var stick1 = ColorRect.new()
	stick1.color = secondary_color
	stick1.custom_minimum_size = Vector2(30, 8)
	_taiko_drum.add_child(stick1)
	stick1.position = Vector2(-20, 46)
	stick1.rotation = -0.3

	var stick2 = ColorRect.new()
	stick2.color = secondary_color
	stick2.custom_minimum_size = Vector2(30, 8)
	_taiko_drum.add_child(stick2)
	stick2.position = Vector2(90, 46)
	stick2.rotation = 0.3


## 开始播放动画
func start_animation() -> void:
	if _is_playing:
		return

	visible = true
	_is_playing = true
	animation_started.emit()

	# 根据类型播放动画
	match loading_type:
		LoadingType.SPINNER:
			_play_spinner_animation()
		LoadingType.DOTS:
			_play_dots_animation()
		LoadingType.BAR:
			_play_bar_animation()
		LoadingType.PULSE:
			_play_pulse_animation()
		LoadingType.TAIKO_DRUM:
			_play_taiko_animation()


## 停止动画
func stop_animation() -> void:
	_is_playing = false
	visible = false

	if _tween:
		_tween.kill()
		_tween = null

	if _rotation_tween:
		_rotation_tween.kill()
		_rotation_tween = null

	animation_stopped.emit()


## 播放旋转动画
func _play_spinner_animation() -> void:
	if not _is_playing:
		return

	var spinner = _animation_container.get_child(0) if _animation_container.get_child_count() > 0 else null
	if not spinner:
		return

	# 创建无限旋转动画
	_rotation_tween = create_tween()
	_rotation_tween.set_loops()
	_rotation_tween.tween_property(spinner, "rotation", TAU, 1.0 / animation_speed)


## 播放跳动点动画
func _play_dots_animation() -> void:
	if not _is_playing:
		return

	# 为每个点创建跳动动画
	for i in range(_dots.size()):
		var dot = _dots[i]
		var delay = i * 0.15

		# 创建延迟后的跳动动画
		var tween = create_tween()
		tween.tween_interval(delay)
		tween.set_loops()
		tween.tween_property(dot, "position:y", -15, 0.2 / animation_speed)
		tween.tween_property(dot, "position:y", 0, 0.2 / animation_speed)
		tween.tween_interval(0.3 / animation_speed)


## 播放进度条动画
func _play_bar_animation() -> void:
	if not _is_playing:
		return

	if not _bar_fill:
		return

	# 创建循环的进度条动画
	_tween = create_tween()
	_tween.set_loops()
	_tween.tween_property(_bar_fill, "custom_minimum_size:x", 150.0, 0.8 / animation_speed)
	_tween.tween_property(_bar_fill, "custom_minimum_size:x", 0.0, 0.8 / animation_speed)


## 播放脉冲动画
func _play_pulse_animation() -> void:
	if not _is_playing:
		return

	if not _pulse_circle:
		return

	# 创建脉冲动画
	_tween = create_tween()
	_tween.set_loops()
	_tween.set_parallel(true)
	_tween.tween_property(_pulse_circle, "scale", Vector2(1.5, 1.5), 0.5 / animation_speed)
	_tween.tween_property(_pulse_circle, "modulate:a", 0.0, 0.5 / animation_speed)
	_tween.tween_callback(_reset_pulse)
	_tween.tween_interval(0.2 / animation_speed)


## 重置脉冲
func _reset_pulse() -> void:
	if _pulse_circle:
		_pulse_circle.scale = Vector2.ONE
		_pulse_circle.modulate.a = 1.0


## 播放太鼓动画
func _play_taiko_animation() -> void:
	if not _is_playing:
		return

	if not _taiko_drum:
		return

	# 获取鼓棒
	var stick1 = _taiko_drum.get_child(2) if _taiko_drum.get_child_count() > 2 else null
	var stick2 = _taiko_drum.get_child(3) if _taiko_drum.get_child_count() > 3 else null

	# 创建敲击动画
	_tween = create_tween()
	_tween.set_loops()

	# 左鼓棒敲击
	if stick1:
		_tween.tween_property(stick1, "rotation", 0.3, 0.15 / animation_speed)
		_tween.tween_property(stick1, "rotation", -0.3, 0.15 / animation_speed)

	# 右鼓棒敲击
	if stick2:
		_tween.tween_property(stick2, "rotation", -0.3, 0.15 / animation_speed)
		_tween.tween_property(stick2, "rotation", 0.3, 0.15 / animation_speed)

	# 太鼓震动效果
	var drum_body = _taiko_drum.get_child(0) if _taiko_drum.get_child_count() > 0 else null
	if drum_body:
		_tween.tween_property(drum_body, "scale", Vector2(1.05, 1.05), 0.1 / animation_speed)
		_tween.tween_property(drum_body, "scale", Vector2.ONE, 0.1 / animation_speed)


## 设置加载文字
func set_loading_text(text: String) -> void:
	loading_text = text
	if _text_label:
		_text_label.text = text


## 设置动画速度
func set_animation_speed(speed: float) -> void:
	animation_speed = speed
	# 重新设置动画
	if _is_playing:
		stop_animation()
		start_animation()


## 设置颜色
func set_colors(primary: Color, secondary: Color) -> void:
	primary_color = primary
	secondary_color = secondary
	_setup_animation()


## 设置动画类型
func set_loading_type(type: LoadingType) -> void:
	loading_type = type
	_setup_animation()


## 检查是否正在播放
func is_playing() -> bool:
	return _is_playing


## 显示加载动画（静态方法）
static func show_loading(parent: Node, type: LoadingType = LoadingType.SPINNER) -> Control:
	var loading = preload("res://src/ui/components/loading_animation.gd").new()
	loading.loading_type = type
	parent.add_child(loading)
	loading.start_animation()
	return loading


## 隐藏加载动画（静态方法）
static func hide_loading(loading: Control) -> void:
	if loading and loading.has_method("stop_animation"):
		loading.stop_animation()
		loading.queue_free()