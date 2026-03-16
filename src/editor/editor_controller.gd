class_name EditorController
extends Node
## 编辑器控制器
## 管理谱面数据、音符操作、命令处理

const EditorData = preload("res://src/editor/editor_data.gd")
const TJAData = preload("res://src/parser/tja_data.gd")
const TJAParser = preload("res://src/parser/tja_parser.gd")
const TJAExporter = preload("res://src/editor/tja_exporter.gd")

## 信号
signal note_added(note: EditorData.EditorNote)
signal note_removed(note: EditorData.EditorNote)
signal note_moved(note: EditorData.EditorNote, old_measure: int, old_position: float)
signal note_type_changed(note: EditorData.EditorNote, old_type: int)
signal measure_added(measure: EditorData.EditorMeasure)
signal measure_removed(measure: EditorData.EditorMeasure)
signal data_changed()
signal selection_changed(selected_notes: Array)
signal project_loaded(project: EditorData.EditorProject)
signal project_saved(file_path: String)
signal branch_changed(new_branch: int)
signal branch_condition_added(condition: EditorData.EditorBranchCondition)
signal branch_condition_removed(index: int)

## 编辑器状态枚举
enum EditorState {
	IDLE,       ## 空闲
	EDITING,    ## 编辑中
	PLAYING,    ## 预览播放
	SAVING,     ## 保存中
	LOADING     ## 加载中
}

## 当前项目
var project: EditorData.EditorProject = null

## 当前状态
var current_state: EditorState = EditorState.IDLE

## 当前选中的音符
var selected_notes: Array[EditorData.EditorNote] = []

## 当前选中的音符类型（用于放置）
var current_note_type: EditorData.NoteType = EditorData.NoteType.DON

## 撤销栈
var _undo_stack: Array[EditorData.EditorCommand] = []
## 重做栈
var _redo_stack: Array[EditorData.EditorCommand] = []

## 最大撤销步数
const MAX_UNDO_STEPS: int = 100

## 复制缓冲区
var _clipboard: Array[EditorData.EditorNote] = []

## 当前编辑的分支 (0=NORMAL, 1=EXPERT, 2=MASTER)
var current_branch: int = EditorData.BranchType.NORMAL


func _ready() -> void:
	_create_new_project()


## 创建新项目
func create_new_project() -> void:
	_create_new_project()
	project_loaded.emit(project)


func _create_new_project() -> void:
	project = EditorData.EditorProject.new()
	selected_notes.clear()
	_undo_stack.clear()
	_redo_stack.clear()
	current_state = EditorState.IDLE


## 加载项目
func load_project(file_path: String) -> bool:
	if not FileAccess.file_exists(file_path):
		push_error("文件不存在: " + file_path)
		return false

	current_state = EditorState.LOADING

	# 解析TJA文件
	var parser = TJAParser.new()
	var result = parser.parse_file(file_path)

	if not result.success:
		push_error("解析TJA文件失败: " + result.error)
		current_state = EditorState.IDLE
		return false

	# 转换为编辑器数据
	_convert_tja_to_editor(result.song)

	project.file_path = file_path
	project.clear_modified()

	current_state = EditorState.IDLE
	project_loaded.emit(project)

	return true


## 将TJA数据转换为编辑器数据
func _convert_tja_to_editor(tja_song: TJAData.TJASong) -> void:
	_create_new_project()

	# 复制元数据
	project.song_meta.title = tja_song.title
	project.song_meta.title_en = tja_song.title_en
	project.song_meta.subtitle = tja_song.subtitle
	project.song_meta.bpm = tja_song.bpm
	project.song_meta.wave = tja_song.wave
	project.song_meta.offset = tja_song.offset
	project.song_meta.demo_start = tja_song.demo_start
	project.song_meta.genre = tja_song.genre
	project.song_meta.score_mode = tja_song.score_mode
	project.song_meta.maker = tja_song.maker
	project.song_meta.lyrics = tja_song.lyrics

	# 转换难度数据
	for course_type in tja_song.courses.keys():
		var tja_course = tja_song.courses[course_type]
		var editor_course = project.get_course(course_type)

		editor_course.level = tja_course.level
		editor_course.balloons = tja_course.balloons.duplicate()
		editor_course.score_init = tja_course.score_init
		editor_course.score_diff = tja_course.score_diff
		editor_course.style = tja_course.style
		editor_course.has_branch = tja_course.has_branch

		# 清空默认小节
		editor_course.measures.clear()

		# 转换小节数据
		for tja_measure in tja_course.measures:
			var editor_measure = EditorData.EditorMeasure.new(tja_measure.index)
			editor_measure.time_signature = tja_measure.time_signature
			editor_measure.bpm = tja_measure.bpm
			editor_measure.scroll = tja_measure.scroll
			editor_measure.show_barline = tja_measure.show_barline
			editor_measure.is_gogo = tja_measure.is_gogo

			# 转换音符
			for tja_note in tja_measure.notes:
				var editor_note = EditorData.EditorNote.new(
					_convert_note_type(tja_note.note_type),
					tja_measure.index,
					tja_note.position
				)
				editor_note.balloon_hits = tja_note.balloon_hits
				editor_note.id = project.generate_note_id()
				editor_measure.add_note(editor_note)

			editor_course.add_measure(editor_measure)


