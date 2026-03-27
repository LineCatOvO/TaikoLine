class_name SongItem
extends PanelContainer
## 歌曲列表项组件
## 显示单个歌曲的信息，支持悬停效果和选中状态
## 作者：TaikoLine Team
## 日期：2026-03-27

## 信号
signal selected
signal preview_requested

## 难度类型映射
const DIFFICULTY_NAMES = ["Easy", "Normal", "Hard", "Oni"]
const DIFFICULTY_COLORS = [
	Color(0.3, 0.8, 0.3),  # 绿色 - Easy
	Color(0.3, 0.6, 1.0),  # 蓝色 - Normal
	Color(1.0, 0.6, 0.0),  # 橙色 - Hard
	Color(1.0, 0.2, 0.2)   # 红色 - Oni
]

## 歌曲数据
var song_data: Dictionary = {}

## UI节点引用
var _title_label: Label
var _subtitle_label: Label
var _bpm_label: Label
var _difficulty_container: HBoxContainer
var _select_button: Button
var _preview_button: Button

## 悬停状态
var _is_hovered: bool = false

## 选中状态
var _is_selected: bool = false

## 动画速度
@export var animation_speed: float = 10.0


func _ready() -> void:
	_setup_ui()
	_connect_signals()


## 设置UI布局
func _setup_ui() -> void:
	# 设置最小尺寸
	custom_minimum_size = Vector2(0, 70)

	# 创建主容器
	var main_hbox = HBoxContainer.new()
	add_child(main_hbox)

	# 左侧信息区域
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_hbox.add_child(info_vbox)

	# 标题
	_title_label = Label.new()
	_title_label.add_theme_font_size_override("font_size", 20)
	_title_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	info_vbox.add_child(_title_label)

	# 副标题
	_subtitle_label = Label.new()
	_subtitle_label.add_theme_font_size_override("font_size", 14)
	_subtitle_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	info_vbox.add_child(_subtitle_label)

	# BPM和难度
	var info_hbox = HBoxContainer.new()
	info_vbox.add_child(info_hbox)

	_bpm_label = Label.new()
	_bpm_label.add_theme_font_size_override("font_size", 12)
	_bpm_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
	info_hbox.add_child(_bpm_label)

	# 难度显示容器
	_difficulty_container = HBoxContainer.new()
	info_hbox.add_child(_difficulty_container)

	# 右侧按钮区域
	var button_vbox = VBoxContainer.new()
	button_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_hbox.add_child(button_vbox)

	# 预览按钮
	_preview_button = Button.new()
	_preview_button.text = "Preview"
	_preview_button.custom_minimum_size = Vector2(80, 30)
	button_vbox.add_child(_preview_button)

	# 选择按钮
	_select_button = Button.new()
	_select_button.text = "Select"
	_select_button.custom_minimum_size = Vector2(80, 30)
	button_vbox.add_child(_select_button)


## 连接信号
func _connect_signals() -> void:
	_preview_button.pressed.connect(_on_preview_pressed)
	_select_button.pressed.connect(_on_select_pressed)


## 设置歌曲数据
func set_song_data(data: Dictionary) -> void:
	song_data = data
	_update_display()


## 更新显示
func _update_display() -> void:
	if song_data.is_empty():
		return

	# 更新标题
	_title_label.text = song_data.get("title", "Unknown")

	# 更新副标题
	var subtitle = song_data.get("subtitle", "")
	if subtitle != "":
		_subtitle_label.text = subtitle
		_subtitle_label.visible = true
	else:
		_subtitle_label.visible = false

	# 更新BPM
	var bpm = song_data.get("bpm", 120.0)
	_bpm_label.text = "BPM: %.0f" % bpm

	# 更新难度显示
	_update_difficulty_display()


## 更新难度显示
func _update_difficulty_display() -> void:
	# 清除现有难度显示
	for child in _difficulty_container.get_children():
		child.queue_free()

	var courses = song_data.get("courses", {})

	for i in range(DIFFICULTY_NAMES.size()):
		if courses.has(i):
			var course = courses[i]
			var level = course.get("level", 0)

			var diff_label = Label.new()
			diff_label.text = " %s Lv.%d" % [DIFFICULTY_NAMES[i], level]
			diff_label.add_theme_font_size_override("font_size", 11)
			diff_label.add_theme_color_override("font_color", DIFFICULTY_COLORS[i])
			_difficulty_container.add_child(diff_label)


## 设置选中状态
func set_selected(selected: bool) -> void:
	_is_selected = selected
	_update_style()


## 更新样式
func _update_style() -> void:
	if _is_selected:
		modulate = Color(1.2, 1.2, 1.2, 1.0)
	else:
		modulate = Color(1.0, 1.0, 1.0, 1.0)


## 处理鼠标进入
func _on_mouse_entered() -> void:
	_is_hovered = true
	# 添加悬停效果
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1.1, 1.1, 1.1, 1.0), 0.1)


## 处理鼠标离开
func _on_mouse_exited() -> void:
	_is_hovered = false
	if not _is_selected:
		var tween = create_tween()
		tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.1)


## 选择按钮按下
func _on_select_pressed() -> void:
	selected.emit()


## 预览按钮按下
func _on_preview_pressed() -> void:
	preview_requested.emit()


## 获取歌曲标题
func get_title() -> String:
	return song_data.get("title", "Unknown")


## 获取歌曲文件路径
func get_file_path() -> String:
	return song_data.get("file_path", "")