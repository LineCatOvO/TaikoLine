class_name DifficultyButton
extends Button
## 难度选择按钮组件
## 显示难度名称、颜色标识和星级
## 参考 Taiko no Tatsujin 虹版设计风格
## 作者：TaikoLine Team
## 日期：2026-04-03
## 更新：添加发光效果、优化动画流畅度

## 难度类型
enum DifficultyType {
	EASY = 0,
	NORMAL = 1,
	HARD = 2,
	ONI = 3
}

## 难度颜色映射
const DIFFICULTY_COLORS = {
	DifficultyType.EASY: Color(0.3, 0.8, 0.3),    # 绿色
	DifficultyType.NORMAL: Color(0.3, 0.6, 1.0),  # 蓝色
	DifficultyType.HARD: Color(1.0, 0.6, 0.0),    # 橙色
	DifficultyType.ONI: Color(1.0, 0.2, 0.2)      # 红色
}

## 难度名称映射
const DIFFICULTY_NAMES = {
	DifficultyType.EASY: "Easy",
	DifficultyType.NORMAL: "Normal",
	DifficultyType.HARD: "Hard",
	DifficultyType.ONI: "Oni"
}

## 难度类型
@export var difficulty_type: DifficultyType = DifficultyType.ONI

## 难度等级（1-10星）
@export var level: int = 1

## 是否可用
@export var is_available: bool = true

## 动画速度
@export var animation_speed: float = 0.12

## 星星图标路径（可选）
@export var star_icon_path: String = ""

## UI节点引用
var _level_container: HBoxContainer
var _level_label: Label

## 发光效果节点
var _glow_effect: ColorRect = null

## 波纹效果节点
var _ripple_effect: ColorRect = null

## 样式资源
var _normal_style: StyleBoxFlat
var _hover_style: StyleBoxFlat
var _pressed_style: StyleBoxFlat
var _disabled_style: StyleBoxFlat
var _selected_style: StyleBoxFlat

## 是否选中
var _is_selected: bool = false

## 是否悬停
var _is_hovering: bool = false

## 发光脉冲 Tween
var _glow_tween: Tween = null

## 波纹 Tween
var _ripple_tween: Tween = null


func _ready() -> void:
	_setup_styles()
	_setup_ui()
	_setup_effects()
	_connect_signals()
	_update_display()
	_start_glow_animation(false)


## 连接信号
func _connect_signals() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


## 鼠标进入响应
func _on_mouse_entered() -> void:
	if not is_available:
		return

	_is_hovering = true
	_start_glow_animation(true)

	# 悬停缩放动画
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale", Vector2(1.05, 1.05), animation_speed)


## 鼠标退出响应
func _on_mouse_exited() -> void:
	_is_hovering = false
	_start_glow_animation(false)

	# 恢复缩放动画
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	var target_scale = 1.1 if _is_selected else 1.0
	tween.tween_property(self, "scale", Vector2(target_scale, target_scale), animation_speed)


## 设置样式
func _setup_styles() -> void:
	var base_color = DIFFICULTY_COLORS[difficulty_type]

	# 普通样式
	_normal_style = StyleBoxFlat.new()
	_normal_style.bg_color = Color(base_color.r * 0.3, base_color.g * 0.3, base_color.b * 0.3, 0.85)
	_normal_style.set_corner_radius_all(12)
	_normal_style.shadow_color = Color(0, 0, 0, 0.3)
	_normal_style.shadow_size = 3
	_normal_style.shadow_offset = Vector2(1, 1)

	# 悬停样式
	_hover_style = StyleBoxFlat.new()
	_hover_style.bg_color = Color(base_color.r * 0.5, base_color.g * 0.5, base_color.b * 0.5, 0.95)
	_hover_style.set_corner_radius_all(12)
	_hover_style.shadow_color = Color(base_color.r, base_color.g, base_color.b, 0.4)
	_hover_style.shadow_size = 6
	_hover_style.shadow_offset = Vector2(0, 0)
	_hover_style.border_color = Color(base_color.r * 0.8, base_color.g * 0.8, base_color.b * 0.8, 1.0)
	_hover_style.set_border_width_all(2)

	# 按下样式
	_pressed_style = StyleBoxFlat.new()
	_pressed_style.bg_color = Color(base_color.r * 0.2, base_color.g * 0.2, base_color.b * 0.2, 1.0)
	_pressed_style.set_corner_radius_all(12)
	_pressed_style.shadow_color = Color(0, 0, 0, 0.4)
	_pressed_style.shadow_size = 2
	_pressed_style.shadow_offset = Vector2(1, 1)

	# 禁用样式
	_disabled_style = StyleBoxFlat.new()
	_disabled_style.bg_color = Color(0.2, 0.2, 0.2, 0.5)
	_disabled_style.set_corner_radius_all(12)

	# 选中样式
	_selected_style = StyleBoxFlat.new()
	_selected_style.bg_color = Color(base_color.r * 0.7, base_color.g * 0.7, base_color.b * 0.7, 1.0)
	_selected_style.set_corner_radius_all(12)
	_selected_style.shadow_color = Color(base_color.r, base_color.g, base_color.b, 0.6)
	_selected_style.shadow_size = 8
	_selected_style.shadow_offset = Vector2(0, 0)
	_selected_style.border_color = Color(base_color.r, base_color.g, base_color.b, 1.0)
	_selected_style.set_border_width_all(3)

	# 应用样式
	add_theme_stylebox_override("normal", _normal_style)
	add_theme_stylebox_override("hover", _hover_style)
	add_theme_stylebox_override("pressed", _pressed_style)
	add_theme_stylebox_override("disabled", _disabled_style)

	# 设置字体颜色
	add_theme_color_override("font_color", base_color)
	add_theme_color_override("font_hover_color", Color(base_color.r * 1.2, base_color.g * 1.2, base_color.b * 1.2, 1.0))
	add_theme_color_override("font_pressed_color", base_color)
	add_theme_color_override("font_disabled_color", Color(0.5, 0.5, 0.5, 1.0))
	add_theme_color_override("font_focus_color", base_color)


