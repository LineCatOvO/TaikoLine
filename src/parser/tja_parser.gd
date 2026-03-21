class_name TJAParser
## TJA文件解析器
## 解析TJA格式的太鼓达人谱面文件

const TJAData = preload("res://src/parser/tja_data.gd")

## 解析状态枚举
enum ParseState {
	HEADER,      ## 头部元数据
	COURSE,      ## 难度定义
	NOTES,       ## 谱面数据
	BRANCH_N,    ## 普通分支
	BRANCH_E,    ## 高级分支
	BRANCH_M     ## 大师分支
}

## 当前解析状态
var _state: ParseState = ParseState.HEADER
## 当前歌曲数据
var _song: TJAData.TJASong = null
## 当前难度数据
var _current_course: TJAData.TJACourse = null
## 当前小节索引
var _measure_index: int = 0
## 当前BPM
var _current_bpm: float = 120.0
## 当前滚动速度
var _current_scroll: float = 1.0
## 当前拍号
var _current_measure: Vector2 = Vector2(4.0, 4.0)
## 是否在Go-Go Time
var _is_gogo: bool = false
## 是否显示小节线
var _show_barline: bool = true
## 当前气球打击次数索引
var _balloon_index: int = 0
## 当前连打计数
var _renda_count: int = 0
## 是否在连打中
var _in_renda: bool = false
## 当前连打类型
var _renda_type: TJAData.NoteType = TJAData.NoteType.NONE
## 当前分支类型
var _current_branch: TJAData.BranchType = TJAData.BranchType.NORMAL
## 分支条件
var _branch_condition: Array = []
## 当前分支条件对象
var _current_branch_condition: TJAData.BranchCondition = null
## 分支小节临时存储
var _branch_measures_n: Array = []
var _branch_measures_e: Array = []
var _branch_measures_m: Array = []
## 错误信息
var _error: String = ""
var _error_line: int = 0

## 解析TJA文件
## @param file_path: TJA文件路径
## @return: TJAParseResult 解析结果
func parse_file(file_path: String) -> TJAData.TJAParseResult:
	var result = TJAData.TJAParseResult.new()

	# 检查文件是否存在
	if not FileAccess.file_exists(file_path):
		result.success = false
		result.error = "文件不存在: " + file_path
		return result

	# 直接尝试打开文件（避免 res:// 路径下非导入文件的问题）
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		result.success = false
		result.error = "无法打开文件: " + file_path
		return result
	file.close()

	# 读取文件内容
	var content = _read_file_with_encoding(file_path)
	if content == "":
		result.success = false
		result.error = "无法读取文件或文件为空"
		return result
	
	# 解析内容
	return parse_content(content, file_path)

## 解析TJA内容
## @param content: TJA文件内容
## @param file_path: 文件路径（可选，用于错误报告）
## @return: TJAParseResult 解析结果
func parse_content(content: String, file_path: String = "") -> TJAData.TJAParseResult:
	# 初始化
	_reset_state()
	_song = TJAData.TJASong.new()
	_song.file_path = file_path
	
	# 按行分割
	var lines = content.split("\n")
	
	for i in range(lines.size()):
		var line = lines[i].strip_edges()
		_error_line = i + 1
		
		# 跳过空行和注释
		if line.is_empty() or line.begins_with("//"):
			continue
		
		# 解析行
		if not _parse_line(line):
			var result = TJAData.TJAParseResult.new()
			result.success = false
			result.error = _error
			result.error_line = _error_line
			return result
	
	# 验证解析结果
	if not _validate_song():
		var result = TJAData.TJAParseResult.new()
		result.success = false
		result.error = _error
		result.error_line = _error_line
		return result
	
	# 返回成功结果
	var result = TJAData.TJAParseResult.new()
	result.success = true
	result.song = _song
	return result

