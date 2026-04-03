## TJA数据结构单元测试
## 测试 TJAData 的数据类、枚举、静态方法
## 测试框架：GUT v9.6.0

extends GutTest

const TJAData = preload("res://src/parser/tja_data.gd")


func before_all() -> void:
	pass


func before_each() -> void:
	pass


func after_each() -> void:
	pass


func after_all() -> void:
	pass


# =============================================================================
# 枚举测试
# =============================================================================

# =============================================================================
# DATA-001: 音符类型枚举
# 测试 NoteType 枚举值
# =============================================================================
func test_data_001_note_type_enum() -> void:
	assert_eq(TJAData.NoteType.NONE, 0, "NONE应为0")
	assert_eq(TJAData.NoteType.DON, 1, "DON应为1")
	assert_eq(TJAData.NoteType.KA, 2, "KA应为2")
	assert_eq(TJAData.NoteType.DON_BIG, 3, "DON_BIG应为3")
	assert_eq(TJAData.NoteType.KA_BIG, 4, "KA_BIG应为4")
	assert_eq(TJAData.NoteType.RENDA, 5, "RENDA应为5")
	assert_eq(TJAData.NoteType.RENDA_BIG, 6, "RENDA_BIG应为6")
	assert_eq(TJAData.NoteType.BALLOON, 7, "BALLOON应为7")
	assert_eq(TJAData.NoteType.END, 8, "END应为8")
	assert_eq(TJAData.NoteType.KUSUDAMA, 9, "KUSUDAMA应为9")
	assert_eq(TJAData.NoteType.DON_DOUBLE, 10, "DON_DOUBLE应为10")
	assert_eq(TJAData.NoteType.KA_DOUBLE, 11, "KA_DOUBLE应为11")
	assert_eq(TJAData.NoteType.BOMB, 12, "BOMB应为12")
	assert_eq(TJAData.NoteType.ADLIB, 13, "ADLIB应为13")
	assert_eq(TJAData.NoteType.SWAP, 14, "SWAP应为14")


# =============================================================================
# DATA-002: 难度类型枚举
# 测试 CourseType 枚举值
# =============================================================================
func test_data_002_course_type_enum() -> void:
	assert_eq(TJAData.CourseType.EASY, 0, "EASY应为0")
	assert_eq(TJAData.CourseType.NORMAL, 1, "NORMAL应为1")
	assert_eq(TJAData.CourseType.HARD, 2, "HARD应为2")
	assert_eq(TJAData.CourseType.ONI, 3, "ONI应为3")
	assert_eq(TJAData.CourseType.EDIT, 4, "EDIT应为4")
	assert_eq(TJAData.CourseType.TOWER, 5, "TOWER应为5")
	assert_eq(TJAData.CourseType.DAN, 6, "DAN应为6")


# =============================================================================
# DATA-003: 分支类型枚举
# 测试 BranchType 枚举值
# =============================================================================
func test_data_003_branch_type_enum() -> void:
	assert_eq(TJAData.BranchType.NORMAL, 0, "NORMAL应为0")
	assert_eq(TJAData.BranchType.EXPERT, 1, "EXPERT应为1")
	assert_eq(TJAData.BranchType.MASTER, 2, "MASTER应为2")


# =============================================================================
# DATA-004: 分支条件类型枚举
# 测试 BranchConditionType 枚举值
# =============================================================================
func test_data_004_branch_condition_type_enum() -> void:
	assert_eq(TJAData.BranchConditionType.ACCURACY, 0, "ACCURACY应为0")
	assert_eq(TJAData.BranchConditionType.RENDA, 1, "RENDA应为1")
	assert_eq(TJAData.BranchConditionType.SCORE, 2, "SCORE应为2")


# =============================================================================
# TJANote 类测试
# =============================================================================