## 设置 UI
func _setup_ui() -> void:
	custom_minimum_size = Vector2(100, 50)

	# 创建星级显示容器（如果需要）
	# 这里我们使用简单的文本显示，因为 Godot Button 不支持复杂的子节点布局
	# 星级显示将在按钮文本中体现


## 设置特效节点
func _setup_effects() -> void:
	var base_color = DIFFICULTY_COLORS[difficulty_type]

	# 创建发光效果层
	_glow_effect = ColorRect.new()
	_glow_effect.color = Color(base_color.r, base_color.g, base_color.b, 0.5)
	_glow_effect.modulate.a = 0.15
	_glow_effect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_glow_effect.z_index = -1  # 在按钮下方

	# 设置全屏锚点
	_glow_effect.anchors_preset = Control.PRESET_FULL_RECT
	_glow_effect.offset_left = -8
	_glow_effect.offset_right = 8
	_glow_effect.offset_top = -8
	_glow_effect.offset_bottom = 8

	add_child(_glow_effect)
	move_child(_glow_effect, 0)

	# 创建波纹效果层
	_ripple_effect = ColorRect.new()
	_ripple_effect.color = Color(base_color.r, base_color.g, base_color.b, 0.4)
	_ripple_effect.custom_minimum_size = Vector2(20, 20)
	_ripple_effect.size = Vector2(20, 20)
	_ripple_effect.modulate.a = 0.0
	_ripple_effect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ripple_effect.z_index = 10
	add_child(_ripple_effect)


## 启动发光动画
func _start_glow_animation(enhanced: bool = false) -> void:
	if not _glow_effect:
		return

	# 停止之前的发光动画
	if _glow_tween and _glow_tween.is_valid():
		_glow_tween.kill()

	var base_color = DIFFICULTY_COLORS[difficulty_type]
	_glow_effect.color = Color(base_color.r, base_color.g, base_color.b, 0.5)

	# 创建发光脉冲动画
	_glow_tween = create_tween()
	_glow_tween.set_ease(Tween.EASE_IN_OUT)
	_glow_tween.set_trans(Tween.TRANS_SINE)
	_glow_tween.set_loops()

	var max_alpha = 0.5 if enhanced else 0.25
	var min_alpha = 0.15

	_glow_tween.tween_property(_glow_effect, "modulate:a", max_alpha, 0.6)
	_glow_tween.tween_property(_glow_effect, "modulate:a", min_alpha, 0.6)


## 创建点击波纹效果
func _create_click_ripple() -> void:
	if not _ripple_effect:
		return

	# 停止之前的波纹动画
	if _ripple_tween and _ripple_tween.is_valid():
		_ripple_tween.kill()

	# 设置波纹初始状态
	_ripple_effect.scale = Vector2.ONE
	_ripple_effect.modulate.a = 0.5
	_ripple_effect.position = size / 2 - Vector2(10, 10)

	# 创建扩散动画
	_ripple_tween = create_tween()
	_ripple_tween.set_ease(Tween.EASE_OUT)
	_ripple_tween.set_trans(Tween.TRANS_QUAD)

	_ripple_tween.set_parallel(true)
	_ripple_tween.tween_property(_ripple_effect, "scale", Vector2(2.5, 2.5), 0.4)
	_ripple_tween.tween_property(_ripple_effect, "modulate:a", 0.0, 0.4)


## 更新显示
func _update_display() -> void:
	# 更新按钮文本
	var name = DIFFICULTY_NAMES[difficulty_type]
	if is_available and level > 0:
		text = "%s\nLv.%d" % [name, level]
	else:
		text = name

	# 更新可用状态
	disabled = not is_available
	modulate.a = 1.0 if is_available else 0.5


## 设置难度类型
func set_difficulty_type(type: DifficultyType) -> void:
	difficulty_type = type
	_setup_styles()
	_update_display()


## 设置难度等级
func set_level(new_level: int) -> void:
	level = clamp(new_level, 1, 10)
	_update_display()


## 设置可用状态
func set_available(available: bool) -> void:
	is_available = available
	_update_display()


## 设置选中状态
func set_selected(selected: bool) -> void:
	_is_selected = selected

	if selected:
		add_theme_stylebox_override("normal", _selected_style)
		# 选中动画
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_BACK)
		tween.tween_property(self, "scale", Vector2(1.1, 1.1), animation_speed)
	else:
		add_theme_stylebox_override("normal", _normal_style)
		# 恢复动画
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_QUAD)
		tween.tween_property(self, "scale", Vector2.ONE, animation_speed)


## 获取难度颜色
func get_difficulty_color() -> Color:
	return DIFFICULTY_COLORS[difficulty_type]


## 获取难度名称
func get_difficulty_name() -> String:
	return DIFFICULTY_NAMES[difficulty_type]


## 处理按钮按下
func _pressed() -> void:
	# 创建点击波纹效果
	_create_click_ripple()

	# 添加点击动画
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "scale", Vector2(0.92, 0.92), 0.05)
	tween.tween_callback(_on_press_animation_complete)


## 按下动画完成回调
func _on_press_animation_complete() -> void:
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale", Vector2.ONE if not _is_selected else Vector2(1.1, 1.1), animation_speed)