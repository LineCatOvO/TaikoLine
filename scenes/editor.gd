extends Control
## 编辑器主场景脚本
## 处理菜单操作、工具选择、场景切换
## 支持高级功能：批量操作、BPM编辑、Go-Go Time编辑等

const EditorController = preload("res://src/editor/editor_controller.gd")
const EditorData = preload("res://src/editor/editor_data.gd")
const TJAData = preload("res://src/parser/tja_data.gd")
const TimelineView = preload("res://src/editor/timeline_view.gd")
const PreviewController = preload("res://src/editor/preview_controller.gd")
const BranchEditor = preload("res://src/editor/branch_editor.gd")
const Metronome = preload("res://src/editor/metronome.gd")
const BPMEditor = preload("res://src/editor/bpm_editor.gd")
const GogoEditor = preload("res://src/editor/gogo_editor.gd")
const BatchOperations = preload("res://src/editor/batch_operations.gd")

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

## 分支编辑器
var branch_editor: BranchEditor = null
var branch_toolbar: HBoxContainer = null
var branch_buttons: ButtonGroup = null

## 音符选择按钮组
var note_buttons: ButtonGroup

## 难度选择按钮组
var course_buttons: ButtonGroup

## 当前文件路径
var current_file_path: String = ""

## 是否已修改
var is_modified: bool = false

## 当前选中的小节索引（-1表示无选中）
var selected_measure_index: int = -1

## 音频相关属性
var audio_file_path: String = ""
var audio_file_dialog: FileDialog = null

## TJA文件对话框
var open_file_dialog: FileDialog = null
var save_file_dialog: FileDialog = null

## 节拍器
var metronome: Metronome = null

## 网格设置
var grid_subdivision: int = 16  ## 网格细分（4, 8, 16, 32）
var snap_enabled: bool = true   ## 吸附开关

## 属性面板控件引用
var bpm_spinbox: SpinBox = null
var scroll_spinbox: SpinBox = null
var time_signature_numerator: SpinBox = null
var time_signature_denominator: SpinBox = null
var gogo_checkbox: CheckBox = null

## 音频控制UI控件
var audio_volume_slider: HSlider = null
var audio_mute_button: Button = null
var audio_status_label: Label = null

## 网格设置UI控件
var grid_subdivision_option: OptionButton = null
var snap_checkbox: CheckBox = null


func _ready() -> void:
	_setup_ui()
	_connect_signals()
	_setup_note_buttons()
	_setup_audio_dialog()
	_setup_file_dialogs()
	_setup_metronome()
	_setup_grid_ui()
	_setup_advanced_panel()
	_update_ui()


## 设置UI
func _setup_ui() -> void:
	# 设置窗口标题
	get_tree().root.title = "TaikoLine 谱面编辑器"

	# 创建音符按钮组
	note_buttons = ButtonGroup.new()

	# 创建分支按钮组
	branch_buttons = ButtonGroup.new()

	# 创建难度选择按钮组
	course_buttons = ButtonGroup.new()

	# 创建预览控制器
	preview_controller = PreviewController.new()
	preview_controller.set_editor_controller(controller)
	add_child(preview_controller)

	# 创建播放控制工具栏
	_setup_playback_toolbar()

	# 创建难度选择工具栏
	_setup_course_toolbar()

	# 创建分支工具栏
	_setup_branch_toolbar()

	# 创建分支编辑器
	_setup_branch_editor()


## 连接菜单信号
func _connect_menu_signals() -> void:
	# 连接菜单按钮的弹出菜单信号
	for child in menu_bar.get_children():
		if child is MenuButton:
			var popup = child.get_popup()
			if popup:
				popup.id_pressed.connect(_on_menu_item_pressed)


