class_name ComboDisplay
extends Control
## 连击显示组件
## 显示当前连击数

## 信号
signal combo_animation_finished

## 显示配置
@export var normal_font_size: int = 24
@export var highlight_font_size: int = 36
@export var highlight_threshold: int = 50  ## 高亮显示阈值

## UI节点引用
var _combo_label: Label
var _combo_text_label: Label
var _tween: Tween

## 当前连击数
var _current_combo: int = 0

## 是否高亮模式
var _is_highlighted: bool = false


func _ready() -> void:
	_setup_ui()


## 设置UI
func _setup_ui() -> void:
	# 创建主容器
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(vbox)
	vbox.anchors_preset = Control.PRESET_FULL_RECT
	
	# 连击数字
	_combo_label = Label.new()
	_combo_label.text = "0"
	_combo_label.add_theme_font_size_override("font_size", normal_font_size)
	_combo_label.add_theme_color_override("font_color", Color.WHITE)
	_combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_combo_label)
	
	# 连击文字
	_combo_text_label = Label.new()
	_combo_text_label.text = "COMBO"
	_combo_text_label.add_theme_font_size_override("font_size", 16)
	_combo_text_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	_combo_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_combo_text_label)


## 更新连击数
func update_combo(combo: int) -> void:
	var old_combo = _current_combo
	_current_combo = combo
	
	# 更新文本
	_combo_label.text = str(combo)
	
	# 检查是否需要切换高亮模式
	if combo >= highlight_threshold and not _is_highlighted:
		_enable_highlight()
	elif combo < highlight_threshold and _is_highlighted:
		_disable_highlight()
	
	# 播放动画
	if combo > 0:
		_play_combo_animation()
	else:
		_play_break_animation()
	
	# 更新可见性
	visible = combo > 0


## 启用高亮模式
func _enable_highlight() -> void:
	_is_highlighted = true
	
	if _tween:
		_tween.kill()
	
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(_combo_label, "modulate", Color(1.0, 0.8, 0.0), 0.2)  # 金色
	_tween.tween_method(_animate_font_size, normal_font_size, highlight_font_size, 0.2)


## 禁用高亮模式
func _disable_highlight() -> void:
	_is_highlighted = false
	
	if _tween:
		_tween.kill()
	
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(_combo_label, "modulate", Color.WHITE, 0.2)
	_tween.tween_method(_animate_font_size, highlight_font_size, normal_font_size, 0.2)


## 播放连击动画
func _play_combo_animation() -> void:
	if _tween:
		_tween.kill()
	
	var original_scale = Vector2.ONE
	var bounce_scale = Vector2(1.2, 1.2)
	
	_tween = create_tween()
	_tween.tween_property(_combo_label, "scale", bounce_scale, 0.1)
	_tween.tween_property(_combo_label, "scale", original_scale, 0.1)


## 播放断连动画
func _play_break_animation() -> void:
	if _tween:
		_tween.kill()
	
	_tween = create_tween()
	_tween.tween_property(_combo_label, "modulate:a", 0.0, 0.3)
	_tween.tween_callback(_reset_display)


## 重置显示
func _reset_display() -> void:
	_combo_label.modulate.a = 1.0
	_combo_label.scale = Vector2.ONE


## 字体大小动画辅助方法
func _animate_font_size(size: float) -> void:
	_combo_label.add_theme_font_size_override("font_size", int(size))


## 获取当前连击数
func get_combo() -> int:
	return _current_combo


## 重置
func reset() -> void:
	_current_combo = 0
	_combo_label.text = "0"
	_combo_label.modulate = Color.WHITE
	_combo_label.scale = Vector2.ONE
	_combo_label.add_theme_font_size_override("font_size", normal_font_size)
	_is_highlighted = false
	visible = false