## 转换音符类型
func _convert_note_type(tja_type: TJAData.NoteType) -> EditorData.NoteType:
	# TJAData.NoteType 和 EditorData.NoteType 的值是一致的
	return tja_type as EditorData.NoteType


## 保存项目
func save_project(file_path: String = "") -> bool:
	if project == null:
		return false

	var save_path = file_path if not file_path.is_empty() else project.file_path

	if save_path.is_empty():
		push_error("未指定保存路径")
		return false

	current_state = EditorState.SAVING

	# 导出为TJA格式
	var exporter = TJAExporter.new()
	var content = exporter.export_project(project)

	# 写入文件
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_error("无法创建文件: " + save_path)
		current_state = EditorState.IDLE
		return false

	file.store_string(content)
	file.close()

	project.file_path = save_path
	project.clear_modified()

	current_state = EditorState.IDLE
	project_saved.emit(save_path)

	return true


## 添加音符
func add_note(measure_index: int, position: float, note_type: EditorData.NoteType = EditorData.NoteType.NONE) -> EditorData.EditorNote:
	if project == null:
		return null

	var course = project.get_current_course()
	if course == null:
		return null

	if measure_index < 0 or measure_index >= course.measures.size():
		return null

	var measure = course.measures[measure_index]

	# 检查位置是否已有音符
	var existing = measure.get_note_at_position(position, 0.01)
	if existing != null:
		return null

	# 使用当前选中的音符类型
	var type = note_type if note_type != EditorData.NoteType.NONE else current_note_type

	# 创建音符
	var note = EditorData.EditorNote.new(type, measure_index, position)
	note.id = project.generate_note_id()

	# 执行命令
	var cmd = EditorData.EditorCommand.new(
		EditorData.EditorCommand.CommandType.ADD_NOTE,
		note,
		null,
		{"measure": measure_index, "position": position}
	)
	cmd.description = "添加音符"

	measure.add_note(note)
	_execute_command(cmd)

	project.mark_modified()
	note_added.emit(note)
	data_changed.emit()

	return note


## 移除音符
func remove_note(note: EditorData.EditorNote) -> bool:
	if project == null or note == null:
		return false

	var course = project.get_current_course()
	if course == null:
		return false

	if note.measure_index < 0 or note.measure_index >= course.measures.size():
		return false

	var measure = course.measures[note.measure_index]

	# 执行命令
	var cmd = EditorData.EditorCommand.new(
		EditorData.EditorCommand.CommandType.REMOVE_NOTE,
		note,
		{"measure": note.measure_index, "position": note.position, "type": note.note_type},
		null
	)
	cmd.description = "移除音符"

	if measure.remove_note(note):
		# 从选中列表移除
		var idx = selected_notes.find(note)
		if idx >= 0:
			selected_notes.remove_at(idx)
			selection_changed.emit(selected_notes)

		_execute_command(cmd)
		project.mark_modified()
		note_removed.emit(note)
		data_changed.emit()
		return true

	return false


## 移动音符
func move_note(note: EditorData.EditorNote, new_measure: int, new_position: float) -> bool:
	if project == null or note == null:
		return false

	var course = project.get_current_course()
	if course == null:
		return false

	if new_measure < 0 or new_measure >= course.measures.size():
		return false

	# 检查新位置是否已有音符
	var target_measure = course.measures[new_measure]
	var existing = target_measure.get_note_at_position(new_position, 0.01)
	if existing != null and existing != note:
		return false

	var old_measure = note.measure_index
	var old_position = note.position

	# 从原小节移除
	var source_measure = course.measures[old_measure]
	if not source_measure.remove_note(note):
		return false

	# 更新音符位置
	note.measure_index = new_measure
	note.position = new_position

	# 添加到新小节
	target_measure.add_note(note)

	# 执行命令
	var cmd = EditorData.EditorCommand.new(
		EditorData.EditorCommand.CommandType.MOVE_NOTE,
		note,
		{"measure": old_measure, "position": old_position},
		{"measure": new_measure, "position": new_position}
	)
	cmd.description = "移动音符"

	_execute_command(cmd)
	project.mark_modified()
	note_moved.emit(note, old_measure, old_position)
	data_changed.emit()

	return true