## 连接信号
func _connect_signals() -> void:
	if controller:
		controller.data_changed.connect(_on_data_changed)
		controller.selection_changed.connect(_on_selection_changed)
		controller.project_loaded.connect(_on_project_loaded)
		controller.project_saved.connect(_on_project_saved)
		controller.branch_changed.connect(_on_branch_changed)
		controller.branch_condition_added.connect(_on_branch_condition_added)
		controller.branch_condition_removed.connect(_on_branch_condition_removed)

	if timeline_view:
		timeline_view.measure_clicked.connect(_on_measure_clicked)

	# 连接预览控制器信号
	if preview_controller:
		preview_controller.playback_started.connect(_on_playback_started)
		preview_controller.playback_stopped.connect(_on_playback_stopped)
		preview_controller.playback_paused.connect(_on_playback_paused)
		preview_controller.position_changed.connect(_on_playback_position_changed)
		preview_controller.speed_changed.connect(_on_playback_speed_changed)
		preview_controller.audio_loaded.connect(_on_audio_loaded)
		preview_controller.audio_unloaded.connect(_on_audio_unloaded)
		preview_controller.audio_load_failed.connect(_on_audio_load_failed)

	# 连接分支编辑器信号
	if branch_editor:
		branch_editor.branch_selected.connect(_on_branch_selected)
		branch_editor.condition_added.connect(_on_condition_added)
		branch_editor.condition_removed.connect(_on_condition_removed)

	# 连接菜单信号
	_connect_menu_signals()


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

	# 添加分隔符
	var separator4 = VSeparator.new()
	playback_toolbar.add_child(separator4)

	# 音频控制区域
	_setup_audio_controls()

	# 将播放控制工具栏添加到工具栏
	toolbar.add_child(playback_toolbar)


## 设置难度选择工具栏
func _setup_course_toolbar() -> void:
	# 创建难度选择工具栏容器
	var course_toolbar = HBoxContainer.new()
	course_toolbar.name = "CourseToolbar"

	# 添加分隔符
	var separator1 = VSeparator.new()
	course_toolbar.add_child(separator1)

	# 难度标签
	var course_label = Label.new()
	course_label.text = "难度:"
	course_toolbar.add_child(course_label)

	# Easy按钮
	var easy_btn = Button.new()
	easy_btn.text = "Easy"
	easy_btn.tooltip_text = "简单难度"
	easy_btn.toggle_mode = true
	easy_btn.button_group = course_buttons
	easy_btn.pressed.connect(_on_course_button_pressed.bind(TJAData.CourseType.EASY))
	course_toolbar.add_child(easy_btn)

	# Normal按钮
	var normal_btn = Button.new()
	normal_btn.text = "Normal"
	normal_btn.tooltip_text = "普通难度"
	normal_btn.toggle_mode = true
	normal_btn.button_group = course_buttons
	normal_btn.pressed.connect(_on_course_button_pressed.bind(TJAData.CourseType.NORMAL))
	course_toolbar.add_child(normal_btn)

	# Hard按钮
	var hard_btn = Button.new()
	hard_btn.text = "Hard"
	hard_btn.tooltip_text = "困难难度"
	hard_btn.toggle_mode = true
	hard_btn.button_group = course_buttons
	hard_btn.pressed.connect(_on_course_button_pressed.bind(TJAData.CourseType.HARD))
	course_toolbar.add_child(hard_btn)

	# Oni按钮（默认选中）
	var oni_btn = Button.new()
	oni_btn.text = "Oni"
	oni_btn.tooltip_text = "魔王难度"
	oni_btn.toggle_mode = true
	oni_btn.button_group = course_buttons
	oni_btn.button_pressed = true
	oni_btn.pressed.connect(_on_course_button_pressed.bind(TJAData.CourseType.ONI))
	course_toolbar.add_child(oni_btn)

	# 将难度选择工具栏添加到工具栏
	toolbar.add_child(course_toolbar)


## 难度按钮按下回调
func _on_course_button_pressed(course_type: TJAData.CourseType) -> void:
	controller.set_current_course(course_type)


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
		5:  # 加载音频
			_on_load_audio_pressed()
		6:  # 卸载音频
			_on_unload_audio_pressed()
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

	if open_file_dialog:
		open_file_dialog.popup_centered(Vector2i(800, 600))