# =============================================================================
# DATA-005: TJANote 初始化
# 测试 TJANote 类初始化
# =============================================================================
func test_data_005_tja_note_initialization() -> void:
	var note = TJAData.TJANote.new()

	assert_eq(note.note_type, TJAData.NoteType.NONE, "默认音符类型应为NONE")
	assert_eq(note.position, 0.0, "默认位置应为0.0")
	assert_eq(note.balloon_hits, 0, "默认气球打击数应为0")
	assert_eq(note.renda_count, 0, "默认连打数应为0")
	assert_eq(note.raw_char, "", "默认原始字符应为空")


# =============================================================================
# DATA-006: TJANote 带参数初始化
# 测试 TJANote 带参数初始化
# =============================================================================
func test_data_006_tja_note_with_params() -> void:
	var note = TJAData.TJANote.new(TJAData.NoteType.DON_BIG, 0.5)

	assert_eq(note.note_type, TJAData.NoteType.DON_BIG, "音符类型应为DON_BIG")
	assert_eq(note.position, 0.5, "位置应为0.5")


# =============================================================================
# DATA-007: TJANote is_hittable 方法
# 测试 is_hittable 方法
# =============================================================================
func test_data_007_tja_note_is_hittable() -> void:
	# 可打击音符
	var hittable_types = [
		TJAData.NoteType.DON, TJAData.NoteType.KA,
		TJAData.NoteType.DON_BIG, TJAData.NoteType.KA_BIG,
		TJAData.NoteType.RENDA, TJAData.NoteType.RENDA_BIG,
		TJAData.NoteType.BALLOON, TJAData.NoteType.KUSUDAMA,
		TJAData.NoteType.DON_DOUBLE, TJAData.NoteType.KA_DOUBLE,
		TJAData.NoteType.ADLIB
	]

	for note_type in hittable_types:
		var note = TJAData.TJANote.new(note_type)
		assert_true(note.is_hittable(), TJAData.NoteType.keys()[note_type] + " 应为可打击")

	# 不可打击音符
	var non_hittable_types = [
		TJAData.NoteType.NONE, TJAData.NoteType.END,
		TJAData.NoteType.BOMB, TJAData.NoteType.SWAP
	]

	for note_type in non_hittable_types:
		var note = TJAData.TJANote.new(note_type)
		assert_false(note.is_hittable(), TJAData.NoteType.keys()[note_type] + " 不应为可打击")


# =============================================================================
# DATA-008: TJANote is_renda 方法
# 测试 is_renda 方法
# =============================================================================
func test_data_008_tja_note_is_renda() -> void:
	# 连打类型
	var renda_types = [
		TJAData.NoteType.RENDA, TJAData.NoteType.RENDA_BIG,
		TJAData.NoteType.BALLOON, TJAData.NoteType.KUSUDAMA
	]

	for note_type in renda_types:
		var note = TJAData.TJANote.new(note_type)
		assert_true(note.is_renda(), TJAData.NoteType.keys()[note_type] + " 应为连打")

	# 非连打类型
	var non_renda_types = [
		TJAData.NoteType.DON, TJAData.NoteType.KA,
		TJAData.NoteType.DON_BIG, TJAData.NoteType.KA_BIG,
		TJAData.NoteType.NONE, TJAData.NoteType.END
	]

	for note_type in non_renda_types:
		var note = TJAData.TJANote.new(note_type)
		assert_false(note.is_renda(), TJAData.NoteType.keys()[note_type] + " 不应为连打")


