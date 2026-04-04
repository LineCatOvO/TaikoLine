## 主菜单按钮控制器
## 功能：管理菜单按钮的悬停动画、点击动画、波纹效果、音效反馈
## 作者：TaikoLine Team
## 日期：2026-04-03
## 更新：添加波纹效果、优化动画流畅度

extends Button

## ==================== 节点引用 ====================

## 发光效果层
@onready var glow_effect: ColorRect = $GlowEffect

## 悬停音效播放器
@onready var hover_sound: AudioStreamPlayer = $HoverSound

## 确认音效播放器
@onready var confirm_sound: AudioStreamPlayer = $ConfirmSound

## ==================== 动画参数 ====================

## 悬停缩放倍数
const HOVER_SCALE := 1.08

## 悬停动画时长（秒）
const HOVER_ANIMATION_DURATION := 0.12

## 按下缩放倍数
const PRESS_SCALE := 0.92

## 按下动画时长（秒）
const PRESS_ANIMATION_DURATION := 0.08

## 恢复动画时长（秒）
const RECOVER_ANIMATION_DURATION := 0.15

## 发光脉冲周期（秒）
const GLOW_PULSE_CYCLE := 1.2

## 发光脉冲最小透明度
const GLOW_PULSE_MIN_ALPHA := 0.15

## 发光脉冲最大透明度（悬停时）
const GLOW_PULSE_MAX_ALPHA_HOVER := 0.6

## 发光脉冲最大透明度（正常时）
const GLOW_PULSE_MAX_ALPHA_NORMAL := 0.25

## 波纹效果参数
const RIPPLE_DURATION := 0.5
const RIPPLE_MAX_SCALE := 2.5
const RIPPLE_COLOR := Color(1.0, 0.8, 0.0, 0.4)

## ==================== 状态变量 ====================

## 是否正在悬停
var _is_hovering: bool = false

## 是否正在按下
var _is_pressed: bool = false

## 当前发光脉冲 Tween
var _glow_tween: Tween = null

## 波纹效果 Tween
var _ripple_tween: Tween = null

## 波纹效果节点
var _ripple_effect: ColorRect = null

## ==================== 动画管理器引用 ====================

var animation_manager: Node = null

## ==================== 初始化 ====================

func _ready() -> void:
	# 获取动画管理器引用
	animation_manager = get_node_or_null("/root/AnimationManager")

	# 设置发光效果初始状态
	if glow_effect:
		glow_effect.modulate.a = GLOW_PULSE_MIN_ALPHA

	# 创建波纹效果节点
	_setup_ripple_effect()

	# 加载音效资源
	_load_sound_resources()

	# 启动默认发光脉冲动画
	_start_glow_pulse_animation(false)

	# 注意：信号已在场景文件中连接，无需重复连接


## ==================== 波纹效果设置 ====================

## 设置波纹效果节点
func _setup_ripple_effect() -> void:
	_ripple_effect = ColorRect.new()
	_ripple_effect.color = RIPPLE_COLOR
	_ripple_effect.custom_minimum_size = Vector2(20, 20)
	_ripple_effect.size = Vector2(20, 20)
	_ripple_effect.modulate.a = 0.0
	_ripple_effect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ripple_effect.z_index = 10  # 确保在最上层
	add_child(_ripple_effect)


## ==================== 音效加载 ====================

## 加载音效资源
func _load_sound_resources() -> void:
	# 悬停音效
	if hover_sound:
		var hover_stream = load("res://resources/sounds/ui/navigate.wav")
		if hover_stream:
			hover_sound.stream = hover_stream

	# 确认音效
	if confirm_sound:
		var confirm_stream = load("res://resources/sounds/ui/confirm.wav")
		if confirm_stream:
			confirm_sound.stream = confirm_stream


## ==================== 悬停动画 ====================

## 鼠标进入响应
func _on_mouse_entered() -> void:
	_is_hovering = true

	# 播放悬停音效
	_play_hover_sound()

	# 执行悬停动画
	_play_hover_animation()

	# 启动发光脉冲动画（增强）
	_start_glow_pulse_animation(true)


## 鼠标退出响应
func _on_mouse_exited() -> void:
	_is_hovering = false

	# 执行恢复动画
	_play_normal_animation()

	# 启动发光脉冲动画（正常）
	_start_glow_pulse_animation(false)


## 焦点进入响应
func _on_focus_entered() -> void:
	# 焦点进入时也执行悬停效果
	_is_hovering = true
	_play_hover_sound()
	_play_hover_animation()
	_start_glow_pulse_animation(true)


## 焦点退出响应
func _on_focus_exited() -> void:
	_is_hovering = false
	_play_normal_animation()
	_start_glow_pulse_animation(false)


