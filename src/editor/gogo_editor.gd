class_name GogoEditor
extends Control
## Go-Go Time编辑器组件
## 提供Go-Go Time区域的可视化编辑和管理功能

const EditorData = preload("res://src/editor/editor_data.gd")

## 信号
signal gogo_toggled(measure_index: int, enabled: bool)
signal gogo_range_set(start_measure: int, end_measure: int, enabled: bool)

## 编辑器控制器引用
var controller: EditorController = null

## 批量操作管理器引用
var batch_operations: BatchOperations = null

## UI组件
var gogo_list: ItemList = null
var add_gogo_button: Button = null
var remove_gogo_button: Button = null

var measure_spinbox: SpinBox = null
var toggle_button: Button = null

var start_measure_spinbox: SpinBox = null
var end_measure_spinbox: SpinBox = null
var enable_range_button: Button = null
var disable_range_button: Button = null

## Go-Go Time区域列表
var gogo_regions: Array = []

## 颜色定义
const GOGO_ENABLED_COLOR: Color = Color(1.0, 0.8, 0.2)   # 启用 - 金色
const GOGO_DISABLED_COLOR: Color = Color(0.5, 0.5, 0.5)  # 禁用 - 灰色


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
	title_label.text = "Go-Go Time 编辑"
	title_label.add_theme_font_size_override("font_size", 14)
	main_vbox.add_child(title_label)

	# Go-Go Time区域列表
	gogo_list = ItemList.new()
	gogo_list.custom_minimum_size.y = 100
	gogo_list.item_selected.connect(_on_gogo_item_selected)
	main_vbox.add_child(gogo_list)

	# 按钮行
	var button_hbox = HBoxContainer.new()
	main_vbox.add_child(button_hbox)

	add_gogo_button = Button.new()
	add_gogo_button.text = "添加区域"
	add_gogo_button.tooltip_text = "添加新的Go-Go Time区域"
	add_gogo_button.pressed.connect(_on_add_gogo_pressed)
	button_hbox.add_child(add_gogo_button)

	remove_gogo_button = Button.new()
	remove_gogo_button.text = "删除区域"
	remove_gogo_button.tooltip_text = "删除选中的Go-Go Time区域"
	remove_gogo_button.pressed.connect(_on_remove_gogo_pressed)
	button_hbox.add_child(remove_gogo_button)

	# 分隔线
	var separator1 = HSeparator.new()
	main_vbox.add_child(separator1)

	# 单个小节Go-Go Time切换
	var single_label = Label.new()
	single_label.text = "单小节切换"
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
	measure_spinbox.tooltip_text = "选择要切换的小节"
	measure_hbox.add_child(measure_spinbox)

	# 切换按钮
	toggle_button = Button.new()
	toggle_button.text = "切换Go-Go"
	toggle_button.tooltip_text = "切换选中位置的Go-Go Time状态"
	toggle_button.pressed.connect(_on_toggle_gogo_pressed)
	main_vbox.add_child(toggle_button)

	# 分隔线
	var separator2 = HSeparator.new()
	main_vbox.add_child(separator2)

	# 批量Go-Go Time设置
	var range_label = Label.new()
	range_label.text = "批量设置"
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

	# 批量按钮
	var range_button_hbox = HBoxContainer.new()
	main_vbox.add_child(range_button_hbox)

	enable_range_button = Button.new()
	enable_range_button.text = "启用区域"
	enable_range_button.tooltip_text = "启用指定范围内的Go-Go Time"
	enable_range_button.pressed.connect(_on_enable_range_pressed)
	range_button_hbox.add_child(enable_range_button)

	disable_range_button = Button.new()
	disable_range_button.text = "禁用区域"
	disable_range_button.tooltip_text = "禁用指定范围内的Go-Go Time"
	disable_range_button.pressed.connect(_on_disable_range_pressed)
	range_button_hbox.add_child(disable_range_button)


func _draw() -> void:
	# 绘制背景
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.15, 0.15, 0.18))


## 设置控制器
func set_controller(p_controller: EditorController) -> void:
	controller = p_controller
	if controller:
		controller.data_changed.connect(_on_data_changed)
		_update_gogo_list()


## 设置批量操作管理器
func set_batch_operations(p_batch: BatchOperations) -> void:
	batch_operations = p_batch


## 更新Go-Go Time区域列表
func _update_gogo_list() -> void:
	if controller == null:
		return

	gogo_list.clear()
	gogo_regions.clear()

	var course = controller.get_current_course()
	if course == null:
		return

	# 扫描Go-Go Time区域
	var in_gogo = false
	var region_start = 0

	for measure in course.measures:
		if measure.is_gogo and not in_gogo:
			# 开始新的Go-Go Time区域
			in_gogo = true
			region_start = measure.index
		elif not measure.is_gogo and in_gogo:
			# 结束当前Go-Go Time区域
			in_gogo = false
			_add_gogo_region(region_start, measure.index - 1)

	# 如果最后还在Go-Go Time中
	if in_gogo:
		_add_gogo_region(region_start, course.measures.size() - 1)


## 添加Go-Go Time区域到列表
func _add_gogo_region(start: int, end: int) -> void:
	gogo_regions.append({
		"start": start,
		"end": end
	})

	var text = "小节 %d - %d" % [start + 1, end + 1]
	gogo_list.add_item(text)
	gogo_list.set_item_custom_fg_color(gogo_list.item_count - 1, GOGO_ENABLED_COLOR)


