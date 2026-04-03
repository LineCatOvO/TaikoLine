class_name SoulStatus
extends Control
## 魂槽状态指示器组件
## 显示清除/未清除状态
##
## 设计参考：太鼓达人虹版结果界面魂槽状态显示
## - 清除状态：显示"CLEAR"文字和金色图标
## - 未清除状态：显示"FAILED"文字和灰色图标

## 信号
signal status_animation_finished

## 状态类型
enum StatusType {
	CLEAR,    ## 清除（魂槽达到阈值）
	FAILED    ## 未清除（魂槽未达到阈值）
}

## 配置
@export var icon_size: float = 80.0
@export var animation_duration: float = 0.5

## 颜色配置
const COLOR_CLEAR := Color(1.0, 0.85, 0.0)  # 金色
const COLOR_FAILED := Color(0.5, 0.5, 0.5)  # 灰色

## UI节点引用
var _icon_container: Control
var _icon_shape: Polygon2D
var _icon_glow: Polygon2D
var _status_label: Label
var _soul_percentage_label: Label
var _tween: Tween
var _glow_tween: Tween

## 当前状态类型
var _current_status: StatusType = StatusType.CLEAR

## 魂槽百分比
var _soul_percentage: float = 100.0

## 是否正在播放动画
var _is_animating: bool = false


func _ready() -> void:
	_setup_ui()


## 设置UI
func _setup_ui() -> void:
	# 设置最小尺寸
	custom_minimum_size = Vector2(icon_size * 2, icon_size * 1.5)

	# 创建图标容器
	_icon_container = Control.new()
	_icon_container.custom_minimum_size = Vector2(icon_size, icon_size)
	add_child(_icon_container)
	_icon_container.anchors_preset = Control.PRESET_CENTER_TOP
	_icon_container.offset_top = 20

	# 创建发光效果（底层）
	_icon_glow = Polygon2D.new()
	_icon_glow.color = COLOR_CLEAR
	_icon_glow.modulate.a = 0.0
	_icon_container.add_child(_icon_glow)
	_create_soul_icon(_icon_glow, icon_size * 1.1)

	# 创建魂图标形状（类似太鼓的圆形）
	_icon_shape = Polygon2D.new()
	_icon_shape.color = COLOR_CLEAR
	_icon_container.add_child(_icon_shape)
	_create_soul_icon(_icon_shape, icon_size)

	# 创建状态标签
	_status_label = Label.new()
	_status_label.text = "CLEAR"
	_status_label.add_theme_font_size_override("font_size", 24)
	_status_label.add_theme_color_override("font_color", COLOR_CLEAR)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_status_label)
	_status_label.anchors_preset = Control.PRESET_BOTTOM_WIDE
	_status_label.offset_top = -50

	# 创建魂槽百分比标签
	_soul_percentage_label = Label.new()
	_soul_percentage_label.text = "100%"
	_soul_percentage_label.add_theme_font_size_override("font_size", 16)
	_soul_percentage_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	_soul_percentage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_soul_percentage_label)
	_soul_percentage_label.anchors_preset = Control.PRESET_BOTTOM_WIDE
	_soul_percentage_label.offset_top = -25

	# 初始隐藏
	modulate.a = 0.0
	scale = Vector2(0.5, 0.5)


## 创建魂图标多边形（圆形）
func _create_soul_icon(polygon: Polygon2D, size: float) -> void:
	# 创建圆形多边形（使用多个点模拟圆形）
	var points: PackedVector2Array = []
	var segments = 32  # 圆形分段数

	for i in range(segments):
		var angle = (i / float(segments)) * 2 * PI
		var x = cos(angle) * size * 0.5
		var y = sin(angle) * size * 0.5
		points.append(Vector2(x, y))

	polygon.polygon = points
	polygon.position = Vector2(size * 0.5, size * 0.5)


## 获取或创建Tween（优化版本 - 复用Tween）
func _get_tween() -> Tween:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	return _tween


## 设置状态
func set_status(status: StatusType, percentage: float = 100.0) -> void:
	_current_status = status
	_soul_percentage = percentage

	# 设置颜色和文本
	var icon_color: Color
	var glow_color: Color
	var status_text: String

	match status:
		StatusType.CLEAR:
			icon_color = COLOR_CLEAR
			glow_color = Color(1.5, 1.2, 0.0)  # 更亮的金色
			status_text = "CLEAR"
		StatusType.FAILED:
			icon_color = COLOR_FAILED
			glow_color = Color(0.6, 0.6, 0.6)
			status_text = "FAILED"

	# 更新颜色
	_icon_shape.color = icon_color
	_icon_glow.color = glow_color
	_status_label.add_theme_color_override("font_color", icon_color)
	_status_label.text = status_text

	# 更新百分比
	_soul_percentage_label.text = "%.1f%%" % percentage


## 播放入场动画
func play_appear_animation() -> void:
	_is_animating = true

	var tween = _get_tween()
	tween.set_parallel(true)

	# 缩放动画（弹性效果）
	tween.tween_property(self, "scale", Vector2.ONE, animation_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	# 淡入动画
	tween.tween_property(self, "modulate:a", 1.0, animation_duration * 0.5)

	# 发光效果（仅清除状态）
	if _current_status == StatusType.CLEAR:
		tween.tween_callback(_start_glow_animation)

	tween.tween_callback(_on_animation_finished)


## 开始发光动画（循环）
func _start_glow_animation() -> void:
	if _glow_tween and _glow_tween.is_valid():
		_glow_tween.kill()

	_glow_tween = create_tween()
	_glow_tween.set_loops()  # 无限循环

	# 发光脉冲效果
	_glow_tween.tween_property(_icon_glow, "modulate:a", 0.4, 1.0)
	_glow_tween.tween_property(_icon_glow, "modulate:a", 0.0, 1.0)


## 停止发光动画
func stop_glow_animation() -> void:
	if _glow_tween and _glow_tween.is_valid():
		_glow_tween.kill()
	_icon_glow.modulate.a = 0.0


## 动画完成回调
func _on_animation_finished() -> void:
	_is_animating = false
	status_animation_finished.emit()


## 播放庆祝动画（清除状态）
func play_celebration_animation() -> void:
	var tween = _get_tween()

	# 连续弹跳效果
	tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.15)
	tween.tween_property(self, "scale", Vector2(0.95, 0.95), 0.1)
	tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.1)
	tween.tween_property(self, "scale", Vector2.ONE, 0.1)


## 播放失败动画（未清除状态）
func play_failed_animation() -> void:
	var tween = _get_tween()

	# 抖动效果
	var original_pos = position
	tween.tween_property(self, "position:x", original_pos.x + 5, 0.05)
	tween.tween_property(self, "position:x", original_pos.x - 5, 0.05)
	tween.tween_property(self, "position:x", original_pos.x + 3, 0.05)
	tween.tween_property(self, "position:x", original_pos.x, 0.05)


## 获取当前状态
func get_status() -> StatusType:
	return _current_status


## 获取魂槽百分比
func get_soul_percentage() -> float:
	return _soul_percentage


## 检查是否正在播放动画
func is_animating() -> bool:
	return _is_animating


## 重置
func reset() -> void:
	stop_glow_animation()
	modulate.a = 0.0
	scale = Vector2(0.5, 0.5)
	_current_status = StatusType.CLEAR
	_soul_percentage = 100.0
	_is_animating = false