## 按钮点击响应
func _on_pressed() -> void:
	# 播放确认音效
	play_confirm_sound()

	# 创建点击波纹效果
	_create_click_ripple()


## ==================== 波纹效果 ====================

## 创建点击波纹效果
func _create_click_ripple() -> void:
	if not _ripple_effect:
		return

	# 停止之前的波纹动画
	if _ripple_tween and _ripple_tween.is_valid():
		_ripple_tween.kill()

	# 设置波纹初始状态
	_ripple_effect.scale = Vector2.ONE
	_ripple_effect.modulate.a = 0.6
	_ripple_effect.position = size / 2 - Vector2(10, 10)  # 居中于按钮

	# 创建扩散动画
	_ripple_tween = create_tween()
	_ripple_tween.set_ease(Tween.EASE_OUT)
	_ripple_tween.set_trans(Tween.TRANS_QUAD)

	_ripple_tween.set_parallel(true)
	_ripple_tween.tween_property(_ripple_effect, "scale", Vector2(RIPPLE_MAX_SCALE, RIPPLE_MAX_SCALE), RIPPLE_DURATION)
	_ripple_tween.tween_property(_ripple_effect, "modulate:a", 0.0, RIPPLE_DURATION)


## ==================== 按下动画 ====================

## 按钮按下响应
func _on_button_down() -> void:
	_is_pressed = true

	# 执行按下动画
	_play_press_animation()


## 按钮释放响应
func _on_button_up() -> void:
	_is_pressed = false

	# 执行恢复动画
	_play_recover_animation()


## ==================== 动画执行 ====================

## 播放悬停动画
func _play_hover_animation() -> void:
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)  # 使用 BACK 缓动，更有弹性
	tween.tween_property(self, "scale", Vector2(HOVER_SCALE, HOVER_SCALE), HOVER_ANIMATION_DURATION)


## 播放正常动画
func _play_normal_animation() -> void:
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "scale", Vector2.ONE, RECOVER_ANIMATION_DURATION)


## 播放按下动画
func _play_press_animation() -> void:
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "scale", Vector2(PRESS_SCALE, PRESS_SCALE), PRESS_ANIMATION_DURATION)


## 播放恢复动画（按下后恢复）
func _play_recover_animation() -> void:
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	var target_scale = HOVER_SCALE if _is_hovering else 1.0
	tween.tween_property(self, "scale", Vector2(target_scale, target_scale), RECOVER_ANIMATION_DURATION)


## ==================== 发光脉冲动画 ====================

## 启动发光脉冲动画
## @param enhanced: 是否增强发光效果（悬停时）
func _start_glow_pulse_animation(enhanced: bool = false) -> void:
	if not glow_effect:
		return

	# 停止之前的发光动画
	if _glow_tween and _glow_tween.is_valid():
		_glow_tween.kill()

	# 创建新的发光脉冲动画
	_glow_tween = create_tween()
	_glow_tween.set_ease(Tween.EASE_IN_OUT)
	_glow_tween.set_trans(Tween.TRANS_SINE)
	_glow_tween.set_loops()  # 无限循环

	var max_alpha = GLOW_PULSE_MAX_ALPHA_HOVER if enhanced else GLOW_PULSE_MAX_ALPHA_NORMAL

	_glow_tween.tween_property(glow_effect, "modulate:a", max_alpha, GLOW_PULSE_CYCLE * 0.5)
	_glow_tween.tween_property(glow_effect, "modulate:a", GLOW_PULSE_MIN_ALPHA, GLOW_PULSE_CYCLE * 0.5)


## ==================== 音效播放 ====================

## 播放悬停音效
func _play_hover_sound() -> void:
	# 使用 AudioManager 播放音效（优先）
	if AudioManager:
		AudioManager.play_ui_navigate()
	elif hover_sound:
		# 使用本地音效播放器
		hover_sound.play()


## 播放确认音效
func play_confirm_sound() -> void:
	# 使用 AudioManager 播放音效（优先）
	if AudioManager:
		AudioManager.play_ui_confirm()
	elif confirm_sound:
		# 使用本地音效播放器
		confirm_sound.play()


## ==================== 外部接口 ====================

## 设置按钮文字
## @param text: 按钮文字
func set_button_text(text: String) -> void:
	self.text = text


## 设置发光颜色
## @param color: 发光颜色
func set_glow_color(color: Color) -> void:
	if glow_effect:
		glow_effect.color = color


## 暂停所有动画
func pause_animations() -> void:
	if _glow_tween and _glow_tween.is_valid():
		_glow_tween.pause()


## 恢复所有动画
func resume_animations() -> void:
	if _glow_tween and _glow_tween.is_valid():
		_glow_tween.play()