extends Control

## 游戏开始按钮
@onready var start_button: Button = $MenuContainer/StartButton

## 选项按钮
@onready var options_button: Button = $MenuContainer/OptionsButton

## 退出按钮
@onready var exit_button: Button = $MenuContainer/ExitButton

## 底部信息
@onready var bottom_info: Control = $BottomInfo

## 当前选中的按钮索引
var _current_button_index: int = 0

## 按钮数组
var _buttons: Array

func _ready() -> void:
	# 设置主题
	theme = preload("res://resources/ui/themes/main_menu_theme.tres")
	_buttons = [start_button, options_button, exit_button]
	_update_button_focus()
	bottom_info.set_hint("按 Enter 确认")

## 游戏开始按钮按下
func _on_start_button_pressed() -> void:
	_change_scene("res://scenes/song_select.tscn")

## 选项按钮按下
func _on_options_button_pressed() -> void:
	# 预留功能：打开设置界面
	pass

## 退出按钮按下
func _on_exit_button_pressed() -> void:
	get_tree().quit()

## 更新按钮焦点
func _update_button_focus() -> void:
	for i in range(_buttons.size()):
		_buttons[i].grab_focus() if i == _current_button_index else _buttons[i].release_focus()

## 切换场景
func _change_scene(scene_path: String) -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished
	get_tree().change_scene_to_file(scene_path)

## 输入处理
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_UP:
			_current_button_index = (_current_button_index - 1 + _buttons.size()) % _buttons.size()
			_update_button_focus()
		elif event.keycode == KEY_DOWN:
			_current_button_index = (_current_button_index + 1) % _buttons.size()
			_update_button_focus()
		elif event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
			_buttons[_current_button_index].emit_signal("pressed")
