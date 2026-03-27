class_name BatchOperations
extends RefCounted
## 批量操作管理器
## 提供批量选择、批量修改、批量移动等功能

const EditorData = preload("res://src/editor/editor_data.gd")

## 信号
signal batch_operation_started(description: String)
signal batch_operation_completed(description: String)
signal batch_operation_failed(description: String, error: String)

## 编辑器控制器引用
var controller: EditorController = null

## 批量操作历史（用于撤销）
var _batch_history: Array = []

## 是否正在执行批量操作
var is_batching: bool = false

## 当前批量操作描述
var _current_batch_description: String = ""

## 批量操作命令列表
var _batch_commands: Array[EditorData.EditorCommand] = []


## 初始化
func _init(p_controller: EditorController = null) -> void:
	controller = p_controller


## 设置控制器
func set_controller(p_controller: EditorController) -> void:
	controller = p_controller


## ========== 批量选择功能 ==========

## 选择小节范围内的所有音符
func select_notes_in_measure_range(start_measure: int, end_measure: int) -> void:
	if controller == null:
		return

	controller.deselect_all()

	var course = controller.get_current_course()
	if course == null:
		return

	start_measure = max(0, start_measure)
	end_measure = min(course.measures.size() - 1, end_measure)

	for i in range(start_measure, end_measure + 1):
		var measure = course.measures[i]
		for note in measure.notes:
			controller.select_note(note, true)


## 选择指定类型的所有音符
func select_notes_by_type(note_type: EditorData.NoteType) -> void:
	if controller == null:
		return

	controller.deselect_all()

	var course = controller.get_current_course()
	if course == null:
		return

	for measure in course.measures:
		for note in measure.notes:
			if note.note_type == note_type:
				controller.select_note(note, true)


## 选择小节内的所有音符
func select_notes_in_measure(measure_index: int) -> void:
	if controller == null:
		return

	controller.deselect_all()

	var course = controller.get_current_course()
	if course == null:
		return

	if measure_index < 0 or measure_index >= course.measures.size():
		return

	var measure = course.measures[measure_index]
	for note in measure.notes:
		controller.select_note(note, true)


## 反选
func invert_selection() -> void:
	if controller == null:
		return

	var course = controller.get_current_course()
	if course == null:
		return

	# 获取当前选中的音符
	var currently_selected = controller.selected_notes.duplicate()

	# 全选
	controller.select_all()

	# 取消之前选中的音符
	for note in currently_selected:
		note.selected = false
		var idx = controller.selected_notes.find(note)
		if idx >= 0:
			controller.selected_notes.remove_at(idx)

	controller.selection_changed.emit(controller.selected_notes)


## ========== 批量修改功能 ==========

## 开始批量操作
func begin_batch(description: String = "") -> void:
	is_batching = true
	_current_batch_description = description
	_batch_commands.clear()
	batch_operation_started.emit(description)


## 结束批量操作
func end_batch() -> void:
	if not is_batching:
		return

	is_batching = false

	# 将批量命令添加到撤销栈
	if not _batch_commands.is_empty():
		_add_batch_to_undo_stack()

	batch_operation_completed.emit(_current_batch_description)
	_batch_commands.clear()
	_current_batch_description = ""


## 添加命令到批量操作
func add_batch_command(cmd: EditorData.EditorCommand) -> void:
	if is_batching:
		_batch_commands.append(cmd)


## 将批量命令添加到撤销栈
func _add_batch_to_undo_stack() -> void:
	if controller == null:
		return

	# 创建批量命令
	var batch_cmd = EditorData.EditorCommand.new(
		EditorData.EditorCommand.CommandType.ADD_NOTE,  # 使用任意类型
		null,
		_batch_commands.duplicate(),
		null
	)
	batch_cmd.description = _current_batch_description

	# 添加到撤销栈
	controller._undo_stack.append(batch_cmd)
	controller._redo_stack.clear()

	# 限制撤销栈大小
	if controller._undo_stack.size() > EditorController.MAX_UNDO_STEPS:
		controller._undo_stack.remove_at(0)


