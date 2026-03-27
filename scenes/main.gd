## 主菜单场景脚本
## 功能：管理主菜单界面，处理按钮交互、键盘导航和场景过渡
## 作者：TaikoLine Team
## 日期：2026-03-23

extends Control

## 游戏开始按钮
@onready var start_button: Button = $MenuContainer/StartButton

## 选项按钮
@onready var options_button: Button = $MenuContainer/OptionsButton

## 退出按钮
@onready var exit_button: Button = $MenuContainer/ExitButton

## 底部信息
@onready var bottom_info: Control = $BottomInfo

## 导航音效播放器
var _navigate_sound: AudioStreamPlayer

## 当前选中的按钮索引
var _current_button_index: int = 0

## 按钮数组
var _buttons: Array

## 导航是否启用
var _navigation_enabled: bool = true

## 场景过渡动画时长
const TRANSITION_DURATION: float = 0.3

func _ready() -> void:
	# 设置主题
	theme = preload("res://resources/ui/themes/main_menu_theme.tres")
	
	# 初始化按钮数组
	_buttons = [start_button, options_button, exit_button]
	
	# 设置导航音效
	_setup_navigate_sound()
	
	# 初始化按钮焦点
	_update_button_focus()
	
	# 设置底部提示信息
	bottom_info.set_hint("按 Enter 确认 | ↑↓ 选择")

## 设置导航音效
func _setup_navigate_sound() -> void:
	_navigate_sound = AudioStreamPlayer.new()
	_navigate_sound.volume_db = -20.0
	add_child(_navigate_sound)
	
	# 尝试加载导航音效
	var navigate_stream = _load_sound_if_exists("res://resources/sounds/ui/navigate.wav")
	if navigate_stream:
		_navigate_sound.stream = navigate_stream

## 尝试加载音效资源
## 参数 path: 音效文件路径
## 返回: AudioStream 或 null
func _load_sound_if_exists(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		return load(path)
	return null

## 游戏开始按钮按下
func _on_start_button_pressed() -> void:
	if not _navigation_enabled:
		return
	_navigation_enabled = false
	_change_scene("res://scenes/song_select.tscn")

## 选项按钮按下
func _on_options_button_pressed() -> void:
	if not _navigation_enabled:
		return
	_navigation_enabled = false
	_change_scene("res://scenes/settings.tscn")

## 退出按钮按下
func _on_exit_button_pressed() -> void:
	if not _navigation_enabled:
		return
	_navigation_enabled = false
	_fade_out_and_quit()

## 更新按钮焦点
func _update_button_focus() -> void:
	for i in range(_buttons.size()):
		if i == _current_button_index:
			_buttons[i].grab_focus()
		else:
			_buttons[i].release_focus()

## 播放导航音效
func _play_navigate_sound() -> void:
	if _navigate_sound and _navigate_sound.stream:
		_navigate_sound.play()

## 切换场景（带过渡动画）
## 参数 scene_path: 目标场景路径
func _change_scene(scene_path: String) -> void:
	# 创建淡出动画
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "modulate:a", 0.0, TRANSITION_DURATION)
	
	# 等待动画完成后切换场景
	await tween.finished
	get_tree().change_scene_to_file(scene_path)

## 淡出并退出游戏
func _fade_out_and_quit() -> void:
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "modulate:a", 0.0, TRANSITION_DURATION)
	
	await tween.finished
	get_tree().quit()

## 输入处理（键盘导航）
func _input(event: InputEvent) -> void:
	if not _navigation_enabled:
		return
	
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_UP:
				_navigate_up()
				get_viewport().set_input_as_handled()
			KEY_DOWN:
				_navigate_down()
				get_viewport().set_input_as_handled()
			KEY_ENTER, KEY_SPACE:
				_confirm_selection()
				get_viewport().set_input_as_handled()

## 向上导航
func _navigate_up() -> void:
	_play_navigate_sound()
	_current_button_index = (_current_button_index - 1 + _buttons.size()) % _buttons.size()
	_update_button_focus()

## 向下导航
func _navigate_down() -> void:
	_play_navigate_sound()
	_current_button_index = (_current_button_index + 1) % _buttons.size()
	_update_button_focus()

## 确认当前选择
func _confirm_selection() -> void:
	if _current_button_index >= 0 and _current_button_index < _buttons.size():
		_buttons[_current_button_index].emit_signal("pressed")