class_name RankCrown
extends Control
## 评级冠显示组件
## 显示金冠、银冠、铜冠或失败图标
##
## 设计参考：太鼓达人虹版结果界面评级显示
## - 金冠：全良（DONDAKO FULL COMBO）
## - 银冠：全连（FULL COMBO）
## - 铜冠：清除（CLEARED）
## - 失败：未清除（FAILED）

## 信号
signal crown_animation_finished

## 评级类型
enum CrownType {
	GOLD,    ## 金冠（全良）
	SILVER,  ## 银冠（全连）
	BRONZE,  ## 铜冠（清除）
	FAILED   ## 失败
}

## 配置
@export var crown_size: float = 120.0
@export var animation_duration: float = 0.5
@export var glow_duration: float = 2.0

## 颜色配置
const COLOR_GOLD := Color(1.0, 0.85, 0.0)
const COLOR_SILVER := Color(0.85, 0.85, 0.85)
const COLOR_BRONZE := Color(0.85, 0.55, 0.25)
const COLOR_FAILED := Color(0.5, 0.5, 0.5)

## UI节点引用
var _crown_container: Control
var _crown_shape: Polygon2D
var _crown_glow: Polygon2D
var _rank_label: Label
var _crown_type_label: Label
var _tween: Tween
var _glow_tween: Tween

## 当前评级类型
var _current_crown_type: CrownType = CrownType.BRONZE

## 是否正在播放动画
var _is_animating: bool = false


func _ready() -> void:
	_setup_ui()


## 设置UI
func _setup_ui() -> void:
	# 设置最小尺寸
	custom_minimum_size = Vector2(crown_size * 1.5, crown_size * 2)

	# 创建冠容器
	_crown_container = Control.new()
	_crown_container.custom_minimum_size = Vector2(crown_size * 1.5, crown_size * 1.5)
	add_child(_crown_container)
	_crown_container.anchors_preset = Control.PRESET_CENTER

	# 创建发光效果（底层）
	_crown_glow = Polygon2D.new()
	_crown_glow.color = COLOR_GOLD
	_crown_glow.modulate.a = 0.0
	_crown_container.add_child(_crown_glow)
	_create_crown_polygon(_crown_glow, crown_size * 1.1)

	# 创建冠形状
	_crown_shape = Polygon2D.new()
	_crown_shape.color = COLOR_GOLD
	_crown_container.add_child(_crown_shape)
	_create_crown_polygon(_crown_shape, crown_size)

	# 创建评级标签（在冠下方）
	_rank_label = Label.new()
	_rank_label.text = "S"
	_rank_label.add_theme_font_size_override("font_size", int(crown_size * 0.6))
	_rank_label.add_theme_color_override("font_color", COLOR_GOLD)
	_rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rank_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_crown_container.add_child(_rank_label)
	_rank_label.position = Vector2(-crown_size * 0.75, crown_size * 0.3)
	_rank_label.size = Vector2(crown_size * 1.5, crown_size * 0.8)

	# 创建评级类型标签
	_crown_type_label = Label.new()
	_crown_type_label.text = "CLEARED"
	_crown_type_label.add_theme_font_size_override("font_size", 18)
	_crown_type_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	_crown_type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_crown_type_label)
	_crown_type_label.anchors_preset = Control.PRESET_BOTTOM_WIDE
	_crown_type_label.offset_top = -30

	# 初始隐藏
	modulate.a = 0.0
	scale = Vector2(0.5, 0.5)


## 创建冠形状多边形
func _create_crown_polygon(polygon: Polygon2D, size: float) -> void:
	# 冠形状：五个尖角的皇冠形状
	var points: PackedVector2Array = []

	# 左下角
	points.append(Vector2(-size * 0.5, size * 0.3))
	# 左侧尖角
	points.append(Vector2(-size * 0.4, -size * 0.2))
	# 左中尖角
	points.append(Vector2(-size * 0.2, size * 0.1))
	# 中央尖角（最高）
	points.append(Vector2(0, -size * 0.4))
	# 右中尖角
	points.append(Vector2(size * 0.2, size * 0.1))
	# 右侧尖角
	points.append(Vector2(size * 0.4, -size * 0.2))
	# 右下角
	points.append(Vector2(size * 0.5, size * 0.3))

	polygon.polygon = points
	polygon.position = Vector2(size * 0.75, size * 0.5)


