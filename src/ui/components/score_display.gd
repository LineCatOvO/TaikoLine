class_name ScoreDisplay
extends Control
## 分数显示组件
## 显示当前分数

## 配置
@export var font_size: int = 28
@export var animation_duration: float = 0.3

## UI节点引用
var _score_label: Label
var _label_prefix: Label
var _tween: Tween

## 当前分数
var _current_score: int = 0

## 显示的分数（用于动画）
var _display_score: int = 0


func _ready() -> void:
	_setup_ui()


## 设置UI
func _setup_ui() -> void:
	# 创建主容器
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(hbox)
	hbox.anchors_preset = Control.PRESET_FULL_RECT
	
	# 前缀标签
	_label_prefix = Label.new()
	_label_prefix.text = "SCORE: "
	_label_prefix.add_theme_font_size_override("font_size", font_size)
	_label_prefix.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	hbox.add_child(_label_prefix)
	
	# 分数标签
	_score_label = Label.new()
	_score_label.text = "0"
	_score_label.add_theme_font_size_override("font_size", font_size)
	_score_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))  # 金色
	hbox.add_child(_score_label)


## 更新分数
func update_score(score: int) -> void:
	var old_score = _current_score
	_current_score = score
	
	# 播放分数滚动动画
	_animate_score(old_score, score)


## 动画显示分数变化
func _animate_score(from: int, to: int) -> void:
	if _tween:
		_tween.kill()
	
	# 使用tween来动画化分数变化
	_tween = create_tween()
	_tween.tween_method(_set_display_score, from, to, animation_duration)
	
	# 播放缩放动画
	_tween.set_parallel(true)
	_tween.tween_property(_score_label, "scale", Vector2(1.1, 1.1), 0.1)
	_tween.chain().tween_property(_score_label, "scale", Vector2.ONE, 0.1)


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


## 获取当前分数
func get_score() -> int:
	return _current_score


## 重置
func reset() -> void:
	_current_score = 0
	_display_score = 0
	_score_label.text = "0"
	_score_label.scale = Vector2.ONE


## 设置高亮模式
func set_highlight(enabled: bool) -> void:
	if enabled:
		_score_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.5))
	else:
		_score_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))