## 更改音符类型
func change_note_type(note: EditorData.EditorNote, new_type: EditorData.NoteType) -> bool:
	if project == null or note == null:
		return false

	var old_type = note.note_type
	note.note_type = new_type

	# 执行命令
	var cmd = EditorData.EditorCommand.new(
		EditorData.EditorCommand.CommandType.CHANGE_NOTE_TYPE,
		note,
		old_type,
		new_type
	)
	cmd.description = "更改音符类型"

	_execute_command(cmd)
	project.mark_modified()
	note_type_changed.emit(note, old_type)
	data_changed.emit()

	return true


## 添加小节
func add_measure(at_index: int = -1) -> EditorData.EditorMeasure:
	if project == null:
		return null

	var course = project.get_current_course()
	if course == null:
		return null

	var insert_index = at_index if at_index >= 0 else course.measures.size()

	# 创建新小节
	var measure = EditorData.EditorMeasure.new(insert_index)

	# 复制前一个小节的属性
	if insert_index > 0:
		var prev_measure = course.measures[insert_index - 1]
		measure.bpm = prev_measure.bpm
		measure.scroll = prev_measure.scroll
		measure.time_signature = prev_measure.time_signature

	# 执行命令
	var cmd = EditorData.EditorCommand.new(
		EditorData.EditorCommand.CommandType.ADD_MEASURE,
		measure,
		null,
		insert_index
	)
	cmd.description = "添加小节"

	course.insert_measure(insert_index, measure)

	_execute_command(cmd)
	project.mark_modified()
	measure_added.emit(measure)
	data_changed.emit()

	return measure


## 移除小节
func remove_measure(index: int) -> bool:
	if project == null:
		return false

	var course = project.get_current_course()
	if course == null:
		return false

	if index < 0 or index >= course.measures.size():
		return false

	if course.measures.size() <= 1:
		push_warning("至少需要保留一个小节")
		return false

	var measure = course.measures[index]

	# 移除该小节中的所有选中音符
	for note in measure.notes:
		var idx = selected_notes.find(note)
		if idx >= 0:
			selected_notes.remove_at(idx)

	# 执行命令
	var cmd = EditorData.EditorCommand.new(
		EditorData.EditorCommand.CommandType.REMOVE_MEASURE,
		measure,
		{"index": index, "measure": measure},
		null
	)
	cmd.description = "移除小节"

	course.remove_measure(index)

	_execute_command(cmd)
	project.mark_modified()
	measure_removed.emit(measure)
	data_changed.emit()

	return true


## 设置小节BPM
func set_measure_bpm(measure_index: int, bpm: float) -> void:
	if project == null:
		return

	var course = project.get_current_course()
	if course == null:
		return

	if measure_index < 0 or measure_index >= course.measures.size():
		return

	var measure = course.measures[measure_index]
	var old_bpm = measure.bpm
	measure.bpm = bpm

	# 执行命令
	var cmd = EditorData.EditorCommand.new(
		EditorData.EditorCommand.CommandType.CHANGE_BPM,
		measure,
		old_bpm,
		bpm
	)
	cmd.description = "更改BPM"

	_execute_command(cmd)
	project.mark_modified()
	data_changed.emit()


## 设置小节滚动速度
func set_measure_scroll(measure_index: int, scroll: float) -> void:
	if project == null:
		return

	var course = project.get_current_course()
	if course == null:
		return

	if measure_index < 0 or measure_index >= course.measures.size():
		return

	var measure = course.measures[measure_index]
	var old_scroll = measure.scroll
	measure.scroll = scroll

	# 执行命令
	var cmd = EditorData.EditorCommand.new(
		EditorData.EditorCommand.CommandType.CHANGE_SCROLL,
		measure,
		old_scroll,
		scroll
	)
	cmd.description = "更改滚动速度"

	_execute_command(cmd)
	project.mark_modified()
	data_changed.emit()