## 打开文件选择回调
func _on_open_file_selected(file_path: String) -> void:
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
	if save_file_dialog:
		save_file_dialog.popup_centered(Vector2i(800, 600))


## 保存文件选择回调
func _on_save_file_selected(file_path: String) -> void:
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
		# 首先检查批量操作快捷键
		if _handle_batch_shortcut(event):
			return

		# 然后检查音符快捷键（不需要Ctrl修饰）
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
				if event.ctrl_pressed and not event.shift_pressed:
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
			KEY_F1:
				# F1: 显示谱面统计
				_show_chart_statistics()
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
			KEY_N:
				# Alt+N: 切换到Normal分支
				if event.alt_pressed and not event.ctrl_pressed and not event.shift_pressed:
					controller.switch_branch(EditorData.BranchType.NORMAL)
			KEY_E:
				# Alt+E: 切换到Expert分支
				if event.alt_pressed and not event.ctrl_pressed and not event.shift_pressed:
					controller.switch_branch(EditorData.BranchType.EXPERT)
			KEY_M:
				# Alt+M: 切换到Master分支
				if event.alt_pressed and not event.ctrl_pressed and not event.shift_pressed:
					controller.switch_branch(EditorData.BranchType.MASTER)


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


## ========== 分支相关方法 ==========

## 设置分支工具栏
func _setup_branch_toolbar() -> void:
	# 创建分支工具栏容器
	branch_toolbar = HBoxContainer.new()
	branch_toolbar.name = "BranchToolbar"

	# 添加分隔符
	var separator1 = VSeparator.new()
	branch_toolbar.add_child(separator1)

	# 分支标签
	var branch_label = Label.new()
	branch_label.text = "分支:"
	branch_toolbar.add_child(branch_label)

	# Normal分支按钮
	var normal_btn = Button.new()
	normal_btn.text = "#N"
	normal_btn.tooltip_text = "普通分支 (Normal) - 快捷键: Alt+N"
	normal_btn.toggle_mode = true
	normal_btn.button_group = branch_buttons
	normal_btn.button_pressed = true
	normal_btn.pressed.connect(_on_branch_button_pressed.bind(EditorData.BranchType.NORMAL))
	branch_toolbar.add_child(normal_btn)

	# Expert分支按钮
	var expert_btn = Button.new()
	expert_btn.text = "#E"
	expert_btn.tooltip_text = "高级分支 (Expert) - 快捷键: Alt+E"
	expert_btn.toggle_mode = true
	expert_btn.button_group = branch_buttons
	expert_btn.pressed.connect(_on_branch_button_pressed.bind(EditorData.BranchType.EXPERT))
	branch_toolbar.add_child(expert_btn)

	# Master分支按钮
	var master_btn = Button.new()
	master_btn.text = "#M"
	master_btn.tooltip_text = "大师分支 (Master) - 快捷键: Alt+M"
	master_btn.toggle_mode = true
	master_btn.button_group = branch_buttons
	master_btn.pressed.connect(_on_branch_button_pressed.bind(EditorData.BranchType.MASTER))
	branch_toolbar.add_child(master_btn)

	# 添加分隔符
	var separator2 = VSeparator.new()
	branch_toolbar.add_child(separator2)

	# 启用分支按钮
	var enable_branch_btn = Button.new()
	enable_branch_btn.text = "启用分支"
	enable_branch_btn.tooltip_text = "为当前难度启用分支模式"
	enable_branch_btn.pressed.connect(_on_enable_branch_pressed)
	branch_toolbar.add_child(enable_branch_btn)

	# 将分支工具栏添加到工具栏
	toolbar.add_child(branch_toolbar)


## 设置分支编辑器
func _setup_branch_editor() -> void:
	branch_editor = BranchEditor.new()
	branch_editor.name = "BranchEditor"
	branch_editor.custom_minimum_size.x = 200

	# 添加到属性面板
	property_panel.add_child(branch_editor)


## 分支按钮按下回调
func _on_branch_button_pressed(branch_type: int) -> void:
	controller.switch_branch(branch_type)


## 启用分支按钮按下回调
func _on_enable_branch_pressed() -> void:
	controller.enable_branch_mode()