## Go-Go Time列表项选中回调
func _on_gogo_item_selected(index: int) -> void:
	if index < 0 or index >= gogo_regions.size():
		return

	var region = gogo_regions[index]
	start_measure_spinbox.value = region.start
	end_measure_spinbox.value = region.end


## 添加Go-Go Time区域按钮回调
func _on_add_gogo_pressed() -> void:
	# 在当前选中的范围添加Go-Go Time
	var start = int(start_measure_spinbox.value)
	var end = int(end_measure_spinbox.value)

	if start > end:
		var temp = start
		start = end
		end = temp

	if batch_operations != null:
		batch_operations.batch_toggle_gogo(start, end, true)
	elif controller != null:
		var course = controller.get_current_course()
		if course != null:
			for i in range(start, min(end + 1, course.measures.size())):
				var measure = course.measures[i]
				if not measure.is_gogo:
					controller.toggle_measure_gogo(i)

	gogo_range_set.emit(start, end, true)


## 删除Go-Go Time区域按钮回调
func _on_remove_gogo_pressed() -> void:
	var selected = gogo_list.get_selected_items()
	if selected.is_empty():
		return

	var index = selected[0]
	if index < 0 or index >= gogo_regions.size():
		return

	var region = gogo_regions[index]

	if batch_operations != null:
		batch_operations.batch_toggle_gogo(region.start, region.end, false)
	elif controller != null:
		var course = controller.get_current_course()
		if course != null:
			for i in range(region.start, min(region.end + 1, course.measures.size())):
				var measure = course.measures[i]
				if measure.is_gogo:
					controller.toggle_measure_gogo(i)


## 切换Go-Go Time按钮回调
func _on_toggle_gogo_pressed() -> void:
	if controller == null:
		return

	var measure_index = int(measure_spinbox.value)
	controller.toggle_measure_gogo(measure_index)

	var course = controller.get_current_course()
	if course != null and measure_index < course.measures.size():
		gogo_toggled.emit(measure_index, course.measures[measure_index].is_gogo)


## 启用区域按钮回调
func _on_enable_range_pressed() -> void:
	var start = int(start_measure_spinbox.value)
	var end = int(end_measure_spinbox.value)

	if start > end:
		var temp = start
		start = end
		end = temp

	if batch_operations != null:
		batch_operations.batch_toggle_gogo(start, end, true)
	elif controller != null:
		var course = controller.get_current_course()
		if course != null:
			for i in range(start, min(end + 1, course.measures.size())):
				var measure = course.measures[i]
				if not measure.is_gogo:
					controller.toggle_measure_gogo(i)

	gogo_range_set.emit(start, end, true)


## 禁用区域按钮回调
func _on_disable_range_pressed() -> void:
	var start = int(start_measure_spinbox.value)
	var end = int(end_measure_spinbox.value)

	if start > end:
		var temp = start
		start = end
		end = temp

	if batch_operations != null:
		batch_operations.batch_toggle_gogo(start, end, false)
	elif controller != null:
		var course = controller.get_current_course()
		if course != null:
			for i in range(start, min(end + 1, course.measures.size())):
				var measure = course.measures[i]
				if measure.is_gogo:
					controller.toggle_measure_gogo(i)

	gogo_range_set.emit(start, end, false)


## 数据变化回调
func _on_data_changed() -> void:
	_update_gogo_list()


## 获取Go-Go Time区域列表
func get_gogo_regions() -> Array:
	return gogo_regions.duplicate()


## 获取Go-Go Time统计信息
func get_gogo_statistics() -> Dictionary:
	if controller == null:
		return {}

	var course = controller.get_current_course()
	if course == null:
		return {}

	var stats = {
		"total_measures": course.measures.size(),
		"gogo_measures": 0,
		"region_count": gogo_regions.size(),
		"gogo_percentage": 0.0
	}

	for measure in course.measures:
		if measure.is_gogo:
			stats.gogo_measures += 1

	if stats.total_measures > 0:
		stats.gogo_percentage = (float(stats.gogo_measures) / float(stats.total_measures)) * 100.0

	return stats


## 跳转到指定Go-Go Time区域
func jump_to_gogo_region(index: int) -> void:
	if index < 0 or index >= gogo_regions.size():
		return

	var region = gogo_regions[index]
	start_measure_spinbox.value = region.start
	end_measure_spinbox.value = region.end
	measure_spinbox.value = region.start


## 检查小节是否在Go-Go Time区域内
func is_measure_in_gogo(measure_index: int) -> bool:
	for region in gogo_regions:
		if measure_index >= region.start and measure_index <= region.end:
			return true
	return false


## 获取小节所在的Go-Go Time区域
func get_gogo_region_for_measure(measure_index: int) -> Dictionary:
	for region in gogo_regions:
		if measure_index >= region.start and measure_index <= region.end:
			return region
	return {}


## 快速设置Go-Go Time区域（用于快捷键）
func quick_set_gogo_region(start: int, end: int, enabled: bool) -> void:
	if batch_operations != null:
		batch_operations.batch_toggle_gogo(start, end, enabled)
	elif controller != null:
		var course = controller.get_current_course()
		if course != null:
			for i in range(start, min(end + 1, course.measures.size())):
				var measure = course.measures[i]
				if measure.is_gogo != enabled:
					controller.toggle_measure_gogo(i)

	gogo_range_set.emit(start, end, enabled)