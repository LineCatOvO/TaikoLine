class_name EditorData
extends RefCounted
## 编辑器数据结构
## 存储谱面信息、音符列表、命令列表

const TJAData = preload("res://src/parser/tja_data.gd")

## 音符类型定义（15种）
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

## 编辑器音符数据
class EditorNote:
	## 音符类型
	var note_type: NoteType = NoteType.NONE
	## 小节索引
	var measure_index: int = 0
	## 小节内位置 (0.0 - 1.0)
	var position: float = 0.0
	## 气球打击次数
	var balloon_hits: int = 0
	## 是否选中
	var selected: bool = false
	## 唯一ID
	var id: int = 0

	func _init(p_type: NoteType = NoteType.NONE, p_measure: int = 0, p_pos: float = 0.0) -> void:
		note_type = p_type
		measure_index = p_measure
		position = p_pos

	## 获取音符显示字符
	func get_char() -> String:
		match note_type:
			NoteType.NONE: return "0"
			NoteType.DON: return "1"
			NoteType.KA: return "2"
			NoteType.DON_BIG: return "3"
			NoteType.KA_BIG: return "4"
			NoteType.RENDA: return "5"
			NoteType.RENDA_BIG: return "6"
			NoteType.BALLOON: return "7"
			NoteType.END: return "8"
			NoteType.KUSUDAMA: return "9"
			NoteType.DON_DOUBLE: return "A"
			NoteType.KA_DOUBLE: return "B"
			NoteType.BOMB: return "C"
			NoteType.ADLIB: return "F"
			NoteType.SWAP: return "G"
			_: return "0"

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

## 编辑器小节数据
class EditorMeasure:
	## 小节索引
	var index: int = 0
	## 音符列表
	var notes: Array[EditorNote] = []
	## 拍号 (分子/分母)
	var time_signature: Vector2 = Vector2(4.0, 4.0)
	## BPM
	var bpm: float = 120.0
	## 滚动速度
	var scroll: float = 1.0
	## 是否显示小节线
	var show_barline: bool = true
	## 是否为Go-Go Time
	var is_gogo: bool = false

	func _init(p_index: int = 0) -> void:
		index = p_index

	## 添加音符
	func add_note(note: EditorNote) -> void:
		notes.append(note)
		_sort_notes()

	## 移除音符
	func remove_note(note: EditorNote) -> bool:
		var idx = notes.find(note)
		if idx >= 0:
			notes.remove_at(idx)
			return true
		return false

	## 获取指定位置的音符
	func get_note_at_position(pos: float, tolerance: float = 0.05) -> EditorNote:
		for note in notes:
			if abs(note.position - pos) <= tolerance:
				return note
		return null

	## 排序音符
	func _sort_notes() -> void:
		notes.sort_custom(func(a, b): return a.position < b.position)

	## 获取小节时长（秒）
	func get_duration() -> float:
		if bpm <= 0:
			return 0.0
		var beats_per_measure = time_signature.x / time_signature.y * 4.0
		return 60.0 / bpm * beats_per_measure

## 编辑器命令（用于撤销/重做）
class EditorCommand:
	## 命令类型
	enum CommandType {
		ADD_NOTE,
		REMOVE_NOTE,
		MOVE_NOTE,
		CHANGE_NOTE_TYPE,
		ADD_MEASURE,
		REMOVE_MEASURE,
		CHANGE_BPM,
		CHANGE_SCROLL,
		CHANGE_TIME_SIGNATURE,
		TOGGLE_GOGO,
		TOGGLE_BARLINE
	}

	var command_type: CommandType
	var target: Object  ## 目标对象
	var old_value: Variant  ## 旧值
	var new_value: Variant  ## 新值
	var description: String = ""

	func _init(p_type: CommandType, p_target: Object = null, p_old: Variant = null, p_new: Variant = null) -> void:
		command_type = p_type
		target = p_target
		old_value = p_old
		new_value = p_new

## 歌曲元数据
class EditorSongMeta:
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

	func _init() -> void:
		pass

## 编辑器难度数据
class EditorCourse:
	## 难度类型
	var course_type: TJAData.CourseType = TJAData.CourseType.ONI
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
	var measures: Array[EditorMeasure] = []
	## 是否有分支
	var has_branch: bool = false

	func _init(p_type: TJAData.CourseType = TJAData.CourseType.ONI) -> void:
		course_type = p_type
		# 添加初始小节
		add_measure(EditorMeasure.new(0))

	## 添加小节
	func add_measure(measure: EditorMeasure) -> void:
		measures.append(measure)

	## 在指定位置插入小节
	func insert_measure(index: int, measure: EditorMeasure) -> void:
		if index >= 0 and index <= measures.size():
			measures.insert(index, measure)
			_reindex_measures()

	## 移除小节
	func remove_measure(index: int) -> bool:
		if index >= 0 and index < measures.size() and measures.size() > 1:
			measures.remove_at(index)
			_reindex_measures()
			return true
		return false

	## 重新索引小节
	func _reindex_measures() -> void:
		for i in range(measures.size()):
			measures[i].index = i

	## 获取所有音符
	func get_all_notes() -> Array[EditorNote]:
		var all_notes: Array[EditorNote] = []
		for measure in measures:
			all_notes.append_array(measure.notes)
		return all_notes

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

