extends Control
## 编辑器主场景脚本
## 处理菜单操作、工具选择、场景切换

const EditorController = preload("res://src/editor/editor_controller.gd")
const EditorData = preload("res://src/editor/editor_data.gd")
const TimelineView = preload("res://src/editor/timeline_view.gd")
const PreviewController = preload("res://src/editor/preview_controller.gd")

## 控制器引用
@onready var controller: EditorController = $EditorController

## 预览控制器
var preview_controller: PreviewController = null

## UI组件
@onready var menu_bar: MenuBar = $VBoxContainer/MenuBar
@onready var toolbar: HBoxContainer = $VBoxContainer/Toolbar
@onready var timeline_container: ScrollContainer = $VBoxContainer/TimelineContainer
@onready var timeline_view: TimelineView = $VBoxContainer/TimelineContainer/TimelineView
@onready var property_panel: VBoxContainer = $VBoxContainer/HSplitContainer/PropertyPanel

## 播放控制工具栏
var playback_toolbar: HBoxContainer = null
var play_button: Button = null
var pause_button: Button = null
var stop_button: Button = null
var speed_option: OptionButton = null
var position_label: Label = null

## 音符选择按钮组
var note_buttons: ButtonGroup

## 当前文件路径
var current_file_path: String = ""

## 是否已修改
var is_modified: bool = false

## 当前选中的小节索引（-1表示无选中）
var selected_measure_index: int = -1

## 属性面板控件引用
var bpm_spinbox: SpinBox = null
var scroll_spinbox: SpinBox = null
var time_signature_numerator: SpinBox = null
var time_signature_denominator: SpinBox = null
var gogo_checkbox: CheckBox = null


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
	
	# 创建预览控制器
	preview_controller = PreviewController.new()
	preview_controller.set_editor_controller(controller)
	add_child(preview_controller)
	
	# 创建播放控制工具栏
	_setup_playback_toolbar()


## 连接信号
func _connect_signals() -> void:
	if controller:
		controller.data_changed.connect(_on_data_changed)
		controller.selection_changed.connect(_on_selection_changed)
		controller.project_loaded.connect(_on_project_loaded)
		controller.project_saved.connect(_on_project_saved)

	if timeline_view:
		timeline_view.measure_clicked.connect(_on_measure_clicked)
	
	# 连接预览控制器信号
	if preview_controller:
		preview_controller.playback_started.connect(_on_playback_started)
		preview_controller.playback_stopped.connect(_on_playback_stopped)
		preview_controller.playback_paused.connect(_on_playback_paused)
		preview_controller.position_changed.connect(_on_playback_position_changed)
		preview_controller.speed_changed.connect(_on_playback_speed_changed)


## 设置播放控制工具栏
func _setup_playback_toolbar() -> void:
	# 创建播放控制工具栏容器
	playback_toolbar = HBoxContainer.new()
	playback_toolbar.name = "PlaybackToolbar"
	
	# 添加分隔符
	var separator1 = VSeparator.new()
	playback_toolbar.add_child(separator1)
	
	# 播放按钮
	play_button = Button.new()
	play_button.text = "▶"
	play_button.tooltip_text = "播放 (Space)"
	play_button.pressed.connect(_on_play_button_pressed)
	playback_toolbar.add_child(play_button)
	
	# 暂停按钮
	pause_button = Button.new()
	pause_button.text = "⏸"
	pause_button.tooltip_text = "暂停"
	pause_button.pressed.connect(_on_pause_button_pressed)
	playback_toolbar.add_child(pause_button)
	
	# 停止按钮
	stop_button = Button.new()
	stop_button.text = "⏹"
	stop_button.tooltip_text = "停止"
	stop_button.pressed.connect(_on_stop_button_pressed)
	playback_toolbar.add_child(stop_button)
	
	# 添加分隔符
	var separator2 = VSeparator.new()
	playback_toolbar.add_child(separator2)
	
	# 播放速度选择器
	var speed_label = Label.new()
	speed_label.text = "速度:"
	playback_toolbar.add_child(speed_label)
	
	speed_option = OptionButton.new()
	speed_option.tooltip_text = "选择播放速度"
	var speed_names = preview_controller.get_speed_option_names()
	for name in speed_names:
		speed_option.add_item(name)
	speed_option.selected = preview_controller.get_speed_index()
	speed_option.item_selected.connect(_on_speed_option_selected)
	playback_toolbar.add_child(speed_option)
	
	# 添加分隔符
	var separator3 = VSeparator.new()
	playback_toolbar.add_child(separator3)
	
	# 当前位置显示
	var pos_label_title = Label.new()
	pos_label_title.text = "位置:"
	playback_toolbar.add_child(pos_label_title)
	
	position_label = Label.new()
	position_label.text = "00:00.00 / 00:00.00"
	position_label.custom_minimum_size.x = 130
	playback_toolbar.add_child(position_label)
	
	# 将播放控制工具栏添加到工具栏
	toolbar.add_child(playback_toolbar)


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
	# 设置选中的小节
	selected_measure_index = measure_index
	
	# 在点击位置添加音符
	controller.add_note(measure_index, position)
	
	# 更新属性面板显示小节属性
	_update_measure_properties(measure_index)


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