## 读取文件（自动检测编码）
func _read_file_with_encoding(file_path: String) -> String:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return ""
	
	var content = file.get_buffer(file.get_length())
	file.close()
	
	# 尝试UTF-8解码
	var text = content.get_string_from_utf8()
	if not text.is_empty():
		return text
	
	# 尝试Shift-JIS解码
	text = content.get_string_from_utf16()
	if not text.is_empty():
		return text
	
	# 回退到ASCII
	return content.get_string_from_ascii()

## 重置解析状态
func _reset_state() -> void:
	_state = ParseState.HEADER
	_song = null
	_current_course = null
	_measure_index = 0
	_current_bpm = 120.0
	_current_scroll = 1.0
	_current_measure = Vector2(4.0, 4.0)
	_is_gogo = false
	_show_barline = true
	_balloon_index = 0
	_renda_count = 0
	_in_renda = false
	_renda_type = TJAData.NoteType.NONE
	_current_branch = TJAData.BranchType.NORMAL
	_branch_condition = []
	_current_branch_condition = null
	_branch_measures_n = []
	_branch_measures_e = []
	_branch_measures_m = []
	_error = ""
	_error_line = 0

## 解析单行
func _parse_line(line: String) -> bool:
	# 检查命令行
	if line.begins_with("#"):
		return _parse_command(line)
	
	# 根据状态处理
	match _state:
		ParseState.HEADER:
			return _parse_header_line(line)
		ParseState.COURSE:
			return _parse_course_line(line)
		ParseState.NOTES, ParseState.BRANCH_N, ParseState.BRANCH_E, ParseState.BRANCH_M:
			return _parse_notes_line(line)
	
	return true

## 解析头部元数据行
func _parse_header_line(line: String) -> bool:
	var colon_pos = line.find(":")
	if colon_pos == -1:
		return true  # 忽略无效行
	
	var key = line.left(colon_pos).to_upper()
	var value = line.substr(colon_pos + 1).strip_edges()
	
	match key:
		"TITLE":
			_song.title = value
		"TITLEEN":
			_song.title_en = value
		"SUBTITLE":
			_song.subtitle = value
		"BPM":
			_song.bpm = _parse_float(value, 120.0)
			_current_bpm = _song.bpm
		"WAVE":
			_song.wave = value
		"OFFSET":
			_song.offset = _parse_float(value, 0.0)
		"DEMOSTART":
			_song.demo_start = _parse_float(value, 0.0)
		"GENRE":
			_song.genre = value
		"SCOREMODE":
			_song.score_mode = _parse_int(value, 0)
		"MAKER":
			_song.maker = value
		"LYRICS":
			_song.lyrics = value
		"COURSE":
			# 切换到难度定义状态
			_state = ParseState.COURSE
			_current_course = TJAData.TJACourse.new()
			_current_course.course_type = TJAData.string_to_course_type(value)
		"START":
			# 直接开始谱面（无COURSE定义）
			_state = ParseState.NOTES
			_current_course = TJAData.TJACourse.new()
			_measure_index = 0
	
	return true

## 解析难度定义行
func _parse_course_line(line: String) -> bool:
	var colon_pos = line.find(":")
	if colon_pos == -1:
		# 检查是否为命令
		if line.begins_with("#"):
			return _parse_command(line)
		return true
	
	var key = line.left(colon_pos).to_upper()
	var value = line.substr(colon_pos + 1).strip_edges()
	
	match key:
		"LEVEL":
			_current_course.level = _parse_int(value, 5)
		"BALLOON":
			_current_course.balloons = _parse_balloon_list(value)
		"SCOREINIT":
			_current_course.score_init = _parse_int(value, 1000)
		"SCOREDIFF":
			_current_course.score_diff = _parse_int(value, 100)
		"STYLE":
			_current_course.style = value
		"START":
			# 开始谱面数据
			_state = ParseState.NOTES
			_measure_index = 0
		"COURSE":
			# 新难度定义，保存当前难度
			if _current_course != null and _current_course.measures.size() > 0:
				_song.add_course(_current_course)
			_current_course = TJAData.TJACourse.new()
			_current_course.course_type = TJAData.string_to_course_type(value)
	
	return true

