class_name TJAData
## TJA数据结构定义
## 定义TJA格式谱面所需的所有数据结构

## 音符类型枚举
enum NoteType {
	NONE = 0,       ## 空白
	DON = 1,        ## 小红音符
	KA = 2,         ## 小蓝音符
	DON_BIG = 3,    ## 大红音符
	KA_BIG = 4,     ## 大蓝音符
	RENDA = 5,      ## 普通连打
	RENDA_BIG = 6,  ## 大连打
	BALLOON = 7,    ## 气球音符
	END = 8,        ## 连打/气球结束标记
	KUSUDAMA = 9,   ## 久寿玉
	DON_DOUBLE = 10, ## 双人合作大红音符 (A)
	KA_DOUBLE = 11, ## 双人合作大蓝音符 (B)
	BOMB = 12,      ## 炸弹音符 (C)
	ADLIB = 13,     ## AD-LIB隐藏音符 (F)
	SWAP = 14       ## 交换音符 (G)
}

## 难度类型枚举
enum CourseType {
	EASY = 0,    ## 简单
	NORMAL = 1,  ## 普通
	HARD = 2,    ## 困难
	ONI = 3,     ## 鬼
	EDIT = 4,    ## 编辑
	TOWER = 5,   ## 塔
	DAN = 6      ## 段位
}

## 分支类型枚举
enum BranchType {
	NORMAL = 0,  ## 普通分支
	EXPERT = 1,  ## 高级分支
	MASTER = 2   ## 大师分支
}

## 分支条件类型枚举
enum BranchConditionType {
	ACCURACY = 0,    ## 准确率判定
	RENDA = 1,       ## 连打次数判定
	SCORE = 2        ## 分数判定
}

## 分支条件数据类
class BranchCondition:
	## 条件类型
	var condition_type: BranchConditionType = BranchConditionType.ACCURACY
	## 普通分支阈值（低于此值进入普通分支）
	var normal_threshold: float = 0.0
	## 高级分支阈值（低于此值进入高级分支，高于则进入大师分支）
	var expert_threshold: float = 0.0
	## 条件触发时间点
	var trigger_time: float = 0.0
	## 是否已判定
	var is_judged: bool = false
	## 判定结果
	var result_branch: BranchType = BranchType.NORMAL

	func _init(p_type: BranchConditionType = BranchConditionType.ACCURACY) -> void:
		condition_type = p_type

	## 根据当前值判定分支
	func evaluate(current_value: float) -> BranchType:
		if current_value >= expert_threshold:
			result_branch = BranchType.MASTER
		elif current_value >= normal_threshold:
			result_branch = BranchType.EXPERT
		else:
			result_branch = BranchType.NORMAL
		is_judged = true
		return result_branch

## 音符数据类
class TJANote:
	## 音符类型
	var note_type: NoteType = NoteType.NONE
	## 在小节中的位置（0-1）
	var position: float = 0.0
	## 气球打击次数（仅对气球和久寿玉有效）
	var balloon_hits: int = 0
	## 连打次数（仅对连打有效）
	var renda_count: int = 0
	## 原始字符
	var raw_char: String = ""
	
	func _init(p_type: NoteType = NoteType.NONE, p_position: float = 0.0) -> void:
		note_type = p_type
		position = p_position
	
	## 是否为可打击音符
	func is_hittable() -> bool:
		return note_type in [
			NoteType.DON, NoteType.KA, NoteType.DON_BIG, NoteType.KA_BIG,
			NoteType.RENDA, NoteType.RENDA_BIG, NoteType.BALLOON, NoteType.KUSUDAMA,
			NoteType.DON_DOUBLE, NoteType.KA_DOUBLE, NoteType.ADLIB
		]
	
	## 是否为连打类型
	func is_renda() -> bool:
		return note_type in [NoteType.RENDA, NoteType.RENDA_BIG, NoteType.BALLOON, NoteType.KUSUDAMA]
	
	## 是否为大音符
	func is_big() -> bool:
		return note_type in [NoteType.DON_BIG, NoteType.KA_BIG, NoteType.RENDA_BIG, NoteType.DON_DOUBLE, NoteType.KA_DOUBLE]