## 更新小节属性面板
func _update_measure_properties(measure_index: int) -> void:
	# 清空属性面板
	for child in property_panel.get_children():
		child.queue_free()
	
	# 显示小节属性编辑
	_show_measure_properties_editor(measure_index)


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
	
	# BPM编辑（可编辑）
	_add_editable_property("BPM", "%.2f" % meta.bpm, 
		func(value): _on_global_bpm_changed(value))
	
	_add_property_field("偏移", "%.3f" % meta.offset)


## 显示小节属性编辑器
func _show_measure_properties_editor(measure_index: int) -> void:
	var project = controller.get_project()
	if project == null:
		return
	
	var course = project.get_current_course()
	if course == null or measure_index < 0 or measure_index >= course.measures.size():
		return
	
	var measure = course.measures[measure_index]
	
	# 标题
	var title_label = Label.new()
	title_label.text = "小节 %d 属性" % (measure_index + 1)
	title_label.add_theme_font_size_override("font_size", 16)
	property_panel.add_child(title_label)
	
	# 分隔线
	_add_separator()
	
	# BPM编辑控件
	var bpm_container = HBoxContainer.new()
	var bpm_label = Label.new()
	bpm_label.text = "BPM:"
	bpm_label.custom_minimum_size.x = 80
	bpm_container.add_child(bpm_label)
	
	bpm_spinbox = SpinBox.new()
	bpm_spinbox.min_value = 1.0
	bpm_spinbox.max_value = 999.0
	bpm_spinbox.step = 1.0
	bpm_spinbox.value = measure.bpm
	bpm_spinbox.tooltip_text = "设置小节BPM"
	bpm_spinbox.value_changed.connect(_on_measure_bpm_changed)
	bpm_container.add_child(bpm_spinbox)
	property_panel.add_child(bpm_container)
	
	# 滚动速度编辑控件
	var scroll_container = HBoxContainer.new()
	var scroll_label = Label.new()
	scroll_label.text = "滚动速度:"
	scroll_label.custom_minimum_size.x = 80
	scroll_container.add_child(scroll_label)
	
	scroll_spinbox = SpinBox.new()
	scroll_spinbox.min_value = 0.1
	scroll_spinbox.max_value = 10.0
	scroll_spinbox.step = 0.1
	scroll_spinbox.value = measure.scroll
	scroll_spinbox.tooltip_text = "设置滚动速度（支持小数）"
	scroll_spinbox.value_changed.connect(_on_measure_scroll_changed)
	scroll_container.add_child(scroll_spinbox)
	property_panel.add_child(scroll_container)
	
	# 拍号编辑控件
	var time_sig_container = VBoxContainer.new()
	var time_sig_label = Label.new()
	time_sig_label.text = "拍号:"
	time_sig_container.add_child(time_sig_label)
	
	var time_sig_hbox = HBoxContainer.new()
	
	time_signature_numerator = SpinBox.new()
	time_signature_numerator.min_value = 1
	time_signature_numerator.max_value = 32
	time_signature_numerator.step = 1
	time_signature_numerator.value = measure.time_signature.x
	time_signature_numerator.tooltip_text = "拍号分子"
	time_signature_numerator.value_changed.connect(_on_measure_time_signature_changed)
	time_sig_hbox.add_child(time_signature_numerator)
	
	var slash_label = Label.new()
	slash_label.text = " / "
	time_sig_hbox.add_child(slash_label)
	
	time_signature_denominator = SpinBox.new()
	time_signature_denominator.min_value = 1
	time_signature_denominator.max_value = 32
	time_signature_denominator.step = 1
	time_signature_denominator.value = measure.time_signature.y
	time_signature_denominator.tooltip_text = "拍号分母"
	time_signature_denominator.value_changed.connect(_on_measure_time_signature_changed)
	time_sig_hbox.add_child(time_signature_denominator)
	
	time_sig_container.add_child(time_sig_hbox)
	property_panel.add_child(time_sig_container)
	
	# 分隔线
	_add_separator()
	
	# Go-Go Time切换按钮
	var gogo_container = HBoxContainer.new()
	var gogo_label = Label.new()
	gogo_label.text = "Go-Go Time:"
	gogo_label.custom_minimum_size.x = 80
	gogo_container.add_child(gogo_label)
	
	gogo_checkbox = CheckBox.new()
	gogo_checkbox.button_pressed = measure.is_gogo
	gogo_checkbox.tooltip_text = "切换Go-Go Time状态"
	gogo_checkbox.toggled.connect(_on_measure_gogo_toggled)
	gogo_container.add_child(gogo_checkbox)
	property_panel.add_child(gogo_container)
	
	# 显示小节线开关
	var barline_container = HBoxContainer.new()
	var barline_label = Label.new()
	barline_label.text = "显示小节线:"
	barline_label.custom_minimum_size.x = 80
	barline_container.add_child(barline_label)
	
	var barline_checkbox = CheckBox.new()
	barline_checkbox.button_pressed = measure.show_barline
	barline_checkbox.tooltip_text = "切换小节线显示"
	barline_checkbox.toggled.connect(_on_measure_barline_toggled)
	barline_container.add_child(barline_checkbox)
	property_panel.add_child(barline_container)
	
	# 分隔线
	_add_separator()
	
	# 小节信息
	_add_property_field("音符数量", str(measure.notes.size()))
	_add_property_field("小节时长", "%.2f 秒" % measure.get_duration())


