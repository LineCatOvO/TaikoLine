class_name BPMEditor
extends Control
## BPM变更编辑器组件
## 提供BPM变化的可视化编辑和管理功能

const EditorData = preload("res://src/editor/editor_data.gd")

## 信号
signal bpm_changed(measure_index: int, new_bpm: float)
signal bpm_range_set(start_measure: int, end_measure: int, bpm: float)

## 编辑器控制器引用
var controller: EditorController = null

## 批量操作管理器引用
var batch_operations: BatchOperations = null

## UI组件
var bpm_list: ItemList = null
var add_bpm_button: Button = null
var remove_bpm_button: Button = null

var bpm_spinbox: SpinBox = null
var measure_spinbox: SpinBox = null
var apply_button: Button = null
var apply_range_button: Button = null

var start_measure_spinbox: SpinBox = null
var end_measure_spinbox: SpinBox = null
var range_bpm_spinbox: SpinBox = null

## BPM变化列表
var bpm_changes: Array = []

## 颜色定义
const BPM_LOW_COLOR: Color = Color(0.3, 0.7, 1.0)     # 低BPM - 蓝色
const BPM_NORMAL_COLOR: Color = Color(0.3, 1.0, 0.3)  # 正常BPM - 绿色
const BPM_HIGH_COLOR: Color = Color(1.0, 0.5, 0.3)    # 高BPM - 橙色
const BPM_VERY_HIGH_COLOR: Color = Color(1.0, 0.3, 0.3) # 极高BPM - 红色


func _ready() -> void:
	_setup_ui()