# =============================================================================
# DATA-009: TJANote is_big 方法
# 测试 is_big 方法
# =============================================================================
func test_data_009_tja_note_is_big() -> void:
	# 大音符类型
	var big_types = [
		TJAData.NoteType.DON_BIG, TJAData.NoteType.KA_BIG,
		TJAData.NoteType.RENDA_BIG, TJAData.NoteType.DON_DOUBLE,
		TJAData.NoteType.KA_DOUBLE
	]

	for note_type in big_types:
		var note = TJAData.TJANote.new(note_type)
		assert_true(note.is_big(), TJAData.NoteType.keys()[note_type] + " 应为大音符")

	# 非大音符类型
	var small_types = [
		TJAData.NoteType.DON, TJAData.NoteType.KA,
		TJAData.NoteType.RENDA, TJAData.NoteType.BALLOON,
		TJAData.NoteType.KUSUDAMA, TJAData.NoteType.NONE
	]

	for note_type in small_types:
		var note = TJAData.TJANote.new(note_type)
		assert_false(note.is_big(), TJAData.NoteType.keys()[note_type] + " 不应为大音符")


# =============================================================================
# TJAMeasure 类测试
# =============================================================================

# =============================================================================
# DATA-010: TJAMeasure 初始化
# 测试 TJAMeasure 类初始化
# =============================================================================
func test_data_010_tja_measure_initialization() -> void:
	var measure = TJAData.TJAMeasure.new()

	assert_eq(measure.index, 0, "默认索引应为0")
	assert_eq(measure.notes.size(), 0, "默认音符列表应为空")
	assert_eq(measure.commands.size(), 0, "默认命令列表应为空")
	assert_eq(measure.time_signature, Vector2(4.0, 4.0), "默认拍号应为4/4")
	assert_eq(measure.bpm, 120.0, "默认BPM应为120")
	assert_eq(measure.scroll, 1.0, "默认滚动速度应为1.0")
	assert_true(measure.show_barline, "默认应显示小节线")
	assert_false(measure.is_gogo, "默认不应为Go-Go Time")


# =============================================================================
# DATA-011: TJAMeasure 带索引初始化
# 测试 TJAMeasure 带索引初始化
# =============================================================================
func test_data_011_tja_measure_with_index() -> void:
	var measure = TJAData.TJAMeasure.new(5)

	assert_eq(measure.index, 5, "索引应为5")


# =============================================================================
# DATA-012: TJAMeasure 添加音符
# 测试 add_note 方法
# =============================================================================
func test_data_012_tja_measure_add_note() -> void:
	var measure = TJAData.TJAMeasure.new()
	var note = TJAData.TJANote.new(TJAData.NoteType.DON)

	measure.add_note(note)

	assert_eq(measure.notes.size(), 1, "应有1个音符")
	assert_eq(measure.notes[0].note_type, TJAData.NoteType.DON, "音符类型应为DON")


# =============================================================================
# DATA-013: TJAMeasure 添加命令
# 测试 add_command 方法
# =============================================================================
func test_data_013_tja_measure_add_command() -> void:
	var measure = TJAData.TJAMeasure.new()
	var command = TJAData.TJACommand.new(TJAData.TJACommand.CommandType.BPMCHANGE, [150.0])

	measure.add_command(command)

	assert_eq(measure.commands.size(), 1, "应有1个命令")
	assert_eq(measure.commands[0].command_type, TJAData.TJACommand.CommandType.BPMCHANGE, "命令类型应为BPMCHANGE")


# =============================================================================
# DATA-014: TJAMeasure 获取时长
# 测试 get_duration 方法
# =============================================================================
func test_data_014_tja_measure_get_duration() -> void:
	var measure = TJAData.TJAMeasure.new()
	measure.bpm = 120.0
	measure.time_signature = Vector2(4.0, 4.0)

	var duration = measure.get_duration()

	# 4/4拍，BPM=120，每拍0.5秒，一小节2秒
	assert_almost_eq(duration, 2.0, 0.01, "4/4拍BPM=120时长应为2秒")


# =============================================================================
# DATA-015: TJAMeasure 获取时长-不同拍号
# 测试不同拍号的时长计算
# =============================================================================
func test_data_015_tja_measure_duration_different_time() -> void:
	var measure = TJAData.TJAMeasure.new()
	measure.bpm = 120.0
	measure.time_signature = Vector2(3.0, 4.0)  # 3/4拍

	var duration = measure.get_duration()

	# 3/4拍，BPM=120，每拍0.5秒，一小节1.5秒
	assert_almost_eq(duration, 1.5, 0.01, "3/4拍BPM=120时长应为1.5秒")


