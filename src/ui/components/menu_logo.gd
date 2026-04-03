## 主菜单 Logo 控制器
## 功能：管理主菜单 Logo 的发光效果、呼吸动画
## 作者：TaikoLine Team
## 日期：2026-04-03

extends Control

## ==================== 节点引用 ====================

## Logo 发光层
@onready var logo_glow: Label = $LogoGlow

## Logo 文字层
@onready var logo_text: Label = $LogoText

## 副标题
@onready var sub_title: Label = $SubTitle

## ==================== 动画参数 ====================

## 呼吸动画周期（秒）
const BREATHING_CYCLE := 2.0

## 呼吸动画最小缩放
const BREATHING_MIN_SCALE := 0.98

## 呼吸动画最大缩放
const BREATHING_MAX_SCALE := 1.02

## 发光脉冲周期（秒）
const GLOW_PULSE_CYCLE := 1.5

## 发光脉冲最小透明度
const GLOW_PULSE_MIN_ALPHA := 0.3

## 发光脉冲最大透明度
const GLOW_PULSE_MAX_ALPHA := 0.6

## 入场动画时长（秒）
const ENTER_ANIMATION_DURATION := 0.5

## ==================== 动画管理器引用 ====================

var animation_manager: Node = null

## ==================== 初始化 ====================

func _ready() -> void:
	# 获取动画管理器引用
	animation_manager = get_node_or_null("/root/AnimationManager")

	# 设置初始状态
	_set_initial_state()

	# 启动入场动画
	_play_enter_animation()

	# 启动呼吸动画
	_start_breathing_animation()

	# 启动发光脉冲动画
	_start_glow_pulse_animation()


## ==================== 初始状态设置 ====================

## 设置初始状态
func _set_initial_state() -> void:
	# Logo 初始透明度为 0（用于入场动画）
	modulate.a = 0.0

	# 发光层初始透明度
	if logo_glow:
		logo_glow.modulate.a = GLOW_PULSE_MIN_ALPHA


## ==================== 入场动画 ====================

## 播放入场动画
func _play_enter_animation() -> void:
	if animation_manager:
		# 使用淡入+缩放组合动画
		animation_manager.create_fade_scale_in(self, ENTER_ANIMATION_DURATION)
	else:
		# 直接设置透明度
		modulate.a = 1.0


## ==================== 呼吸动画 ====================

## 启动呼吸动画
func _start_breathing_animation() -> void:
	# 创建无限循环的呼吸动画
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_loops()  # 无限循环

	# 缩放呼吸动画
	tween.tween_property(self, "scale", Vector2(BREATHING_MAX_SCALE, BREATHING_MAX_SCALE), BREATHING_CYCLE * 0.5)
	tween.tween_property(self, "scale", Vector2(BREATHING_MIN_SCALE, BREATHING_MIN_SCALE), BREATHING_CYCLE * 0.5)


## ==================== 发光脉冲动画 ====================

## 启动发光脉冲动画
func _start_glow_pulse_animation() -> void:
	if not logo_glow:
		return

	# 创建无限循环的发光脉冲动画
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_loops()  # 无限循环

	# 透明度脉冲动画
	tween.tween_property(logo_glow, "modulate:a", GLOW_PULSE_MAX_ALPHA, GLOW_PULSE_CYCLE * 0.5)
	tween.tween_property(logo_glow, "modulate:a", GLOW_PULSE_MIN_ALPHA, GLOW_PULSE_CYCLE * 0.5)


## ==================== 文字设置 ====================

## 设置主标题文字
## @param text: 标题文字
func set_title_text(text: String) -> void:
	if logo_text:
		logo_text.text = text

	if logo_glow:
		logo_glow.text = text


## 设置副标题文字
## @param text: 副标题文字
func set_subtitle_text(text: String) -> void:
	if sub_title:
		sub_title.text = text


## ==================== 颜色设置 ====================

## 设置主标题颜色
## @param color: 文字颜色
func set_title_color(color: Color) -> void:
	if logo_text:
		logo_text.add_theme_color_override("font_color", color)


## 设置发光颜色
## @param color: 发光颜色
func set_glow_color(color: Color) -> void:
	if logo_glow:
		logo_glow.add_theme_color_override("font_color", color)


## ==================== 动画控制 ====================

## 暂停所有动画
func pause_animations() -> void:
	# 停止所有 Tween
	var tweens = get_tree().get_nodes_in_group("tween")
	for tween in tweens:
		if tween.is_valid():
			tween.pause()


## 恢复所有动画
func resume_animations() -> void:
	# 恢复所有 Tween
	var tweens = get_tree().get_nodes_in_group("tween")
	for tween in tweens:
		if tween.is_valid():
			tween.play()