## 设置UI
func _setup_ui() -> void:
	# 创建主容器
	var main_vbox = VBoxContainer.new()
	main_vbox.name = "MainVBox"
	add_child(main_vbox)

	# 标题
	var title_label = Label.new()
	title_label.text = "BPM 变更编辑"
	title_label.add_theme_font_size_override("font_size", 14)
	main_vbox.add_child(title_label)

	# BPM变化列表
	bpm_list = ItemList.new()
	bpm_list.custom_minimum_size.y = 120
	bpm_list.item_selected.connect(_on_bpm_item_selected)
	main_vbox.add_child(bpm_list)

	# 按钮行
	var button_hbox = HBoxContainer.new()
	main_vbox.add_child(button_hbox)

	add_bpm_button = Button.new()
	add_bpm_button.text = "添加"
	add_bpm_button.tooltip_text = "添加新的BPM变化点"
	add_bpm_button.pressed.connect(_on_add_bpm_pressed)
	button_hbox.add_child(add_bpm_button)

	remove_bpm_button = Button.new()
	remove_bpm_button.text = "删除"
	remove_bpm_button.tooltip_text = "删除选中的BPM变化点"
	remove_bpm_button.pressed.connect(_on_remove_bpm_pressed)
	button_hbox.add_child(remove_bpm_button)

	# 分隔线
	var separator1 = HSeparator.new()
	main_vbox.add_child(separator1)

	# 单个小节BPM编辑
	var single_label = Label.new()
	single_label.text = "单小节BPM"
	single_label.add_theme_font_size_override("font_size", 12)
	main_vbox.add_child(single_label)

	# 小节选择
	var measure_hbox = HBoxContainer.new()
	main_vbox.add_child(measure_hbox)

	var measure_label = Label.new()
	measure_label.text = "小节:"
	measure_label.custom_minimum_size.x = 50
	measure_hbox.add_child(measure_label)

	measure_spinbox = SpinBox.new()
	measure_spinbox.min_value = 0
	measure_spinbox.max_value = 999
	measure_spinbox.step = 1
	measure_spinbox.tooltip_text = "选择要编辑的小节"
	measure_hbox.add_child(measure_spinbox)

	# BPM值
	var bpm_hbox = HBoxContainer.new()
	main_vbox.add_child(bpm_hbox)

	var bpm_label = Label.new()
	bpm_label.text = "BPM:"
	bpm_label.custom_minimum_size.x = 50
	bpm_hbox.add_child(bpm_label)

	bpm_spinbox = SpinBox.new()
	bpm_spinbox.min_value = 1.0
	bpm_spinbox.max_value = 999.0
	bpm_spinbox.step = 1.0
	bpm_spinbox.value = 120.0
	bpm_spinbox.tooltip_text = "设置BPM值"
	bpm_hbox.add_child(bpm_spinbox)

	# 应用按钮
	apply_button = Button.new()
	apply_button.text = "应用"
	apply_button.tooltip_text = "应用BPM变更"
	apply_button.pressed.connect(_on_apply_bpm_pressed)
	main_vbox.add_child(apply_button)

	# 分隔线
	var separator2 = HSeparator.new()
	main_vbox.add_child(separator2)

	# 批量BPM编辑
	var range_label = Label.new()
	range_label.text = "批量设置BPM"
	range_label.add_theme_font_size_override("font_size", 12)
	main_vbox.add_child(range_label)

	# 起始小节
	var start_hbox = HBoxContainer.new()
	main_vbox.add_child(start_hbox)

	var start_label = Label.new()
	start_label.text = "起始:"
	start_label.custom_minimum_size.x = 50
	start_hbox.add_child(start_label)

	start_measure_spinbox = SpinBox.new()
	start_measure_spinbox.min_value = 0
	start_measure_spinbox.max_value = 999
	start_measure_spinbox.step = 1
	start_hbox.add_child(start_measure_spinbox)

	# 结束小节
	var end_hbox = HBoxContainer.new()
	main_vbox.add_child(end_hbox)

	var end_label = Label.new()
	end_label.text = "结束:"
	end_label.custom_minimum_size.x = 50
	end_hbox.add_child(end_label)

	end_measure_spinbox = SpinBox.new()
	end_measure_spinbox.min_value = 0
	end_measure_spinbox.max_value = 999
	end_measure_spinbox.step = 1
	end_hbox.add_child(end_measure_spinbox)

	# BPM值
	var range_bpm_hbox = HBoxContainer.new()
	main_vbox.add_child(range_bpm_hbox)

	var range_bpm_label = Label.new()
	range_bpm_label.text = "BPM:"
	range_bpm_label.custom_minimum_size.x = 50
	range_bpm_hbox.add_child(range_bpm_label)

	range_bpm_spinbox = SpinBox.new()
	range_bpm_spinbox.min_value = 1.0
	range_bpm_spinbox.max_value = 999.0
	range_bpm_spinbox.step = 1.0
	range_bpm_spinbox.value = 120.0
	range_bpm_hbox.add_child(range_bpm_spinbox)

	# 批量应用按钮
	apply_range_button = Button.new()
	apply_range_button.text = "批量应用"
	apply_range_button.tooltip_text = "批量设置指定范围内的BPM"
	apply_range_button.pressed.connect(_on_apply_range_pressed)
	main_vbox.add_child(apply_range_button)


func _draw() -> void:
	# 绘制背景
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.15, 0.15, 0.18))


## 设置控制器
func set_controller(p_controller: EditorController) -> void:
	controller = p_controller
	if controller:
		controller.data_changed.connect(_on_data_changed)
		_update_bpm_list()


## 设置批量操作管理器
func set_batch_operations(p_batch: BatchOperations) -> void:
	batch_operations = p_batch


## 更新BPM变化列表
func _update_bpm_list() -> void:
	if controller == null:
		return

	bpm_list.clear()
	bpm_changes.clear()

	var course = controller.get_current_course()
	if course == null:
		return

	var last_bpm = -1.0

	for measure in course.measures:
		if measure.bpm != last_bpm:
			bpm_changes.append({
				"measure": measure.index,
				"bpm": measure.bpm
			})

			# 添加到列表
			var text = "小节 %d: %.1f BPM" % [measure.index + 1, measure.bpm]
			bpm_list.add_item(text)

			# 设置颜色
			var color = _get_bpm_color(measure.bpm)
			bpm_list.set_item_custom_fg_color(bpm_list.item_count - 1, color)

			last_bpm = measure.bpm


