## 设置界面背景控制器
## 功能：管理设置界面背景的渐变效果、发光动画
## 参考 Taiko no Tatsujin 设置界面风格
## 作者：TaikoLine Team
## 日期：2026-04-03

extends Control

## ==================== 节点引用 ====================

## 背景渐变
@onready var background_gradient: ColorRect = $BackgroundGradient

## 发光叠加层
@onready var glow_overlay: ColorRect = $GlowOverlay

## 顶部发光
@onready var glow_top: ColorRect = $GlowTop

## 底部发光
@onready var glow_bottom: ColorRect = $GlowBottom

## ==================== 动画参数 ====================

## 发光脉冲周期（秒）
const GLOW_PULSE_CYCLE := 4.0

## 发光脉冲最小透明度
const GLOW_PULSE_MIN_ALPHA := 0.08

## 发光脉冲最大透明度
const GLOW_PULSE_MAX_ALPHA := 0.15

## 顶部发光脉冲最大透明度
const GLOW_TOP_MAX_ALPHA := 0.2

## 底部发光脉冲最大透明度
const GLOW_BOTTOM_MAX_ALPHA := 0.1

## ==================== 颜色配置 ====================

## 背景颜色（深紫色）
const BACKGROUND_COLOR := Color(0.08, 0.04, 0.15, 1.0)

## 发光颜色（紫色调）
const GLOW_COLOR := Color(0.25, 0.12, 0.4, 1.0)

## 顶部发光颜色（亮紫色）
const GLOW_TOP_COLOR := Color(0.35, 0.18, 0.55, 1.0)

## 底部发光颜色（深紫色）
const GLOW_BOTTOM_COLOR := Color(0.15, 0.08, 0.25, 1.0)

## ==================== 初始化 ====================

func _ready() -> void:
	# 设置初始颜色
	_setup_colors()

	# 启动发光脉冲动画
	_start_glow_pulse_animation()


## 设置初始颜色
func _setup_colors() -> void:
	if background_gradient:
		background_gradient.color = BACKGROUND_COLOR

	if glow_overlay:
		glow_overlay.color = GLOW_COLOR
		glow_overlay.modulate.a = GLOW_PULSE_MIN_ALPHA

	if glow_top:
		glow_top.color = GLOW_TOP_COLOR
		glow_top.modulate.a = GLOW_PULSE_MIN_ALPHA

	if glow_bottom:
		glow_bottom.color = GLOW_BOTTOM_COLOR
		glow_bottom.modulate.a = GLOW_PULSE_MIN_ALPHA


## ==================== 发光脉冲动画 ====================

## 启动发光脉冲动画
func _start_glow_pulse_animation() -> void:
	# 主发光层脉冲动画
	if glow_overlay:
		var tween = create_tween()
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_loops()  # 无限循环

		tween.tween_property(glow_overlay, "modulate:a", GLOW_PULSE_MAX_ALPHA, GLOW_PULSE_CYCLE * 0.5)
		tween.tween_property(glow_overlay, "modulate:a", GLOW_PULSE_MIN_ALPHA, GLOW_PULSE_CYCLE * 0.5)

	# 顶部发光脉冲动画（相位偏移）
	if glow_top:
		var top_tween = create_tween()
		top_tween.set_ease(Tween.EASE_IN_OUT)
		top_tween.set_trans(Tween.TRANS_SINE)
		top_tween.set_loops()

		# 相位偏移 1 秒
		top_tween.tween_property(glow_top, "modulate:a", GLOW_TOP_MAX_ALPHA, GLOW_PULSE_CYCLE * 0.5)
		top_tween.tween_property(glow_top, "modulate:a", GLOW_PULSE_MIN_ALPHA, GLOW_PULSE_CYCLE * 0.5)

	# 底部发光脉冲动画（相位偏移）
	if glow_bottom:
		var bottom_tween = create_tween()
		bottom_tween.set_ease(Tween.EASE_IN_OUT)
		bottom_tween.set_trans(Tween.TRANS_SINE)
		bottom_tween.set_loops()

		# 相位偏移 2 秒
		bottom_tween.tween_property(glow_bottom, "modulate:a", GLOW_BOTTOM_MAX_ALPHA, GLOW_PULSE_CYCLE * 0.5)
		bottom_tween.tween_property(glow_bottom, "modulate:a", GLOW_PULSE_MIN_ALPHA, GLOW_PULSE_CYCLE * 0.5)


## ==================== 颜色设置 ====================

## 设置背景颜色
## @param color: 背景颜色
func set_background_color(color: Color) -> void:
	if background_gradient:
		background_gradient.color = color


## 设置发光颜色
## @param color: 发光颜色
func set_glow_color(color: Color) -> void:
	if glow_overlay:
		glow_overlay.color = color


## 设置顶部发光颜色
## @param color: 顶部发光颜色
func set_glow_top_color(color: Color) -> void:
	if glow_top:
		glow_top.color = color


## 设置底部发光颜色
## @param color: 底部发光颜色
func set_glow_bottom_color(color: Color) -> void:
	if glow_bottom:
		glow_bottom.color = color


## ==================== 动画控制 ====================

## 暂停所有动画
func pause_animations() -> void:
	set_process(false)


## 恢复所有动画
func resume_animations() -> void:
	set_process(true)


## ==================== 入场动画 ====================

## 入场动画
func play_enter_animation() -> void:
	# 设置初始状态
	modulate.a = 0.0

	# 创建入场动画
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "modulate:a", 1.0, 0.5)