# =============================================================================
# DATA-016: TJAMeasure 获取时长-零BPM
# 测试零BPM时的时长计算
# =============================================================================
func test_data_016_tja_measure_duration_zero_bpm() -> void:
	var measure = TJAData.TJAMeasure.new()
	measure.bpm = 0.0

	var duration = measure.get_duration()

	assert_eq(duration, 0.0, "零BPM时长应为0")


# =============================================================================
# TJACourse 类测试
# =============================================================================

# =============================================================================
# DATA-017: TJACourse 初始化
# 测试 TJACourse 类初始化
# =============================================================================
func test_data_017_tja_course_initialization() -> void:
	var course = TJAData.TJACourse.new()

	assert_eq(course.course_type, TJAData.CourseType.ONI, "默认难度应为ONI")
	assert_eq(course.level, 5, "默认星级应为5")
	assert_eq(course.balloons.size(), 0, "默认气球列表应为空")
	assert_eq(course.score_init, 1000, "默认计分初始值应为1000")
	assert_eq(course.score_diff, 100, "默认计分差值应为100")
	assert_eq(course.style, "Single", "默认样式应为Single")
	assert_eq(course.measures.size(), 0, "默认小节列表应为空")
	assert_false(course.has_branch, "默认无分支")


# =============================================================================
# DATA-018: TJACourse 带类型初始化
# 测试 TJACourse 带类型初始化
# =============================================================================
func test_data_018_tja_course_with_type() -> void:
	var course = TJAData.TJACourse.new(TJAData.CourseType.HARD)

	assert_eq(course.course_type, TJAData.CourseType.HARD, "难度应为HARD")


# =============================================================================
# DATA-019: TJACourse 添加小节
# 测试 add_measure 方法
# =============================================================================
func test_data_019_tja_course_add_measure() -> void:
	var course = TJAData.TJACourse.new()
	var measure = TJAData.TJAMeasure.new(0)

	course.add_measure(measure)

	assert_eq(course.measures.size(), 1, "应有1个小节")


# =============================================================================
# DATA-020: TJACourse 获取总音符数
# 测试 get_total_notes 方法
# =============================================================================
func test_data_020_tja_course_get_total_notes() -> void:
	var course = TJAData.TJACourse.new()

	# 添加小节和音符
	var measure1 = TJAData.TJAMeasure.new(0)
	measure1.add_note(TJAData.TJANote.new(TJAData.NoteType.DON))
	measure1.add_note(TJAData.TJANote.new(TJAData.NoteType.KA))
	measure1.add_note(TJAData.TJANote.new(TJAData.NoteType.NONE))  # 不计入

	var measure2 = TJAData.TJAMeasure.new(1)
	measure2.add_note(TJAData.TJANote.new(TJAData.NoteType.DON_BIG))

	course.add_measure(measure1)
	course.add_measure(measure2)

	var total = course.get_total_notes()

	assert_eq(total, 3, "应有3个可打击音符")


# =============================================================================
# DATA-021: TJACourse 获取总时长
# 测试 get_total_duration 方法
# =============================================================================
func test_data_021_tja_course_get_total_duration() -> void:
	var course = TJAData.TJACourse.new()

	var measure1 = TJAData.TJAMeasure.new(0)
	measure1.bpm = 120.0

	var measure2 = TJAData.TJAMeasure.new(1)
	measure2.bpm = 120.0

	course.add_measure(measure1)
	course.add_measure(measure2)

	var duration = course.get_total_duration()

	# 2个小节，每小节2秒
	assert_almost_eq(duration, 4.0, 0.01, "总时长应为4秒")


