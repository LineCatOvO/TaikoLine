## 主菜单动态背景脚本
## 功能：显示渐变背景、光晕效果和漂浮音符动画
## 作者：TaikoLine Team
## 日期：2026-03-23

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

## 漂浮起始时间偏移（用于随机化动画）
var _time_offset: float = 0.0

## 音符初始位置数组
var _note_initial_positions: Array = []

## 光晕基础透明度
var _glow_base_alpha: float = 0.1

func _ready() -> void:
	# 随机时间偏移，使每个音符动画不同步
	_time_offset = randf() * 10.0
	_setup_floating_notes()
	_setup_glow_effect()

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

## 更新漂浮动画
func _process(delta: float) -> void:
	var time = Time.get_ticks_msec() / 1000.0 + _time_offset
	_update_floating_animation(delta, time)
	_update_glow_animation(time)

## 更新漂浮动画逻辑
## 参数 delta: 帧间隔时间
## 参数 time: 当前时间（秒）
func _update_floating_animation(delta: float, time: float) -> void:
	for i in range(floating_notes.get_child_count()):
		var note = floating_notes.get_child(i)
		var offset = i * 2.0  # 每个音符有不同的相位偏移
		
		# 正弦波漂浮效果（上下）
		note.position.y += sin(time + offset) * float_amplitude * delta * 0.5
		# 余弦波漂浮效果（左右，速度较慢）
		note.position.x += cos(time * 0.5 + offset) * float_amplitude * delta * 0.3
		
		# 边界检查，超出屏幕则重置位置
		if note.position.x < -50:
			note.position.x = 1330
		elif note.position.x > 1330:
			note.position.x = -50
		if note.position.y < -50:
			note.position.y = 770
		elif note.position.y > 770:
			note.position.y = -50

## 更新光晕呼吸动画
## 参数 time: 当前时间（秒）
func _update_glow_animation(time: float) -> void:
	# 正弦波呼吸效果
	var breathe = sin(time * glow_breathe_speed) * glow_breathe_amplitude
	var new_alpha = _glow_base_alpha + breathe
	glow_center.color.a = clamp(new_alpha, 0.05, 0.2)

## 树进入信号处理（预留扩展）
func _on_tree_entered() -> void:
	pass