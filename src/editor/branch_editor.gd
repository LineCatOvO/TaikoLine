class_name BranchEditor
extends Control
## 分支编辑器组件
## 提供分支切换、条件编辑等功能

const EditorData = preload("res://src/editor/editor_data.gd")

## 信号
signal branch_selected(branch_type: int)
signal condition_added(condition: EditorData.EditorBranchCondition)
signal condition_removed(index: int)

## 当前选中的分支
var current_branch: int = EditorData.BranchType.NORMAL

## 分支条件列表
var branch_conditions: Array = []

## UI组件
var branch_button_group: ButtonGroup
var normal_button: Button
var expert_button: Button
var master_button: Button

var condition_list: ItemList
var add_condition_button: Button
var remove_condition_button: Button

var condition_type_option: OptionButton
var measure_spinbox: SpinBox
var normal_threshold_spinbox: SpinBox
var expert_threshold_spinbox: SpinBox

## 分支颜色
const BRANCH_COLORS: Dictionary = {
	EditorData.BranchType.NORMAL: Color(0.4, 0.4, 0.5),
	EditorData.BranchType.EXPERT: Color(0.3, 0.5, 0.7),
	EditorData.BranchType.MASTER: Color(0.6, 0.3, 0.6)
}


func _ready() -> void:
	_setup_ui()


## 设置UI
func _setup_ui() -> void:
	# 创建主容器
	var main_vbox = VBoxContainer.new()
	main_vbox.name = "MainVBox"
	add_child(main_vbox)

	# 创建分支选择区域
	_setup_branch_selector(main_vbox)

	# 添加分隔线
	var separator1 = HSeparator.new()
	main_vbox.add_child(separator1)

	# 创建条件编辑区域
	_setup_condition_editor(main_vbox)


## 设置分支选择器
func _setup_branch_selector(parent: Control) -> void:
	# 标题
	var title_label = Label.new()
	title_label.text = "分支选择"
	title_label.add_theme_font_size_override("font_size", 14)
	parent.add_child(title_label)

	# 按钮组
	branch_button_group = ButtonGroup.new()

	# 按钮容器
	var button_hbox = HBoxContainer.new()
	parent.add_child(button_hbox)

	# Normal按钮
	normal_button = Button.new()
	normal_button.text = "#N"
	normal_button.tooltip_text = "普通分支 (Normal)"
	normal_button.toggle_mode = true
	normal_button.button_group = branch_button_group
	normal_button.button_pressed = true
	normal_button.pressed.connect(_on_branch_button_pressed.bind(EditorData.BranchType.NORMAL))
	button_hbox.add_child(normal_button)

	# Expert按钮
	expert_button = Button.new()
	expert_button.text = "#E"
	expert_button.tooltip_text = "高级分支 (Expert)"
	expert_button.toggle_mode = true
	expert_button.button_group = branch_button_group
	expert_button.pressed.connect(_on_branch_button_pressed.bind(EditorData.BranchType.EXPERT))
	button_hbox.add_child(expert_button)

	# Master按钮
	master_button = Button.new()
	master_button.text = "#M"
	master_button.tooltip_text = "大师分支 (Master)"
	master_button.toggle_mode = true
	master_button.button_group = branch_button_group
	master_button.pressed.connect(_on_branch_button_pressed.bind(EditorData.BranchType.MASTER))
	button_hbox.add_child(master_button)

	# 更新按钮颜色
	_update_button_colors()


