## 发光效果组件
## 功能：为 UI 元素添加可配置的发光效果，支持多种发光模式
## 作者：TaikoLine Team
## 日期：2026-04-03

class_name GlowEffect
extends Control

## 发光模式
enum GlowMode {
	STATIC,         ## 静态发光（固定强度）
	PULSE,          ## 脉冲发光（周期性变化）
	BREATH,         ## 呼吸发光（缓慢变化）
	FLASH,          ## 闪烁发光（快速闪烁）
	RAINBOW         ## 彩虹发光（颜色渐变）
}

## 信号
signal glow_started
signal glow_stopped

## 配置参数
@export var glow_mode: GlowMode = GlowMode.PULSE
@export var glow_color: Color = Color(1.0, 0.8, 0.0, 0.5)  ## 金色发光
@export var glow_intensity: float = 0.5  ## 发光强度（0-1）
@export var glow_size: float = 10.0  ## 发光扩散大小
@export var pulse_speed: float = 1.0  ## 脉冲速度
@export var rainbow_speed: float = 0.5  ## 彩虹渐变速度
@export var flash_count: int = 3  ## 闪烁次数

## 发光层节点
var _glow_layer: ColorRect

## 动画 Tween
var _glow_tween: Tween

## 是否正在播放
var _is_playing: bool = false

## 彩虹颜色索引
var _rainbow_index: float = 0.0


func _ready() -> void:
	_setup_glow_layer()


## 设置发光层
func _setup_glow_layer() -> void:
	# 创建发光层（覆盖整个区域）
	_glow_layer = ColorRect.new()
	_glow_layer.color = glow_color
	_glow_layer.modulate.a = glow_intensity

	# 设置全屏锚点
	_glow_layer.anchors_preset = Control.PRESET_FULL_RECT
	_glow_layer.offset_left = -glow_size
	_glow_layer.offset_right = glow_size
	_glow_layer.offset_top = -glow_size
	_glow_layer.offset_bottom = glow_size

	# 添加到节点树（在最底层）
	add_child(_glow_layer)
	move_child(_glow_layer, 0)

	# 设置鼠标过滤
	_glow_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## 开始发光效果
func start_glow() -> void:
	if _is_playing:
		return

	_is_playing = true
	glow_started.emit()

	match glow_mode:
		GlowMode.STATIC:
			_apply_static_glow()
		GlowMode.PULSE:
			_start_pulse_glow()
		GlowMode.BREATH:
			_start_breath_glow()
		GlowMode.FLASH:
			_start_flash_glow()
		GlowMode.RAINBOW:
			_start_rainbow_glow()


## 停止发光效果
func stop_glow() -> void:
	_is_playing = false

	if _glow_tween and _glow_tween.is_valid():
		_glow_tween.kill()
		_glow_tween = null

	_glow_layer.modulate.a = 0.0
	glow_stopped.emit()


## 应用静态发光
func _apply_static_glow() -> void:
	_glow_layer.modulate.a = glow_intensity


## 开始脉冲发光
func _start_pulse_glow() -> void:
	var cycle_duration = 1.0 / pulse_speed

	_glow_tween = create_tween()
	_glow_tween.set_ease(Tween.EASE_IN_OUT)
	_glow_tween.set_trans(Tween.TRANS_SINE)
	_glow_tween.set_loops()

	_glow_tween.tween_property(_glow_layer, "modulate:a", glow_intensity * 1.5, cycle_duration * 0.5)
	_glow_tween.tween_property(_glow_layer, "modulate:a", glow_intensity * 0.5, cycle_duration * 0.5)


## 开始呼吸发光
func _start_breath_glow() -> void:
	var cycle_duration = 2.0 / pulse_speed

	_glow_tween = create_tween()
	_glow_tween.set_ease(Tween.EASE_IN_OUT)
	_glow_tween.set_trans(Tween.TRANS_SINE)
	_glow_tween.set_loops()

	_glow_tween.tween_property(_glow_layer, "modulate:a", glow_intensity * 1.2, cycle_duration * 0.5)
	_glow_tween.tween_property(_glow_layer, "modulate:a", glow_intensity * 0.8, cycle_duration * 0.5)


