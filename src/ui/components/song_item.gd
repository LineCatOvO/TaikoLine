class_name SongItem
extends PanelContainer
## 歌曲列表项组件
## 显示单个歌曲的信息

## 信号
signal selected
signal preview_requested

## 歌曲数据
var song_data: Dictionary = {}

## UI节点引用
var _title_label: Label
var _subtitle_label: Label
var _bpm_label: Label
var _difficulty_container: HBoxContainer
var _select_button: Button
var _preview_button: Button


func _ready() -> void:
	_setup_ui()


## 设置UI布局
func _setup_ui() -> void:
	# 设置最小尺寸
	custom_minimum_size = Vector2(600, 80)
	
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
	_title_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))  # 红色
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
	_preview_button.pressed.connect(_on_preview_pressed)
	button_vbox.add_child(_preview_button)
	
	# 选择按钮
	_select_button = Button.new()
	_select_button.text = "Select"
	_select_button.custom_minimum_size = Vector2(80, 30)
	_select_button.pressed.connect(_on_select_pressed)
	button_vbox.add_child(_select_button)


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
	var difficulty_names = ["Easy", "Normal", "Hard", "Oni"]
	var difficulty_colors = [
		Color(0.3, 0.8, 0.3),  # 绿色 - Easy
		Color(0.3, 0.6, 1.0),  # 蓝色 - Normal
		Color(1.0, 0.6, 0.0),  # 橙色 - Hard
		Color(1.0, 0.0, 0.0)   # 红色 - Oni
	]
	
	for i in range(difficulty_names.size()):
		var course_type = i  # CourseType枚举值
		if courses.has(course_type):
			var course = courses[course_type]
			var level = course.get("level", 0)
			
			var diff_label = Label.new()
			diff_label.text = "%s Lv.%d" % [difficulty_names[i], level]
			diff_label.add_theme_font_size_override("font_size", 11)
			diff_label.add_theme_color_override("font_color", difficulty_colors[i])
			_difficulty_container.add_child(diff_label)


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