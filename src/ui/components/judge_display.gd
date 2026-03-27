class_name JudgeDisplay
extends Control
## 判定显示组件
## 显示判定结果（良/可/不可）
##
## 性能优化说明：
## - 复用Tween对象，避免频繁创建和销毁
## - 减少不必要的属性设置

## 判定类型
enum JudgeType {
	PERFECT,  ## 良
	GOOD,     ## 可
	MISS      ## 不可
}

## 显示配置
@export var display_duration: float = 0.5  ## 显示持续时间（秒）
@export var fade_duration: float = 0.2    ## 淡出时间（秒）

## UI节点引用
var _label: Label
var _tween: Tween

## 当前显示时间
var _display_time: float = 0.0

## 是否正在显示
var _is_showing: bool = false


func _ready() -> void:
	_setup_ui()


## 设置UI
func _setup_ui() -> void:
	# 创建标签
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 32)
	_label.add_theme_color_override("font_color", Color.WHITE)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(_label)

	# 设置锚点
	_label.anchors_preset = Control.PRESET_FULL_RECT
	_label.offset_left = 0
	_label.offset_right = 0
	_label.offset_top = 0
	_label.offset_bottom = 0

	# 初始隐藏
	_label.modulate.a = 0.0


## 获取或创建Tween（优化版本 - 复用Tween）
func _get_tween() -> Tween:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	return _tween


## 显示判定结果
func show_judge(judge_type: JudgeType) -> void:
	# 设置文本和颜色
	match judge_type:
		JudgeType.PERFECT:
			_label.text = "良"
			_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))  # 金色
		JudgeType.GOOD:
			_label.text = "可"
			_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))  # 蓝色
		JudgeType.MISS:
			_label.text = "不可"
			_label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2))  # 红色

	# 重置透明度
	_label.modulate.a = 1.0
	_is_showing = true
	_display_time = 0.0

	# 创建淡出动画
	var tween = _get_tween()
	tween.tween_interval(display_duration)
	tween.tween_property(_label, "modulate:a", 0.0, fade_duration)
	tween.tween_callback(_on_display_finished)


## 显示自定义文本
func show_custom_text(text: String, color: Color = Color.WHITE) -> void:
	_label.text = text
	_label.add_theme_color_override("font_color", color)
	_label.modulate.a = 1.0
	_is_showing = true

	# 创建淡出动画
	var tween = _get_tween()
	tween.tween_interval(display_duration)
	tween.tween_property(_label, "modulate:a", 0.0, fade_duration)
	tween.tween_callback(_on_display_finished)


## 显示完成回调
func _on_display_finished() -> void:
	_is_showing = false


## 检查是否正在显示
func is_displaying() -> bool:
	return _is_showing


## 立即隐藏
func hide_immediately() -> void:
	if _tween:
		_tween.kill()
	_label.modulate.a = 0.0
	_is_showing = false