## 编辑器项目数据
class EditorProject:
	## 歌曲元数据
	var song_meta: EditorSongMeta
	## 难度数据字典
	var courses: Dictionary = {}
	## 当前编辑的难度
	var current_course_type: TJAData.CourseType = TJAData.CourseType.ONI
	## 文件路径
	var file_path: String = ""
	## 是否已修改
	var modified: bool = false
	## 下一个音符ID
	var _next_note_id: int = 1

	func _init() -> void:
		song_meta = EditorSongMeta.new()
		# 创建默认难度
		for course_type in [TJAData.CourseType.EASY, TJAData.CourseType.NORMAL, 
							TJAData.CourseType.HARD, TJAData.CourseType.ONI]:
			courses[course_type] = EditorCourse.new(course_type)

	## 获取当前难度
	func get_current_course() -> EditorCourse:
		return courses.get(current_course_type, null)

	## 设置当前难度
	func set_current_course(course_type: TJAData.CourseType) -> void:
		current_course_type = course_type
		if not courses.has(course_type):
			courses[course_type] = EditorCourse.new(course_type)

	## 获取难度
	func get_course(type: TJAData.CourseType) -> EditorCourse:
		if not courses.has(type):
			courses[type] = EditorCourse.new(type)
		return courses[type]

	## 生成新音符ID
	func generate_note_id() -> int:
		_next_note_id += 1
		return _next_note_id - 1

	## 标记已修改
	func mark_modified() -> void:
		modified = true

	## 清除修改标记
	func clear_modified() -> void:
		modified = false

## 静态工具方法

## 将字符转换为音符类型
static func char_to_note_type(char: String) -> NoteType:
	match char.to_upper():
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
		"A": return NoteType.DON_DOUBLE
		"B": return NoteType.KA_DOUBLE
		"C": return NoteType.BOMB
		"F": return NoteType.ADLIB
		"G": return NoteType.SWAP
		_: return NoteType.NONE

## 将音符类型转换为字符
static func note_type_to_char(type: NoteType) -> String:
	match type:
		NoteType.NONE: return "0"
		NoteType.DON: return "1"
		NoteType.KA: return "2"
		NoteType.DON_BIG: return "3"
		NoteType.KA_BIG: return "4"
		NoteType.RENDA: return "5"
		NoteType.RENDA_BIG: return "6"
		NoteType.BALLOON: return "7"
		NoteType.END: return "8"
		NoteType.KUSUDAMA: return "9"
		NoteType.DON_DOUBLE: return "A"
		NoteType.KA_DOUBLE: return "B"
		NoteType.BOMB: return "C"
		NoteType.ADLIB: return "F"
		NoteType.SWAP: return "G"
		_: return "0"

## 获取音符类型名称
static func get_note_type_name(type: NoteType) -> String:
	match type:
		NoteType.NONE: return "空白"
		NoteType.DON: return "Don"
		NoteType.KA: return "Ka"
		NoteType.DON_BIG: return "Big Don"
		NoteType.KA_BIG: return "Big Ka"
		NoteType.RENDA: return "连打"
		NoteType.RENDA_BIG: return "大连打"
		NoteType.BALLOON: return "气球"
		NoteType.END: return "结束"
		NoteType.KUSUDAMA: return "久寿玉"
		NoteType.DON_DOUBLE: return "双人Don"
		NoteType.KA_DOUBLE: return "双人Ka"
		NoteType.BOMB: return "炸弹"
		NoteType.ADLIB: return "AD-LIB"
		NoteType.SWAP: return "交换"
		_: return "未知"

## 获取所有可用音符类型
static func get_all_note_types() -> Array[NoteType]:
	return [
		NoteType.DON,
		NoteType.KA,
		NoteType.DON_BIG,
		NoteType.KA_BIG,
		NoteType.RENDA,
		NoteType.RENDA_BIG,
		NoteType.BALLOON,
		NoteType.KUSUDAMA,
		NoteType.END,
		NoteType.DON_DOUBLE,
		NoteType.KA_DOUBLE,
		NoteType.BOMB,
		NoteType.ADLIB,
		NoteType.SWAP
	]