class_name UndoRedoManager
extends RefCounted
## 撤销/重做管理器
## 提供增强的撤销/重做功能，支持批量命令、命令合并、命令组

const EditorData = preload("res://src/editor/editor_data.gd")

## 信号
signal undo_stack_changed(size: int)
signal redo_stack_changed(size: int)
signal can_undo_changed(can_undo: bool)
signal can_redo_changed(can_redo: bool)

## 编辑器控制器引用
var controller: EditorController = null

## 撤销栈
var _undo_stack: Array = []

## 重做栈
var _redo_stack: Array = []

## 最大撤销步数
var max_undo_steps: int = 100

## 是否正在执行撤销/重做
var is_performing: bool = false

## 当前命令组
var _current_group: Array = []

## 是否在命令组中
var is_in_group: bool = false

## 当前组描述
var _group_description: String = ""

## 命令合并时间阈值（毫秒）
var merge_threshold_ms: int = 500

## 上次命令时间
var _last_command_time: int = 0

## 是否启用命令合并
var merge_enabled: bool = true


## 初始化
func _init(p_controller: EditorController = null) -> void:
	controller = p_controller


## 设置控制器
func set_controller(p_controller: EditorController) -> void:
	controller = p_controller


## ========== 基本操作 ==========

## 执行命令并添加到撤销栈
func execute_command(cmd: EditorData.EditorCommand) -> void:
	if is_performing:
		return

	# 如果在命令组中，添加到组
	if is_in_group:
		_current_group.append(cmd)
		return

	# 尝试合并命令
	if merge_enabled and _try_merge_command(cmd):
		return

	# 添加到撤销栈
	_undo_stack.append(cmd)
	_redo_stack.clear()

	# 限制栈大小
	_limit_stack_size()

	# 更新时间
	_last_command_time = Time.get_ticks_msec()

	# 发送信号
	_emit_signals()


## 撤销
func undo() -> bool:
	if not can_undo() or is_performing:
		return false

	is_performing = true

	var cmd = _undo_stack.pop_back()
	_undo_command(cmd)
	_redo_stack.append(cmd)

	is_performing = false
	_emit_signals()

	return true


## 重做
func redo() -> bool:
	if not can_redo() or is_performing:
		return false

	is_performing = true

	var cmd = _redo_stack.pop_back()
	_redo_command(cmd)
	_undo_stack.append(cmd)

	is_performing = false
	_emit_signals()

	return true


## 是否可以撤销
func can_undo() -> bool:
	return not _undo_stack.is_empty() and not is_performing


## 是否可以重做
func can_redo() -> bool:
	return not _redo_stack.is_empty() and not is_performing


## 清空所有栈
func clear() -> void:
	_undo_stack.clear()
	_redo_stack.clear()
	_current_group.clear()
	is_in_group = false
	_emit_signals()


## 获取撤销栈大小
func get_undo_count() -> int:
	return _undo_stack.size()


## 获取重做栈大小
func get_redo_count() -> int:
	return _redo_stack.size()


## 获取撤销描述
func get_undo_description() -> String:
	if _undo_stack.is_empty():
		return ""

	var cmd = _undo_stack.back()
	if cmd is EditorData.EditorCommand:
		return cmd.description if not cmd.description.is_empty() else "操作"
	elif cmd is Array:
		return "批量操作"
	return "操作"


## 获取重做描述
func get_redo_description() -> String:
	if _redo_stack.is_empty():
		return ""

	var cmd = _redo_stack.back()
	if cmd is EditorData.EditorCommand:
		return cmd.description if not cmd.description.is_empty() else "操作"
	elif cmd is Array:
		return "批量操作"
	return "操作"


## ========== 命令组 ==========

## 开始命令组
func begin_group(description: String = "") -> void:
	is_in_group = true
	_group_description = description
	_current_group.clear()


## 结束命令组
func end_group() -> void:
	if not is_in_group:
		return

	is_in_group = false

	if _current_group.is_empty():
		return

	# 创建命令组
	var group_cmd = _create_group_command()
	if group_cmd != null:
		_undo_stack.append(group_cmd)
		_redo_stack.clear()
		_limit_stack_size()

	_current_group.clear()
	_group_description = ""
	_emit_signals()


## 取消命令组
func cancel_group() -> void:
	is_in_group = false
	_current_group.clear()
	_group_description = ""


## 创建组命令
func _create_group_command() -> Variant:
	if _current_group.is_empty():
		return null

	# 如果只有一个命令，直接返回
	if _current_group.size() == 1:
		return _current_group[0]

	# 返回命令数组
	return _current_group.duplicate()


## ========== 命令合并 ==========

