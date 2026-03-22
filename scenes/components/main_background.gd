extends Control

## 漂浮音符容器
@onready var floating_notes: Node2D = $FloatingNotes

## 漂浮动画速度
@export var float_speed: float = 0.5

## 漂浮幅度
@export var float_amplitude: float = 20.0

## 漂浮起始时间偏移
var _time_offset: float = 0.0

func _ready() -> void:
	_time_offset = randf() * 10.0
	_setup_floating_notes()

## 设置漂浮音符
func _setup_floating_notes() -> void:
	for note in floating_notes.get_children():
		note.position = Vector2(randf() * 1280, randf() * 720)

## 更新漂浮动画
func _process(delta: float) -> void:
	var time = Time.get_ticks_msec() / 1000.0 + _time_offset
	_update_floating_animation(delta, time)

## 更新漂浮动画逻辑
func _update_floating_animation(delta: float, time: float) -> void:
	for i in range(floating_notes.get_child_count()):
		var note = floating_notes.get_child(i)
		var offset = i * 2.0
		note.position.y += sin(time + offset) * float_amplitude * delta * 0.5
		note.position.x += cos(time * 0.5 + offset) * float_amplitude * delta * 0.3

## 树进入信号处理
func _on_tree_entered() -> void:
	pass
