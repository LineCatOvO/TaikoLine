## 菜单按钮组件
## 功能：带有悬停缩放动画、光晕效果和音效的菜单按钮
## 作者：TaikoLine Team
## 日期：2026-03-23

extends Button

## 悬停时的缩放倍数（1.1 表示放大 10%）
@export var hover_scale: float = 1.1

## 动画插值速度（越大越快）
@export var animation_speed: float = 10.0

## 光晕效果节点
@onready var glow_effect: ColorRect = $GlowEffect

## 悬停音效播放器
@onready var hover_sound: AudioStreamPlayer = $HoverSound

## 确认音效播放器
@onready var confirm_sound: AudioStreamPlayer = $ConfirmSound

## 基础缩放值（按钮原始大小）
var _base_scale: Vector2 = Vector2(1, 1)

## 当前缩放值（用于平滑插值）
var _current_scale: Vector2 = Vector2(1, 1)

## 鼠标是否悬停在按钮上
var _is_hovered: bool = false

## 是否获得焦点
var _is_focused: bool = false

## 光晕目标透明度
var _glow_target_alpha: float = 0.0

## 初始化时记录基础缩放并设置光晕效果
func _ready() -> void:
	_base_scale = scale
	_setup_glow_effect()
	_setup_sounds()

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

## 尝试加载音效资源
## 参数 path: 音效文件路径
## 返回: AudioStream 或 null
func _load_sound_if_exists(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		return load(path)
	return null

## 每帧处理悬停动画和光晕效果
func _process(delta: float) -> void:
	_update_hover_animation(delta)
	_update_glow_effect(delta)

## 更新悬停动画效果
## 当鼠标悬停或获得焦点时放大按钮，离开时恢复原状
func _update_hover_animation(delta: float) -> void:
	# 根据悬停或焦点状态确定目标缩放值
	var target_scale = hover_scale if (_is_hovered or _is_focused) else 1.0
	# 使用 lerp 实现平滑过渡
	_current_scale.x = lerp(_current_scale.x, target_scale, animation_speed * delta)
	_current_scale.y = lerp(_current_scale.y, target_scale, animation_speed * delta)
	# 应用缩放（基于基础缩放值）
	scale = _base_scale * _current_scale

## 更新光晕效果
## 参数 delta: 帧间隔时间
func _update_glow_effect(delta: float) -> void:
	if not glow_effect:
		return
	
	# 根据悬停或焦点状态确定目标透明度
	_glow_target_alpha = 0.5 if (_is_hovered or _is_focused) else 0.0
	
	# 平滑过渡光晕透明度
	var current_alpha = glow_effect.modulate.a
	var new_alpha = lerp(current_alpha, _glow_target_alpha, animation_speed * delta)
	glow_effect.modulate.a = new_alpha

## 鼠标进入时触发悬停状态
func _on_mouse_entered() -> void:
	_is_hovered = true
	_play_hover_sound()

## 鼠标离开时取消悬停状态
func _on_mouse_exited() -> void:
	_is_hovered = false

## 按钮获得焦点时
func _on_focus_entered() -> void:
	_is_focused = true
	_play_hover_sound()

## 按钮失去焦点时
func _on_focus_exited() -> void:
	_is_focused = false

## 按钮按下时的回调
func _on_pressed() -> void:
	_play_confirm_sound()

## 播放悬停音效
func _play_hover_sound() -> void:
	if hover_sound and hover_sound.stream:
		hover_sound.play()

## 播放确认音效
func _play_confirm_sound() -> void:
	if confirm_sound and confirm_sound.stream:
		confirm_sound.play()