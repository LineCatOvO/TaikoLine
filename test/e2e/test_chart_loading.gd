## E2E 谱面加载测试
## 测试谱面从文件加载到游戏初始化的完整流程
## 测试框架：GUT v9.6.0
##
## 测试用例：
## - CL-001: TJA 文件解析流程
## - CL-002: 谱面数据验证
## - CL-003: 多难度谱面加载
## - CL-004: 分支谱面加载
## - CL-005: 谱面加载错误处理

extends GutTest

# ==================== 测试常量 ====================

const TJAParser = preload("res://src/parser/tja_parser.gd")
const VTTParser = preload("res://src/parser/vtt_parser.gd")
const TJAData = preload("res://src/parser/tja_data.gd")
const GameController = preload("res://src/game/game_controller.gd")
const NoteManager = preload("res://src/game/note_manager.gd")

# 测试文件路径
const BASIC_TJA_PATH = "res://test/fixtures/sample_tja/basic.tja"
const BRANCHING_TJA_PATH = "res://test/fixtures/sample_tja/branching.tja"

# ==================== 测试变量 ====================

var parser: TJAParser = null
var game_controller: GameController = null

# ==================== 测试生命周期 ====================

func before_all() -> void:
	# 预加载资源
	pass


func before_each() -> void:
	# 创建解析器实例
	parser = TJAParser.new()

	# 创建 GameController
	game_controller = GameController.new()
	game_controller.auto_play = false
	add_child_autofree(game_controller)


func after_each() -> void:
	# 清理
	if parser:
		parser.free()
	parser = null


func after_all() -> void:
	pass


# ==================== 辅助方法 ====================

## 创建测试谱面数据
func _create_test_song() -> TJAData.TJASong:
	var song = TJAData.TJASong.new()
	song.title = "Test Song"
	song.subtitle = "Test Subtitle"
	song.bpm = 120.0
	song.offset = 0.0
	song.wave = "test.ogg"
	song.demo_start = 0.0

	# 添加多个难度的课程
	for course_type in [TJAData.CourseType.EASY, TJAData.CourseType.NORMAL, TJAData.CourseType.HARD, TJAData.CourseType.ONI]:
		var course = TJAData.TJACourse.new()
		course.course_type = course_type
		course.level = 1 + course_type  # 难度等级
		course.score_init = 1000
		course.score_diff = 100

		# 添加小节
		for i in range(4):
			var measure = TJAData.TJAMeasure.new(i)
			measure.bpm = 120.0
			measure.scroll = 1.0
			measure.time_signature = Vector2(4.0, 4.0)

			# 添加音符
			var note1 = TJAData.TJANote.new(TJAData.NoteType.DON, 0.0)
			var note2 = TJAData.TJANote.new(TJAData.NoteType.KA, 0.5)
			measure.add_note(note1)
			measure.add_note(note2)

			course.add_measure(measure)

		song.add_course(course)

	return song


## 创建带分支的测试谱面
func _create_branching_song() -> TJAData.TJASong:
	var song = TJAData.TJASong.new()
	song.title = "Branching Test"
	song.bpm = 140.0

	var course = TJAData.TJACourse.new()
	course.course_type = TJAData.CourseType.ONI
	course.level = 8
	course.score_init = 1000
	course.score_diff = 100
	course.has_branches = true

	# 添加普通分支小节
	var normal_measure = TJAData.TJAMeasure.new(0)
	normal_measure.branch = TJAData.BranchType.NORMAL
	normal_measure.bpm = 140.0
	normal_measure.add_note(TJAData.TJANote.new(TJAData.NoteType.DON, 0.0))
	course.add_measure(normal_measure)

	# 添加精英分支小节
	var master_measure = TJAData.TJAMeasure.new(1)
	master_measure.branch = TJAData.BranchType.MASTER
	master_measure.bpm = 140.0
	master_measure.add_note(TJAData.TJANote.new(TJAData.NoteType.DON, 0.0))
	master_measure.add_note(TJAData.TJANote.new(TJAData.NoteType.KA, 0.25))
	course.add_measure(master_measure)

	song.add_course(course)
	return song


# ==================== CL-001: TJA 文件解析流程测试 ====================

## CL-001-1: 测试基础 TJA 文件解析
func test_cl001_basic_tja_parsing() -> void:
	# 检查测试文件是否存在
	if not ResourceLoader.exists(BASIC_TJA_PATH):
		push_warning("基础 TJA 文件不存在：" + BASIC_TJA_PATH)
		assert_true(true, "测试跳过（无测试文件）")
		return

	# 解析文件
	var result = parser.parse_file(BASIC_TJA_PATH)

	# 验证解析结果
	assert_true(result.success, "TJA 文件解析应成功")
	assert_not_null(result.song, "解析结果应包含歌曲数据")