## 开始闪烁发光
func _start_flash_glow() -> void:
	var flash_duration = 0.1

	_glow_tween = create_tween()

	for i in range(flash_count):
		_glow_tween.tween_property(_glow_layer, "modulate:a", glow_intensity * 2.0, flash_duration)
		_glow_tween.tween_property(_glow_layer, "modulate:a", glow_intensity * 0.3, flash_duration)

	# 闪烁完成后恢复到脉冲模式
	_glow_tween.tween_callback(_start_pulse_glow)


## 开始彩虹发光
func _start_rainbow_glow() -> void:
	var cycle_duration = 3.0 / rainbow_speed

	_glow_tween = create_tween()
	_glow_tween.set_loops()

	# 使用方法调用来更新颜色
	_glow_tween.tween_method(_update_rainbow_color, 0.0, 1.0, cycle_duration)


## 更新彩虹颜色
func _update_rainbow_color(value: float) -> void:
	# 使用 HSV 颜色空间创建彩虹效果
	var hue = value
	var saturation = 0.8
	var value_color = 1.0

	var rainbow_color = Color.from_hsv(hue, saturation, value_color, glow_intensity)
	_glow_layer.color = rainbow_color


## 设置发光颜色
func set_glow_color(color: Color) -> void:
	glow_color = color
	if _glow_layer and glow_mode != GlowMode.RAINBOW:
		_glow_layer.color = color


## 设置发光强度
func set_glow_intensity(intensity: float) -> void:
	glow_intensity = clamp(intensity, 0.0, 1.0)
	if _glow_layer and glow_mode == GlowMode.STATIC:
		_glow_layer.modulate.a = glow_intensity


## 设置发光大小
func set_glow_size(size: float) -> void:
	glow_size = size
	if _glow_layer:
		_glow_layer.offset_left = -glow_size
		_glow_layer.offset_right = glow_size
		_glow_layer.offset_top = -glow_size
		_glow_layer.offset_bottom = glow_size


## 设置发光模式
func set_glow_mode(mode: GlowMode) -> void:
	glow_mode = mode

	if _is_playing:
		# 停止当前动画并重新开始
		if _glow_tween and _glow_tween.is_valid():
			_glow_tween.kill()
		start_glow()


## 设置脉冲速度
func set_pulse_speed(speed: float) -> void:
	pulse_speed = speed

	if _is_playing and glow_mode in [GlowMode.PULSE, GlowMode.BREATH]:
		if _glow_tween and _glow_tween.is_valid():
			_glow_tween.kill()
		start_glow()


## 暂停发光效果
func pause_glow() -> void:
	if _glow_tween and _glow_tween.is_valid():
		_glow_tween.pause()


## 恢复发光效果
func resume_glow() -> void:
	if _glow_tween and _glow_tween.is_valid():
		_glow_tween.play()


## 检查是否正在播放
func is_playing() -> bool:
	return _is_playing


## 获取当前发光强度
func get_current_intensity() -> float:
	return _glow_layer.modulate.a if _glow_layer else 0.0


## 静态方法：为按钮添加发光效果
## 参数 button: 目标按钮
## 参数 color: 发光颜色
## 参数 mode: 发光模式
## 返回: 创建的发光效果节点
static func add_glow_to_button(button: Button, color: Color = Color(1.0, 0.8, 0.0, 0.5), mode: GlowMode = GlowMode.PULSE) -> GlowEffect:
	var glow = GlowEffect.new()
	glow.glow_color = color
	glow.glow_mode = mode
	glow.glow_intensity = 0.4
	glow.glow_size = 8.0
	button.add_child(glow)
	glow.start_glow()
	return glow


## 静态方法：创建一次性闪烁效果
## 参数 parent: 父节点
## 参数 color: 闪烁颜色
## 参数 count: 闪烁次数
static func create_flash_effect(parent: Control, color: Color = Color(1.0, 1.0, 1.0, 0.8), count: int = 3) -> GlowEffect:
	var glow = GlowEffect.new()
	glow.glow_color = color
	glow.glow_mode = GlowMode.FLASH
	glow.flash_count = count
	glow.glow_intensity = 0.6
	parent.add_child(glow)
	glow.start_glow()
	return glow


## 静态方法：创建彩虹发光效果
## 参数 parent: 父节点
## 参数 speed: 渐变速度
static func create_rainbow_glow(parent: Control, speed: float = 0.5) -> GlowEffect:
	var glow = GlowEffect.new()
	glow.glow_mode = GlowMode.RAINBOW
	glow.rainbow_speed = speed
	glow.glow_intensity = 0.5
	parent.add_child(glow)
	glow.start_glow()
	return glow