## 批量修改选中音符的类型
func batch_change_note_type(new_type: EditorData.NoteType) -> bool:
	if controller == null:
		return false

	var selected = controller.selected_notes
	if selected.is_empty():
		return false

	begin_batch("批量修改音符类型")

	for note in selected:
		var old_type = note.note_type
		note.note_type = new_type

		# 创建命令
		var cmd = EditorData.EditorCommand.new(
			EditorData.EditorCommand.CommandType.CHANGE_NOTE_TYPE,
			note,
			old_type,
			new_type
		)
		cmd.description = "修改音符类型"
		add_batch_command(cmd)

	end_batch()

	controller.project.mark_modified()
	controller.note_type_changed.emit(selected[0], selected[0].note_type)
	controller.data_changed.emit()

	return true


## 批量移动选中音符（相对偏移）
func batch_move_notes(measure_offset: int, position_offset: float) -> bool:
	if controller == null:
		return false

	var selected = controller.selected_notes
	if selected.is_empty():
		return false

	begin_batch("批量移动音符")

	var notes_to_move = selected.duplicate()
	var success = true

	for note in notes_to_move:
		var new_measure = note.measure_index + measure_offset
		var new_position = note.position + position_offset

		# 处理位置溢出
		while new_position >= 1.0:
			new_measure += 1
			new_position -= 1.0
		while new_position < 0.0:
			new_measure -= 1
			new_position += 1.0

		# 检查目标小节是否存在
		var course = controller.get_current_course()
		if course == null or new_measure < 0 or new_measure >= course.measures.size():
			success = false
			continue

		# 执行移动
		var old_measure = note.measure_index
		var old_position = note.position

		# 从原小节移除
		course.measures[old_measure].remove_note(note)

		# 更新音符位置
		note.measure_index = new_measure
		note.position = new_position

		# 添加到新小节
		course.measures[new_measure].add_note(note)

		# 创建命令
		var cmd = EditorData.EditorCommand.new(
			EditorData.EditorCommand.CommandType.MOVE_NOTE,
			note,
			{"measure": old_measure, "position": old_position},
			{"measure": new_measure, "position": new_position}
		)
		cmd.description = "移动音符"
		add_batch_command(cmd)

	end_batch()

	controller.project.mark_modified()
	controller.data_changed.emit()

	return success


## 批量删除选中音符
func batch_delete_notes() -> bool:
	if controller == null:
		return false

	var selected = controller.selected_notes
	if selected.is_empty():
		return false

	begin_batch("批量删除音符")

	var notes_to_delete = selected.duplicate()

	for note in notes_to_delete:
		var course = controller.get_current_course()
		if course == null:
			continue

		if note.measure_index < 0 or note.measure_index >= course.measures.size():
			continue

		var measure = course.measures[note.measure_index]

		# 创建命令
		var cmd = EditorData.EditorCommand.new(
			EditorData.EditorCommand.CommandType.REMOVE_NOTE,
			note,
			{"measure": note.measure_index, "position": note.position, "type": note.note_type},
			null
		)
		cmd.description = "删除音符"
		add_batch_command(cmd)

		# 移除音符
		measure.remove_note(note)

		# 从选中列表移除
		var idx = controller.selected_notes.find(note)
		if idx >= 0:
			controller.selected_notes.remove_at(idx)

	end_batch()

	controller.project.mark_modified()
	controller.selection_changed.emit(controller.selected_notes)
	controller.data_changed.emit()

	return true


## 批量复制选中音符到剪贴板
func batch_copy_to_clipboard() -> Array:
	if controller == null:
		return []

	var selected = controller.selected_notes
	if selected.is_empty():
		return []

	# 调用控制器的复制方法
	controller.copy_selected()

	return controller._clipboard.duplicate()