## 分支变更回调
func _on_branch_changed(new_branch: int) -> void:
	# 更新分支编辑器
	if branch_editor:
		branch_editor.set_current_branch(new_branch)

	# 更新分支按钮状态
	_update_branch_button_state(new_branch)


## 更新分支按钮状态
func _update_branch_button_state(branch_type: int) -> void:
	if branch_buttons == null:
		return

	var buttons = branch_buttons.get_buttons()
	var index = 0
	for btn in buttons:
		if index == branch_type:
			btn.button_pressed = true
			break
		index += 1


## 分支条件添加回调
func _on_branch_condition_added(condition: EditorData.EditorBranchCondition) -> void:
	if branch_editor:
		branch_editor.update_conditions(controller.get_branch_conditions())


## 分支条件移除回调
func _on_branch_condition_removed(index: int) -> void:
	if branch_editor:
		branch_editor.update_conditions(controller.get_branch_conditions())


## 分支编辑器 - 分支选择回调
func _on_branch_selected(branch_type: int) -> void:
	controller.switch_branch(branch_type)


## 分支编辑器 - 条件添加回调
func _on_condition_added(condition: EditorData.EditorBranchCondition) -> void:
	controller.add_branch_condition(
		condition.measure_index,
		condition.condition_type,
		condition.normal_threshold,
		condition.expert_threshold
	)


## 分支编辑器 - 条件移除回调
func _on_condition_removed(index: int) -> void:
	controller.remove_branch_condition(index)


## ========== 音频相关方法 ==========

## 设置音频文件对话框
func _setup_audio_dialog() -> void:
	audio_file_dialog = FileDialog.new()
	audio_file_dialog.name = "AudioFileDialog"
	audio_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	audio_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	audio_file_dialog.title = "选择音频文件"
	audio_file_dialog.filters = ["*.ogg ; OGG Vorbis", "*.mp3 ; MP3 Audio", "*.wav ; WAV Audio"]
	audio_file_dialog.file_selected.connect(_on_audio_file_selected)
	add_child(audio_file_dialog)


## 设置TJA文件对话框
func _setup_file_dialogs() -> void:
	# 打开文件对话框
	open_file_dialog = FileDialog.new()
	open_file_dialog.name = "OpenFileDialog"
	open_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	open_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	open_file_dialog.title = "打开TJA文件"
	open_file_dialog.filters = ["*.tja ; TJA Chart File", "*.tjf ; TJF Chart File"]
	open_file_dialog.file_selected.connect(_on_open_file_selected)
	add_child(open_file_dialog)

	# 保存文件对话框
	save_file_dialog = FileDialog.new()
	save_file_dialog.name = "SaveFileDialog"
	save_file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	save_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	save_file_dialog.title = "保存TJA文件"
	save_file_dialog.filters = ["*.tja ; TJA Chart File"]
	save_file_dialog.file_selected.connect(_on_save_file_selected)
	add_child(save_file_dialog)


## 设置节拍器
func _setup_metronome() -> void:
	metronome = Metronome.new()
	metronome.name = "Metronome"
	metronome.enabled = false
	add_child(metronome)


## 设置网格UI
func _setup_grid_ui() -> void:
	# 创建网格设置容器
	var grid_container = HBoxContainer.new()
	grid_container.name = "GridSettings"

	# 添加分隔符
	var separator1 = VSeparator.new()
	grid_container.add_child(separator1)

	# 网格细分标签
	var grid_label = Label.new()
	grid_label.text = "网格:"
	grid_container.add_child(grid_label)

	# 网格细分选择器
	grid_subdivision_option = OptionButton.new()
	grid_subdivision_option.tooltip_text = "选择网格细分"
	grid_subdivision_option.add_item("1/4")
	grid_subdivision_option.add_item("1/8")
	grid_subdivision_option.add_item("1/16")
	grid_subdivision_option.add_item("1/32")
	grid_subdivision_option.selected = 2  # 默认1/16
	grid_subdivision_option.item_selected.connect(_on_grid_subdivision_changed)
	grid_container.add_child(grid_subdivision_option)

	# 吸附开关
	snap_checkbox = CheckBox.new()
	snap_checkbox.text = "吸附"
	snap_checkbox.button_pressed = snap_enabled
	snap_checkbox.tooltip_text = "启用/禁用网格吸附"
	snap_checkbox.toggled.connect(_on_snap_toggled)
	grid_container.add_child(snap_checkbox)

	# 将网格设置添加到工具栏
	toolbar.add_child(grid_container)


