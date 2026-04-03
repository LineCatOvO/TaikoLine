class_name NoteTrack
extends Control
## 音符轨道效果组件
## 显示音符滚动区域，包括轨道背景、判定线、发光效果等
##
## 设计参考：太鼓达人虹版（Taiko no Tatsujin Nijiiro）
## - 中央横向轨道，带渐变效果
## - 判定线垂直显示，带发光效果
## - Go-Go Time 特效增强

## 信号
signal judge_line_hit

## 配置
@export var track_height: float = 200.0      ## 轨道高度
@export var judge_line_width: float = 4.0    ## 判定线宽度
@export var glow_radius: float = 8.0         ## 发光半径
@export var gogo_glow_multiplier: float = 1.5 ## Go-Go Time 发光倍数

## UI节点引用
var _track_background: ColorRect
var _track_gradient: ColorRect
var _judge_line: ColorRect
var _judge_line_glow: ColorRect
var _judge_line_outer_glow: ColorRect

## 动画Tween
var _glow_tween: Tween
var _gogo_tween: Tween

## Go-Go Time状态
var _is_gogo_active: bool = false

## 基础颜色
var _track_color: Color = Color(0.086, 0.13, 0.24, 0.8)
var _judge_line_color: Color = Color(1.0, 0.84, 0.0, 0.8)
var _glow_color: Color = Color(1.0, 0.84, 0.0, 0.3)


func _ready() -> void:
	_setup_ui()
	_start_glow_animation()


## 设置UI
func _setup_ui() -> void:
	# 轨道背景
	_track_background = ColorRect.new()
	_track_background.color = _track_color
	_track_background.name = "TrackBackground"
	add_child(_track_background)
	
	# 轨道渐变（从左到右渐变）
	_track_gradient = ColorRect.new()
	_track_gradient.color = Color(0.05, 0.08, 0.15, 0.5)
	_track_gradient.name = "TrackGradient"
	add_child(_track_gradient)
	
	# 判定线外发光（最外层）
	_judge_line_outer_glow = ColorRect.new()
	_judge_line_outer_glow.color = Color(_glow_color.r, _glow_color.g, _glow_color.b, 0.1)
	_judge_line_outer_glow.name = "JudgeLineOuterGlow"
	add_child(_judge_line_outer_glow)
	
	# 判定线内发光
	_judge_line_glow = ColorRect.new()
	_judge_line_glow.color = _glow_color
	_judge_line_glow.name = "JudgeLineGlow"
	add_child(_judge_line_glow)
	
	# 判定线
	_judge_line = ColorRect.new()
	_judge_line.color = _judge_line_color
	_judge_line.name = "JudgeLine"
	add_child(_judge_line)
	
	# 设置布局
	_update_layout()


## 更新布局
func _update_layout() -> void:
	var track_y = (size.y - track_height) / 2
	
	# 轨道背景
	_track_background.position = Vector2(0, track_y)
	_track_background.size = Vector2(size.x, track_height)
	
	# 轨道渐变（左侧渐变）
	_track_gradient.position = Vector2(0, track_y)
	_track_gradient.size = Vector2(size.x * 0.3, track_height)
	
	# 判定线位置（屏幕中心偏右）
	var judge_x = size.x * 0.7
	var judge_y = track_y
	var judge_height = track_height
	
	# 判定线外发光
	var outer_glow_size = glow_radius * 2 * gogo_glow_multiplier
	_judge_line_outer_glow.position = Vector2(judge_x - outer_glow_size / 2, judge_y - outer_glow_size / 2)
	_judge_line_outer_glow.size = Vector2(outer_glow_size, judge_height + outer_glow_size)
	
	# 判定线内发光
	_judge_line_glow.position = Vector2(judge_x - glow_radius, judge_y - glow_radius)
	_judge_line_glow.size = Vector2(glow_radius * 2, judge_height + glow_radius * 2)
	
	# 判定线
	_judge_line.position = Vector2(judge_x - judge_line_width / 2, judge_y)
	_judge_line.size = Vector2(judge_line_width, judge_height)