## 切换Go-Go Time
func toggle_measure_gogo(measure_index: int) -> void:
	if project == null:
		return

	var course = project.get_current_course()
	if course == null:
		return

	if measure_index < 0 or measure_index >= course.measures.size():
		return

	var measure = course.measures[measure_index]
	measure.is_gogo = not measure.is_gogo

	# 执行命令
	var cmd = EditorData.EditorCommand.new(
		EditorData.EditorCommand.CommandType.TOGGLE_GOGO,
		measure,
		not measure.is_gogo,
		measure.is_gogo
	)
	cmd.description = "切换Go-Go Time"

	_execute_command(cmd)
	project.mark_modified()
	data_changed.emit()


## 选择音符
func select_note(note: EditorData.EditorNote, additive: bool = false) -> void:
	if note == null:
		return

	if not additive:
		# 清除之前的选择
		for n in selected_notes:
			n.selected = false
		selected_notes.clear()

	# 添加到选择
	if not selected_notes.has(note):
		note.selected = true
		selected_notes.append(note)

	selection_changed.emit(selected_notes)


## 取消选择
func deselect_all() -> void:
	for note in selected_notes:
		note.selected = false
	selected_notes.clear()
	selection_changed.emit(selected_notes)


## 全选
func select_all() -> void:
	if project == null:
		return

	var course = project.get_current_course()
	if course == null:
		return

	deselect_all()

	for measure in course.measures:
		for note in measure.notes:
			note.selected = true
			selected_notes.append(note)

	selection_changed.emit(selected_notes)


## 删除选中的音符
func delete_selected() -> void:
	var notes_to_remove = selected_notes.duplicate()
	for note in notes_to_remove:
		remove_note(note)


## 复制选中的音符
func copy_selected() -> void:
	_clipboard.clear()
	for note in selected_notes:
		# 创建副本
		var copy = EditorData.EditorNote.new(note.note_type, note.measure_index, note.position)
		copy.balloon_hits = note.balloon_hits
		_clipboard.append(copy)


## 粘贴音符
func paste(target_measure: int, target_position: float) -> void:
	if _clipboard.is_empty():
		return

	deselect_all()

	# 计算偏移
	var min_measure = _clipboard[0].measure_index
	var min_position = _clipboard[0].position
	for note in _clipboard:
		if note.measure_index < min_measure or \
		   (note.measure_index == min_measure and note.position < min_position):
			min_measure = note.measure_index
			min_position = note.position

	# 粘贴音符
	for note in _clipboard:
		var new_measure = target_measure + (note.measure_index - min_measure)
		var new_position = target_position + (note.position - min_position)

		# 限制位置范围
		while new_position >= 1.0:
			new_measure += 1
			new_position -= 1.0
		while new_position < 0.0:
			new_measure -= 1
			new_position += 1.0

		if new_measure >= 0:
			var new_note = add_note(new_measure, new_position, note.note_type)
			if new_note != null:
				new_note.balloon_hits = note.balloon_hits
				select_note(new_note, true)


## 执行命令（添加到撤销栈）
func _execute_command(cmd: EditorData.EditorCommand) -> void:
	_undo_stack.append(cmd)
	_redo_stack.clear()

	# 限制撤销栈大小
	if _undo_stack.size() > MAX_UNDO_STEPS:
		_undo_stack.remove_at(0)


## 撤销
func undo() -> bool:
	if _undo_stack.is_empty():
		return false

	var cmd = _undo_stack.pop_back()
	_undo_command(cmd)
	_redo_stack.append(cmd)

	data_changed.emit()
	return true


## 重做
func redo() -> bool:
	if _redo_stack.is_empty():
		return false

	var cmd = _redo_stack.pop_back()
	_redo_command(cmd)
	_undo_stack.append(cmd)

	data_changed.emit()
	return true