## 设置音频控制UI
func _setup_audio_controls() -> void:
	# 音频状态标签
	audio_status_label = Label.new()
	audio_status_label.text = "无音频"
	audio_status_label.tooltip_text = "当前音频状态"
	audio_status_label.custom_minimum_size.x = 80
	playback_toolbar.add_child(audio_status_label)

	# 音量控制
	var volume_label = Label.new()
	volume_label.text = "音量:"
	playback_toolbar.add_child(volume_label)

	audio_volume_slider = HSlider.new()
	audio_volume_slider.min_value = -40.0
	audio_volume_slider.max_value = 6.0
	audio_volume_slider.value = 0.0
	audio_volume_slider.step = 1.0
	audio_volume_slider.custom_minimum_size.x = 80
	audio_volume_slider.tooltip_text = "调整音频音量"
	audio_volume_slider.value_changed.connect(_on_audio_volume_changed)
	audio_volume_slider.editable = false  # 默认禁用，加载音频后启用
	playback_toolbar.add_child(audio_volume_slider)

	# 静音按钮
	audio_mute_button = Button.new()
	audio_mute_button.text = "🔊"
	audio_mute_button.tooltip_text = "静音/取消静音"
	audio_mute_button.toggle_mode = true
	audio_mute_button.button_pressed = false
	audio_mute_button.pressed.connect(_on_audio_mute_toggled)
	audio_mute_button.disabled = true  # 默认禁用，加载音频后启用
	playback_toolbar.add_child(audio_mute_button)


## 加载音频菜单项
func _on_load_audio_pressed() -> void:
	if audio_file_dialog:
		audio_file_dialog.popup_centered(Vector2i(800, 600))


## 音频文件选择回调
func _on_audio_file_selected(path: String) -> void:
	if preview_controller == null:
		return

	if preview_controller.load_audio(path):
		audio_file_path = path
		_update_audio_status()
		_enable_audio_controls(true)
		
		# 更新项目数据
		var project = controller.get_project()
		if project != null:
			project.audio_file = path
			is_modified = true
			_update_ui()
	else:
		# 显示错误提示
		print("音频加载失败: ", path)


## 卸载音频菜单项
func _on_unload_audio_pressed() -> void:
	if preview_controller == null:
		return

	preview_controller.unload_audio()
	audio_file_path = ""
	_update_audio_status()
	_enable_audio_controls(false)

	# 更新项目数据
	var project = controller.get_project()
	if project != null:
		project.audio_file = ""
		is_modified = true
		_update_ui()


## 更新音频状态显示
func _update_audio_status() -> void:
	if audio_status_label == null:
		return

	if preview_controller and preview_controller.is_audio_loaded:
		audio_status_label.text = preview_controller.get_audio_filename()
		audio_status_label.tooltip_text = "已加载: " + preview_controller.audio_file_path
	else:
		audio_status_label.text = "无音频"
		audio_status_label.tooltip_text = "当前音频状态"


## 启用/禁用音频控制
func _enable_audio_controls(enabled: bool) -> void:
	if audio_volume_slider:
		audio_volume_slider.editable = enabled
	if audio_mute_button:
		audio_mute_button.disabled = not enabled


## 音频音量变更回调
func _on_audio_volume_changed(value: float) -> void:
	if preview_controller:
		preview_controller.set_audio_volume(value)


## 音频静音切换回调
func _on_audio_mute_toggled() -> void:
	if preview_controller == null or audio_mute_button == null:
		return

	var muted = audio_mute_button.button_pressed
	preview_controller.set_audio_muted(muted)
	audio_mute_button.text = "🔇" if muted else "🔊"