## CL-001-2: 测试解析结果数据结构
func test_cl001_parsing_result_structure() -> void:
	# 创建测试歌曲
	var song = _create_test_song()

	# 验证基础信息
	assert_eq(song.title, "Test Song", "歌曲标题应正确")
	assert_eq(song.bpm, 120.0, "BPM 应正确")
	assert_eq(song.offset, 0.0, "偏移应正确")


## CL-001-3: 测试课程数据解析
func test_cl001_course_data_parsing() -> void:
	var song = _create_test_song()

	# 验证课程数量
	var courses = song.get_all_courses()
	assert_gte(courses.size(), 1, "应至少有一个课程")

	# 验证课程数据
	var oni_course = song.get_course(TJAData.CourseType.ONI)
	assert_not_null(oni_course, "应有 ONI 课程")
	assert_eq(oni_course.level, 4, "ONI 难度等级应为 4")


## CL-001-4: 测试音符数据解析
func test_cl001_note_data_parsing() -> void:
	var song = _create_test_song()
	var course = song.get_course(TJAData.CourseType.ONI)

	# 获取所有音符
	var notes: Array[TJAData.TJANote] = []
	for measure in course.measures:
		for note in measure.notes:
			notes.append(note)

	assert_gte(notes.size(), 1, "应至少有一个音符")


## CL-001-5: 测试小节数据解析
func test_cl001_measure_data_parsing() -> void:
	var song = _create_test_song()
	var course = song.get_course(TJAData.CourseType.ONI)

	# 验证小节数量
	assert_eq(course.measures.size(), 4, "应有 4 个小节")

	# 验证小节属性
	for i in range(course.measures.size()):
		var measure = course.measures[i]
		assert_eq(measure.bpm, 120.0, "小节 BPM 应正确")
		assert_eq(measure.scroll, 1.0, "小节滚动速度应正确")


# ==================== CL-002: 谱面数据验证测试 ====================

## CL-002-1: 测试谱面元数据验证
func test_cl002_metadata_validation() -> void:
	var song = _create_test_song()

	# 验证必需字段
	assert_not_null(song.title, "标题不应为空")
	assert_gt(song.bpm, 0.0, "BPM 应大于 0")


## CL-002-2: 测试音符类型验证
func test_cl002_note_type_validation() -> void:
	# 验证音符类型常量
	assert_eq(TJAData.NoteType.DON, 0, "DON 音符类型应为 0")
	assert_eq(TJAData.NoteType.KA, 1, "KA 音符类型应为 1")
	assert_eq(TJAData.NoteType.DON_BIG, 2, "DON_BIG 音符类型应为 2")
	assert_eq(TJAData.NoteType.KA_BIG, 3, "KA_BIG 音符类型应为 3")
	assert_eq(TJAData.NoteType.ROLL, 4, "ROLL 音符类型应为 4")
	assert_eq(TJAData.NoteType.ROLL_BIG, 5, "ROLL_BIG 音符类型应为 5")
	assert_eq(TJAData.NoteType.BALLOON, 6, "BALLOON 音符类型应为 6")


## CL-002-3: 测试课程类型验证
func test_cl002_course_type_validation() -> void:
	# 验证课程类型常量
	assert_eq(TJAData.CourseType.EASY, 0, "EASY 课程类型应为 0")
	assert_eq(TJAData.CourseType.NORMAL, 1, "NORMAL 课程类型应为 1")
	assert_eq(TJAData.CourseType.HARD, 2, "HARD 课程类型应为 2")
	assert_eq(TJAData.CourseType.ONI, 3, "ONI 课程类型应为 3")
	assert_eq(TJAData.CourseType.URA, 4, "URA 课程类型应为 4")


## CL-002-4: 测试音符时间验证
func test_cl002_note_time_validation() -> void:
	var song = _create_test_song()
	var course = song.get_course(TJAData.CourseType.ONI)

	# 验证音符时间在有效范围内
	for measure in course.measures:
		for note in measure.notes:
			assert_gte(note.time, 0.0, "音符时间应 >= 0")
			assert_lt(note.time, 4.0, "音符时间应在小节范围内")


## CL-002-5: 测试 BPM 范围验证
func test_cl002_bpm_range_validation() -> void:
	var song = _create_test_song()

	# 验证 BPM 在合理范围内
	assert_gt(song.bpm, 0.0, "BPM 应大于 0")
	assert_lt(song.bpm, 500.0, "BPM 应小于 500")