## 撤销命令
func _undo_command(cmd: EditorData.EditorCommand) -> void:
	match cmd.command_type:
		EditorData.EditorCommand.CommandType.ADD_NOTE:
			# 撤销添加 = 移除音符
			var course = project.get_current_course()
			if cmd.target.measure_index < course.measures.size():
				course.measures[cmd.target.measure_index].remove_note(cmd.target)

		EditorData.EditorCommand.CommandType.REMOVE_NOTE:
			# 撤销移除 = 添加音符
			var course = project.get_current_course()
			var old_data = cmd.old_value
			if old_data.measure < course.measures.size():
				course.measures[old_data.measure].add_note(cmd.target)

		EditorData.EditorCommand.CommandType.MOVE_NOTE:
			# 撤销移动 = 移回原位置
			var old_data = cmd.old_value
			var course = project.get_current_course()
			course.measures[cmd.target.measure_index].remove_note(cmd.target)
			cmd.target.measure_index = old_data.measure
			cmd.target.position = old_data.position
			course.measures[old_data.measure].add_note(cmd.target)

		EditorData.EditorCommand.CommandType.CHANGE_NOTE_TYPE:
			cmd.target.note_type = cmd.old_value

		EditorData.EditorCommand.CommandType.CHANGE_BPM:
			cmd.target.bpm = cmd.old_value

		EditorData.EditorCommand.CommandType.CHANGE_SCROLL:
			cmd.target.scroll = cmd.old_value

		EditorData.EditorCommand.CommandType.TOGGLE_GOGO:
			cmd.target.is_gogo = cmd.old_value


## 重做命令
func _redo_command(cmd: EditorData.EditorCommand) -> void:
	match cmd.command_type:
		EditorData.EditorCommand.CommandType.ADD_NOTE:
			var course = project.get_current_course()
			var new_data = cmd.new_value
			if new_data.measure < course.measures.size():
				course.measures[new_data.measure].add_note(cmd.target)

		EditorData.EditorCommand.CommandType.REMOVE_NOTE:
			var course = project.get_current_course()
			if cmd.target.measure_index < course.measures.size():
				course.measures[cmd.target.measure_index].remove_note(cmd.target)

		EditorData.EditorCommand.CommandType.MOVE_NOTE:
			var new_data = cmd.new_value
			var course = project.get_current_course()
			course.measures[cmd.target.measure_index].remove_note(cmd.target)
			cmd.target.measure_index = new_data.measure
			cmd.target.position = new_data.position
			course.measures[new_data.measure].add_note(cmd.target)

		EditorData.EditorCommand.CommandType.CHANGE_NOTE_TYPE:
			cmd.target.note_type = cmd.new_value

		EditorData.EditorCommand.CommandType.CHANGE_BPM:
			cmd.target.bpm = cmd.new_value

		EditorData.EditorCommand.CommandType.CHANGE_SCROLL:
			cmd.target.scroll = cmd.new_value

		EditorData.EditorCommand.CommandType.TOGGLE_GOGO:
			cmd.target.is_gogo = cmd.new_value


## 是否可以撤销
func can_undo() -> bool:
	return not _undo_stack.is_empty()


## 是否可以重做
func can_redo() -> bool:
	return not _redo_stack.is_empty()


## 获取当前项目
func get_project() -> EditorData.EditorProject:
	return project


## 获取当前难度
func get_current_course() -> EditorData.EditorCourse:
	if project == null:
		return null
	return project.get_current_course()


## 设置当前难度
func set_current_course(course_type: TJAData.CourseType) -> void:
	if project == null:
		return

	project.set_current_course(course_type)
	deselect_all()
	data_changed.emit()


## 设置当前音符类型
func set_current_note_type(note_type: EditorData.NoteType) -> void:
	current_note_type = note_type


## 获取当前音符类型
func get_current_note_type() -> EditorData.NoteType:
	return current_note_type


## 检查项目是否已修改
func is_modified() -> bool:
	return project != null and project.modified


## 获取选中音符数量
func get_selection_count() -> int:
	return selected_notes.size()


## ========== 分支相关方法 ==========

## 切换分支
func switch_branch(branch_type: int) -> void:
	if branch_type < 0 or branch_type > 2:
		return

	var old_branch = current_branch
	current_branch = branch_type

	# 如果课程有分支，切换到对应分支的小节数据
	var course = get_current_course()
	if course != null and course.has_branch:
		# 保存当前分支的小节数据
		if old_branch != current_branch:
			course.branch_measures[old_branch] = course.measures.duplicate(true)

		# 加载目标分支的小节数据
		if course.branch_measures[branch_type].size() > 0:
			course.measures = course.branch_measures[branch_type].duplicate(true)
		else:
			# 如果目标分支没有数据，复制普通分支的数据
			if course.branch_measures[EditorData.BranchType.NORMAL].size() > 0:
				course.measures = course.branch_measures[EditorData.BranchType.NORMAL].duplicate(true)

	# 清除选择
	deselect_all()

	# 发送信号
	branch_changed.emit(current_branch)
	data_changed.emit()


