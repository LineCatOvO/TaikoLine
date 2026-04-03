## 设置标签页按钮控制器
## 功能：管理设置界面标签页按钮的样式和动画效果
## 参考 Taiko no Tatsujin 设置界面风格
## 作者：TaikoLine Team
## 日期：2026-04-03

extends Button

## ==================== 信号 ====================

## 标签页选中信号
signal tab_selected(tab_index: int)

## ==================== 导出变量 ====================

## 标签页索引
@export var tab_index: int = 0

## 标签页图标（可选）
@export var tab_icon: Texture2D = null

## 是否显示图标
@export var show_icon: bool = true

## ==================== 节点引用 ====================

## 图标显示节点
@onready var icon_display: TextureRect = $HBoxContainer/IconDisplay

## 文字显示节点
@onready var text_display: Label = $HBoxContainer/TextDisplay

## 选中指示器
@onready var selection_indicator: ColorRect = $SelectionIndicator

## 发光效果层
@onready var glow_effect: ColorRect = $GlowEffect

## ==================== 动画参数 ====================

## 悬停缩放倍数
const HOVER_SCALE := 1.05

## 选中缩放倍数
const SELECTED_SCALE := 1.08

## 悬停动画时长（秒）
const HOVER_ANIMATION_DURATION := 0.15

## 按下缩放倍数
const PRESS_SCALE := 0.95

## 按下动画时长（秒）
const PRESS_ANIMATION_DURATION := 0.05

## 发光脉冲周期（秒）
const GLOW_PULSE_CYCLE := 1.5

## 发光脉冲最小透明度
const GLOW_PULSE_MIN_ALPHA := 0.1

## 发光脉冲最大透明度（选中时）
const GLOW_PULSE_MAX_ALPHA_SELECTED := 0.4

## 发光脉冲最大透明度（悬停时）
const GLOW_PULSE_MAX_ALPHA_HOVER := 0.3

## 选中指示器动画时长
const INDICATOR_ANIMATION_DURATION := 0.2

## ==================== 状态变量 ====================

## 是否正在悬停
var _is_hovering: bool = false

## 是否正在按下
var _is_pressed: bool = false

## 是否已选中
var _is_selected: bool = false

## 当前发光脉冲 Tween
var _glow_tween: Tween = null

## 选中指示器 Tween
var _indicator_tween: Tween = null

## ==================== 动画管理器引用 ====================

var animation_manager: Node = null

## ==================== 初始化 ====================

func _ready() -> void:
	# 获取动画管理器引用
	animation_manager = get_node_or_null("/root/AnimationManager")

	# 设置初始状态
	_setup_initial_state()

	# 设置图标
	_setup_icon()

	# 连接信号
	connect_signals()


## 设置初始状态
func _setup_initial_state() -> void:
	# 设置发光效果初始状态
	if glow_effect:
		glow_effect.modulate.a = GLOW_PULSE_MIN_ALPHA

	# 设置选中指示器初始状态
	if selection_indicator:
		selection_indicator.modulate.a = 0.0


## 设置图标
func _setup_icon() -> void:
	if icon_display and tab_icon:
		icon_display.texture = tab_icon
		icon_display.visible = show_icon
	elif icon_display:
		icon_display.visible = false


## 连接信号
func connect_signals() -> void:
	# 鼠标悬停信号
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	# 焦点信号
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)

	# 按钮信号
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	pressed.connect(_on_pressed)


## ==================== 公共方法 ====================

## 设置选中状态
## @param selected: 是否选中
func set_selected(selected: bool) -> void:
	_is_selected = selected

	# 更新选中指示器动画
	_update_selection_indicator()

	# 更新发光效果
	_update_glow_effect()

	# 更新缩放
	_update_scale()


## 获取选中状态
func is_selected() -> bool:
	return _is_selected


## 设置标签页文字
## @param text: 标签页文字
func set_tab_text(text: String) -> void:
	if text_display:
		text_display.text = text
	else:
		self.text = text


## 设置标签页图标
## @param icon: 图标纹理
func set_tab_icon(icon: Texture2D) -> void:
	tab_icon = icon
	_setup_icon()


## ==================== 动画执行 ====================