## ========== 网格设置方法 ==========

## 网格细分变更回调
func _on_grid_subdivision_changed(index: int) -> void:
	match index:
		0: grid_subdivision = 4
		1: grid_subdivision = 8
		2: grid_subdivision = 16
		3: grid_subdivision = 32
		_: grid_subdivision = 16

	# 通知时间线视图更新
	if timeline_view:
		timeline_view.set_grid_subdivision(grid_subdivision)


## 吸附开关切换回调
func _on_snap_toggled(enabled: bool) -> void:
	snap_enabled = enabled

	# 通知时间线视图更新
	if timeline_view:
		timeline_view.set_snap_enabled(snap_enabled)


## 获取当前网格细分
func get_grid_subdivision() -> int:
	return grid_subdivision


## 获取吸附状态
func is_snap_enabled() -> bool:
	return snap_enabled


## 将位置吸附到网格
func snap_to_grid(position: float) -> float:
	if not snap_enabled:
		return position

	# 计算网格间隔（在小节内的位置，0.0-1.0）
	var grid_step = 1.0 / float(grid_subdivision)
	return round(position / grid_step) * grid_step


## ========== 音频信号回调 ==========

## 音频加载成功回调
func _on_audio_loaded(path: String) -> void:
	_update_audio_status()
	print("音频加载成功: ", path)


## 音频卸载回调
func _on_audio_unloaded() -> void:
	_update_audio_status()


## 音频加载失败回调
func _on_audio_load_failed(error: String) -> void:
	print("音频加载失败: ", error)
	# 可以在这里显示错误对话框


## ========== 高级功能面板 ==========

## BPM编辑器
var bpm_editor: BPMEditor = null

## Go-Go Time编辑器
var gogo_editor: GogoEditor = null

## 高级功能面板容器
var advanced_panel: TabContainer = null


## 设置高级功能面板
func _setup_advanced_panel() -> void:
	# 创建标签容器
	advanced_panel = TabContainer.new()
	advanced_panel.name = "AdvancedPanel"
	advanced_panel.custom_minimum_size.x = 250

	# 创建BPM编辑器
	bpm_editor = BPMEditor.new()
	bpm_editor.name = "BPM"
	bpm_editor.set_controller(controller)
	if controller.batch_operations != null:
		bpm_editor.set_batch_operations(controller.batch_operations)
	advanced_panel.add_child(bpm_editor)

	# 创建Go-Go Time编辑器
	gogo_editor = GogoEditor.new()
	gogo_editor.name = "Go-Go"
	gogo_editor.set_controller(controller)
	if controller.batch_operations != null:
		gogo_editor.set_batch_operations(controller.batch_operations)
	advanced_panel.add_child(gogo_editor)

	# 添加到属性面板
	property_panel.add_child(advanced_panel)


## 更新高级功能面板
func _update_advanced_panel() -> void:
	if bpm_editor != null:
		bpm_editor._update_bpm_list()
	if gogo_editor != null:
		gogo_editor._update_gogo_list()


## ========== 批量操作快捷键 ==========

## 处理批量操作快捷键
func _handle_batch_shortcut(event: InputEventKey) -> bool:
	if event.ctrl_pressed and event.shift_pressed:
		match event.keycode:
			KEY_A:
				# Ctrl+Shift+A: 高级全选（弹出选择对话框）
				_show_advanced_select_dialog()
				return true
			KEY_B:
				# Ctrl+Shift+B: 批量修改音符类型
				_show_batch_type_dialog()
				return true
			KEY_G:
				# Ctrl+Shift+G: 批量设置Go-Go Time
				_show_batch_gogo_dialog()
				return true
			KEY_T:
				# Ctrl+Shift+T: 批量设置BPM
				_show_batch_bpm_dialog()
				return true

	return false