# =============================================================================
# DATA-022: TJACourse 分支小节数据
# 测试分支小节数据管理
# =============================================================================
func test_data_022_tja_course_branch_measures() -> void:
	var course = TJAData.TJACourse.new()

	var normal_measures = [TJAData.TJAMeasure.new(0)]
	var expert_measures = [TJAData.TJAMeasure.new(1)]
	var master_measures = [TJAData.TJAMeasure.new(2)]

	course.set_branch_measures(TJAData.BranchType.NORMAL, normal_measures)
	course.set_branch_measures(TJAData.BranchType.EXPERT, expert_measures)
	course.set_branch_measures(TJAData.BranchType.MASTER, master_measures)

	assert_eq(course.get_branch_measures(TJAData.BranchType.NORMAL).size(), 1, "普通分支应有1个小节")
	assert_eq(course.get_branch_measures(TJAData.BranchType.EXPERT).size(), 1, "高级分支应有1个小节")
	assert_eq(course.get_branch_measures(TJAData.BranchType.MASTER).size(), 1, "大师分支应有1个小节")


# =============================================================================
# TJASong 类测试
# =============================================================================

# =============================================================================
# DATA-023: TJASong 初始化
# 测试 TJASong 类初始化
# =============================================================================
func test_data_023_tja_song_initialization() -> void:
	var song = TJAData.TJASong.new()

	assert_eq(song.title, "", "默认标题应为空")
	assert_eq(song.title_en, "", "默认英文标题应为空")
	assert_eq(song.subtitle, "", "默认副标题应为空")
	assert_eq(song.bpm, 120.0, "默认BPM应为120")
	assert_eq(song.wave, "", "默认音频文件应为空")
	assert_eq(song.offset, 0.0, "默认偏移应为0")
	assert_eq(song.demo_start, 0.0, "默认预览开始时间应为0")
	assert_eq(song.genre, "", "默认类型应为空")
	assert_eq(song.score_mode, 0, "默认计分模式应为0")
	assert_eq(song.maker, "", "默认作者应为空")
	assert_eq(song.lyrics, "", "默认歌词文件应为空")
	assert_eq(song.courses.size(), 0, "默认难度字典应为空")
	assert_eq(song.file_path, "", "默认文件路径应为空")
	assert_true(song.is_valid, "默认应有效")
	assert_eq(song.error_message, "", "默认错误信息应为空")


# =============================================================================
# DATA-024: TJASong 添加难度
# 测试 add_course 方法
# =============================================================================
func test_data_024_tja_song_add_course() -> void:
	var song = TJAData.TJASong.new()
	var course = TJAData.TJACourse.new(TJAData.CourseType.HARD)

	song.add_course(course)

	assert_eq(song.courses.size(), 1, "应有1个难度")
	assert_not_null(song.get_course(TJAData.CourseType.HARD), "应能获取HARD难度")


# =============================================================================
# DATA-025: TJASong 获取难度
# 测试 get_course 方法
# =============================================================================
func test_data_025_tja_song_get_course() -> void:
	var song = TJAData.TJASong.new()

	# 获取不存在的难度
	var course = song.get_course(TJAData.CourseType.ONI)
	assert_null(course, "不存在的难度应返回null")

	# 添加难度后获取
	song.add_course(TJAData.TJACourse.new(TJAData.CourseType.ONI))
	course = song.get_course(TJAData.CourseType.ONI)
	assert_not_null(course, "存在的难度应返回")


# =============================================================================
# DATA-026: TJASong 获取所有难度
# 测试 get_all_courses 方法
# =============================================================================
func test_data_026_tja_song_get_all_courses() -> void:
	var song = TJAData.TJASong.new()

	song.add_course(TJAData.TJACourse.new(TJAData.CourseType.EASY))
	song.add_course(TJAData.TJACourse.new(TJAData.CourseType.NORMAL))
	song.add_course(TJAData.TJACourse.new(TJAData.CourseType.HARD))

	var courses = song.get_all_courses()

	assert_eq(courses.size(), 3, "应有3个难度")


