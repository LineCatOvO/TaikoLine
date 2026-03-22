## 菜单按钮组件
## 功能：带有悬停缩放动画的菜单按钮
## 作者：TaikoLine Team
## 日期：2026-03-23

extends Button

## 悬停时的缩放倍数（1.1 表示放大 10%）
@export var hover_scale: float = 1.1

## 动画插值速度（越大越快）
@export var animation_speed: float = 10.0

## 基础缩放值（按钮原始大小）
var _base_scale: Vector2 = Vector2(1, 1)

## 当前缩放值（用于平滑插值）
var _current_scale: Vector2 = Vector2(1, 1)

## 鼠标是否悬停在按钮上
var _is_hovered: bool = false

## 初始化时记录基础缩放
func _ready() -> void:
	_base_scale = scale

## 每帧处理悬停动画
func _process(delta: float) -> void:
	_update_hover_animation(delta)

## 更新悬停动画效果
## 当鼠标悬停时放大按钮，离开时恢复原状
func _update_hover_animation(delta: float) -> void:
	# 根据悬停状态确定目标缩放值
	var target_scale = hover_scale if _is_hovered else 1.0
	# 使用 lerp 实现平滑过渡
	_current_scale.x = lerp(_current_scale.x, target_scale, animation_speed * delta)
	_current_scale.y = lerp(_current_scale.y, target_scale, animation_speed * delta)
	# 应用缩放（基于基础缩放值）
	scale = _base_scale * _current_scale

## 鼠标进入时触发悬停状态
func _on_mouse_entered() -> void:
	_is_hovered = true

## 鼠标离开时取消悬停状态
func _on_mouse_exited() -> void:
	_is_hovered = false

## 按钮按下时的回调（预留扩展）
func _on_pressed() -> void:
	pass