## 获取或创建Tween（优化版本 - 复用Tween）
func _get_tween() -> Tween:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	return _tween


## 设置评级类型
func set_crown_type(crown_type: CrownType, rank_text: String = "") -> void:
	_current_crown_type = crown_type

	# 设置颜色
	var crown_color: Color
	var glow_color: Color
	var type_text: String

	match crown_type:
		CrownType.GOLD:
			crown_color = COLOR_GOLD
			glow_color = Color(1.5, 1.2, 0.0)  # 更亮的金色
			type_text = "DONDAKO FC"
		CrownType.SILVER:
			crown_color = COLOR_SILVER
			glow_color = Color(1.0, 1.0, 1.2)  # 更亮的银色
			type_text = "FULL COMBO"
		CrownType.BRONZE:
			crown_color = COLOR_BRONZE
			glow_color = Color(1.0, 0.7, 0.4)  # 更亮的铜色
			type_text = "CLEARED"
		CrownType.FAILED:
			crown_color = COLOR_FAILED
			glow_color = Color(0.6, 0.6, 0.6)
			type_text = "FAILED"

	# 更新颜色
	_crown_shape.color = crown_color
	_crown_glow.color = glow_color
	_rank_label.add_theme_color_override("font_color", crown_color)
	_crown_type_label.text = type_text

	# 设置评级文本
	if rank_text != "":
		_rank_label.text = rank_text
	else:
		_rank_label.text = _get_default_rank_text(crown_type)


## 获取默认评级文本
func _get_default_rank_text(crown_type: CrownType) -> String:
	match crown_type:
		CrownType.GOLD:
			return "SS"
		CrownType.SILVER:
			return "FC"
		CrownType.BRONZE:
			return "S"  # 需要根据准确度计算
		CrownType.FAILED:
			return "F"
		_:
			return "?"


## 播放入场动画
func play_appear_animation() -> void:
	_is_animating = true

	var tween = _get_tween()
	tween.set_parallel(true)

	# 缩放动画（弹性效果）
	tween.tween_property(self, "scale", Vector2.ONE, animation_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)

	# 淡入动画
	tween.tween_property(self, "modulate:a", 1.0, animation_duration * 0.5)

	# 发光效果（仅金冠和银冠）
	if _current_crown_type == CrownType.GOLD or _current_crown_type == CrownType.SILVER:
		tween.tween_callback(_start_glow_animation)

	tween.tween_callback(_on_animation_finished)


## 开始发光动画（循环）
func _start_glow_animation() -> void:
	if _glow_tween and _glow_tween.is_valid():
		_glow_tween.kill()

	_glow_tween = create_tween()
	_glow_tween.set_loops()  # 无限循环

	# 发光脉冲效果
	_glow_tween.tween_property(_crown_glow, "modulate:a", 0.3, glow_duration * 0.5)
	_glow_tween.tween_property(_crown_glow, "modulate:a", 0.0, glow_duration * 0.5)


## 停止发光动画
func stop_glow_animation() -> void:
	if _glow_tween and _glow_tween.is_valid():
		_glow_tween.kill()
	_crown_glow.modulate.a = 0.0


## 动画完成回调
func _on_animation_finished() -> void:
	_is_animating = false
	crown_animation_finished.emit()


## 播放庆祝动画（金冠/银冠）
func play_celebration_animation() -> void:
	var tween = _get_tween()

	# 连续弹跳效果
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.15)
	tween.tween_property(self, "scale", Vector2(0.9, 0.9), 0.1)
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.1)
	tween.tween_property(self, "scale", Vector2.ONE, 0.1)


## 获取当前评级类型
func get_crown_type() -> CrownType:
	return _current_crown_type


## 检查是否正在播放动画
func is_animating() -> bool:
	return _is_animating


## 重置
func reset() -> void:
	stop_glow_animation()
	modulate.a = 0.0
	scale = Vector2(0.5, 0.5)
	_current_crown_type = CrownType.BRONZE
	_is_animating = false