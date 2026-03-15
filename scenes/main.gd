extends Control

## 主场景脚本

func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/song_select.tscn")

func _on_exit_button_pressed() -> void:
	get_tree().quit()

func _ready() -> void:
	$VBoxContainer/StartButton.pressed.connect(_on_start_button_pressed)
	$VBoxContainer/ExitButton.pressed.connect(_on_exit_button_pressed)