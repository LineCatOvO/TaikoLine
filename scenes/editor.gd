extends Control
## 编辑器主场景脚本
## 处理菜单操作、工具选择、场景切换

const EditorController = preload("res://src/editor/editor_controller.gd")
const EditorData = preload("res://src/editor/editor_data.gd")
const TimelineView = preload("res://src/editor/timeline_view.gd")

## 控制器引用
@onready var controller: EditorController = $EditorController

## UI组件
@onready var menu_bar: MenuBar = $VBoxContainer/MenuBar
@onready var toolbar: HBoxContainer = $VBoxContainer/Toolbar
@onready var timeline_container: ScrollContainer = $VBoxContainer/TimelineContainer
@onready var timeline_view: TimelineView = $VBoxContainer/TimelineContainer/TimelineView
@onready var property_panel: VBoxContainer = $VBoxContainer/HSplitContainer/PropertyPanel

## 音符选择按钮组
var note_buttons: ButtonGroup

## 当前文件路径
var current_file_path: String = ""

## 是否已修改
var is_modified: bool = false


func _ready() -> void:
	_setup_ui()
	_connect_signals()
	_setup_note_buttons()
	_update_ui()


## 设置UI
func _setup_ui() -> void:
	# 设置窗口标题
	get_tree().root.title = "TaikoLine 谱面编辑器"

	# 创建音符按钮组
	note_buttons = ButtonGroup.new()


## 连接信号
func _connect_signals() -> void:
	if controller:
		controller.data_changed.connect(_on_data_changed)
		controller.selection_changed.connect(_on_selection_changed)
		controller.project_loaded.connect(_on_project_loaded)
		controller.project_saved.connect(_on_project_saved)

	if timeline_view:
		timeline_view.measure_clicked.connect(_on_measure_clicked)


## 设置音符按钮
func _setup_note_buttons() -> void:
	# 清除现有按钮
	for child in toolbar.get_children():
		if child.is_in_group("note_buttons"):
			child.queue_free()

	# 创建音符类型按钮
	var note_types = EditorData.get_all_note_types()
	for note_type in note_types:
		var btn = Button.new()
		btn.text = EditorData.get_note_type_name(note_type)
		btn.tooltip_text = "%s (%s)" % [EditorData.get_note_type_name(note_type), EditorData.note_type_to_char(note_type)]
		btn.toggle_mode = true
		btn.button_group = note_buttons
		btn.add_to_group("note_buttons")

		# 连接按钮信号
		btn.pressed.connect(_on_note_button_pressed.bind(note_type))

		toolbar.add_child(btn)

	# 默认选中第一个
	if note_buttons.get_buttons().size() > 0:
		note_buttons.get_buttons()[0].button_pressed = true


## 更新UI
func _update_ui() -> void:
	# 更新窗口标题
	var title = "TaikoLine 谱面编辑器"
	if not current_file_path.is_empty():
		title += " - " + current_file_path.get_file()
	if is_modified:
		title += " *"
	get_tree().root.title = title


## 处理菜单操作
func _on_menu_item_pressed(id: int) -> void:
	match id:
		0:  # 新建
			_new_project()
		1:  # 打开
			_open_project()
		2:  # 保存
			_save_project()
		3:  # 另存为
			_save_project_as()
		4:  # 退出
			_quit_editor()
		10: # 撤销
			_undo()
		11: # 重做
			_redo()
		12: # 剪切
			_cut()
		13: # 复制
			_copy()
		14: # 粘贴
			_paste()
		15: # 删除
			_delete_selected()
		16: # 全选
			_select_all()
		20: # 放大
			_zoom_in()
		21: # 缩小
			_zoom_out()
		22: # 重置缩放
			_reset_zoom()


## 新建项目
func _new_project() -> void:
	if is_modified:
		# TODO: 显示保存确认对话框
		pass

	controller.create_new_project()
	current_file_path = ""
	is_modified = false
	_update_ui()


## 打开项目
func _open_project() -> void:
	if is_modified:
		# TODO: 显示保存确认对话框
		pass

	# TODO: 显示文件选择对话框
	# 这里使用简化的文件路径
	var file_path = ""  # 需要通过文件对话框获取

	if not file_path.is_empty():
		if controller.load_project(file_path):
			current_file_path = file_path
			is_modified = false
			_update_ui()


## 保存项目
func _save_project() -> void:
	if current_file_path.is_empty():
		_save_project_as()
	else:
		if controller.save_project(current_file_path):
			is_modified = false
			_update_ui()


## 另存为
func _save_project_as() -> void:
	# TODO: 显示文件保存对话框
	var file_path = ""  # 需要通过文件对话框获取

	if not file_path.is_empty():
		if controller.save_project(file_path):
			current_file_path = file_path
			is_modified = false
			_update_ui()


## 退出编辑器
func _quit_editor() -> void:
	if is_modified:
		# TODO: 显示保存确认对话框
		pass

	get_tree().quit()


## 撤销
func _undo() -> void:
	controller.undo()


## 重做
func _redo() -> void:
	controller.redo()


