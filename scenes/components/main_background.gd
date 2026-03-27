## 主菜单动态背景脚本
## 功能：显示渐变背景、光晕效果和漂浮音符动画
## 作者：TaikoLine Team
## 日期：2026-03-27
## 更新：优化动画性能，使用Tween替代_process中的计算

extends Control

## 漂浮音符容器
@onready var floating_notes: Node2D = $FloatingNotes

## 光晕中心效果
@onready var glow_center: ColorRect = $GlowCenter

## 漂浮动画速度（每秒移动的像素数）
@export var float_speed: float = 0.5

## 漂浮幅度（上下浮动的最大距离）
@export var float_amplitude: float = 20.0

## 光晕呼吸速度
@export var glow_breathe_speed: float = 1.5

## 光晕呼吸幅度
@export var glow_breathe_amplitude: float = 0.05

## 音符漂浮周期（秒）
@export var float_cycle_duration: float = 4.0

## 音符初始位置数组
var _note_initial_positions: Array = []

## 光晕基础透明度
var _glow_base_alpha: float = 0.1

## 动画Tween
var _glow_tween: Tween
var _note_tweens: Array[Tween] = []


func _ready() -> void:
	_setup_floating_notes()
	_setup_glow_effect()
	_start_animations()


## 设置漂浮音符的初始位置
func _setup_floating_notes() -> void:
	# 记录每个音符的初始位置
	for note in floating_notes.get_children():
		var initial_pos = Vector2(randf() * 1280, randf() * 720)
		note.position = initial_pos
		_note_initial_positions.append(initial_pos)

		# 为音符创建简单的圆形纹理（如果未设置）
		if note.texture == null:
			_create_note_texture(note)


## 为音符创建简单的圆形纹理
## 参数 note: 需要创建纹理的 Sprite2D 节点
func _create_note_texture(note: Sprite2D) -> void:
	# 创建一个简单的圆形图像作为音符纹理
	var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))  # 透明背景

	# 绘制圆形（太鼓音符风格）
	var center = Vector2(16, 16)
	var radius = 12
	var color = Color(0.8, 0.3, 0.2, 0.6)  # 红色半透明

	# 使用简单的圆形填充
	for x in range(32):
		for y in range(32):
			var dist = Vector2(x, y).distance_to(center)
			if dist <= radius:
				image.set_pixel(x, y, color)

	var texture = ImageTexture.create_from_image(image)
	note.texture = texture
	note.scale = Vector2(1.5, 1.5)


## 设置光晕效果
func _setup_glow_effect() -> void:
	_glow_base_alpha = glow_center.color.a


## 启动所有动画
func _start_animations() -> void:
	_start_glow_animation()
	_start_floating_notes_animation()


## 启动光晕呼吸动画
func _start_glow_animation() -> void:
	_glow_tween = create_tween()
	_glow_tween.set_loops()
	_glow_tween.set_ease(Tween.EASE_IN_OUT)
	_glow_tween.set_trans(Tween.TRANS_SINE)

	# 呼吸周期
	var cycle_time = 1.0 / glow_breathe_speed
	var target_alpha = _glow_base_alpha + glow_breathe_amplitude

	_glow_tween.tween_property(glow_center, "color:a", target_alpha, cycle_time * 0.5)
	_glow_tween.tween_property(glow_center, "color:a", _glow_base_alpha, cycle_time * 0.5)


## 启动漂浮音符动画
func _start_floating_notes_animation() -> void:
	for i in range(floating_notes.get_child_count()):
		var note = floating_notes.get_child(i)
		var initial_pos = _note_initial_positions[i]

		# 为每个音符创建独立的漂浮动画
		_start_single_note_animation(note, initial_pos, i)


## 启动单个音符的漂浮动画
## 参数 note: 音符节点
## 参数 initial_pos: 初始位置
## 参数 index: 音符索引
func _start_single_note_animation(note: Node2D, initial_pos: Vector2, index: float) -> void:
	# 随机化动画参数
	var phase_offset = index * 0.5
	var cycle_time = float_cycle_duration + randf() * 2.0

	# 创建漂浮动画
	var tween = create_tween()
	tween.set_loops()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)

	# 计算目标位置
	var target_y = initial_pos.y + float_amplitude
	var target_x = initial_pos.x + float_amplitude * 0.5

	# 漂浮动画序列
	tween.tween_property(note, "position:y", target_y, cycle_time * 0.5)
	tween.tween_property(note, "position:y", initial_pos.y, cycle_time * 0.5)

	# 水平移动（使用独立的Tween）
	var x_tween = create_tween()
	x_tween.set_loops()
	x_tween.set_ease(Tween.EASE_IN_OUT)
	x_tween.set_trans(Tween.TRANS_SINE)
	x_tween.tween_property(note, "position:x", target_x, cycle_time * 0.7)
	x_tween.tween_property(note, "position:x", initial_pos.x, cycle_time * 0.7)

	_note_tweens.append(tween)
	_note_tweens.append(x_tween)


## 停止所有动画
func stop_animations() -> void:
	if _glow_tween:
		_glow_tween.kill()

	for tween in _note_tweens:
		if tween:
			tween.kill()

	_note_tweens.clear()


## 暂停所有动画
func pause_animations() -> void:
	if _glow_tween:
		_glow_tween.pause()

	for tween in _note_tweens:
		if tween:
			tween.pause()


## 恢复所有动画
func resume_animations() -> void:
	if _glow_tween:
		_glow_tween.play()

	for tween in _note_tweens:
		if tween:
			tween.play()


## 树进入信号处理（预留扩展）
func _on_tree_entered() -> void:
	pass