## 命令数据类
class TJACommand:
	## 命令类型枚举
	enum CommandType {
		MEASURE,      ## #MEASURE 拍号变化
		BPMCHANGE,    ## #BPMCHANGE BPM变化
		DELAY,        ## #DELAY 时间偏移
		SCROLL,      ## #SCROLL 滚动速度
		GOGOSTART,   ## #GOGOSTART Go-Go Time开始
		GOGOEND,     ## #GOGOEND Go-Go Time结束
		BARLINEOFF,  ## #BARLINEOFF 隐藏小节线
		BARLINEON,   ## #BARLINEON 显示小节线
		BRANCHSTART, ## #BRANCHSTART 分支开始
		BRANCHEND,   ## #BRANCHEND 分支结束
		SECTION,     ## #SECTION 重置分支判定
		LYRIC,       ## #LYRIC 歌词显示
		N,           ## #N 普通分支
		E,           ## #E 高级分支
		M,           ## #M 大师分支
		START,       ## #START 谱面开始
		END          ## #END 谱面结束
	}
	
	## 命令类型
	var command_type: CommandType
	## 命令参数
	var params: Array = []
	## 命令所在位置（小节索引）
	var measure_index: int = 0
	## 命令所在位置（小节内位置）
	var position: float = 0.0
	
	func _init(p_type: CommandType, p_params: Array = []) -> void:
		command_type = p_type
		params = p_params

## 小节数据类
class TJAMeasure:
	## 小节索引
	var index: int = 0
	## 音符列表
	var notes: Array[TJANote] = []
	## 命令列表
	var commands: Array[TJACommand] = []
	## 拍号（分子/分母）
	var time_signature: Vector2 = Vector2(4.0, 4.0)
	## BPM
	var bpm: float = 120.0
	## 滚动速度
	var scroll: float = 1.0
	## 是否显示小节线
	var show_barline: bool = true
	## 是否为Go-Go Time
	var is_gogo: bool = false
	## 分支类型（用于分支谱面）
	var branch: BranchType = BranchType.NORMAL
	
	func _init(p_index: int = 0) -> void:
		index = p_index
	
	## 添加音符
	func add_note(note: TJANote) -> void:
		notes.append(note)
	
	## 添加命令
	func add_command(command: TJACommand) -> void:
		commands.append(command)
	
	## 获取小节时长（秒）
	func get_duration() -> float:
		if bpm <= 0:
			return 0.0
		var beats_per_measure = time_signature.x / time_signature.y * 4.0
		return 60.0 / bpm * beats_per_measure

## 难度数据类
class TJACourse:
	## 难度类型
	var course_type: CourseType = CourseType.ONI
	## 难度星级（1-10）
	var level: int = 5
	## 气球音符打击次数列表
	var balloons: Array[int] = []
	## 计分初始值
	var score_init: int = 1000
	## 计分差值
	var score_diff: int = 100
	## 样式（单人/双人）
	var style: String = "Single"
	## 小节数据列表
	var measures: Array[TJAMeasure] = []
	## 分支谱面数据
	var branches: Dictionary = {
		BranchType.NORMAL: [],   ## 普通分支小节
		BranchType.EXPERT: [],   ## 高级分支小节
		BranchType.MASTER: []    ## 大师分支小节
	}
	## 是否有分支
	var has_branch: bool = false
	## 分支条件列表
	var branch_conditions: Array[BranchCondition] = []
	## 当前分支
	var current_branch: BranchType = BranchType.NORMAL

	func _init(p_type: CourseType = CourseType.ONI) -> void:
		course_type = p_type

	## 添加小节
	func add_measure(measure: TJAMeasure) -> void:
		measures.append(measure)

	## 添加分支条件
	func add_branch_condition(condition: BranchCondition) -> void:
		branch_conditions.append(condition)

	## 获取总音符数
	func get_total_notes() -> int:
		var count: int = 0
		for measure in measures:
			for note in measure.notes:
				if note.is_hittable():
					count += 1
		return count

	## 获取总时长（秒）
	func get_total_duration() -> float:
		var duration: float = 0.0
		for measure in measures:
			duration += measure.get_duration()
		return duration

	## 获取指定分支的小节数据
	func get_branch_measures(branch: BranchType) -> Array:
		return branches.get(branch, [])

	## 设置分支小节数据
	func set_branch_measures(branch: BranchType, branch_measures: Array) -> void:
		branches[branch] = branch_measures