## 显示高级选择对话框
func _show_advanced_select_dialog() -> void:
	# 创建选择对话框
	var dialog = ConfirmationDialog.new()
	dialog.title = "高级选择"
	dialog.min_size = Vector2(300, 200)

	var vbox = VBoxContainer.new()
	dialog.add_child(vbox)

	# 选择类型
	var type_label = Label.new()
	type_label.text = "选择类型:"
	vbox.add_child(type_label)

	var type_option = OptionButton.new()
	type_option.add_item("小节范围")
	type_option.add_item("音符类型")
	type_option.add_item("Go-Go Time区域")
	type_option.add_item("连打音符")
	type_option.add_item("大音符")
	vbox.add_child(type_option)

	# 参数输入
	var param_container = VBoxContainer.new()
	vbox.add_child(param_container)

	dialog.confirmed.connect(func():
		_execute_advanced_select(type_option.selected, param_container)
		dialog.queue_free()
	)

	dialog.canceled.connect(func(): dialog.queue_free())

	add_child(dialog)
	dialog.popup_centered()


## 执行高级选择
func _execute_advanced_select(type_index: int, param_container: VBoxContainer) -> void:
	if controller == null or controller.batch_operations == null:
		return

	match type_index:
		0:  # 小节范围
			# 需要从参数容器获取范围
			pass
		1:  # 音符类型
			# 需要从参数容器获取类型
			pass
		2:  # Go-Go Time区域
			controller.batch_operations.select_notes_in_gogo_region()
		3:  # 连打音符
			controller.batch_operations.select_renda_notes()
		4:  # 大音符
			controller.batch_operations.select_big_notes()


## 显示批量类型修改对话框
func _show_batch_type_dialog() -> void:
	if controller == null:
		return

	var selected = controller.selected_notes
	if selected.is_empty():
		return

	# 创建对话框
	var dialog = ConfirmationDialog.new()
	dialog.title = "批量修改音符类型"
	dialog.min_size = Vector2(300, 150)

	var vbox = VBoxContainer.new()
	dialog.add_child(vbox)

	var info_label = Label.new()
	info_label.text = "选中 %d 个音符" % selected.size()
	vbox.add_child(info_label)

	var type_label = Label.new()
	type_label.text = "新类型:"
	vbox.add_child(type_label)

	var type_option = OptionButton.new()
	var note_types = EditorData.get_all_note_types()
	for note_type in note_types:
		type_option.add_item(EditorData.get_note_type_name(note_type))
	vbox.add_child(type_option)

	dialog.confirmed.connect(func():
		var new_type = note_types[type_option.selected]
		controller.batch_change_note_type(new_type)
		dialog.queue_free()
	)

	dialog.canceled.connect(func(): dialog.queue_free())

	add_child(dialog)
	dialog.popup_centered()


## 显示批量Go-Go Time对话框
func _show_batch_gogo_dialog() -> void:
	if controller == null:
		return

	var dialog = ConfirmationDialog.new()
	dialog.title = "批量设置Go-Go Time"
	dialog.min_size = Vector2(300, 200)

	var vbox = VBoxContainer.new()
	dialog.add_child(vbox)

	# 起始小节
	var start_hbox = HBoxContainer.new()
	vbox.add_child(start_hbox)

	var start_label = Label.new()
	start_label.text = "起始小节:"
	start_label.custom_minimum_size.x = 80
	start_hbox.add_child(start_label)

	var start_spinbox = SpinBox.new()
	start_spinbox.min_value = 0
	start_spinbox.max_value = 999
	start_hbox.add_child(start_spinbox)

	# 结束小节
	var end_hbox = HBoxContainer.new()
	vbox.add_child(end_hbox)

	var end_label = Label.new()
	end_label.text = "结束小节:"
	end_label.custom_minimum_size.x = 80
	end_hbox.add_child(end_label)

	var end_spinbox = SpinBox.new()
	end_spinbox.min_value = 0
	end_spinbox.max_value = 999
	end_hbox.add_child(end_spinbox)

	# 启用/禁用
	var enable_check = CheckBox.new()
	enable_check.text = "启用Go-Go Time"
	enable_check.button_pressed = true
	vbox.add_child(enable_check)

	dialog.confirmed.connect(func():
		var start = int(start_spinbox.value)
		var end = int(end_spinbox.value)
		var enable = enable_check.button_pressed
		controller.batch_toggle_gogo(start, end, enable)
		dialog.queue_free()
	)

	dialog.canceled.connect(func(): dialog.queue_free())

	add_child(dialog)
	dialog.popup_centered()