## 批量粘贴音符（带偏移）
func batch_paste_with_offset(target_measure: int, target_position: float, measure_offset: int = 0, position_offset: float = 0.0) -> bool:
	if controller == null:
		return false

	var clipboard = controller._clipboard
	if clipboard.is_empty():
		return false

	begin_batch("批量粘贴音符")

	controller.deselect_all()

	# 计算偏移
	var min_measure = clipboard[0].measure_index
	var min_position = clipboard[0].position
	for note in clipboard:
		if note.measure_index < min_measure or \
		   (note.measure_index == min_measure and note.position < min_position):
			min_measure = note.measure_index
			min_position = note.position

	# 粘贴音符
	for note in clipboard:
		var new_measure = target_measure + (note.measure_index - min_measure) + measure_offset
		var new_position = target_position + (note.position - min_position) + position_offset

		# 限制位置范围
		while new_position >= 1.0:
			new_measure += 1
			new_position -= 1.0
		while new_position < 0.0:
			new_measure -= 1
			new_position += 1.0

		if new_measure >= 0:
			var new_note = controller.add_note(new_measure, new_position, note.note_type)
			if new_note != null:
				new_note.balloon_hits = note.balloon_hits
				controller.select_note(new_note, true)

	end_batch()

	return true


## ========== 批量小节操作 ==========

## 批量设置小节BPM
func batch_set_measure_bpm(start_measure: int, end_measure: int, bpm: float) -> bool:
	if controller == null:
		return false

	var course = controller.get_current_course()
	if course == null:
		return false

	start_measure = max(0, start_measure)
	end_measure = min(course.measures.size() - 1, end_measure)

	begin_batch("批量设置BPM")

	for i in range(start_measure, end_measure + 1):
		var measure = course.measures[i]
		var old_bpm = measure.bpm
		measure.bpm = bpm

		# 创建命令
		var cmd = EditorData.EditorCommand.new(
			EditorData.EditorCommand.CommandType.CHANGE_BPM,
			measure,
			old_bpm,
			bpm
		)
		cmd.description = "设置BPM"
		add_batch_command(cmd)

	end_batch()

	controller.project.mark_modified()
	controller.data_changed.emit()

	return true


## 批量设置小节滚动速度
func batch_set_measure_scroll(start_measure: int, end_measure: int, scroll: float) -> bool:
	if controller == null:
		return false

	var course = controller.get_current_course()
	if course == null:
		return false

	start_measure = max(0, start_measure)
	end_measure = min(course.measures.size() - 1, end_measure)

	begin_batch("批量设置滚动速度")

	for i in range(start_measure, end_measure + 1):
		var measure = course.measures[i]
		var old_scroll = measure.scroll
		measure.scroll = scroll

		# 创建命令
		var cmd = EditorData.EditorCommand.new(
			EditorData.EditorCommand.CommandType.CHANGE_SCROLL,
			measure,
			old_scroll,
			scroll
		)
		cmd.description = "设置滚动速度"
		add_batch_command(cmd)

	end_batch()

	controller.project.mark_modified()
	controller.data_changed.emit()

	return true


## 批量切换Go-Go Time
func batch_toggle_gogo(start_measure: int, end_measure: int, enable: bool) -> bool:
	if controller == null:
		return false

	var course = controller.get_current_course()
	if course == null:
		return false

	start_measure = max(0, start_measure)
	end_measure = min(course.measures.size() - 1, end_measure)

	begin_batch("批量切换Go-Go Time")

	for i in range(start_measure, end_measure + 1):
		var measure = course.measures[i]
		var old_gogo = measure.is_gogo
		measure.is_gogo = enable

		# 创建命令
		var cmd = EditorData.EditorCommand.new(
			EditorData.EditorCommand.CommandType.TOGGLE_GOGO,
			measure,
			old_gogo,
			enable
		)
		cmd.description = "切换Go-Go Time"
		add_batch_command(cmd)

	end_batch()

	controller.project.mark_modified()
	controller.data_changed.emit()

	return true


## 批量插入小节
func batch_insert_measures(at_index: int, count: int) -> bool:
	if controller == null or count <= 0:
		return false

	begin_batch("批量插入小节")

	for i in range(count):
		controller.add_measure(at_index + i)

	end_batch()

	return true


