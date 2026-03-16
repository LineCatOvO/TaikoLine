class_name TJAExporter
extends RefCounted
## TJA文件导出器
## 将编辑器数据转换为TJA格式

const EditorData = preload("res://src/editor/editor_data.gd")
const TJAData = preload("res://src/parser/tja_data.gd")

## 导出项目为TJA格式
func export_project(project: EditorData.EditorProject) -> String:
	var lines: Array[String] = []

	# 导出头部元数据
	_export_header(project.song_meta, lines)

	# 导出各难度
	for course_type in _get_sorted_course_types(project.courses):
		var course = project.courses[course_type]
		if course.measures.is_empty():
			continue
		_export_course(course, lines)

	return "\n".join(lines)


## 导出头部元数据
func _export_header(meta: EditorData.EditorSongMeta, lines: Array[String]) -> void:
	lines.append("TITLE:" + meta.title)

	if not meta.title_en.is_empty():
		lines.append("TITLEEN:" + meta.title_en)

	if not meta.subtitle.is_empty():
		lines.append("SUBTITLE:" + meta.subtitle)

	lines.append("BPM:%.2f" % meta.bpm)

	if not meta.wave.is_empty():
		lines.append("WAVE:" + meta.wave)

	lines.append("OFFSET:%.3f" % meta.offset)

	if meta.demo_start > 0:
		lines.append("DEMOSTART:%.3f" % meta.demo_start)

	if not meta.genre.is_empty():
		lines.append("GENRE:" + meta.genre)

	if meta.score_mode > 0:
		lines.append("SCOREMODE:%d" % meta.score_mode)

	if not meta.maker.is_empty():
		lines.append("MAKER:" + meta.maker)

	if not meta.lyrics.is_empty():
		lines.append("LYRICS:" + meta.lyrics)

	lines.append("")


## 导出难度
func _export_course(course: EditorData.EditorCourse, lines: Array[String]) -> void:
	# 检查是否有分支
	if course.has_branch and not course.branch_conditions.is_empty():
		_export_course_with_branch(course, lines)
		return

	# 难度声明
	lines.append("COURSE:" + _course_type_to_string(course.course_type))

	# 难度等级
	lines.append("LEVEL:%d" % course.level)

	# 气球列表
	if not course.balloons.is_empty():
		var balloon_strs: Array[String] = []
		for b in course.balloons:
			balloon_strs.append(str(b))
		lines.append("BALLOON:" + ",".join(balloon_strs))

	# 计分参数
	lines.append("SCOREINIT:%d" % course.score_init)
	lines.append("SCOREDIFF:%d" % course.score_diff)

	# 样式
	if course.style != "Single":
		lines.append("STYLE:" + course.style)

	# 谱面开始
	lines.append("")
	lines.append("#START")

	# 导出小节
	var current_bpm: float = -1.0
	var current_scroll: float = 1.0
	var current_gogo: bool = false
	var current_measure: Vector2 = Vector2(-1.0, -1.0)
	var balloon_index: int = 0

	for measure in course.measures:
		# BPM变化
		if measure.bpm != current_bpm:
			lines.append("")
			lines.append("#BPMCHANGE %.2f" % measure.bpm)
			current_bpm = measure.bpm

		# 滚动速度变化
		if measure.scroll != current_scroll:
			lines.append("")
			lines.append("#SCROLL %.2f" % measure.scroll)
			current_scroll = measure.scroll

		# Go-Go Time变化
		if measure.is_gogo != current_gogo:
			lines.append("")
			if measure.is_gogo:
				lines.append("#GOGOSTART")
			else:
				lines.append("#GOGOEND")
			current_gogo = measure.is_gogo

		# 拍号变化
		if measure.time_signature != current_measure:
			lines.append("")
			lines.append("#MEASURE %.0f/%.0f" % [measure.time_signature.x, measure.time_signature.y])
			current_measure = measure.time_signature

		# 小节线显示
		if not measure.show_barline:
			lines.append("#BARLINEOFF")

		# 导出音符数据
		var note_line = _export_measure_notes(measure, course.balloons, balloon_index)
		lines.append(note_line)

		# 更新气球索引
		balloon_index += _count_balloons_in_measure(measure)

		# 恢复小节线显示
		if not measure.show_barline:
			lines.append("#BARLINEON")

	# 谱面结束
	lines.append("")
	lines.append("#END")
	lines.append("")