## 设置条件编辑器
func _setup_condition_editor(parent: Control) -> void:
	# 标题
	var title_label = Label.new()
	title_label.text = "分支条件"
	title_label.add_theme_font_size_override("font_size", 14)
	parent.add_child(title_label)

	# 条件列表
	condition_list = ItemList.new()
	condition_list.custom_minimum_size.y = 100
	condition_list.item_selected.connect(_on_condition_selected)
	parent.add_child(condition_list)

	# 条件编辑区域
	var edit_vbox = VBoxContainer.new()
	parent.add_child(edit_vbox)

	# 条件类型选择
	var type_hbox = HBoxContainer.new()
	edit_vbox.add_child(type_hbox)

	var type_label = Label.new()
	type_label.text = "类型:"
	type_label.custom_minimum_size.x = 60
	type_hbox.add_child(type_label)

	condition_type_option = OptionButton.new()
	condition_type_option.add_item("精度 (p)")
	condition_type_option.add_item("连打 (r)")
	condition_type_option.add_item("分数 (s)")
	condition_type_option.tooltip_text = "选择分支条件类型"
	type_hbox.add_child(condition_type_option)

	# 小节索引
	var measure_hbox = HBoxContainer.new()
	edit_vbox.add_child(measure_hbox)

	var measure_label = Label.new()
	measure_label.text = "小节:"
	measure_label.custom_minimum_size.x = 60
	measure_hbox.add_child(measure_label)

	measure_spinbox = SpinBox.new()
	measure_spinbox.min_value = 0
	measure_spinbox.max_value = 999
	measure_spinbox.step = 1
	measure_spinbox.tooltip_text = "分支开始的小节索引"
	measure_hbox.add_child(measure_spinbox)

	# 普通阈值
	var normal_hbox = HBoxContainer.new()
	edit_vbox.add_child(normal_hbox)

	var normal_label = Label.new()
	normal_label.text = "普通阈值:"
	normal_label.custom_minimum_size.x = 60
	normal_hbox.add_child(normal_label)

	normal_threshold_spinbox = SpinBox.new()
	normal_threshold_spinbox.min_value = 0
	normal_threshold_spinbox.max_value = 100000
	normal_threshold_spinbox.step = 1
	normal_threshold_spinbox.tooltip_text = "进入普通分支的阈值"
	normal_hbox.add_child(normal_threshold_spinbox)

	# 高级阈值
	var expert_hbox = HBoxContainer.new()
	edit_vbox.add_child(expert_hbox)

	var expert_label = Label.new()
	expert_label.text = "高级阈值:"
	expert_label.custom_minimum_size.x = 60
	expert_hbox.add_child(expert_label)

	expert_threshold_spinbox = SpinBox.new()
	expert_threshold_spinbox.min_value = 0
	expert_threshold_spinbox.max_value = 100000
	expert_threshold_spinbox.step = 1
	expert_threshold_spinbox.tooltip_text = "进入高级分支的阈值"
	expert_hbox.add_child(expert_threshold_spinbox)

	# 按钮区域
	var button_hbox = HBoxContainer.new()
	parent.add_child(button_hbox)

	add_condition_button = Button.new()
	add_condition_button.text = "添加条件"
	add_condition_button.tooltip_text = "添加新的分支条件"
	add_condition_button.pressed.connect(_on_add_condition_pressed)
	button_hbox.add_child(add_condition_button)

	remove_condition_button = Button.new()
	remove_condition_button.text = "删除条件"
	remove_condition_button.tooltip_text = "删除选中的分支条件"
	remove_condition_button.pressed.connect(_on_remove_condition_pressed)
	button_hbox.add_child(remove_condition_button)


func _draw() -> void:
	# 绘制背景
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.15, 0.15, 0.18))


## 分支按钮按下回调
func _on_branch_button_pressed(branch_type: int) -> void:
	current_branch = branch_type
	_update_button_colors()
	branch_selected.emit(branch_type)


## 添加条件按钮按下回调
func _on_add_condition_pressed() -> void:
	var condition = EditorData.EditorBranchCondition.new(
		int(measure_spinbox.value),
		condition_type_option.selected,
		normal_threshold_spinbox.value,
		expert_threshold_spinbox.value
	)

	branch_conditions.append(condition)
	_update_condition_list()

	condition_added.emit(condition)


## 删除条件按钮按下回调
func _on_remove_condition_pressed() -> void:
	var selected = condition_list.get_selected_items()
	if selected.is_empty():
		return

	var index = selected[0]
	branch_conditions.remove_at(index)
	_update_condition_list()

	condition_removed.emit(index)


## 条件选中回调
func _on_condition_selected(index: int) -> void:
	if index < 0 or index >= branch_conditions.size():
		return

	var condition = branch_conditions[index]
	measure_spinbox.value = condition.measure_index
	condition_type_option.selected = condition.condition_type
	normal_threshold_spinbox.value = condition.normal_threshold
	expert_threshold_spinbox.value = condition.expert_threshold


## 更新按钮颜色
func _update_button_colors() -> void:
	if normal_button:
		normal_button.add_theme_color_override("font_color", BRANCH_COLORS[EditorData.BranchType.NORMAL])
	if expert_button:
		expert_button.add_theme_color_override("font_color", BRANCH_COLORS[EditorData.BranchType.EXPERT])
	if master_button:
		master_button.add_theme_color_override("font_color", BRANCH_COLORS[EditorData.BranchType.MASTER])


## 更新条件列表
func _update_condition_list() -> void:
	condition_list.clear()

	for i in range(branch_conditions.size()):
		var condition = branch_conditions[i]
		var text = "小节%d: %s (N:%.0f E:%.0f)" % [
			condition.measure_index + 1,
			condition.get_condition_type_name(),
			condition.normal_threshold,
			condition.expert_threshold
		]
		condition_list.add_item(text)


## 更新条件列表（外部调用）
func update_conditions(conditions: Array) -> void:
	branch_conditions = conditions.duplicate()
	_update_condition_list()


## 设置当前分支（外部调用）
func set_current_branch(branch_type: int) -> void:
	current_branch = branch_type

	# 更新按钮状态
	match branch_type:
		EditorData.BranchType.NORMAL:
			if normal_button:
				normal_button.button_pressed = true
		EditorData.BranchType.EXPERT:
			if expert_button:
				expert_button.button_pressed = true
		EditorData.BranchType.MASTER:
			if master_button:
				master_button.button_pressed = true

	_update_button_colors()


## 获取当前分支
func get_current_branch() -> int:
	return current_branch


## 获取分支条件列表
func get_branch_conditions() -> Array:
	return branch_conditions.duplicate()


## 清空条件列表
func clear_conditions() -> void:
	branch_conditions.clear()
	_update_condition_list()