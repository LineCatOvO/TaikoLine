## Logo 场景组件
## 功能：显示游戏 Logo，带有呼吸动画效果
## 作者：TaikoLine Team
## 日期：2026-03-23

extends Control

## Logo 文字
@onready var logo_text: Label = $LogoText

## 副标题
@onready var sub_title: Label = $SubTitle

## 呼吸动画速度（每秒周期数）
@export var breathe_speed: float = 2.0

## 呼吸幅度（缩放变化范围）
@export var breathe_amplitude: float = 0.05

## 基础缩放值
var _base_scale: float = 1.0

## 当前缩放值（用于平滑插值）
var _current_scale: float = 1.0

## 初始化时记录基础缩放
func _ready() -> void:
	_base_scale = scale.x

## 每帧处理呼吸动画
func _process(delta: float) -> void:
	_update_breathe_animation(delta)

## 更新呼吸动画效果
## 使用正弦波实现平滑的缩放变化
func _update_breathe_animation(delta: float) -> void:
	var time = Time.get_ticks_msec() / 1000.0
	# 计算目标缩放值：基础缩放 + 正弦波变化
	var target_scale = _base_scale + sin(time * breathe_speed) * breathe_amplitude
	# 使用 lerp 实现平滑过渡，10.0 为插值速度
	_current_scale = lerp(_current_scale, target_scale, 10.0 * delta)
	scale = Vector2(_current_scale, _current_scale)

## 场景树进入时的回调（预留扩展）
func _on_tree_entered() -> void:
	pass