# =============================================================================
# DATA-027: TJASong 获取显示名称
# 测试 get_display_name 方法
# =============================================================================
func test_data_027_tja_song_get_display_name() -> void:
	var song = TJAData.TJASong.new()

	# 无英文标题时使用日文标题
	song.title = "テスト曲"
	assert_eq(song.get_display_name(), "テスト曲", "无英文标题时应使用日文标题")

	# 有英文标题时使用英文标题
	song.title_en = "Test Song"
	assert_eq(song.get_display_name(), "Test Song", "有英文标题时应使用英文标题")


# =============================================================================
# DATA-028: TJASong 获取基础目录
# 测试 get_base_dir 方法
# =============================================================================
func test_data_028_tja_song_get_base_dir() -> void:
	var song = TJAData.TJASong.new()

	# 无文件路径时
	assert_eq(song.get_base_dir(), "", "无文件路径时应返回空")

	# 有文件路径时
	song.file_path = "res://songs/test/song.tja"
	assert_eq(song.get_base_dir(), "res://songs/test", "应返回文件所在目录")


# =============================================================================
# 静态方法测试
# =============================================================================

# =============================================================================
# DATA-029: char_to_note_type 静态方法
# 测试字符转音符类型
# =============================================================================
func test_data_029_char_to_note_type() -> void:
	assert_eq(TJAData.char_to_note_type("0"), TJAData.NoteType.NONE, "0应为NONE")
	assert_eq(TJAData.char_to_note_type("1"), TJAData.NoteType.DON, "1应为DON")
	assert_eq(TJAData.char_to_note_type("2"), TJAData.NoteType.KA, "2应为KA")
	assert_eq(TJAData.char_to_note_type("3"), TJAData.NoteType.DON_BIG, "3应为DON_BIG")
	assert_eq(TJAData.char_to_note_type("4"), TJAData.NoteType.KA_BIG, "4应为KA_BIG")
	assert_eq(TJAData.char_to_note_type("5"), TJAData.NoteType.RENDA, "5应为RENDA")
	assert_eq(TJAData.char_to_note_type("6"), TJAData.NoteType.RENDA_BIG, "6应为RENDA_BIG")
	assert_eq(TJAData.char_to_note_type("7"), TJAData.NoteType.BALLOON, "7应为BALLOON")
	assert_eq(TJAData.char_to_note_type("8"), TJAData.NoteType.END, "8应为END")
	assert_eq(TJAData.char_to_note_type("9"), TJAData.NoteType.KUSUDAMA, "9应为KUSUDAMA")
	assert_eq(TJAData.char_to_note_type("A"), TJAData.NoteType.DON_DOUBLE, "A应为DON_DOUBLE")
	assert_eq(TJAData.char_to_note_type("a"), TJAData.NoteType.DON_DOUBLE, "a应为DON_DOUBLE")
	assert_eq(TJAData.char_to_note_type("B"), TJAData.NoteType.KA_DOUBLE, "B应为KA_DOUBLE")
	assert_eq(TJAData.char_to_note_type("C"), TJAData.NoteType.BOMB, "C应为BOMB")
	assert_eq(TJAData.char_to_note_type("F"), TJAData.NoteType.ADLIB, "F应为ADLIB")
	assert_eq(TJAData.char_to_note_type("G"), TJAData.NoteType.SWAP, "G应为SWAP")
	assert_eq(TJAData.char_to_note_type("X"), TJAData.NoteType.NONE, "未知字符应为NONE")