## 显示批量BPM对话框
func _show_batch_bpm_dialog() -> void:
	if controller == null:
		return

	var dialog = ConfirmationDialog.new()
	dialog.title = "批量设置BPM"
	dialog.min_size = Vector2(300, 200)

	var vbox = VBoxContainer.new()
	dialog.add_child(vbox)

	# 起始小节
	var start_hbox = HBoxContainer.new()
	vbox.add_child(start_hbox)

	var start_label = Label.new()
	start_label.text = "起始小节:"
	start_label.custom_minimum_size.x = 80
	start_hbox.add_child(start_label)

	var start_spinbox = SpinBox.new()
	start_spinbox.min_value = 0
	start_spinbox.max_value = 999
	start_hbox.add_child(start_spinbox)

	# 结束小节
	var end_hbox = HBoxContainer.new()
	vbox.add_child(end_hbox)

	var end_label = Label.new()
	end_label.text = "结束小节:"
	end_label.custom_minimum_size.x = 80
	end_hbox.add_child(end_label)

	var end_spinbox = SpinBox.new()
	end_spinbox.min_value = 0
	end_spinbox.max_value = 999
	end_hbox.add_child(end_spinbox)

	# BPM值
	var bpm_hbox = HBoxContainer.new()
	vbox.add_child(bpm_hbox)

	var bpm_label = Label.new()
	bpm_label.text = "BPM:"
	bpm_label.custom_minimum_size.x = 80
	bpm_hbox.add_child(bpm_label)

	var bpm_spinbox = SpinBox.new()
	bpm_spinbox.min_value = 1.0
	bpm_spinbox.max_value = 999.0
	bpm_spinbox.value = 120.0
	bpm_hbox.add_child(bpm_spinbox)

	dialog.confirmed.connect(func():
		var start = int(start_spinbox.value)
		var end = int(end_spinbox.value)
		var bpm = bpm_spinbox.value
		controller.batch_set_bpm(start, end, bpm)
		dialog.queue_free()
	)

	dialog.canceled.connect(func(): dialog.queue_free())

	add_child(dialog)
	dialog.popup_centered()


## ========== 统计信息显示 ==========

## 显示谱面统计信息
func _show_chart_statistics() -> void:
	if controller == null:
		return

	var stats = controller.get_chart_statistics()

	var dialog = AcceptDialog.new()
	dialog.title = "谱面统计"
	dialog.min_size = Vector2(350, 300)

	var vbox = VBoxContainer.new()
	dialog.add_child(vbox)

	# 基本信息
	_add_stat_item(vbox, "总小节数", str(stats.get("total_measures", 0)))
	_add_stat_item(vbox, "总音符数", str(stats.get("total_notes", 0)))
	_add_stat_item(vbox, "Go-Go Time小节数", str(stats.get("gogo_measures", 0)))
	_add_stat_item(vbox, "总时长", "%.2f 秒" % stats.get("duration", 0.0))

	# 分隔线
	vbox.add_child(HSeparator.new())

	# 音符类型统计
	var type_label = Label.new()
	type_label.text = "音符类型分布:"
	vbox.add_child(type_label)

	var by_type = stats.get("by_type", {})
	for type_name in by_type.keys():
		_add_stat_item(vbox, "  " + type_name, str(by_type[type_name]))

	add_child(dialog)
	dialog.popup_centered()


## 添加统计项
func _add_stat_item(parent: Container, name: String, value: String) -> void:
	var hbox = HBoxContainer.new()
	parent.add_child(hbox)

	var name_label = Label.new()
	name_label.text = name + ":"
	name_label.custom_minimum_size.x = 120
	hbox.add_child(name_label)

	var value_label = Label.new()
	value_label.text = value
	hbox.add_child(value_label)