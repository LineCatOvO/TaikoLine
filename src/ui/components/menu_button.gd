## 主菜单按钮控制器
## 功能：管理菜单按钮的悬停动画、点击动画、音效反馈
## 作者：TaikoLine Team
## 日期：2026-04-03

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
const HOVER_SCALE := 1.1

## 悬停动画时长（秒）
const HOVER_ANIMATION_DURATION := 0.15

## 按下缩放倍数
const PRESS_SCALE := 0.95

## 按下动画时长（秒）
const PRESS_ANIMATION_DURATION := 0.05

## 发光脉冲周期（秒）
const GLOW_PULSE_CYCLE := 1.0

## 发光脉冲最小透明度
const GLOW_PULSE_MIN_ALPHA := 0.2

## 发光脉冲最大透明度（悬停时）
const GLOW_PULSE_MAX_ALPHA_HOVER := 0.5

## 发光脉冲最大透明度（正常时）
const GLOW_PULSE_MAX_ALPHA_NORMAL := 0.3

## ==================== 状态变量 ====================

## 是否正在悬停
var _is_hovering: bool = false

## 是否正在按下
var _is_pressed: bool = false

## 当前发光脉冲 Tween
var _glow_tween: Tween = null

## ==================== 动画管理器引用 ====================

var animation_manager: Node = null

## ==================== 初始化 ====================

func _ready() -> void:
	# 获取动画管理器引用
	animation_manager = get_node_or_null("/root/AnimationManager")

	# 设置发光效果初始状态
	if glow_effect:
		glow_effect.modulate.a = GLOW_PULSE_MIN_ALPHA

	# 加载音效资源
	_load_sound_resources()

	# 注意：信号已在场景文件中连接，无需重复连接


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
	if _is_hovering:
		_play_hover_animation()
	else:
		_play_normal_animation()


## ==================== 动画执行 ====================

## 播放悬停动画
func _play_hover_animation() -> void:
	if animation_manager:
		animation_manager.create_hover_animation(self, HOVER_SCALE, HOVER_ANIMATION_DURATION)
	else:
		# 直接设置缩放
		scale = Vector2(HOVER_SCALE, HOVER_SCALE)


## 播放正常动画
func _play_normal_animation() -> void:
	if animation_manager:
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_QUAD)
		tween.tween_property(self, "scale", Vector2.ONE, HOVER_ANIMATION_DURATION)
	else:
		scale = Vector2.ONE


## 播放按下动画
func _play_press_animation() -> void:
	if animation_manager:
		animation_manager.create_press_animation(self, PRESS_SCALE, PRESS_ANIMATION_DURATION)
	else:
		# 直接设置缩放
		scale = Vector2(PRESS_SCALE, PRESS_SCALE)


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