## 获取BPM对应的颜色
func _get_bpm_color(bpm: float) -> Color:
	if bpm < 100:
		return BPM_LOW_COLOR
	elif bpm < 150:
		return BPM_NORMAL_COLOR
	elif bpm < 200:
		return BPM_HIGH_COLOR
	else:
		return BPM_VERY_HIGH_COLOR


## BPM列表项选中回调
func _on_bpm_item_selected(index: int) -> void:
	if index < 0 or index >= bpm_changes.size():
		return

	var change = bpm_changes[index]
	measure_spinbox.value = change.measure
	bpm_spinbox.value = change.bpm


## 添加BPM变化按钮回调
func _on_add_bpm_pressed() -> void:
	# 在当前选中的小节添加BPM变化
	if controller == null:
		return

	var measure_index = int(measure_spinbox.value)
	var new_bpm = bpm_spinbox.value

	controller.set_measure_bpm(measure_index, new_bpm)
	bpm_changed.emit(measure_index, new_bpm)


## 删除BPM变化按钮回调
func _on_remove_bpm_pressed() -> void:
	# 将选中小节的BPM恢复为前一个小节的BPM
	if controller == null:
		return

	var selected = bpm_list.get_selected_items()
	if selected.is_empty():
		return

	var index = selected[0]
	if index <= 0 or index >= bpm_changes.size():
		return  # 不能删除第一个BPM变化

	var prev_bpm = bpm_changes[index - 1].bpm
	var measure_index = bpm_changes[index].measure

	controller.set_measure_bpm(measure_index, prev_bpm)


## 应用BPM按钮回调
func _on_apply_bpm_pressed() -> void:
	if controller == null:
		return

	var measure_index = int(measure_spinbox.value)
	var new_bpm = bpm_spinbox.value

	controller.set_measure_bpm(measure_index, new_bpm)
	bpm_changed.emit(measure_index, new_bpm)


## 批量应用BPM按钮回调
func _on_apply_range_pressed() -> void:
	if controller == null:
		return

	var start = int(start_measure_spinbox.value)
	var end = int(end_measure_spinbox.value)
	var bpm = range_bpm_spinbox.value

	# 确保起始不大于结束
	if start > end:
		var temp = start
		start = end
		end = temp

	if batch_operations != null:
		batch_operations.batch_set_measure_bpm(start, end, bpm)
	else:
		# 直接设置
		var course = controller.get_current_course()
		if course != null:
			for i in range(start, min(end + 1, course.measures.size())):
				controller.set_measure_bpm(i, bpm)

	bpm_range_set.emit(start, end, bpm)


## 数据变化回调
func _on_data_changed() -> void:
	_update_bpm_list()


## 获取BPM变化列表
func get_bpm_changes() -> Array:
	return bpm_changes.duplicate()


## 跳转到指定BPM变化点
func jump_to_bpm_change(index: int) -> void:
	if index < 0 or index >= bpm_changes.size():
		return

	var change = bpm_changes[index]
	measure_spinbox.value = change.measure
	bpm_spinbox.value = change.bpm

	# 发送信号让时间线滚动到该小节
	if controller and controller.has_signal("measure_selected"):
		# 如果控制器有相关信号，发送它
		pass


## 获取BPM统计信息
func get_bpm_statistics() -> Dictionary:
	if bpm_changes.is_empty():
		return {}

	var stats = {
		"min_bpm": 999999.0,
		"max_bpm": 0.0,
		"avg_bpm": 0.0,
		"change_count": bpm_changes.size()
	}

	var total = 0.0
	for change in bpm_changes:
		var bpm = change.bpm
		stats.min_bpm = min(stats.min_bpm, bpm)
		stats.max_bpm = max(stats.max_bpm, bpm)
		total += bpm

	if bpm_changes.size() > 0:
		stats.avg_bpm = total / bpm_changes.size()

	return stats