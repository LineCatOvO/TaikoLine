## Logo 场景组件
## 功能：显示游戏 Logo，带有呼吸动画和光晕效果
## 作者：TaikoLine Team
## 日期：2026-03-27
## 更新：优化动画性能，使用Tween替代_process中的计算

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

## 光晕基础透明度
var _glow_base_alpha: float = 0.5

## 动画Tween
var _scale_tween: Tween
var _glow_tween: Tween


## 初始化时记录基础缩放并设置光晕效果
func _ready() -> void:
	_base_scale = scale.x
	_setup_glow_effect()
	_start_breathing_animation()


## 设置光晕效果
func _setup_glow_effect() -> void:
	if logo_glow:
		_glow_base_alpha = logo_glow.modulate.a
		# 光晕层偏移，产生立体感
		logo_glow.position = Vector2(2, 2)


## 启动呼吸动画
func _start_breathing_animation() -> void:
	# 缩放呼吸动画
	_scale_tween = create_tween()
	_scale_tween.set_loops()
	_scale_tween.set_ease(Tween.EASE_IN_OUT)
	_scale_tween.set_trans(Tween.TRANS_SINE)

	var cycle_time = 1.0 / breathe_speed
	var max_scale = _base_scale + breathe_amplitude
	var min_scale = _base_scale - breathe_amplitude * 0.5

	_scale_tween.tween_property(self, "scale", Vector2(max_scale, max_scale), cycle_time * 0.5)
	_scale_tween.tween_property(self, "scale", Vector2(min_scale, min_scale), cycle_time * 0.5)

	# 光晕呼吸动画（与缩放相反）
	if logo_glow:
		_glow_tween = create_tween()
		_glow_tween.set_loops()
		_glow_tween.set_ease(Tween.EASE_IN_OUT)
		_glow_tween.set_trans(Tween.TRANS_SINE)

		var min_glow = _glow_base_alpha - glow_breathe_amplitude
		var max_glow = _glow_base_alpha + glow_breathe_amplitude

		_glow_tween.tween_property(logo_glow, "modulate:a", min_glow, cycle_time * 0.5)
		_glow_tween.tween_property(logo_glow, "modulate:a", max_glow, cycle_time * 0.5)


## 停止呼吸动画
func stop_breathing_animation() -> void:
	if _scale_tween:
		_scale_tween.kill()
	if _glow_tween:
		_glow_tween.kill()


## 暂停呼吸动画
func pause_breathing_animation() -> void:
	if _scale_tween:
		_scale_tween.pause()
	if _glow_tween:
		_glow_tween.pause()


## 恢复呼吸动画
func resume_breathing_animation() -> void:
	if _scale_tween:
		_scale_tween.play()
	if _glow_tween:
		_glow_tween.play()


## 播放入场动画
func play_entrance_animation(duration: float = 0.5) -> void:
	# 初始状态
	modulate.a = 0.0
	scale = Vector2(0.8, 0.8)

	# 停止呼吸动画
	stop_breathing_animation()

	# 入场动画
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)

	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, duration)
	tween.tween_property(self, "scale", Vector2(_base_scale, _base_scale), duration)

	# 入场完成后启动呼吸动画
	tween.tween_callback(_start_breathing_animation)


## 播放退场动画
func play_exit_animation(duration: float = 0.3) -> void:
	# 停止呼吸动画
	stop_breathing_animation()

	# 退场动画
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_QUAD)

	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, duration)
	tween.tween_property(self, "scale", Vector2(_base_scale * 1.1, _base_scale * 1.1), duration)


## 场景树进入时的回调（预留扩展）
func _on_tree_entered() -> void:
	pass