# =============================================================================
# DATA-030: string_to_course_type 静态方法
# 测试字符串转难度类型
# =============================================================================
func test_data_030_string_to_course_type() -> void:
	assert_eq(TJAData.string_to_course_type("Easy"), TJAData.CourseType.EASY, "Easy应为EASY")
	assert_eq(TJAData.string_to_course_type("Normal"), TJAData.CourseType.NORMAL, "Normal应为NORMAL")
	assert_eq(TJAData.string_to_course_type("Hard"), TJAData.CourseType.HARD, "Hard应为HARD")
	assert_eq(TJAData.string_to_course_type("Oni"), TJAData.CourseType.ONI, "Oni应为ONI")
	assert_eq(TJAData.string_to_course_type("Edit"), TJAData.CourseType.EDIT, "Edit应为EDIT")
	assert_eq(TJAData.string_to_course_type("Tower"), TJAData.CourseType.TOWER, "Tower应为TOWER")
	assert_eq(TJAData.string_to_course_type("Dan"), TJAData.CourseType.DAN, "Dan应为DAN")
	assert_eq(TJAData.string_to_course_type("Unknown"), TJAData.CourseType.ONI, "未知应为ONI")


# =============================================================================
# DATA-031: course_type_to_string 静态方法
# 测试难度类型转字符串
# =============================================================================
func test_data_031_course_type_to_string() -> void:
	assert_eq(TJAData.course_type_to_string(TJAData.CourseType.EASY), "Easy", "EASY应为Easy")
	assert_eq(TJAData.course_type_to_string(TJAData.CourseType.NORMAL), "Normal", "NORMAL应为Normal")
	assert_eq(TJAData.course_type_to_string(TJAData.CourseType.HARD), "Hard", "HARD应为Hard")
	assert_eq(TJAData.course_type_to_string(TJAData.CourseType.ONI), "Oni", "ONI应为Oni")
	assert_eq(TJAData.course_type_to_string(TJAData.CourseType.EDIT), "Edit", "EDIT应为Edit")
	assert_eq(TJAData.course_type_to_string(TJAData.CourseType.TOWER), "Tower", "TOWER应为Tower")
	assert_eq(TJAData.course_type_to_string(TJAData.CourseType.DAN), "Dan", "DAN应为Dan")


# =============================================================================
# BranchCondition 类测试
# =============================================================================

# =============================================================================
# DATA-032: BranchCondition 初始化
# 测试 BranchCondition 类初始化
# =============================================================================
func test_data_032_branch_condition_initialization() -> void:
	var condition = TJAData.BranchCondition.new()

	assert_eq(condition.condition_type, TJAData.BranchConditionType.ACCURACY, "默认条件类型应为ACCURACY")
	assert_eq(condition.normal_threshold, 0.0, "默认普通阈值应为0")
	assert_eq(condition.expert_threshold, 0.0, "默认高级阈值应为0")
	assert_eq(condition.trigger_time, 0.0, "默认触发时间应为0")
	assert_false(condition.is_judged, "默认未判定")
	assert_eq(condition.result_branch, TJAData.BranchType.NORMAL, "默认结果分支应为NORMAL")


# =============================================================================
# DATA-033: BranchCondition evaluate 方法
# 测试分支条件判定
# =============================================================================
func test_data_033_branch_condition_evaluate() -> void:
	var condition = TJAData.BranchCondition.new()
	condition.normal_threshold = 60.0
	condition.expert_threshold = 80.0

	# 低于普通阈值
	var result = condition.evaluate(50.0)
	assert_eq(result, TJAData.BranchType.NORMAL, "低于普通阈值应进入普通分支")
	assert_true(condition.is_judged, "应已判定")

	# 重置并测试高级阈值
	condition.is_judged = false
	result = condition.evaluate(70.0)
	assert_eq(result, TJAData.BranchType.EXPERT, "在阈值之间应进入高级分支")

	# 重置并测试大师阈值
	condition.is_judged = false
	result = condition.evaluate(90.0)
	assert_eq(result, TJAData.BranchType.MASTER, "高于高级阈值应进入大师分支")


# =============================================================================
# TJACommand 类测试
# =============================================================================