## 剪切
func _cut() -> void:
	controller.copy_selected()
	controller.delete_selected()


## 复制
func _copy() -> void:
	controller.copy_selected()


## 粘贴
func _paste() -> void:
	# TODO: 获取当前时间线位置
	controller.paste(0, 0.0)


## 删除选中
func _delete_selected() -> void:
	controller.delete_selected()


## 全选
func _select_all() -> void:
	controller.select_all()


## 放大
func _zoom_in() -> void:
	if timeline_view:
		timeline_view.set_zoom(timeline_view.zoom * 1.25)


## 缩小
func _zoom_out() -> void:
	if timeline_view:
		timeline_view.set_zoom(timeline_view.zoom / 1.25)


## 重置缩放
func _reset_zoom() -> void:
	if timeline_view:
		timeline_view.set_zoom(1.0)


## 音符按钮按下
func _on_note_button_pressed(note_type: EditorData.NoteType) -> void:
	controller.set_current_note_type(note_type)


## 数据变化回调
func _on_data_changed() -> void:
	is_modified = controller.is_modified()
	_update_ui()


## 选择变化回调
func _on_selection_changed(selected_notes: Array) -> void:
	# 更新属性面板
	_update_property_panel(selected_notes)


## 项目加载回调
func _on_project_loaded(project: EditorData.EditorProject) -> void:
	# 更新时间线视图
	if timeline_view:
		timeline_view.set_controller(controller)


## 项目保存回调
func _on_project_saved(file_path: String) -> void:
	is_modified = false
	_update_ui()


## 小节点击回调
func _on_measure_clicked(measure_index: int, position: float) -> void:
	# 在点击位置添加音符
	controller.add_note(measure_index, position)


## 更新属性面板
func _update_property_panel(selected_notes: Array) -> void:
	# 清空属性面板
	for child in property_panel.get_children():
		child.queue_free()

	if selected_notes.is_empty():
		# 显示项目属性
		_show_project_properties()
	elif selected_notes.size() == 1:
		# 显示单个音符属性
		_show_note_properties(selected_notes[0])
	else:
		# 显示多选属性
		_show_multi_selection_properties(selected_notes.size())


## 显示项目属性
func _show_project_properties() -> void:
	var project = controller.get_project()
	if project == null:
		return

	var meta = project.song_meta

	# 标题
	var title_label = Label.new()
	title_label.text = "项目属性"
	title_label.add_theme_font_size_override("font_size", 16)
	property_panel.add_child(title_label)

	# 歌曲标题
	_add_property_field("歌曲标题", meta.title)
	_add_property_field("BPM", "%.2f" % meta.bpm)
	_add_property_field("偏移", "%.3f" % meta.offset)


## 显示音符属性
func _show_note_properties(note: EditorData.EditorNote) -> void:
	var title_label = Label.new()
	title_label.text = "音符属性"
	title_label.add_theme_font_size_override("font_size", 16)
	property_panel.add_child(title_label)

	_add_property_field("类型", EditorData.get_note_type_name(note.note_type))
	_add_property_field("小节", str(note.measure_index + 1))
	_add_property_field("位置", "%.2f" % note.position)

	if note.note_type in [EditorData.NoteType.BALLOON, EditorData.NoteType.KUSUDAMA]:
		_add_property_field("打击次数", str(note.balloon_hits))


## 显示多选属性
func _show_multi_selection_properties(count: int) -> void:
	var title_label = Label.new()
	title_label.text = "多选属性"
	title_label.add_theme_font_size_override("font_size", 16)
	property_panel.add_child(title_label)

	_add_property_field("选中数量", str(count))


## 添加属性字段
func _add_property_field(label: String, value: String) -> void:
	var hbox = HBoxContainer.new()

	var name_label = Label.new()
	name_label.text = label + ":"
	name_label.custom_minimum_size.x = 80
	hbox.add_child(name_label)

	var value_label = Label.new()
	value_label.text = value
	hbox.add_child(value_label)

	property_panel.add_child(hbox)


## 处理快捷键
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_Z:
				if event.ctrl_pressed:
					if event.shift_pressed:
						_redo()
					else:
						_undo()
			KEY_Y:
				if event.ctrl_pressed:
					_redo()
			KEY_S:
				if event.ctrl_pressed:
					_save_project()
			KEY_O:
				if event.ctrl_pressed:
					_open_project()
			KEY_N:
				if event.ctrl_pressed:
					_new_project()
			KEY_A:
				if event.ctrl_pressed:
					_select_all()
			KEY_C:
				if event.ctrl_pressed:
					_copy()
			KEY_X:
				if event.ctrl_pressed:
					_cut()
			KEY_V:
				if event.ctrl_pressed:
					_paste()
			KEY_DELETE:
				_delete_selected()
			KEY_EQUAL, KEY_PLUS:
				if event.ctrl_pressed:
					_zoom_in()
			KEY_MINUS:
				if event.ctrl_pressed:
					_zoom_out()
			KEY_0:
				if event.ctrl_pressed:
					_reset_zoom()