## 启动发光动画
func _start_glow_animation() -> void:
	if _glow_tween:
		_glow_tween.kill()
	
	_glow_tween = create_tween()
	_glow_tween.set_loops()
	
	# 发光脉冲效果
	_glow_tween.tween_property(_judge_line_glow, "color:a", 0.4, 0.5)
	_glow_tween.tween_property(_judge_line_glow, "color:a", 0.3, 0.5)


## 启动Go-Go Time效果
func start_gogo_effect() -> void:
	if _is_gogo_active:
		return
	
	_is_gogo_active = true
	
	# 增强发光效果
	if _gogo_tween:
		_gogo_tween.kill()
	
	_gogo_tween = create_tween()
	
	# 判定线颜色变亮
	var bright_color = Color(_judge_line_color.r * 1.1, _judge_line_color.g * 1.1, _judge_line_color.b * 0.9, 1.0)
	bright_color = bright_color.clamp()
	_gogo_tween.tween_property(_judge_line, "color", bright_color, 0.3)
	
	# 发光增强
	_gogo_tween.parallel().tween_property(_judge_line_glow, "color:a", 0.5, 0.3)
	_gogo_tween.parallel().tween_property(_judge_line_outer_glow, "color:a", 0.2, 0.3)
	
	# 轨道背景变亮
	var bright_track = Color(_track_color.r * 1.2, _track_color.g * 1.2, _track_color.b * 1.1, 0.9)
	bright_track = bright_track.clamp()
	_gogo_tween.parallel().tween_property(_track_background, "color", bright_track, 0.3)


## 结束Go-Go Time效果
func end_gogo_effect() -> void:
	if not _is_gogo_active:
		return
	
	_is_gogo_active = false
	
	# 恢复发光效果
	if _gogo_tween:
		_gogo_tween.kill()
	
	_gogo_tween = create_tween()
	
	# 判定线颜色恢复
	_gogo_tween.tween_property(_judge_line, "color", _judge_line_color, 0.3)
	
	# 发光恢复
	_gogo_tween.parallel().tween_property(_judge_line_glow, "color:a", 0.3, 0.3)
	_gogo_tween.parallel().tween_property(_judge_line_outer_glow, "color:a", 0.1, 0.3)
	
	# 轨道背景恢复
	_gogo_tween.parallel().tween_property(_track_background, "color", _track_color, 0.3)
	
	# 重新启动发光动画
	_start_glow_animation()


## 播放判定线击打效果
func play_hit_effect() -> void:
	judge_line_hit.emit()
	
	# 闪烁效果
	var hit_tween = create_tween()
	hit_tween.tween_property(_judge_line, "color:a", 1.2, 0.05)
	hit_tween.tween_property(_judge_line, "color:a", 0.8, 0.1)
	
	# 发光脉冲
	hit_tween.parallel().tween_property(_judge_line_glow, "color:a", 0.6, 0.05)
	hit_tween.parallel().tween_property(_judge_line_glow, "color:a", 0.3, 0.1)


## 设置轨道颜色
func set_track_color(color: Color) -> void:
	_track_color = color
	_track_background.color = color


## 设置判定线颜色
func set_judge_line_color(color: Color) -> void:
	_judge_line_color = color
	_judge_line.color = color
	_glow_color = Color(color.r, color.g, color.b, 0.3)
	_judge_line_glow.color = _glow_color
	_judge_line_outer_glow.color = Color(color.r, color.g, color.b, 0.1)


## 检查Go-Go状态
func is_gogo_active() -> bool:
	return _is_gogo_active


## 重置
func reset() -> void:
	_is_gogo_active = false
	_judge_line.color = _judge_line_color
	_judge_line_glow.color.a = 0.3
	_judge_line_outer_glow.color.a = 0.1
	_track_background.color = _track_color
	_start_glow_animation()


## 调整大小时更新布局
func _resized() -> void:
	_update_layout()