## 导出小节音符
func _export_measure_notes(measure: EditorData.EditorMeasure, balloons: Array[int], balloon_start: int) -> String:
	if measure.notes.is_empty():
		return "0,"

	# 计算音符密度（确定小节内的音符数量）
	var max_position = 0.0
	for note in measure.notes:
		if note.position > max_position:
			max_position = note.position

	# 默认使用16分音符精度
	var resolution = 16
	var note_chars: Array[String] = []
	for i in range(resolution):
		note_chars.append("0")

	# 填充音符
	for note in measure.notes:
		var index = int(note.position * (resolution - 1))
		index = clamp(index, 0, resolution - 1)
		note_chars[index] = note.get_char()

	return "".join(note_chars) + ","


## 计算小节中的气球数量
func _count_balloons_in_measure(measure: EditorData.EditorMeasure) -> int:
	var count = 0
	for note in measure.notes:
		if note.note_type in [EditorData.NoteType.BALLOON, EditorData.NoteType.KUSUDAMA]:
			count += 1
	return count


## 难度类型转字符串
func _course_type_to_string(type: TJAData.CourseType) -> String:
	match type:
		TJAData.CourseType.EASY: return "Easy"
		TJAData.CourseType.NORMAL: return "Normal"
		TJAData.CourseType.HARD: return "Hard"
		TJAData.CourseType.ONI: return "Oni"
		TJAData.CourseType.EDIT: return "Edit"
		TJAData.CourseType.TOWER: return "Tower"
		TJAData.CourseType.DAN: return "Dan"
		_: return "Oni"


## 获取排序后的难度类型列表
func _get_sorted_course_types(courses: Dictionary) -> Array:
	var types: Array = []
	var order = [
		TJAData.CourseType.EASY,
		TJAData.CourseType.NORMAL,
		TJAData.CourseType.HARD,
		TJAData.CourseType.ONI,
		TJAData.CourseType.EDIT,
		TJAData.CourseType.TOWER,
		TJAData.CourseType.DAN
	]

	for type in order:
		if courses.has(type):
			types.append(type)

	return types


## 导出单个难度
func export_course(course: EditorData.EditorCourse, meta: EditorData.EditorSongMeta) -> String:
	var lines: Array[String] = []

	# 导出头部
	_export_header(meta, lines)

	# 导出难度
	_export_course(course, lines)

	return "\n".join(lines)


## 验证导出数据
func validate_project(project: EditorData.EditorProject) -> Array[String]:
	var errors: Array[String] = []

	# 检查标题
	if project.song_meta.title.is_empty():
		errors.append("缺少歌曲标题")

	# 检查BPM
	if project.song_meta.bpm <= 0:
		errors.append("无效的BPM值")

	# 检查难度
	var has_notes = false
	for course in project.courses.values():
		if course.measures.size() > 0:
			for measure in course.measures:
				if not measure.notes.is_empty():
					has_notes = true
					break

	if not has_notes:
		errors.append("没有任何音符数据")

	# 检查气球数据
	for course_type in project.courses.keys():
		var course = project.courses[course_type]
		var balloon_count = _count_total_balloons(course)
		if balloon_count > course.balloons.size():
			errors.append("难度 %s 的气球数据不完整" % _course_type_to_string(course_type))

	return errors


## 计算总气球数量
func _count_total_balloons(course: EditorData.EditorCourse) -> int:
	var count = 0
	for measure in course.measures:
		for note in measure.notes:
			if note.note_type in [EditorData.NoteType.BALLOON, EditorData.NoteType.KUSUDAMA]:
				count += 1
	return count


## ========== 分支导出方法 ==========

## 导出分支条件
func _export_branch_condition(condition: EditorData.EditorBranchCondition) -> String:
	return condition.to_tja_string()


## 导出分支小节
func _export_branch_measures(measures: Array, branch_type: int) -> Array[String]:
	var lines: Array[String] = []

	# 分支开始标记
	match branch_type:
		EditorData.BranchType.NORMAL:
			lines.append("#N")
		EditorData.BranchType.EXPERT:
			lines.append("#E")
		EditorData.BranchType.MASTER:
			lines.append("#M")

	# 导出小节音符
	for measure in measures:
		var note_line = _export_measure_notes(measure, [], 0)
		lines.append(note_line)

	return lines