## 解析谱面数据行
func _parse_notes_line(line: String) -> bool:
	# 检查命令
	if line.begins_with("#"):
		return _parse_command(line)
	
	# 解析音符数据
	return _parse_notes_data(line)

## 解析音符数据
func _parse_notes_data(line: String) -> bool:
	if _current_course == null:
		_error = "谱面数据在难度定义之外"
		return false

	# 创建新小节
	var measure = TJAData.TJAMeasure.new(_measure_index)
	measure.bpm = _current_bpm
	measure.scroll = _current_scroll
	measure.time_signature = _current_measure
	measure.show_barline = _show_barline
	measure.is_gogo = _is_gogo
	measure.branch = _current_branch

	# 解析音符
	var note_chars = line.split("")
	var note_count = 0
	
	# 计算有效音符数量（排除逗号）
	var total_notes = 0
	for char in note_chars:
		if char != ",":
			total_notes += 1

	for i in range(note_chars.size()):
		var char = note_chars[i]

		# 跳过逗号（小节分隔符）
		if char == ",":
			continue

		# 解析音符类型
		var note_type = TJAData.char_to_note_type(char)
		var note = TJAData.TJANote.new()
		note.note_type = note_type
		note.position = float(note_count) / float(max(total_notes, 1))
		note.raw_char = char

		# 处理连打
		if _in_renda:
			if note_type == TJAData.NoteType.END:
				# 连打结束
				_in_renda = false
				_renda_count = 0
				_renda_type = TJAData.NoteType.NONE
			else:
				# 连打中的音符计数
				_renda_count += 1
		else:
			# 检查是否开始连打
			if note_type in [TJAData.NoteType.RENDA, TJAData.NoteType.RENDA_BIG]:
				_in_renda = true
				_renda_type = note_type
				_renda_count = 0
			elif note_type == TJAData.NoteType.BALLOON:
				# 气球音符
				if _balloon_index < _current_course.balloons.size():
					note.balloon_hits = _current_course.balloons[_balloon_index]
					_balloon_index += 1
				_in_renda = true
				_renda_type = note_type
				_renda_count = 0
			elif note_type == TJAData.NoteType.KUSUDAMA:
				# 久寿玉
				if _balloon_index < _current_course.balloons.size():
					note.balloon_hits = _current_course.balloons[_balloon_index]
					_balloon_index += 1
				_in_renda = true
				_renda_type = note_type
				_renda_count = 0

		# 添加音符到小节
		if note_type != TJAData.NoteType.NONE or char == "0":
			measure.add_note(note)
			note_count += 1

	# 根据当前分支状态存储小节
	match _state:
		ParseState.BRANCH_N:
			_branch_measures_n.append(measure)
		ParseState.BRANCH_E:
			_branch_measures_e.append(measure)
		ParseState.BRANCH_M:
			_branch_measures_m.append(measure)
		_:
			# 非分支状态，添加到主小节列表
			_current_course.add_measure(measure)
	
	_measure_index += 1

	return true