## 批量删除小节
func batch_delete_measures(start_index: int, count: int) -> bool:
	if controller == null or count <= 0:
		return false

	var course = controller.get_current_course()
	if course == null:
		return false

	if start_index < 0 or start_index + count > course.measures.size():
		return false

	if course.measures.size() - count < 1:
		return false  # 至少保留一个小节

	begin_batch("批量删除小节")

	# 从后向前删除，避免索引问题
	for i in range(count - 1, -1, -1):
		controller.remove_measure(start_index + i)

	end_batch()

	return true


## ========== 高级选择功能 ==========

## 选择Go-Go Time区域内的所有音符
func select_notes_in_gogo_region() -> void:
	if controller == null:
		return

	controller.deselect_all()

	var course = controller.get_current_course()
	if course == null:
		return

	for measure in course.measures:
		if measure.is_gogo:
			for note in measure.notes:
				controller.select_note(note, true)


## 选择指定BPM范围内的所有音符
func select_notes_in_bpm_range(min_bpm: float, max_bpm: float) -> void:
	if controller == null:
		return

	controller.deselect_all()

	var course = controller.get_current_course()
	if course == null:
		return

	for measure in course.measures:
		if measure.bpm >= min_bpm and measure.bpm <= max_bpm:
			for note in measure.notes:
				controller.select_note(note, true)


## 选择连打音符
func select_renda_notes() -> void:
	if controller == null:
		return

	controller.deselect_all()

	var course = controller.get_current_course()
	if course == null:
		return

	for measure in course.measures:
		for note in measure.notes:
			if note.is_renda():
				controller.select_note(note, true)


## 选择大音符
func select_big_notes() -> void:
	if controller == null:
		return

	controller.deselect_all()

	var course = controller.get_current_course()
	if course == null:
		return

	for measure in course.measures:
		for note in measure.notes:
			if note.is_big():
				controller.select_note(note, true)


## ========== 统计功能 ==========

## 获取选中音符统计
func get_selection_statistics() -> Dictionary:
	if controller == null:
		return {}

	var selected = controller.selected_notes
	if selected.is_empty():
		return {}

	var stats = {
		"total": selected.size(),
		"by_type": {},
		"measure_range": Vector2i(999999, -1),
		"big_notes": 0,
		"renda_notes": 0
	}

	for note in selected:
		# 按类型统计
		var type_name = EditorData.get_note_type_name(note.note_type)
		if not stats.by_type.has(type_name):
			stats.by_type[type_name] = 0
		stats.by_type[type_name] += 1

		# 小节范围
		stats.measure_range.x = min(stats.measure_range.x, note.measure_index)
		stats.measure_range.y = max(stats.measure_range.y, note.measure_index)

		# 大音符统计
		if note.is_big():
			stats.big_notes += 1

		# 连打统计
		if note.is_renda():
			stats.renda_notes += 1

	return stats


## 获取谱面统计
func get_chart_statistics() -> Dictionary:
	if controller == null:
		return {}

	var course = controller.get_current_course()
	if course == null:
		return {}

	var stats = {
		"total_measures": course.measures.size(),
		"total_notes": 0,
		"by_type": {},
		"gogo_measures": 0,
		"bpm_changes": [],
		"scroll_changes": [],
		"duration": 0.0
	}

	var last_bpm = -1.0
	var last_scroll = -1.0

	for measure in course.measures:
		# 音符统计
		for note in measure.notes:
			if note.is_hittable():
				stats.total_notes += 1

			var type_name = EditorData.get_note_type_name(note.note_type)
			if not stats.by_type.has(type_name):
				stats.by_type[type_name] = 0
			stats.by_type[type_name] += 1

		# Go-Go Time统计
		if measure.is_gogo:
			stats.gogo_measures += 1

		# BPM变化
		if measure.bpm != last_bpm:
			stats.bpm_changes.append({
				"measure": measure.index,
				"bpm": measure.bpm
			})
			last_bpm = measure.bpm

		# 滚动速度变化
		if measure.scroll != last_scroll:
			stats.scroll_changes.append({
				"measure": measure.index,
				"scroll": measure.scroll
			})
			last_scroll = measure.scroll

		# 时长
		stats.duration += measure.get_duration()

	return stats