## 添加分隔线
func _add_separator() -> void:
	var separator = HSeparator.new()
	property_panel.add_child(separator)


## 添加可编辑属性字段
func _add_editable_property(label: String, value: String, callback: Callable) -> void:
	var hbox = HBoxContainer.new()

	var name_label = Label.new()
	name_label.text = label + ":"
	name_label.custom_minimum_size.x = 80
	hbox.add_child(name_label)

	var line_edit = LineEdit.new()
	line_edit.text = value
	line_edit.custom_minimum_size.x = 100
	line_edit.tooltip_text = "编辑" + label
	line_edit.text_submitted.connect(callback)
	hbox.add_child(line_edit)

	property_panel.add_child(hbox)


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


## 音符快捷键映射表
const NOTE_SHORTCUTS: Dictionary = {
	# 数字键映射
	KEY_1: EditorData.NoteType.DON,           # 1 = Don（小红）
	KEY_2: EditorData.NoteType.KA,            # 2 = Ka（小蓝）
	KEY_3: EditorData.NoteType.DON_BIG,       # 3 = Big Don（大红）
	KEY_4: EditorData.NoteType.KA_BIG,        # 4 = Big Ka（大蓝）
	KEY_5: EditorData.NoteType.RENDA,         # 5 = Renda（连打）
	KEY_6: EditorData.NoteType.RENDA_BIG,     # 6 = Big Renda（大连打）
	KEY_7: EditorData.NoteType.BALLOON,       # 7 = Balloon（气球）
	KEY_8: EditorData.NoteType.END,           # 8 = End（结束标记）
	KEY_9: EditorData.NoteType.KUSUDAMA,      # 9 = Kusudama（久寿玉）
	# 字母键映射
	KEY_A: EditorData.NoteType.DON_DOUBLE,    # A = Don Double（双人红）
	KEY_B: EditorData.NoteType.KA_DOUBLE,     # B = Ka Double（双人蓝）
	KEY_C: EditorData.NoteType.BOMB,          # C = Bomb（炸弹）
	KEY_F: EditorData.NoteType.ADLIB,         # F = ADLIB（隐藏音符）
	KEY_G: EditorData.NoteType.SWAP,          # G = Swap（交换）
}


## 处理快捷键
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		# 首先检查音符快捷键（不需要Ctrl修饰）
		if _handle_note_shortcut(event):
			return
		
		# 然后检查其他快捷键
		match event.keycode:
			KEY_SPACE:
				# 空格键：播放/暂停
				if preview_controller:
					preview_controller.toggle_play_pause()
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
			KEY_LEFT:
				# 左箭头：向后跳转5秒
				if preview_controller and not event.ctrl_pressed:
					preview_controller.skip_backward(5.0)
			KEY_RIGHT:
				# 右箭头：向前跳转5秒
				if preview_controller and not event.ctrl_pressed:
					preview_controller.skip_forward(5.0)
			KEY_HOME:
				# Home键：跳转到开头
				if preview_controller:
					preview_controller.jump_to_start()
			KEY_END:
				# End键：跳转到结尾
				if preview_controller:
					preview_controller.jump_to_end()


## 处理音符快捷键
## 返回true表示已处理，false表示未处理
func _handle_note_shortcut(event: InputEventKey) -> bool:
	# 不处理带有Ctrl/Shift/Alt修饰的按键
	if event.ctrl_pressed or event.shift_pressed or event.alt_pressed:
		return false
	
	# 检查是否是音符快捷键
	if NOTE_SHORTCUTS.has(event.keycode):
		var note_type: EditorData.NoteType = NOTE_SHORTCUTS[event.keycode]
		controller.set_current_note_type(note_type)
		_update_note_button_selection(note_type)
		return true
	
	return false