## 更新选中指示器动画
func _update_selection_indicator() -> void:
	if not selection_indicator:
		return

	# 停止之前的动画
	if _indicator_tween and _indicator_tween.is_valid():
		_indicator_tween.kill()

	# 创建新动画
	_indicator_tween = create_tween()
	_indicator_tween.set_ease(Tween.EASE_OUT)
	_indicator_tween.set_trans(Tween.TRANS_QUAD)

	if _is_selected:
		# 显示选中指示器
		_indicator_tween.tween_property(selection_indicator, "modulate:a", 1.0, INDICATOR_ANIMATION_DURATION)
		# 同时扩展宽度
		_indicator_tween.set_parallel(true)
		_indicator_tween.tween_property(selection_indicator, "size:x", custom_minimum_size.x, INDICATOR_ANIMATION_DURATION)
	else:
		# 隐藏选中指示器
		_indicator_tween.tween_property(selection_indicator, "modulate:a", 0.0, INDICATOR_ANIMATION_DURATION)


## 更新发光效果
func _update_glow_effect() -> void:
	_start_glow_pulse_animation(_is_selected or _is_hovering)


## 更新缩放
func _update_scale() -> void:
	var target_scale = Vector2.ONE

	if _is_selected:
		target_scale = Vector2(SELECTED_SCALE, SELECTED_SCALE)
	elif _is_hovering:
		target_scale = Vector2(HOVER_SCALE, HOVER_SCALE)

	if _is_pressed:
		target_scale = Vector2(PRESS_SCALE, PRESS_SCALE)

	# 执行缩放动画
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "scale", target_scale, HOVER_ANIMATION_DURATION)


## 启动发光脉冲动画
## @param enhanced: 是否增强发光效果
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

	var max_alpha = GLOW_PULSE_MAX_ALPHA_SELECTED if _is_selected else (GLOW_PULSE_MAX_ALPHA_HOVER if enhanced else GLOW_PULSE_MIN_ALPHA)

	_glow_tween.tween_property(glow_effect, "modulate:a", max_alpha, GLOW_PULSE_CYCLE * 0.5)
	_glow_tween.tween_property(glow_effect, "modulate:a", GLOW_PULSE_MIN_ALPHA, GLOW_PULSE_CYCLE * 0.5)


## ==================== 信号处理 ====================

## 鼠标进入响应
func _on_mouse_entered() -> void:
	_is_hovering = true

	# 播放悬停音效
	_play_hover_sound()

	# 更新视觉效果
	if not _is_selected:
		_update_scale()
		_start_glow_pulse_animation(true)


## 鼠标退出响应
func _on_mouse_exited() -> void:
	_is_hovering = false

	# 更新视觉效果
	if not _is_selected:
		_update_scale()
		_start_glow_pulse_animation(false)


## 焦点进入响应
func _on_focus_entered() -> void:
	_is_hovering = true

	# 播放悬停音效
	_play_hover_sound()

	# 更新视觉效果
	if not _is_selected:
		_update_scale()
		_start_glow_pulse_animation(true)


## 焦点退出响应
func _on_focus_exited() -> void:
	_is_hovering = false

	# 更新视觉效果
	if not _is_selected:
		_update_scale()
		_start_glow_pulse_animation(false)


## 按钮按下响应
func _on_button_down() -> void:
	_is_pressed = true
	_update_scale()


## 按钮释放响应
func _on_button_up() -> void:
	_is_pressed = false
	_update_scale()


## 按钮点击响应
func _on_pressed() -> void:
	# 播放确认音效
	_play_confirm_sound()

	# 发送选中信号
	tab_selected.emit(tab_index)


## ==================== 音效播放 ====================

## 播放悬停音效
func _play_hover_sound() -> void:
	if AudioManager:
		AudioManager.play_ui_navigate()


## 播放确认音效
func _play_confirm_sound() -> void:
	if AudioManager:
		AudioManager.play_ui_confirm()


## ==================== 外部接口 ====================

## 设置发光颜色
## @param color: 发光颜色
func set_glow_color(color: Color) -> void:
	if glow_effect:
		glow_effect.color = color


## 设置选中指示器颜色
## @param color: 指示器颜色
func set_indicator_color(color: Color) -> void:
	if selection_indicator:
		selection_indicator.color = color


## 暂停所有动画
func pause_animations() -> void:
	if _glow_tween and _glow_tween.is_valid():
		_glow_tween.pause()
	if _indicator_tween and _indicator_tween.is_valid():
		_indicator_tween.pause()


## 恢复所有动画
func resume_animations() -> void:
	if _glow_tween and _glow_tween.is_valid():
		_glow_tween.play()
	if _indicator_tween and _indicator_tween.is_valid():
		_indicator_tween.play()