## 尝试合并命令
func _try_merge_command(cmd: EditorData.EditorCommand) -> bool:
	if _undo_stack.is_empty():
		return false

	var current_time = Time.get_ticks_msec()
	if current_time - _last_command_time > merge_threshold_ms:
		return false

	var last_cmd = _undo_stack.back()
	if last_cmd is EditorData.EditorCommand:
		return _merge_commands(last_cmd, cmd)

	return false


## 合并两个命令
func _merge_commands(old_cmd: EditorData.EditorCommand, new_cmd: EditorData.EditorCommand) -> bool:
	# 只合并相同类型和目标的命令
	if old_cmd.command_type != new_cmd.command_type:
		return false

	if old_cmd.target != new_cmd.target:
		return false

	# 根据命令类型决定是否合并
	match old_cmd.command_type:
		EditorData.EditorCommand.CommandType.CHANGE_BPM:
			# BPM变更可以合并
			old_cmd.new_value = new_cmd.new_value
			return true

		EditorData.EditorCommand.CommandType.CHANGE_SCROLL:
			# 滚动速度变更可以合并
			old_cmd.new_value = new_cmd.new_value
			return true

		EditorData.EditorCommand.CommandType.MOVE_NOTE:
			# 音符移动可以合并
			old_cmd.new_value = new_cmd.new_value
			return true

		EditorData.EditorCommand.CommandType.CHANGE_NOTE_TYPE:
			# 音符类型变更可以合并
			old_cmd.new_value = new_cmd.new_value
			return true

	return false


## ========== 撤销/重做执行 ==========

## 撤销命令
func _undo_command(cmd: Variant) -> void:
	if cmd is EditorData.EditorCommand:
		_undo_single_command(cmd)
	elif cmd is Array:
		# 批量命令：从后向前撤销
		for i in range(cmd.size() - 1, -1, -1):
			_undo_single_command(cmd[i])


## 重做命令
func _redo_command(cmd: Variant) -> void:
	if cmd is EditorData.EditorCommand:
		_redo_single_command(cmd)
	elif cmd is Array:
		# 批量命令：从前向后重做
		for single_cmd in cmd:
			_redo_single_command(single_cmd)


## 撤销单个命令
func _undo_single_command(cmd: EditorData.EditorCommand) -> void:
	if controller == null or cmd == null:
		return

	match cmd.command_type:
		EditorData.EditorCommand.CommandType.ADD_NOTE:
			# 撤销添加 = 移除音符
			var course = controller.get_current_course()
			if course != null and cmd.target.measure_index < course.measures.size():
				course.measures[cmd.target.measure_index].remove_note(cmd.target)

		EditorData.EditorCommand.CommandType.REMOVE_NOTE:
			# 撤销移除 = 添加音符
			var course = controller.get_current_course()
			var old_data = cmd.old_value
			if course != null and old_data.measure < course.measures.size():
				course.measures[old_data.measure].add_note(cmd.target)

		EditorData.EditorCommand.CommandType.MOVE_NOTE:
			# 撤销移动 = 移回原位置
			var old_data = cmd.old_value
			var course = controller.get_current_course()
			if course != null:
				course.measures[cmd.target.measure_index].remove_note(cmd.target)
				cmd.target.measure_index = old_data.measure
				cmd.target.position = old_data.position
				course.measures[old_data.measure].add_note(cmd.target)

		EditorData.EditorCommand.CommandType.CHANGE_NOTE_TYPE:
			cmd.target.note_type = cmd.old_value

		EditorData.EditorCommand.CommandType.ADD_MEASURE:
			# 撤销添加小节 = 移除小节
			var course = controller.get_current_course()
			if course != null:
				course.remove_measure(cmd.new_value)

		EditorData.EditorCommand.CommandType.REMOVE_MEASURE:
			# 撤销移除小节 = 添加小节
			var course = controller.get_current_course()
			var old_data = cmd.old_value
			if course != null:
				course.insert_measure(old_data.index, old_data.measure)

		EditorData.EditorCommand.CommandType.CHANGE_BPM:
			cmd.target.bpm = cmd.old_value

		EditorData.EditorCommand.CommandType.CHANGE_SCROLL:
			cmd.target.scroll = cmd.old_value

		EditorData.EditorCommand.CommandType.TOGGLE_GOGO:
			cmd.target.is_gogo = cmd.old_value

		EditorData.EditorCommand.CommandType.TOGGLE_BARLINE:
			cmd.target.show_barline = cmd.old_value

		EditorData.EditorCommand.CommandType.ADD_BRANCH_CONDITION:
			# 撤销添加分支条件 = 移除分支条件
			var course = controller.get_current_course()
			if course != null:
				course.branch_conditions.erase(cmd.target)

		EditorData.EditorCommand.CommandType.REMOVE_BRANCH_CONDITION:
			# 撤销移除分支条件 = 添加分支条件
			var course = controller.get_current_course()
			var old_data = cmd.old_value
			if course != null:
				course.branch_conditions.insert(old_data.index, old_data.condition)

		EditorData.EditorCommand.CommandType.SWITCH_BRANCH:
			# 撤销分支切换
			controller.current_branch = cmd.old_value