## 更新音符按钮选中状态
func _update_note_button_selection(note_type: EditorData.NoteType) -> void:
	if note_buttons == null:
		return
	
	var buttons = note_buttons.get_buttons()
	for btn in buttons:
		# 通过按钮的元数据或索引来确定选中状态
		var btn_index = btn.get_index()
		var note_types = EditorData.get_all_note_types()
		if btn_index < note_types.size() and note_types[btn_index] == note_type:
			btn.button_pressed = true
			break


## ========== 属性变更回调函数 ==========

## 全局BPM变更
func _on_global_bpm_changed(value: String) -> void:
	var new_bpm = value.to_float()
	if new_bpm > 0:
		var project = controller.get_project()
		if project != null:
			project.song_meta.bpm = new_bpm
			controller.set_measure_bpm(0, new_bpm)  # 设置第一个小节的BPM
			is_modified = true
			_update_ui()


## 小节BPM变更
func _on_measure_bpm_changed(value: float) -> void:
	if selected_measure_index >= 0:
		controller.set_measure_bpm(selected_measure_index, value)


## 小节滚动速度变更
func _on_measure_scroll_changed(value: float) -> void:
	if selected_measure_index >= 0:
		controller.set_measure_scroll(selected_measure_index, value)


## 小节拍号变更
func _on_measure_time_signature_changed(_value: float) -> void:
	if selected_measure_index >= 0 and time_signature_numerator != null and time_signature_denominator != null:
		var project = controller.get_project()
		if project == null:
			return
		
		var course = project.get_current_course()
		if course == null or selected_measure_index >= course.measures.size():
			return
		
		var measure = course.measures[selected_measure_index]
		measure.time_signature = Vector2(
			time_signature_numerator.value,
			time_signature_denominator.value
		)
		
		# 触发数据变更
		controller.data_changed.emit()


## 小节Go-Go Time切换
func _on_measure_gogo_toggled(pressed: bool) -> void:
	if selected_measure_index >= 0:
		controller.toggle_measure_gogo(selected_measure_index)


## 小节小节线显示切换
func _on_measure_barline_toggled(pressed: bool) -> void:
	if selected_measure_index >= 0:
		var project = controller.get_project()
		if project == null:
			return
		
		var course = project.get_current_course()
		if course == null or selected_measure_index >= course.measures.size():
			return
		
		var measure = course.measures[selected_measure_index]
		measure.show_barline = pressed
		
		# 触发数据变更
		controller.data_changed.emit()


## ========== 播放控制回调函数 ==========

## 播放按钮按下
func _on_play_button_pressed() -> void:
	if preview_controller:
		preview_controller.play()


## 暂停按钮按下
func _on_pause_button_pressed() -> void:
	if preview_controller:
		preview_controller.pause()


## 停止按钮按下
func _on_stop_button_pressed() -> void:
	if preview_controller:
		preview_controller.stop()


## 播放速度选择
func _on_speed_option_selected(index: int) -> void:
	if preview_controller:
		preview_controller.set_speed_by_index(index)


## 播放开始回调
func _on_playback_started() -> void:
	# 更新按钮状态
	if play_button:
		play_button.disabled = true
	if pause_button:
		pause_button.disabled = false
	if stop_button:
		stop_button.disabled = false
	
	# 更新时间线视图
	if timeline_view:
		timeline_view.set_playing(true)


## 播放停止回调
func _on_playback_stopped() -> void:
	# 更新按钮状态
	if play_button:
		play_button.disabled = false
	if pause_button:
		pause_button.disabled = true
	if stop_button:
		stop_button.disabled = true
	
	# 更新时间线视图
	if timeline_view:
		timeline_view.set_playing(false)
		timeline_view.set_play_position(0.0)
	
	# 更新位置显示
	_update_position_display(0.0)


## 播放暂停回调
func _on_playback_paused() -> void:
	# 更新按钮状态
	if play_button:
		play_button.disabled = false
	if pause_button:
		pause_button.disabled = true


## 播放位置变更回调
func _on_playback_position_changed(time: float) -> void:
	# 更新时间线视图
	if timeline_view:
		timeline_view.set_play_position(time)
	
	# 更新位置显示
	_update_position_display(time)


## 播放速度变更回调
func _on_playback_speed_changed(speed: float) -> void:
	# 更新速度选择器
	if speed_option:
		speed_option.selected = preview_controller.get_speed_index()


## 更新位置显示
func _update_position_display(time: float) -> void:
	if position_label and preview_controller:
		position_label.text = "%s / %s" % [
			preview_controller.get_formatted_position(),
			preview_controller.get_formatted_duration()
		]