# =============================================================================
# DATA-034: TJACommand 初始化
# 测试 TJACommand 类初始化
# =============================================================================
func test_data_034_tja_command_initialization() -> void:
	var command = TJAData.TJACommand.new(TJAData.TJACommand.CommandType.BPMCHANGE)

	assert_eq(command.command_type, TJAData.TJACommand.CommandType.BPMCHANGE, "命令类型应为BPMCHANGE")
	assert_eq(command.params.size(), 0, "默认参数应为空")
	assert_eq(command.measure_index, 0, "默认小节索引应为0")
	assert_eq(command.position, 0.0, "默认位置应为0")


# =============================================================================
# DATA-035: TJACommand 带参数初始化
# 测试 TJACommand 带参数初始化
# =============================================================================
func test_data_035_tja_command_with_params() -> void:
	var command = TJAData.TJACommand.new(TJAData.TJACommand.CommandType.BPMCHANGE, [150.0])

	assert_eq(command.params.size(), 1, "应有1个参数")
	assert_eq(command.params[0], 150.0, "参数应为150.0")


# =============================================================================
# TJAParseResult 类测试
# =============================================================================

# =============================================================================
# DATA-036: TJAParseResult 初始化
# 测试 TJAParseResult 类初始化
# =============================================================================
func test_data_036_tja_parse_result_initialization() -> void:
	var result = TJAData.TJAParseResult.new()

	assert_true(result.success, "默认应成功")
	assert_eq(result.error, "", "默认错误信息应为空")
	assert_eq(result.error_line, 0, "默认错误行号应为0")
	assert_null(result.song, "默认歌曲数据应为null")


# =============================================================================
# DATA-037: TJAParseResult 失败结果
# 测试 TJAParseResult 失败结果
# =============================================================================
func test_data_037_tja_parse_result_failure() -> void:
	var result = TJAData.TJAParseResult.new(false, "测试错误")

	assert_false(result.success, "应失败")
	assert_eq(result.error, "测试错误", "错误信息应为测试错误")


# =============================================================================
# 附加测试：TJACommand CommandType 枚举
# =============================================================================
func test_tja_command_type_enum() -> void:
	assert_eq(TJAData.TJACommand.CommandType.MEASURE, 0, "MEASURE应为0")
	assert_eq(TJAData.TJACommand.CommandType.BPMCHANGE, 1, "BPMCHANGE应为1")
	assert_eq(TJAData.TJACommand.CommandType.DELAY, 2, "DELAY应为2")
	assert_eq(TJAData.TJACommand.CommandType.SCROLL, 3, "SCROLL应为3")
	assert_eq(TJAData.TJACommand.CommandType.GOGOSTART, 4, "GOGOSTART应为4")
	assert_eq(TJAData.TJACommand.CommandType.GOGOEND, 5, "GOGOEND应为5")


# =============================================================================
# 附加测试：边界值
# =============================================================================
func test_boundary_values() -> void:
	# 测试位置边界
	var note = TJAData.TJANote.new(TJAData.NoteType.DON, 0.0)
	assert_eq(note.position, 0.0, "位置可以为0")

	note = TJAData.TJANote.new(TJAData.NoteType.DON, 1.0)
	assert_eq(note.position, 1.0, "位置可以为1")

	# 测试BPM边界
	var measure = TJAData.TJAMeasure.new()
	measure.bpm = 1.0
	assert_true(measure.get_duration() > 0, "BPM=1时应有时长")

	measure.bpm = 300.0
	assert_true(measure.get_duration() > 0, "BPM=300时应有时长")


# =============================================================================
# 附加测试：大量数据
# =============================================================================
func test_large_data() -> void:
	var course = TJAData.TJACourse.new()

	# 添加大量小节
	for i in range(100):
		var measure = TJAData.TJAMeasure.new(i)
		for j in range(10):
			measure.add_note(TJAData.TJANote.new(TJAData.NoteType.DON))
		course.add_measure(measure)

	assert_eq(course.measures.size(), 100, "应有100个小节")
	assert_eq(course.get_total_notes(), 1000, "应有1000个音符")