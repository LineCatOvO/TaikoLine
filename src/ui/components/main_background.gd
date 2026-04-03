## 主菜单背景控制器
## 功能：管理主菜单背景的渐变效果、浮动音符动画
## 作者：TaikoLine Team
## 日期：2026-04-03

extends Control

## ==================== 节点引用 ====================

## 背景渐变
@onready var background_gradient: ColorRect = $BackgroundGradient

## 发光叠加层
@onready var glow_overlay: ColorRect = $GlowOverlay

## 中心发光
@onready var glow_center: ColorRect = $GlowCenter

## 浮动音符容器
@onready var floating_notes: Node2D = $FloatingNotes

## ==================== 动画参数 ====================

## 发光脉冲周期（秒）
const GLOW_PULSE_CYCLE := 3.0

## 发光脉冲最小透明度
const GLOW_PULSE_MIN_ALPHA := 0.1

## 发光脉冲最大透明度
const GLOW_PULSE_MAX_ALPHA := 0.2

## 浮动音符数量
const FLOATING_NOTE_COUNT := 5

## 浮动音符速度范围
const FLOATING_NOTE_SPEED_MIN := 30.0
const FLOATING_NOTE_SPEED_MAX := 80.0

## 浮动音符振幅范围
const FLOATING_NOTE_AMPLITUDE_MIN := 20.0
const FLOATING_NOTE_AMPLITUDE_MAX := 50.0

## 浮动音符周期范围（秒）
const FLOATING_NOTE_PERIOD_MIN := 2.0
const FLOATING_NOTE_PERIOD_MAX := 5.0

## ==================== 浮动音符数据 ====================

## 浮动音符动画数据
var _floating_note_data: Array[Dictionary] = []

## ==================== 初始化 ====================

func _ready() -> void:
	# 初始化浮动音符数据
	_init_floating_notes()

	# 启动发光脉冲动画
	_start_glow_pulse_animation()


## ==================== 发光脉冲动画 ====================

## 启动发光脉冲动画
func _start_glow_pulse_animation() -> void:
	# 创建无限循环的发光脉冲动画
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_loops()  # 无限循环

	# 透明度脉冲动画
	tween.tween_property(glow_overlay, "modulate:a", GLOW_PULSE_MAX_ALPHA, GLOW_PULSE_CYCLE * 0.5)
	tween.tween_property(glow_overlay, "modulate:a", GLOW_PULSE_MIN_ALPHA, GLOW_PULSE_CYCLE * 0.5)

	# 中心发光脉冲动画
	var center_tween = create_tween()
	center_tween.set_ease(Tween.EASE_IN_OUT)
	center_tween.set_trans(Tween.TRANS_SINE)
	center_tween.set_loops()

	center_tween.tween_property(glow_center, "modulate:a", GLOW_PULSE_MAX_ALPHA + 0.05, GLOW_PULSE_CYCLE * 0.5)
	center_tween.tween_property(glow_center, "modulate:a", GLOW_PULSE_MIN_ALPHA + 0.05, GLOW_PULSE_CYCLE * 0.5)


## ==================== 浮动音符动画 ====================

## 初始化浮动音符数据
func _init_floating_notes() -> void:
	_floating_note_data.clear()

	# 为每个音符创建动画数据
	for i in range(FLOATING_NOTE_COUNT):
		# 使用 get_child 方法获取子节点
		if i >= floating_notes.get_child_count():
			continue
		var note_node = floating_notes.get_child(i)
		if note_node == null:
			continue

		# 随机生成动画参数
		var data = {
			"node": note_node,
			"base_y": note_node.position.y,
			"speed": randf_range(FLOATING_NOTE_SPEED_MIN, FLOATING_NOTE_SPEED_MAX),
			"amplitude": randf_range(FLOATING_NOTE_AMPLITUDE_MIN, FLOATING_NOTE_AMPLITUDE_MAX),
			"period": randf_range(FLOATING_NOTE_PERIOD_MIN, FLOATING_NOTE_PERIOD_MAX),
			"phase": randf() * TAU,  # 随机初始相位
			"rotation_speed": randf_range(-0.5, 0.5)
		}

		_floating_note_data.append(data)


## 更新浮动音符动画
func _process(delta: float) -> void:
	# 更新每个浮动音符的位置和旋转
	for data in _floating_note_data:
		var node = data["node"]
		if node == null:
			continue

		# 水平移动（向右）
		node.position.x += data["speed"] * delta

		# 垂直波动（正弦波）
		data["phase"] += delta * TAU / data["period"]
		node.position.y = data["base_y"] + sin(data["phase"]) * data["amplitude"]

		# 旋转
		node.rotation += data["rotation_speed"] * delta

		# 如果超出屏幕右侧，重置到左侧
		if node.position.x > get_viewport_rect().size.x + 50:
			node.position.x = -50
			# 随机新的垂直位置
			data["base_y"] = randf_range(100, get_viewport_rect().size.y - 100)


## ==================== 颜色渐变效果 ====================

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

	if glow_center:
		glow_center.color = color


## ==================== 动画控制 ====================

## 暂停所有动画
func pause_animations() -> void:
	set_process(false)


## 恢复所有动画
func resume_animations() -> void:
	set_process(true)