## 歌曲元数据类
class TJASong:
	## 歌曲标题
	var title: String = ""
	## 英文标题
	var title_en: String = ""
	## 副标题
	var subtitle: String = ""
	## 初始BPM
	var bpm: float = 120.0
	## 音频文件路径
	var wave: String = ""
	## 谱面偏移（秒）
	var offset: float = 0.0
	## 预览开始时间
	var demo_start: float = 0.0
	## 歌曲类型
	var genre: String = ""
	## 计分模式
	var score_mode: int = 0
	## 谱面作者
	var maker: String = ""
	## 歌词文件路径
	var lyrics: String = ""
	## 难度数据字典
	var courses: Dictionary = {}
	## 原始文件路径
	var file_path: String = ""
	## 解析是否成功
	var is_valid: bool = true
	## 解析错误信息
	var error_message: String = ""
	
	## 添加难度
	func add_course(course: TJACourse) -> void:
		courses[course.course_type] = course
	
	## 获取难度
	func get_course(type: CourseType) -> TJACourse:
		return courses.get(type, null)
	
	## 获取所有难度
	func get_all_courses() -> Array:
		return courses.values()
	
	## 获取歌曲显示名称
	func get_display_name() -> String:
		if title_en != "":
			return title_en
		return title

	## 获取歌曲文件所在目录
	func get_base_dir() -> String:
		if file_path.is_empty():
			return ""
		return file_path.get_base_dir()

## 解析结果类
class TJAParseResult:
	## 是否成功
	var success: bool = true
	## 错误信息
	var error: String = ""
	## 错误行号
	var error_line: int = 0
	## 解析的歌曲数据
	var song: TJASong = null
	
	func _init(p_success: bool = true, p_error: String = "") -> void:
		success = p_success
		error = p_error

## 静态工具方法
## 将字符串转换为音符类型
static func char_to_note_type(char: String) -> NoteType:
	match char:
		"0": return NoteType.NONE
		"1": return NoteType.DON
		"2": return NoteType.KA
		"3": return NoteType.DON_BIG
		"4": return NoteType.KA_BIG
		"5": return NoteType.RENDA
		"6": return NoteType.RENDA_BIG
		"7": return NoteType.BALLOON
		"8": return NoteType.END
		"9": return NoteType.KUSUDAMA
		"A", "a": return NoteType.DON_DOUBLE
		"B", "b": return NoteType.KA_DOUBLE
		"C", "c": return NoteType.BOMB
		"F", "f": return NoteType.ADLIB
		"G", "g": return NoteType.SWAP
		_: return NoteType.NONE

## 将字符串转换为难度类型
static func string_to_course_type(str: String) -> CourseType:
	var normalized = str.to_lower().strip_edges()
	match normalized:
		"easy": return CourseType.EASY
		"normal": return CourseType.NORMAL
		"hard": return CourseType.HARD
		"oni": return CourseType.ONI
		"edit": return CourseType.EDIT
		"tower": return CourseType.TOWER
		"dan": return CourseType.DAN
		_: return CourseType.ONI

## 将难度类型转换为字符串
static func course_type_to_string(type: CourseType) -> String:
	match type:
		CourseType.EASY: return "Easy"
		CourseType.NORMAL: return "Normal"
		CourseType.HARD: return "Hard"
		CourseType.ONI: return "Oni"
		CourseType.EDIT: return "Edit"
		CourseType.TOWER: return "Tower"
		CourseType.DAN: return "Dan"
		_: return "Oni"