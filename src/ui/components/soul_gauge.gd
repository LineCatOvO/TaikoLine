class_name SoulGauge
extends Control
## 魂槽显示组件
## 显示当前魂槽进度

## 信号
signal soul_threshold_reached

## 配置
@export var max_soul: float = 10000.0
@export var clear_threshold: float = 8000.0  ## 清除阈值
@export var animation_duration: float = 0.3

## 颜色配置
@export var normal_color: Color = Color(0.3, 0.6, 1.0)  ## 蓝色
@export var clear_color: Color = Color(1.0, 0.8, 0.0)   ## 金色（清除状态）
@export var danger_color: Color = Color(1.0, 0.3, 0.3)  ## 红色（危险状态）

## UI节点引用
var _background: ColorRect
var _fill: ColorRect
var _threshold_line: ColorRect
var _label: Label
var _tween: Tween

## 当前魂槽值
var _current_soul: float = 0.0

## 是否已达到清除阈值
var _is_clear: bool = false


func _ready() -> void:
	_setup_ui()


## 设置UI
func _setup_ui() -> void:
	# 设置最小尺寸
	custom_minimum_size = Vector2(200, 30)
	
	# 背景
	_background = ColorRect.new()
	_background.color = Color(0.2, 0.2, 0.2)
	add_child(_background)
	_background.anchors_preset = Control.PRESET_FULL_RECT
	
	# 填充条
	_fill = ColorRect.new()
	_fill.color = normal_color
	_background.add_child(_fill)
	_fill.anchors_preset = Control.PRESET_LEFT_WIDE
	_fill.offset_right = 0
	
	# 阈值线
	_threshold_line = ColorRect.new()
	_threshold_line.color = Color.WHITE
	_threshold_line.custom_minimum_size = Vector2(2, 30)
	_background.add_child(_threshold_line)
	
	# 标签
	_label = Label.new()
	_label.text = "0%"
	_label.add_theme_font_size_override("font_size", 14)
	_label.add_theme_color_override("font_color", Color.WHITE)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(_label)
	_label.anchors_preset = Control.PRESET_CENTER
	
	# 初始化阈值线位置
	_update_threshold_line_position()


## 更新阈值线位置
func _update_threshold_line_position() -> void:
	var threshold_ratio = clear_threshold / max_soul
	var width = size.x
	_threshold_line.position.x = width * threshold_ratio - 1
	_threshold_line.position.y = 0


## 更新魂槽值
func update_soul(soul: float) -> void:
	var old_soul = _current_soul
	_current_soul = clamp(soul, 0.0, max_soul)
	
	# 计算百分比
	var percentage = (_current_soul / max_soul) * 100.0
	
	# 更新标签
	_label.text = "%.1f%%" % percentage
	
	# 更新填充条
	_update_fill(percentage)
	
	# 检查清除状态变化
	var was_clear = _is_clear
	_is_clear = _current_soul >= clear_threshold
	
	if _is_clear and not was_clear:
		_on_threshold_reached()
	elif not _is_clear and was_clear:
		_on_threshold_lost()
	
	# 更新颜色
	_update_color()


## 更新填充条
func _update_fill(percentage: float) -> void:
	if _tween:
		_tween.kill()
	
	var target_width = (percentage / 100.0) * size.x
	
	_tween = create_tween()
	_tween.tween_property(_fill, "size:x", target_width, animation_duration)


## 更新颜色
func _update_color() -> void:
	var target_color: Color
	
	if _is_clear:
		target_color = clear_color
	elif _current_soul < max_soul * 0.3:
		target_color = danger_color
	else:
		target_color = normal_color
	
	if _tween:
		_tween.kill()
	
	_tween = create_tween()
	_tween.tween_property(_fill, "color", target_color, 0.2)


## 达到阈值回调
func _on_threshold_reached() -> void:
	soul_threshold_reached.emit()
	
	# 播放闪烁动画
	if _tween:
		_tween.kill()
	
	_tween = create_tween()
	_tween.tween_property(_fill, "modulate", Color(1.5, 1.5, 1.5), 0.1)
	_tween.tween_property(_fill, "modulate", Color.WHITE, 0.1)


## 失去阈值回调
func _on_threshold_lost() -> void:
	pass


## 获取当前魂槽值
func get_soul() -> float:
	return _current_soul


## 获取百分比
func get_percentage() -> float:
	return (_current_soul / max_soul) * 100.0


## 检查是否清除状态
func is_clear() -> bool:
	return _is_clear


## 重置
func reset() -> void:
	_current_soul = 0.0
	_is_clear = false
	_fill.size.x = 0
	_fill.color = normal_color
	_label.text = "0%"


## 调整大小时更新阈值线
func _resized() -> void:
	_update_threshold_line_position()