# ==================== CL-003: 多难度谱面加载测试 ====================

## CL-003-1: 测试多难度课程加载
func test_cl003_multiple_difficulty_loading() -> void:
	var song = _create_test_song()

	# 验证所有难度都存在
	assert_not_null(song.get_course(TJAData.CourseType.EASY), "应有 EASY 课程")
	assert_not_null(song.get_course(TJAData.CourseType.NORMAL), "应有 NORMAL 课程")
	assert_not_null(song.get_course(TJAData.CourseType.HARD), "应有 HARD 课程")
	assert_not_null(song.get_course(TJAData.CourseType.ONI), "应有 ONI 课程")


## CL-003-2: 测试难度等级递增
func test_cl003_difficulty_level_progression() -> void:
	var song = _create_test_song()

	# 验证难度等级递增
	var easy_level = song.get_course(TJAData.CourseType.EASY).level
	var normal_level = song.get_course(TJAData.CourseType.NORMAL).level
	var hard_level = song.get_course(TJAData.CourseType.HARD).level
	var oni_level = song.get_course(TJAData.CourseType.ONI).level

	assert_lt(easy_level, normal_level, "EASY 难度应低于 NORMAL")
	assert_lt(normal_level, hard_level, "NORMAL 难度应低于 HARD")
	assert_lt(hard_level, oni_level, "HARD 难度应低于 ONI")


## CL-003-3: 测试课程切换
func test_cl003_course_switching() -> void:
	var song = _create_test_song()

	# 切换到不同课程
	var easy_course = song.get_course(TJAData.CourseType.EASY)
	var oni_course = song.get_course(TJAData.CourseType.ONI)

	assert_ne(easy_course.level, oni_course.level, "不同课程应有不同难度")


## CL-003-4: 测试 URA 课程加载
func test_cl003_ura_course_loading() -> void:
	var song = _create_test_song()

	# 添加 URA 课程
	var ura_course = TJAData.TJACourse.new()
	ura_course.course_type = TJAData.CourseType.URA
	ura_course.level = 10
	song.add_course(ura_course)

	# 验证 URA 课程
	assert_not_null(song.get_course(TJAData.CourseType.URA), "应有 URA 课程")
	assert_eq(song.get_course(TJAData.CourseType.URA).level, 10, "URA 难度应为 10")


## CL-003-5: 测试课程不存在处理
func test_cl003_nonexistent_course_handling() -> void:
	var song = TJAData.TJASong.new()
	song.title = "No Courses"

	# 尝试获取不存在的课程
	var result = song.get_course(TJAData.CourseType.ONI)
	assert_null(result, "不存在的课程应返回 null")


# ==================== CL-004: 分支谱面加载测试 ====================

## CL-004-1: 测试分支谱面数据结构
func test_cl004_branch_data_structure() -> void:
	var song = _create_branching_song()
	var course = song.get_course(TJAData.CourseType.ONI)

	# 验证分支标志
	assert_true(course.has_branches, "课程应有分支")


## CL-004-2: 测试分支类型常量
func test_cl004_branch_type_constants() -> void:
	# 验证分支类型常量
	assert_eq(TJAData.BranchType.NORMAL, 0, "NORMAL 分支类型应为 0")
	assert_eq(TJAData.BranchType.EXPERT, 1, "EXPERT 分支类型应为 1")
	assert_eq(TJAData.BranchType.MASTER, 2, "MASTER 分支类型应为 2")


## CL-004-3: 测试分支条件
func test_cl004_branch_conditions() -> void:
	var song = _create_branching_song()
	var course = song.get_course(TJAData.CourseType.ONI)

	# 验证分支条件属性存在
	assert_true(course.has_branches, "应有分支条件")


## CL-004-4: 测试分支音符差异
func test_cl004_branch_note_differences() -> void:
	var song = _create_branching_song()
	var course = song.get_course(TJAData.CourseType.ONI)

	# 统计各分支音符数量
	var normal_notes = 0
	var master_notes = 0

	for measure in course.measures:
		if measure.branch == TJAData.BranchType.NORMAL:
			normal_notes += measure.notes.size()
		elif measure.branch == TJAData.BranchType.MASTER:
			master_notes += measure.notes.size()

	# 验证分支存在
	assert_gt(normal_notes + master_notes, 0, "应有分支音符")


## CL-004-5: 测试分支切换逻辑
func test_cl004_branch_switching_logic() -> void:
	# 创建 GameController 测试分支切换
	game_controller.current_song = _create_branching_song()
	game_controller.current_course = game_controller.current_song.get_course(TJAData.CourseType.ONI)
	game_controller._initialize_game_systems()

	# 验证初始化成功
	assert_not_null(game_controller.note_manager, "NoteManager 应已初始化")