## 添加分支条件
func add_branch_condition(measure_index: int, condition_type: int, normal_threshold: float, expert_threshold: float) -> void:
	if project == null:
		return

	var course = get_current_course()
	if course == null:
		return

	# 创建分支条件
	var condition = EditorData.EditorBranchCondition.new(measure_index, condition_type, normal_threshold, expert_threshold)

	# 添加到条件列表
	course.branch_conditions.append(condition)
	course.has_branch = true

	# 初始化分支小节数据
	if course.branch_measures[EditorData.BranchType.NORMAL].is_empty():
		course.branch_measures[EditorData.BranchType.NORMAL] = course.measures.duplicate(true)
	if course.branch_measures[EditorData.BranchType.EXPERT].is_empty():
		course.branch_measures[EditorData.BranchType.EXPERT] = course.measures.duplicate(true)
	if course.branch_measures[EditorData.BranchType.MASTER].is_empty():
		course.branch_measures[EditorData.BranchType.MASTER] = course.measures.duplicate(true)

	# 执行命令
	var cmd = EditorData.EditorCommand.new(
		EditorData.EditorCommand.CommandType.ADD_BRANCH_CONDITION,
		condition,
		null,
		{"measure": measure_index, "type": condition_type, "normal": normal_threshold, "expert": expert_threshold}
	)
	cmd.description = "添加分支条件"

	_execute_command(cmd)
	project.mark_modified()
	branch_condition_added.emit(condition)
	data_changed.emit()


## 移除分支条件
func remove_branch_condition(index: int) -> void:
	if project == null:
		return

	var course = get_current_course()
	if course == null:
		return

	if index < 0 or index >= course.branch_conditions.size():
		return

	var condition = course.branch_conditions[index]

	# 执行命令
	var cmd = EditorData.EditorCommand.new(
		EditorData.EditorCommand.CommandType.REMOVE_BRANCH_CONDITION,
		condition,
		{"index": index, "condition": condition},
		null
	)
	cmd.description = "移除分支条件"

	course.branch_conditions.remove_at(index)

	# 如果没有分支条件了，清除分支标记
	if course.branch_conditions.is_empty():
		course.has_branch = false

	_execute_command(cmd)
	project.mark_modified()
	branch_condition_removed.emit(index)
	data_changed.emit()


## 获取当前分支
func get_current_branch() -> int:
	return current_branch


## 获取分支条件列表
func get_branch_conditions() -> Array:
	var course = get_current_course()
	if course == null:
		return []
	return course.branch_conditions


## 复制小节到所有分支
func copy_measure_to_all_branches(measure_index: int) -> void:
	if project == null:
		return

	var course = get_current_course()
	if course == null:
		return

	if measure_index < 0 or measure_index >= course.measures.size():
		return

	if not course.has_branch:
		return

	var source_measure = course.measures[measure_index]

	# 复制到所有分支
	for branch_type in [EditorData.BranchType.NORMAL, EditorData.BranchType.EXPERT, EditorData.BranchType.MASTER]:
		if branch_type != current_branch:
			if course.branch_measures[branch_type].size() > measure_index:
				course.branch_measures[branch_type][measure_index] = source_measure.duplicate(true)

	project.mark_modified()
	data_changed.emit()


## 启用分支模式
func enable_branch_mode() -> void:
	var course = get_current_course()
	if course == null:
		return

	if course.has_branch:
		return

	course.has_branch = true

	# 初始化所有分支的小节数据
	course.branch_measures[EditorData.BranchType.NORMAL] = course.measures.duplicate(true)
	course.branch_measures[EditorData.BranchType.EXPERT] = course.measures.duplicate(true)
	course.branch_measures[EditorData.BranchType.MASTER] = course.measures.duplicate(true)

	project.mark_modified()
	data_changed.emit()


## 禁用分支模式
func disable_branch_mode() -> void:
	var course = get_current_course()
	if course == null:
		return

	if not course.has_branch:
		return

	course.has_branch = false
	course.branch_conditions.clear()
	course.branch_measures[EditorData.BranchType.NORMAL] = []
	course.branch_measures[EditorData.BranchType.EXPERT] = []
	course.branch_measures[EditorData.BranchType.MASTER] = []

	# 切换到普通分支
	current_branch = EditorData.BranchType.NORMAL

	project.mark_modified()
	branch_changed.emit(current_branch)
	data_changed.emit()


## 检查当前课程是否有分支
func has_branch() -> bool:
	var course = get_current_course()
	if course == null:
		return false
	return course.has_branch