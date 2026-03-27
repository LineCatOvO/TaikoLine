## Logo 场景组件
## 功能：显示游戏 Logo，带有呼吸动画和光晕效果
## 作者：TaikoLine Team
## 日期：2026-03-23

extends Control

## Logo 文字
@onready var logo_text: Label = $LogoText

## Logo 光晕层
@onready var logo_glow: Label = $LogoGlow

## 副标题
@onready var sub_title: Label = $SubTitle

## 呼吸动画速度（每秒周期数）
@export var breathe_speed: float = 2.0

## 呼吸幅度（缩放变化范围）
@export var breathe_amplitude: float = 0.05

## 光晕呼吸幅度
@export var glow_breathe_amplitude: float = 0.2

## 基础缩放值
var _base_scale: float = 1.0

## 当前缩放值（用于平滑插值）
var _current_scale: float = 1.0

## 光晕基础透明度
var _glow_base_alpha: float = 0.5

## 初始化时记录基础缩放并设置光晕效果
func _ready() -> void:
	_base_scale = scale.x
	_setup_glow_effect()

## 设置光晕效果
func _setup_glow_effect() -> void:
	if logo_glow:
		_glow_base_alpha = logo_glow.modulate.a
		# 光晕层偏移，产生立体感
		logo_glow.position = Vector2(2, 2)

## 每帧处理呼吸动画
func _process(delta: float) -> void:
	_update_breathe_animation(delta)

## 更新呼吸动画效果
## 使用正弦波实现平滑的缩放变化
func _update_breathe_animation(delta: float) -> void:
	var time = Time.get_ticks_msec() / 1000.0
	
	# 计算目标缩放值：基础缩放 + 正弦波变化
	var scale_factor = sin(time * breathe_speed) * breathe_amplitude
	var target_scale = _base_scale + scale_factor
	
	# 使用 lerp 实现平滑过渡，10.0 为插值速度
	_current_scale = lerp(_current_scale, target_scale, 10.0 * delta)
	scale = Vector2(_current_scale, _current_scale)
	
	# 更新光晕透明度（与缩放相反的呼吸效果）
	if logo_glow:
		var glow_factor = cos(time * breathe_speed) * glow_breathe_amplitude
		var new_alpha = _glow_base_alpha + glow_factor
		logo_glow.modulate.a = clamp(new_alpha, 0.3, 0.7)

## 场景树进入时的回调（预留扩展）
func _on_tree_entered() -> void:
	pass