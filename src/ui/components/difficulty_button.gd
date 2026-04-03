class_name DifficultyButton
extends Button
## 难度选择按钮组件
## 显示难度名称、颜色标识和星级
## 参考 Taiko no Tatsujin 虹版设计风格
## 作者：TaikoLine Team
## 日期：2026-04-03

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
@export var animation_speed: float = 0.15

## 星星图标路径（可选）
@export var star_icon_path: String = ""

## UI节点引用
var _level_container: HBoxContainer
var _level_label: Label

## 样式资源
var _normal_style: StyleBoxFlat
var _hover_style: StyleBoxFlat
var _pressed_style: StyleBoxFlat
var _disabled_style: StyleBoxFlat
var _selected_style: StyleBoxFlat

## 是否选中
var _is_selected: bool = false


func _ready() -> void:
	_setup_styles()
	_setup_ui()
	_update_display()


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
	# 添加点击动画
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "scale", Vector2(0.95, 0.95), 0.05)
	tween.tween_callback(_on_press_animation_complete)


## 按下动画完成回调
func _on_press_animation_complete() -> void:
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale", Vector2.ONE if not _is_selected else Vector2(1.1, 1.1), animation_speed)