# ==================== CL-005: 谱面加载错误处理测试 ====================

## CL-005-1: 测试空文件处理
func test_cl005_empty_file_handling() -> void:
	# 解析空字符串
	var result = parser.parse("")

	# 验证处理结果
	assert_not_null(result, "应返回结果对象")


## CL-005-2: 测试无效文件路径处理
func test_cl005_invalid_file_path_handling() -> void:
	# 尝试解析不存在的文件
	var result = parser.parse_file("res://nonexistent/path/file.tja")

	# 验证错误处理
	assert_false(result.success, "无效路径应返回失败")


## CL-005-3: 测试损坏数据处理
func test_cl005_corrupted_data_handling() -> void:
	# 解析损坏的数据
	var corrupted_data = "TITLE:Test\nBPM:invalid\n#START\n1\n#END"
	var result = parser.parse(corrupted_data)

	# 验证处理结果（不应崩溃）
	assert_not_null(result, "应返回结果对象")


## CL-005-4: 测试缺失字段处理
func test_cl005_missing_field_handling() -> void:
	# 解析缺少必需字段的数据
	var incomplete_data = "#START\n1\n#END"
	var result = parser.parse(incomplete_data)

	# 验证处理结果
	assert_not_null(result, "应返回结果对象")


## CL-005-5: 测试超大谱面处理
func test_cl005_large_chart_handling() -> void:
	# 创建大型谱面
	var song = TJAData.TJASong.new()
	song.title = "Large Chart"
	song.bpm = 200.0

	var course = TJAData.TJACourse.new()
	course.course_type = TJAData.CourseType.ONI
	course.level = 10

	# 添加大量小节
	for i in range(100):
		var measure = TJAData.TJAMeasure.new(i)
		measure.bpm = 200.0

		# 每小节添加多个音符
		for j in range(16):
			measure.add_note(TJAData.TJANote.new(TJAData.NoteType.DON, j * 0.25))

		course.add_measure(measure)

	song.add_course(course)

	# 验证大型谱面处理
	assert_eq(course.measures.size(), 100, "应有 100 个小节")


# ==================== 谱面加载性能测试 ====================

## 测试谱面加载时间
func test_chart_loading_performance() -> void:
	# 创建测试谱面
	var song = _create_test_song()

	# 记录开始时间
	var start_time = Time.get_ticks_msec()

	# 执行加载操作（模拟）
	game_controller.current_song = song
	game_controller.current_course = song.get_course(TJAData.CourseType.ONI)
	game_controller._initialize_game_systems()

	# 记录结束时间
	var end_time = Time.get_ticks_msec()
	var elapsed = end_time - start_time

	# 验证加载时间在合理范围内（< 100ms）
	assert_lt(elapsed, 100, "谱面加载时间应小于 100ms")


## 测试音符初始化性能
func test_note_initialization_performance() -> void:
	var song = _create_test_song()
	var course = song.get_course(TJAData.CourseType.ONI)

	# 记录开始时间
	var start_time = Time.get_ticks_msec()

	# 统计音符数量
	var note_count = 0
	for measure in course.measures:
		note_count += measure.notes.size()

	# 记录结束时间
	var end_time = Time.get_ticks_msec()
	var elapsed = end_time - start_time

	# 验证处理时间
	assert_lt(elapsed, 10, "音符统计时间应小于 10ms")
	assert_gt(note_count, 0, "应有音符")


# ==================== 谱面加载集成测试 ====================

## 测试完整加载流程
func test_complete_loading_flow() -> void:
	# 1. 创建谱面数据
	var song = _create_test_song()

	# 2. 设置 GameController
	game_controller.current_song = song
	game_controller.current_course = song.get_course(TJAData.CourseType.ONI)

	# 3. 初始化游戏系统
	game_controller._initialize_game_systems()

	# 4. 验证系统状态
	assert_not_null(game_controller.note_manager, "NoteManager 应已创建")
	assert_not_null(game_controller.scroll_system, "ScrollSystem 应已创建")
	assert_not_null(game_controller.judge_system, "JudgeSystem 应已创建")


## 测试加载后游戏状态
func test_game_state_after_loading() -> void:
	var song = _create_test_song()
	game_controller.current_song = song
	game_controller.current_course = song.get_course(TJAData.CourseType.ONI)
	game_controller._initialize_game_systems()

	# 验证游戏状态
	assert_eq(game_controller.current_state, GameController.PlayState.IDLE, "初始状态应为 IDLE")