## 重做单个命令
func _redo_single_command(cmd: EditorData.EditorCommand) -> void:
	if controller == null or cmd == null:
		return

	match cmd.command_type:
		EditorData.EditorCommand.CommandType.ADD_NOTE:
			var course = controller.get_current_course()
			var new_data = cmd.new_value
			if course != null and new_data.measure < course.measures.size():
				course.measures[new_data.measure].add_note(cmd.target)

		EditorData.EditorCommand.CommandType.REMOVE_NOTE:
			var course = controller.get_current_course()
			if course != null and cmd.target.measure_index < course.measures.size():
				course.measures[cmd.target.measure_index].remove_note(cmd.target)

		EditorData.EditorCommand.CommandType.MOVE_NOTE:
			var new_data = cmd.new_value
			var course = controller.get_current_course()
			if course != null:
				course.measures[cmd.target.measure_index].remove_note(cmd.target)
				cmd.target.measure_index = new_data.measure
				cmd.target.position = new_data.position
				course.measures[new_data.measure].add_note(cmd.target)

		EditorData.EditorCommand.CommandType.CHANGE_NOTE_TYPE:
			cmd.target.note_type = cmd.new_value

		EditorData.EditorCommand.CommandType.ADD_MEASURE:
			var course = controller.get_current_course()
			if course != null:
				course.insert_measure(cmd.new_value, cmd.target)

		EditorData.EditorCommand.CommandType.REMOVE_MEASURE:
			var course = controller.get_current_course()
			if course != null:
				course.remove_measure(cmd.old_data.index)

		EditorData.EditorCommand.CommandType.CHANGE_BPM:
			cmd.target.bpm = cmd.new_value

		EditorData.EditorCommand.CommandType.CHANGE_SCROLL:
			cmd.target.scroll = cmd.new_value

		EditorData.EditorCommand.CommandType.TOGGLE_GOGO:
			cmd.target.is_gogo = cmd.new_value

		EditorData.EditorCommand.CommandType.TOGGLE_BARLINE:
			cmd.target.show_barline = cmd.new_value

		EditorData.EditorCommand.CommandType.ADD_BRANCH_CONDITION:
			var course = controller.get_current_course()
			if course != null:
				course.branch_conditions.append(cmd.target)

		EditorData.EditorCommand.CommandType.REMOVE_BRANCH_CONDITION:
			var course = controller.get_current_course()
			if course != null:
				course.branch_conditions.remove_at(cmd.old_value.index)

		EditorData.EditorCommand.CommandType.SWITCH_BRANCH:
			controller.current_branch = cmd.new_value


## ========== 辅助方法 ==========

## 限制栈大小
func _limit_stack_size() -> void:
	while _undo_stack.size() > max_undo_steps:
		_undo_stack.remove_at(0)


## 发送信号
func _emit_signals() -> void:
	undo_stack_changed.emit(_undo_stack.size())
	redo_stack_changed.emit(_redo_stack.size())
	can_undo_changed.emit(can_undo())
	can_redo_changed.emit(can_redo())


## 获取撤销历史
func get_undo_history() -> Array:
	var history = []
	for cmd in _undo_stack:
		if cmd is EditorData.EditorCommand:
			history.append(cmd.description if not cmd.description.is_empty() else "操作")
		elif cmd is Array:
			history.append("批量操作 (%d)" % cmd.size())
	return history


## 获取重做历史
func get_redo_history() -> Array:
	var history = []
	for cmd in _redo_stack:
		if cmd is EditorData.EditorCommand:
			history.append(cmd.description if not cmd.description.is_empty() else "操作")
		elif cmd is Array:
			history.append("批量操作 (%d)" % cmd.size())
	return history


## 跳转到指定历史点
func jump_to_history_point(steps: int) -> bool:
	# steps > 0: 撤销指定步数
	# steps < 0: 重做指定步数
	if steps > 0:
		for i in range(steps):
			if not undo():
				return false
	elif steps < 0:
		for i in range(-steps):
			if not redo():
				return false
	return true


## 创建快照
func create_snapshot() -> Dictionary:
	return {
		"undo_stack": _undo_stack.duplicate(true),
		"redo_stack": _redo_stack.duplicate(true)
	}


## 恢复快照
func restore_snapshot(snapshot: Dictionary) -> void:
	_undo_stack = snapshot.get("undo_stack", [])
	_redo_stack = snapshot.get("redo_stack", [])
	_emit_signals()