## 解析命令
func _parse_command(line: String) -> bool:
	# 移除#号
	var cmd = line.substr(1).to_upper()
	
	# 解析命令和参数
	var space_pos = cmd.find(" ")
	var cmd_name: String
	var cmd_params: String
	
	if space_pos != -1:
		cmd_name = cmd.left(space_pos)
		cmd_params = cmd.substr(space_pos + 1).strip_edges()
	else:
		cmd_name = cmd
		cmd_params = ""
	
	# 处理命令
	match cmd_name:
		"START":
			# 如果没有当前课程，创建一个默认课程
			if _current_course == null:
				_current_course = TJAData.TJACourse.new()
			_state = ParseState.NOTES
			_measure_index = 0
		"END":
			# 结束当前难度
			if _current_course != null:
				_song.add_course(_current_course)
				_current_course = null
			_state = ParseState.HEADER
		"MEASURE":
			# 拍号变化
			var parts = cmd_params.split("/")
			if parts.size() == 2:
				_current_measure = Vector2(
					_parse_float(parts[0], 4.0),
					_parse_float(parts[1], 4.0)
				)
		"BPMCHANGE":
			# BPM变化
			_current_bpm = _parse_float(cmd_params, _current_bpm)
		"DELAY":
			# 时间偏移（暂不处理）
			pass
		"SCROLL":
			# 滚动速度
			_current_scroll = _parse_float(cmd_params, 1.0)
		"GOGOSTART":
			# Go-Go Time开始
			_is_gogo = true
		"GOGOEND":
			# Go-Go Time结束
			_is_gogo = false
		"BARLINEOFF":
			# 隐藏小节线
			_show_barline = false
		"BARLINEON":
			# 显示小节线
			_show_barline = true
		"BRANCHSTART":
			# 分支开始
			_current_course.has_branch = true
			var parts = cmd_params.split(",")
			if parts.size() >= 3:
				var condition_type = _parse_int(parts[0], 0)
				var normal_threshold = _parse_float(parts[1], 0.0)
				var expert_threshold = _parse_float(parts[2], 0.0)
				
				# 创建分支条件对象
				_current_branch_condition = TJAData.BranchCondition.new()
				_current_branch_condition.condition_type = condition_type as TJAData.BranchConditionType
				_current_branch_condition.normal_threshold = normal_threshold
				_current_branch_condition.expert_threshold = expert_threshold
				
				# 保存阈值用于兼容
				_branch_condition = [normal_threshold, expert_threshold]
				
				# 清空分支小节临时存储
				_branch_measures_n = []
				_branch_measures_e = []
				_branch_measures_m = []
		"N":
			# 普通分支
			_state = ParseState.BRANCH_N
			_current_branch = TJAData.BranchType.NORMAL
		"E":
			# 高级分支
			_state = ParseState.BRANCH_E
			_current_branch = TJAData.BranchType.EXPERT
		"M":
			# 大师分支
			_state = ParseState.BRANCH_M
			_current_branch = TJAData.BranchType.MASTER
		"BRANCHEND":
			# 分支结束
			_state = ParseState.NOTES
			_current_branch = TJAData.BranchType.NORMAL
			
			# 保存分支小节数据到课程
			if _current_branch_condition != null:
				_current_course.add_branch_condition(_current_branch_condition)
				_current_course.set_branch_measures(TJAData.BranchType.NORMAL, _branch_measures_n.duplicate())
				_current_course.set_branch_measures(TJAData.BranchType.EXPERT, _branch_measures_e.duplicate())
				_current_course.set_branch_measures(TJAData.BranchType.MASTER, _branch_measures_m.duplicate())
				_current_branch_condition = null
		"SECTION":
			# 重置分支判定
			_branch_condition = []
		"LYRIC":
			# 歌词显示（暂不处理）
			pass
	
	return true

## 解析浮点数
func _parse_float(value: String, default: float) -> float:
	var result = value.to_float()
	if result == 0.0 and value != "0" and value != "0.0":
		return default
	return result

## 解析整数
func _parse_int(value: String, default: int) -> int:
	var result = value.to_int()
	if result == 0 and value != "0":
		return default
	return result

## 解析气球列表
func _parse_balloon_list(value: String) -> Array[int]:
	var result: Array[int] = []
	var parts = value.split(",")
	for part in parts:
		var num = part.strip_edges().to_int()
		if num > 0:
			result.append(num)
	return result

## 验证歌曲数据
func _validate_song() -> bool:
	if _song.title.is_empty():
		_error = "缺少歌曲标题"
		return false
	
	if _song.bpm <= 0:
		_error = "无效的BPM值"
		return false
	
	if _song.courses.is_empty():
		_error = "没有定义任何难度"
		return false
	
	return true

## 获取解析错误信息
func get_error() -> String:
	return _error

## 获取错误行号
func get_error_line() -> int:
	return _error_line