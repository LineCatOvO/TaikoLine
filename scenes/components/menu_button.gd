## 菜单按钮组件
## 功能：带有悬停缩放动画、光晕效果和音效的菜单按钮
## 作者：TaikoLine Team
## 日期：2026-03-27
## 更新：优化动画效果，使用Tween替代_process中的lerp

extends Button

## 悬停时的缩放倍数（1.1 表示放大 10%）
@export var hover_scale: float = 1.1

## 按下时的缩放倍数
@export var press_scale: float = 0.95

## 动画时长（秒）
@export var animation_duration: float = 0.15

## 弹跳效果强度
@export var bounce_strength: float = 0.05

## 光晕效果节点
@onready var glow_effect: ColorRect = $GlowEffect

## 悬停音效播放器
@onready var hover_sound: AudioStreamPlayer = $HoverSound

## 确认音效播放器
@onready var confirm_sound: AudioStreamPlayer = $ConfirmSound

## 基础缩放值（按钮原始大小）
var _base_scale: Vector2 = Vector2(1, 1)

## 当前动画Tween
var _scale_tween: Tween
var _glow_tween: Tween

## 鼠标是否悬停在按钮上
var _is_hovered: bool = false

## 是否获得焦点
var _is_focused: bool = false

## 是否正在按下
var _is_pressed: bool = false


## 初始化时记录基础缩放并设置光晕效果
func _ready() -> void:
	_base_scale = scale
	_setup_glow_effect()
	_setup_sounds()
	_connect_signals()


## 设置光晕效果初始状态
func _setup_glow_effect() -> void:
	if glow_effect:
		glow_effect.modulate.a = 0.0
		# 将光晕效果置于按钮内容下方
		move_child(glow_effect, 0)


## 设置音效资源
func _setup_sounds() -> void:
	# 尝试加载音效资源（如果存在）
	var hover_stream = _load_sound_if_exists("res://resources/sounds/ui/hover.wav")
	var confirm_stream = _load_sound_if_exists("res://resources/sounds/ui/confirm.wav")

	if hover_stream and hover_sound:
		hover_sound.stream = hover_stream
	if confirm_stream and confirm_sound:
		confirm_sound.stream = confirm_stream


## 连接信号
func _connect_signals() -> void:
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)


## 尝试加载音效资源
## 参数 path: 音效文件路径
## 返回: AudioStream 或 null
func _load_sound_if_exists(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		return load(path)
	return null


## 鼠标进入时触发悬停状态
func _on_mouse_entered() -> void:
	_is_hovered = true
	_play_hover_sound()
	_animate_hover_in()


## 鼠标离开时取消悬停状态
func _on_mouse_exited() -> void:
	_is_hovered = false
	_animate_hover_out()


## 按钮获得焦点时
func _on_focus_entered() -> void:
	_is_focused = true
	_play_hover_sound()
	_animate_hover_in()


## 按钮失去焦点时
func _on_focus_exited() -> void:
	_is_focused = false
	_animate_hover_out()


## 按钮按下时
func _on_button_down() -> void:
	_is_pressed = true
	_animate_press()


## 按钮释放时
func _on_button_up() -> void:
	_is_pressed = false
	if _is_hovered or _is_focused:
		_animate_hover_in()
	else:
		_animate_hover_out()


## 按钮按下时的回调
func _on_pressed() -> void:
	_play_confirm_sound()
	_animate_click()


## 播放悬停进入动画
func _animate_hover_in() -> void:
	# 停止之前的动画
	if _scale_tween:
		_scale_tween.kill()

	# 创建缩放动画（带轻微弹跳）
	_scale_tween = create_tween()
	_scale_tween.set_ease(Tween.EASE_OUT)
	_scale_tween.set_trans(Tween.TRANS_BACK)
	_scale_tween.tween_property(self, "scale", _base_scale * hover_scale, animation_duration)

	# 光晕效果
	_animate_glow(0.5)


## 播放悬停退出动画
func _animate_hover_out() -> void:
	if _is_pressed:
		return

	# 停止之前的动画
	if _scale_tween:
		_scale_tween.kill()

	# 创建缩放动画
	_scale_tween = create_tween()
	_scale_tween.set_ease(Tween.EASE_OUT)
	_scale_tween.set_trans(Tween.TRANS_QUAD)
	_scale_tween.tween_property(self, "scale", _base_scale, animation_duration)

	# 光晕效果
	_animate_glow(0.0)


## 播放按下动画
func _animate_press() -> void:
	# 停止之前的动画
	if _scale_tween:
		_scale_tween.kill()

	# 创建按下缩放动画
	_scale_tween = create_tween()
	_scale_tween.set_ease(Tween.EASE_OUT)
	_scale_tween.set_trans(Tween.TRANS_QUAD)
	_scale_tween.tween_property(self, "scale", _base_scale * press_scale, animation_duration * 0.5)

	# 光晕效果增强
	_animate_glow(0.7)


## 播放点击动画（弹跳效果）
func _animate_click() -> void:
	# 停止之前的动画
	if _scale_tween:
		_scale_tween.kill()

	# 创建弹跳动画
	_scale_tween = create_tween()
	_scale_tween.set_ease(Tween.EASE_OUT)
	_scale_tween.set_trans(Tween.TRANS_ELASTIC)

	# 先放大一点，然后恢复
	var bounce_scale = hover_scale + bounce_strength
	_scale_tween.tween_property(self, "scale", _base_scale * bounce_scale, animation_duration * 0.3)
	_scale_tween.tween_property(self, "scale", _base_scale * hover_scale, animation_duration * 0.5)


## 播放光晕动画
## 参数 target_alpha: 目标透明度
func _animate_glow(target_alpha: float) -> void:
	if not glow_effect:
		return

	# 停止之前的动画
	if _glow_tween:
		_glow_tween.kill()

	# 创建光晕动画
	_glow_tween = create_tween()
	_glow_tween.set_ease(Tween.EASE_OUT)
	_glow_tween.set_trans(Tween.TRANS_QUAD)
	_glow_tween.tween_property(glow_effect, "modulate:a", target_alpha, animation_duration)


## 播放悬停音效
func _play_hover_sound() -> void:
	if hover_sound and hover_sound.stream:
		hover_sound.play()


## 播放确认音效
func _play_confirm_sound() -> void:
	if confirm_sound and confirm_sound.stream:
		confirm_sound.play()


## 设置悬停缩放倍数
func set_hover_scale(value: float) -> void:
	hover_scale = value


## 设置动画时长
func set_animation_duration(value: float) -> void:
	animation_duration = value