## 导出带分支的难度
func _export_course_with_branch(course: EditorData.EditorCourse, lines: Array[String]) -> void:
	# 难度声明
	lines.append("COURSE:" + _course_type_to_string(course.course_type))

	# 难度等级
	lines.append("LEVEL:%d" % course.level)

	# 气球列表
	if not course.balloons.is_empty():
		var balloon_strs: Array[String] = []
		for b in course.balloons:
			balloon_strs.append(str(b))
		lines.append("BALLOON:" + ",".join(balloon_strs))

	# 计分参数
	lines.append("SCOREINIT:%d" % course.score_init)
	lines.append("SCOREDIFF:%d" % course.score_diff)

	# 样式
	if course.style != "Single":
		lines.append("STYLE:" + course.style)

	# 谱面开始
	lines.append("")
	lines.append("#START")

	# 导出分支条件和小节
	var current_bpm: float = -1.0
	var current_scroll: float = 1.0
	var current_gogo: bool = false
	var current_measure: Vector2 = Vector2(-1.0, -1.0)
	var balloon_index: int = 0

	# 记录已处理的分支条件索引
	var processed_conditions: Dictionary = {}

	for i in range(course.measures.size()):
		var measure = course.measures[i]

		# 检查是否有分支条件在此小节
		for cond_idx in range(course.branch_conditions.size()):
			var condition = course.branch_conditions[cond_idx]
			if condition.measure_index == i and not processed_conditions.has(cond_idx):
				# 导出分支条件
				lines.append("")
				lines.append(_export_branch_condition(condition))
				processed_conditions[cond_idx] = true

				# 导出各分支的小节
				# Normal分支
				if course.branch_measures.has(EditorData.BranchType.NORMAL):
					var normal_measures = course.branch_measures[EditorData.BranchType.NORMAL]
					if normal_measures.size() > i:
						var normal_lines = _export_branch_measures(
							normal_measures.slice(i),
							EditorData.BranchType.NORMAL
						)
						for line in normal_lines:
							lines.append(line)

				# Expert分支
				if course.branch_measures.has(EditorData.BranchType.EXPERT):
					var expert_measures = course.branch_measures[EditorData.BranchType.EXPERT]
					if expert_measures.size() > i:
						var expert_lines = _export_branch_measures(
							expert_measures.slice(i),
							EditorData.BranchType.EXPERT
						)
						for line in expert_lines:
							lines.append(line)

				# Master分支
				if course.branch_measures.has(EditorData.BranchType.MASTER):
					var master_measures = course.branch_measures[EditorData.BranchType.MASTER]
					if master_measures.size() > i:
						var master_lines = _export_branch_measures(
							master_measures.slice(i),
							EditorData.BranchType.MASTER
						)
						for line in master_lines:
							lines.append(line)

				# 分支结束
				lines.append("#BRANCHEND")

		# BPM变化
		if measure.bpm != current_bpm:
			lines.append("")
			lines.append("#BPMCHANGE %.2f" % measure.bpm)
			current_bpm = measure.bpm

		# 滚动速度变化
		if measure.scroll != current_scroll:
			lines.append("")
			lines.append("#SCROLL %.2f" % measure.scroll)
			current_scroll = measure.scroll

		# Go-Go Time变化
		if measure.is_gogo != current_gogo:
			lines.append("")
			if measure.is_gogo:
				lines.append("#GOGOSTART")
			else:
				lines.append("#GOGOEND")
			current_gogo = measure.is_gogo

		# 拍号变化
		if measure.time_signature != current_measure:
			lines.append("")
			lines.append("#MEASURE %.0f/%.0f" % [measure.time_signature.x, measure.time_signature.y])
			current_measure = measure.time_signature

		# 小节线显示
		if not measure.show_barline:
			lines.append("#BARLINEOFF")

		# 导出音符数据
		var note_line = _export_measure_notes(measure, course.balloons, balloon_index)
		lines.append(note_line)

		# 更新气球索引
		balloon_index += _count_balloons_in_measure(measure)

		# 恢复小节线显示
		if not measure.show_barline:
			lines.append("#BARLINEON")

	# 谱面结束
	lines.append("")
	lines.append("#END")
	lines.append("")


## 保存到文件
func save_to_file(project: EditorData.EditorProject, file_path: String) -> bool:
	var errors = validate_project(project)
	if not errors.is_empty():
		push_error("验证失败: " + ", ".join(errors))
		return false

	var content = export_project(project)
	var file = FileAccess.open(file_path, FileAccess.WRITE)

	if file == null:
		push_error("无法创建文件: " + file_path)
		return false

	file.store_string(content)
	file.close()

	return true