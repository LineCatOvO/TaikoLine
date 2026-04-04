## 波纹效果组件
## 功能：在点击位置创建扩散的波纹动画效果
## 作者：TaikoLine Team
## 日期：2026-04-03

class_name RippleEffect
extends Control

## 信号
signal ripple_completed

## 配置参数
@export var ripple_color: Color = Color(1.0, 0.8, 0.0, 0.5)  ## 金色波纹
@export var ripple_duration: float = 0.6  ## 波纹持续时间
@export var max_scale: float = 3.0  ## 最大扩散倍数
@export var ripple_count: int = 1  ## 同时波纹数量
@export var auto_remove: bool = true  ## 动画完成后自动移除

## 波纹节点列表
var _ripples: Array[ColorRect] = []

## 活动的 Tween
var _active_tweens: Array[Tween] = []


func _ready() -> void:
	# 设置为覆盖整个父节点区域
	anchors_preset = Control.PRESET_FULL_RECT
	offset_left = 0
	offset_right = 0
	offset_top = 0
	offset_bottom = 0
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## 在指定位置创建波纹
## 参数 position: 波纹起始位置（相对于本节点）
## 参数 color: 波纹颜色（可选，默认使用配置颜色）
func create_ripple(position: Vector2, color: Color = ripple_color) -> void:
	# 创建波纹节点
	var ripple = ColorRect.new()
	ripple.color = color
	ripple.modulate.a = 0.8

	# 设置波纹大小（从小到大）
	var start_size = 20.0
	ripple.custom_minimum_size = Vector2(start_size, start_size)
	ripple.size = Vector2(start_size, start_size)

	# 设置位置（居中于点击位置）
	ripple.position = position - Vector2(start_size / 2, start_size / 2)

	# 设置锚点为中心
	ripple.anchors_preset = Control.PRESET_CENTER

	add_child(ripple)
	_ripples.append(ripple)

	# 创建扩散动画
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)

	# 并行执行缩放和透明度变化
	tween.set_parallel(true)
	tween.tween_property(ripple, "scale", Vector2(max_scale, max_scale), ripple_duration)
	tween.tween_property(ripple, "modulate:a", 0.0, ripple_duration)

	# 动画完成回调
	tween.set_parallel(false)
	tween.tween_callback(_on_ripple_completed.bind(ripple, tween))

	_active_tweens.append(tween)


## 在全局位置创建波纹
## 参数 global_position: 全局坐标位置
func create_ripple_at_global(global_position: Vector2) -> void:
	var local_pos = global_position - global_position
	create_ripple(local_pos)


## 创建多个波纹（连续效果）
## 参数 position: 波纹起始位置
## 参数 count: 波纹数量
## 参数 delay: 波纹之间的延迟
func create_multiple_ripples(position: Vector2, count: int = 3, delay: float = 0.1) -> void:
	for i in range(count):
		await get_tree().create_timer(i * delay).timeout
		create_ripple(position, ripple_color)


## 创建彩色波纹（用于特殊效果）
## 参数 position: 波纹起始位置
## 参数 colors: 颜色数组
func create_colorful_ripples(position: Vector2, colors: Array[Color] = []) -> void:
	if colors.is_empty():
		colors = [
			Color(1.0, 0.3, 0.3, 0.5),  # 红色
			Color(1.0, 0.8, 0.0, 0.5),  # 金色
			Color(0.3, 0.8, 0.3, 0.5)   # 绿色
		]

	for i in range(colors.size()):
		await get_tree().create_timer(i * 0.08).timeout
		create_ripple(position, colors[i])


## 波纹完成回调
func _on_ripple_completed(ripple: ColorRect, tween: Tween) -> void:
	ripples_completed.emit()

	# 移除波纹节点
	_ripples.erase(ripple)
	_active_tweens.erase(tween)

	if auto_remove:
		ripple.queue_free()


## 停止所有波纹动画
func stop_all_ripples() -> void:
	for tween in _active_tweens:
		if tween and tween.is_valid():
			tween.kill()

	_active_tweens.clear()

	for ripple in _ripples:
		ripple.queue_free()

	_ripples.clear()


## 设置波纹颜色
func set_ripple_color(color: Color) -> void:
	ripple_color = color


## 设置波纹持续时间
func set_ripple_duration(duration: float) -> void:
	ripple_duration = duration


## 设置最大扩散倍数
func set_max_scale(scale: float) -> void:
	max_scale = scale


## 静态方法：在指定节点上创建波纹效果
## 参数 parent: 父节点
## 参数 position: 波纹位置
## 参数 color: 波纹颜色
## 返回: 创建的波纹效果节点
static func spawn_ripple(parent: Control, position: Vector2, color: Color = Color(1.0, 0.8, 0.0, 0.5)) -> RippleEffect:
	var ripple_effect = RippleEffect.new()
	ripple_effect.ripple_color = color
	parent.add_child(ripple_effect)
	ripple_effect.create_ripple(position, color)
	return ripple_effect


## 静态方法：在按钮点击时创建波纹
## 参数 button: 按钮节点
## 参数 event: 输入事件
static func spawn_button_ripple(button: Button, event: InputEventMouseButton) -> RippleEffect:
	if not event.pressed:
		return null

	var ripple_effect = RippleEffect.new()
	ripple_effect.ripple_color = Color(1.0, 0.8, 0.0, 0.4)
	ripple_effect.ripple_duration = 0.5
	ripple_effect.max_scale = 2.5
	button.add_child(ripple_effect)

	# 获取点击位置（相对于按钮）
	var local_pos = event.position
	ripple_effect.create_ripple(local_pos)

	return ripple_effect