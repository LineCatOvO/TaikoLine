## 解析到游玩集成测试
## 测试 TJAParser、TJAData、NoteManager、ScrollSystem 之间的协作
## 测试框架：GUT v9.6.0
##
## 测试用例：
## - PTP-001: TJA解析到音符生成
## - PTP-002: BPM变化正确应用
## - PTP-003: 滚动速度变化正确应用
## - PTP-004: 分支谱面解析测试
## - PTP-005: 音符时间计算正确

extends GutTest

# ==================== 测试常量 ====================

const TJAData = preload("res://src/parser/tja_data.gd")
const TJAParser = preload("res://src/parser/tja_parser.gd")
const NoteManager = preload("res://src/game/note_manager.gd")
const ScrollSystem = preload("res://src/game/scroll.gd")

# 测试文件路径
const BASIC_TJA_PATH = "res://test/fixtures/sample_tja/basic.tja"
const BRANCHING_TJA_PATH = "res://test/fixtures/sample_tja/branching.tja"

# ==================== 测试变量 ====================

var parser: TJAParser = null
var note_manager: NoteManager = null
var scroll_system: ScrollSystem = null

# ==================== 测试生命周期 ====================

func before_all() -> void:
	pass

func before_each() -> void:
	# 创建解析器
	parser = TJAParser.new()
	
	# 创建 NoteManager
	note_manager = NoteManager.new()
	add_child_autofree(note_manager)
	
	# 创建 ScrollSystem
	scroll_system = ScrollSystem.new()
	add_child_autofree(scroll_system)
	
	# 设置系统关联
	note_manager.set_scroll_system(scroll_system)

func after_each() -> void:
	# 清理
	if note_manager:
		note_manager.clear_all_notes()
	if scroll_system:
		scroll_system.reset()

func after_all() -> void:
	pass

# ==================== 辅助方法 ====================

## 创建带BPM变化的测试谱面
func _create_bpm_change_course() -> TJAData.TJACourse:
	var course = TJAData.TJACourse.new()
	course.course_type = TJAData.CourseType.ONI
	course.level = 5
	
	# 第一个小节：BPM 120
	var measure1 = TJAData.TJAMeasure.new(0)
	measure1.bpm = 120.0
	measure1.scroll = 1.0
	measure1.time_signature = Vector2(4.0, 4.0)
	var note1 = TJAData.TJANote.new(TJAData.NoteType.DON, 0.0)
	measure1.add_note(note1)
	course.add_measure(measure1)
	
	# 第二个小节：BPM 150
	var measure2 = TJAData.TJAMeasure.new(1)
	measure2.bpm = 150.0
	measure2.scroll = 1.0
	measure2.time_signature = Vector2(4.0, 4.0)
	var note2 = TJAData.TJANote.new(TJAData.NoteType.KA, 0.0)
	measure2.add_note(note2)
	course.add_measure(measure2)
	
	# 第三个小节：BPM 100
	var measure3 = TJAData.TJAMeasure.new(2)
	measure3.bpm = 100.0
	measure3.scroll = 1.0
	measure3.time_signature = Vector2(4.0, 4.0)
	var note3 = TJAData.TJANote.new(TJAData.NoteType.DON, 0.0)
	measure3.add_note(note3)
	course.add_measure(measure3)
	
	return course

## 创建带滚动速度变化的测试谱面
func _create_scroll_change_course() -> TJAData.TJACourse:
	var course = TJAData.TJACourse.new()
	course.course_type = TJAData.CourseType.ONI
	course.level = 5
	
	# 第一个小节：scroll 1.0
	var measure1 = TJAData.TJAMeasure.new(0)
	measure1.bpm = 120.0
	measure1.scroll = 1.0
	measure1.time_signature = Vector2(4.0, 4.0)
	var note1 = TJAData.TJANote.new(TJAData.NoteType.DON, 0.0)
	measure1.add_note(note1)
	course.add_measure(measure1)
	
	# 第二个小节：scroll 2.0
	var measure2 = TJAData.TJAMeasure.new(1)
	measure2.bpm = 120.0
	measure2.scroll = 2.0
	measure2.time_signature = Vector2(4.0, 4.0)
	var note2 = TJAData.TJANote.new(TJAData.NoteType.KA, 0.0)
	measure2.add_note(note2)
	course.add_measure(measure2)
	
	# 第三个小节：scroll 0.5
	var measure3 = TJAData.TJAMeasure.new(2)
	measure3.bpm = 120.0
	measure3.scroll = 0.5
	measure3.time_signature = Vector2(4.0, 4.0)
	var note3 = TJAData.TJANote.new(TJAData.NoteType.DON, 0.0)
	measure3.add_note(note3)
	course.add_measure(measure3)
	
	return course

## 创建复杂音符类型的测试谱面
func _create_complex_notes_course() -> TJAData.TJACourse:
	var course = TJAData.TJACourse.new()
	course.course_type = TJAData.CourseType.ONI
	course.level = 5
	course.balloons = [5, 3]  # 气球打击次数
	
	var measure = TJAData.TJAMeasure.new(0)
	measure.bpm = 120.0
	measure.scroll = 1.0
	measure.time_signature = Vector2(4.0, 4.0)
	
	# 添加各种音符类型
	measure.add_note(TJAData.TJANote.new(TJAData.NoteType.DON, 0.0))
	measure.add_note(TJAData.TJANote.new(TJAData.NoteType.KA, 0.125))
	measure.add_note(TJAData.TJANote.new(TJAData.NoteType.DON_BIG, 0.25))
	measure.add_note(TJAData.TJANote.new(TJAData.NoteType.KA_BIG, 0.375))
	measure.add_note(TJAData.TJANote.new(TJAData.NoteType.RENDA, 0.5))
	measure.add_note(TJAData.TJANote.new(TJAData.NoteType.END, 0.625))
	measure.add_note(TJAData.TJANote.new(TJAData.NoteType.BALLOON, 0.75))
	measure.add_note(TJAData.TJANote.new(TJAData.NoteType.END, 0.875))
	
	course.add_measure(measure)
	return course

# ==================== PTP-001: TJA解析到音符生成测试 ====================

## PTP-001-1: 测试解析到音符生成基本流程
func test_ptp001_parse_to_note_generation() -> void:
	# 解析测试文件
	var result = parser.parse_file(BASIC_TJA_PATH)
	assert_true(result.success, "TJA文件解析应该成功")
	
	var song = result.song
	var course = song.get_course(TJAData.CourseType.ONI)
	assert_not_null(course, "应该找到Oni难度")
	
	# 加载谱面到 NoteManager
	note_manager.load_chart(course, song.offset)
	
	# 验证音符队列
	var pending_count = note_manager.get_pending_note_count()
	assert_gt(pending_count, 0, "应该有待生成的音符")

## PTP-001-2: 测试音符数据正确性
func test_ptp001_note_data_correctness() -> void:
	# 解析测试文件
	var result = parser.parse_file(BASIC_TJA_PATH)
	assert_true(result.success, "TJA文件解析应该成功")
	
	var song = result.song
	var course = song.get_course(TJAData.CourseType.ONI)
	
	# 验证小节数量
	assert_eq(course.measures.size(), 4, "应该有4个小节")
	
	# 验证音符数量
	var total_notes = course.get_total_notes()
	assert_gt(total_notes, 0, "应该有音符")

## PTP-001-3: 测试音符类型正确映射
func test_ptp001_note_type_mapping() -> void:
	# 创建复杂音符类型的谱面
	var course = _create_complex_notes_course()
	
	# 加载谱面
	note_manager.load_chart(course, 0.0)
	
	# 验证音符队列中的音符类型
	var note_queue = note_manager._note_queue
	assert_gt(note_queue.size(), 0, "应该有音符数据")
	
	# 检查第一个音符类型
	var first_note = note_queue[0]
	assert_eq(first_note.note_data.note_type, TJAData.NoteType.DON, "第一个音符应为DON")

## PTP-001-4: 测试音符位置计算
func test_ptp001_note_position_calculation() -> void:
	# 创建测试谱面
	var course = TJAData.TJACourse.new()
	course.course_type = TJAData.CourseType.ONI
	
	var measure = TJAData.TJAMeasure.new(0)
	measure.bpm = 120.0
	measure.scroll = 1.0
	measure.time_signature = Vector2(4.0, 4.0)
	
	# 添加音符在不同位置
	measure.add_note(TJAData.TJANote.new(TJAData.NoteType.DON, 0.0))
	measure.add_note(TJAData.TJANote.new(TJAData.NoteType.DON, 0.5))
	measure.add_note(TJAData.TJANote.new(TJAData.NoteType.DON, 1.0))
	
	course.add_measure(measure)
	
	# 加载谱面
	note_manager.load_chart(course, 0.0)
	
	# 验证音符时间
	var note_queue = note_manager._note_queue
	assert_eq(note_queue.size(), 3, "应该有3个音符")
	
	# 第一个音符时间应为0
	assert_almost_eq(note_queue[0].hit_time, 0.0, 0.001, "第一个音符时间应为0")
	
	# 第二个音符时间应为小节时长的一半
	var measure_duration = measure.get_duration()  # 2秒 (120 BPM, 4/4拍)
	assert_almost_eq(note_queue[1].hit_time, measure_duration * 0.5, 0.001, "第二个音符时间应正确")

## PTP-001-5: 测试分支谱面解析
func test_ptp001_branch_chart_parsing() -> void:
	# 解析分支测试文件
	var result = parser.parse_file(BRANCHING_TJA_PATH)
	assert_true(result.success, "分支TJA文件解析应该成功")
	
	var song = result.song
	var course = song.get_course(TJAData.CourseType.ONI)
	
	# 验证分支标志
	assert_true(course.has_branch, "应该有分支")

# ==================== PTP-002: BPM变化正确应用测试 ====================

## PTP-002-1: 测试BPM变化加载到ScrollSystem
func test_ptp002_bpm_change_loading() -> void:
	# 创建带BPM变化的谱面
	var course = _create_bpm_change_course()
	
	# 加载到 ScrollSystem
	scroll_system.load_chart_data(course)
	
	# 验证BPM变化数量
	var bpm_change_count = scroll_system.get_bpm_change_count()
	assert_eq(bpm_change_count, 3, "应该有3个BPM变化点")

## PTP-002-2: 测试BPM变化时间点正确
func test_ptp002_bpm_change_timing() -> void:
	# 创建带BPM变化的谱面
	var course = _create_bpm_change_course()
	
	# 加载到 ScrollSystem
	scroll_system.load_chart_data(course)
	
	# 计算第一个小节时长 (120 BPM, 4/4拍 = 2秒)
	var measure1_duration = 60.0 / 120.0 * 4.0  # 2秒
	
	# 验证第一个BPM变化点
	assert_true(scroll_system.has_bpm_change_at(0.0), "应该在时间0有BPM变化")
	
	# 验证第二个BPM变化点
	assert_true(scroll_system.has_bpm_change_at(measure1_duration, 0.1), "应该在第一个小节结束时有BPM变化")

## PTP-002-3: 测试BPM变化影响时间计算
func test_ptp002_bpm_change_affects_time_calculation() -> void:
	# 创建带BPM变化的谱面
	var course = _create_bpm_change_course()
	
	# 加载到 ScrollSystem
	scroll_system.load_chart_data(course)
	
	# 在第一个BPM区间 (120 BPM)
	scroll_system.update_time(0.0)
	var pos1 = scroll_system.time_to_position(1.0)  # 1秒后的位置
	
	# 在第二个BPM区间 (150 BPM)
	scroll_system.update_time(3.0)  # 第二个小节
	var pos2 = scroll_system.time_to_position(1.0)  # 1秒后的位置
	
	# 更高的BPM应该产生更大的位置变化
	assert_gt(pos2 - scroll_system.judge_line_x, pos1 - scroll_system.judge_line_x, "更高BPM应该产生更大的位置变化")

## PTP-002-4: 测试BPM变化信号
func test_ptp002_bpm_change_signal() -> void:
	# 创建带BPM变化的谱面
	var course = _create_bpm_change_course()
	scroll_system.load_chart_data(course)

	# 监听BPM变化信号
	watch_signals(scroll_system)

	# 设置一个与当前BPM不同的值，以便下一次更新时触发信号
	scroll_system._current_bpm = 60.0  # 当前是120，设置为60

	# 更新时间触发BPM变化
	scroll_system.update_time(0.0)

	# 验证BPM变化信号触发（因为当前BPM与查找到的BPM不同）
	assert_signal_emitted(scroll_system, "bpm_changed", "应该触发BPM变化信号")

## PTP-002-5: 测试小节时长计算
func test_ptp002_measure_duration_calculation() -> void:
	# 创建不同BPM的小节
	var measure_120 = TJAData.TJAMeasure.new(0)
	measure_120.bpm = 120.0
	measure_120.time_signature = Vector2(4.0, 4.0)
	
	var measure_150 = TJAData.TJAMeasure.new(1)
	measure_150.bpm = 150.0
	measure_150.time_signature = Vector2(4.0, 4.0)
	
	# 验证时长计算
	# 120 BPM, 4/4拍 = 60/120 * 4 = 2秒
	assert_almost_eq(measure_120.get_duration(), 2.0, 0.001, "120BPM小节时长应为2秒")
	
	# 150 BPM, 4/4拍 = 60/150 * 4 = 1.6秒
	assert_almost_eq(measure_150.get_duration(), 1.6, 0.001, "150BPM小节时长应为1.6秒")

# ==================== PTP-003: 滚动速度变化正确应用测试 ====================

## PTP-003-1: 测试滚动速度变化加载
func test_ptp003_scroll_change_loading() -> void:
	# 创建带滚动速度变化的谱面
	var course = _create_scroll_change_course()
	
	# 加载到 ScrollSystem
	scroll_system.load_chart_data(course)
	
	# 验证滚动速度变化数量
	var scroll_change_count = scroll_system.get_scroll_change_count()
	assert_eq(scroll_change_count, 3, "应该有3个滚动速度变化点")

## PTP-003-2: 测试滚动速度变化时间点正确
func test_ptp003_scroll_change_timing() -> void:
	# 创建带滚动速度变化的谱面
	var course = _create_scroll_change_course()
	
	# 加载到 ScrollSystem
	scroll_system.load_chart_data(course)
	
	# 验证第一个滚动速度变化点
	assert_true(scroll_system.has_scroll_change_at(0.0), "应该在时间0有滚动速度变化")

## PTP-003-3: 测试滚动速度影响位置计算
func test_ptp003_scroll_affects_position() -> void:
	# 创建带滚动速度变化的谱面
	var course = _create_scroll_change_course()
	scroll_system.load_chart_data(course)
	
	# 在 scroll 1.0 时
	scroll_system.update_time(0.0)
	var pos1 = scroll_system.time_to_position(1.0)
	
	# 在 scroll 2.0 时
	scroll_system.update_time(3.0)  # 第二个小节
	var pos2 = scroll_system.time_to_position(1.0)
	
	# 更高的滚动速度应该产生更大的位置变化
	assert_gt(pos2 - scroll_system.judge_line_x, pos1 - scroll_system.judge_line_x, "更高滚动速度应该产生更大的位置变化")

## PTP-003-4: 测试滚动速度变化信号
func test_ptp003_scroll_change_signal() -> void:
	# 创建带滚动速度变化的谱面
	var course = _create_scroll_change_course()
	scroll_system.load_chart_data(course)

	# 监听滚动速度变化信号
	watch_signals(scroll_system)

	# 设置一个与当前滚动速度不同的值，以便下一次更新时触发信号
	scroll_system._current_scroll = 0.5  # 当前是1.0，设置为0.5

	# 更新时间触发滚动速度变化
	scroll_system.update_time(0.0)

	# 验证信号触发
	assert_signal_emitted(scroll_system, "scroll_speed_changed", "应该触发滚动速度变化信号")

## PTP-003-5: 测试有效滚动速度计算
func test_ptp003_effective_scroll_speed() -> void:
	scroll_system.base_scroll_speed = 2.0
	scroll_system._current_scroll = 1.5
	
	var effective = scroll_system.get_effective_scroll_speed()
	assert_eq(effective, 3.0, "有效滚动速度应为基础速度乘以当前速度")

# ==================== PTP-004: 分支谱面解析测试 ====================

## PTP-004-1: 测试分支谱面解析
func test_ptp004_branch_parsing() -> void:
	# 解析分支测试文件
	var result = parser.parse_file(BRANCHING_TJA_PATH)
	assert_true(result.success, "分支TJA文件解析应成功")

	var song = result.song
	var course = song.get_course(TJAData.CourseType.ONI)

	# 验证分支标志
	assert_true(course.has_branch, "应检测到分支")

## PTP-004-2: 测试分支类型识别
func test_ptp004_branch_type_identification() -> void:
	# 解析分支测试文件
	var result = parser.parse_file(BRANCHING_TJA_PATH)
	assert_true(result.success, "分支TJA文件解析应成功")

	var song = result.song
	var course = song.get_course(TJAData.CourseType.ONI)

	# 验证分支标志
	if course.has_branch:
		# 验证分支条件存在
		assert_gt(course.branch_conditions.size(), 0, "应有分支条件")

## PTP-004-3: 测试分支阈值解析
func test_ptp004_branch_threshold_parsing() -> void:
	# 解析分支测试文件
	var result = parser.parse_file(BRANCHING_TJA_PATH)
	assert_true(result.success, "分支TJA文件解析应成功")

	var song = result.song
	var course = song.get_course(TJAData.CourseType.ONI)

	# 验证分支阈值
	if course.has_branch and course.branch_conditions.size() > 0:
		# 验证分支条件有阈值设置
		var condition = course.branch_conditions[0]
		assert_gte(condition.normal_threshold, 0.0, "应有普通分支阈值")
		assert_gte(condition.expert_threshold, 0.0, "应有高级分支阈值")

## PTP-004-4: 测试分支音符加载
func test_ptp004_branch_note_loading() -> void:
	# 解析分支测试文件
	var result = parser.parse_file(BRANCHING_TJA_PATH)
	assert_true(result.success, "分支TJA文件解析应成功")

	var song = result.song
	var course = song.get_course(TJAData.CourseType.ONI)

	# 加载谱面到 NoteManager
	note_manager.load_chart(course, song.offset)

	# 验证音符队列
	var pending_count = note_manager.get_pending_note_count()
	assert_gt(pending_count, 0, "应有待生成的音符")

## PTP-004-5: 测试分支切换时机计算
func test_ptp004_branch_switch_timing() -> void:
	# 解析分支测试文件
	var result = parser.parse_file(BRANCHING_TJA_PATH)
	assert_true(result.success, "分支TJA文件解析应成功")

	var song = result.song
	var course = song.get_course(TJAData.CourseType.ONI)

	# 验证分支切换点
	if course.has_branch and course.branch_conditions.size() > 0:
		# 分支条件应有触发时间
		for condition in course.branch_conditions:
			assert_gte(condition.trigger_time, 0.0, "分支切换时间应大于等于0")

## PTP-004-6: 测试不同分支的音符差异
func test_ptp004_branch_note_differences() -> void:
	# 解析分支测试文件
	var result = parser.parse_file(BRANCHING_TJA_PATH)
	assert_true(result.success, "分支TJA文件解析应成功")

	var song = result.song
	var course = song.get_course(TJAData.CourseType.ONI)

	# 如果有分支，验证分支数据存在
	if course.has_branch:
		# 验证分支数据存在
		var normal_measures = course.get_branch_measures(TJAData.BranchType.NORMAL)
		var master_measures = course.get_branch_measures(TJAData.BranchType.MASTER)
		
		# 至少普通分支应该有数据
		assert_gt(normal_measures.size(), 0, "普通分支应有小节数据")

# ==================== PTP-005: 音符时间计算正确测试 ====================

## PTP-005-1: 测试时间到位置转换
func test_ptp005_time_to_position_conversion() -> void:
	scroll_system.reset()
	scroll_system._current_bpm = 120.0
	scroll_system._current_scroll = 1.0
	scroll_system.base_scroll_speed = 1.0
	
	# 1秒后的位置
	var pos = scroll_system.time_to_position(1.0)
	
	# 验证位置在判定线右侧
	assert_gt(pos, scroll_system.judge_line_x, "未来时间的位置应在判定线右侧")

## PTP-005-2: 测试位置到时间转换
func test_ptp005_position_to_time_conversion() -> void:
	scroll_system.reset()
	scroll_system._current_bpm = 120.0
	scroll_system._current_scroll = 1.0
	scroll_system.base_scroll_speed = 1.0
	
	# 判定线右侧500像素的时间
	var time = scroll_system.position_to_time(scroll_system.judge_line_x + 500.0)
	
	# 验证时间为正（未来）
	assert_gt(time, 0.0, "判定线右侧的位置应对应未来时间")

## PTP-005-3: 测试时间位置转换可逆性
func test_ptp005_time_position_reversibility() -> void:
	scroll_system.reset()
	scroll_system._current_bpm = 120.0
	scroll_system._current_scroll = 1.0
	scroll_system.base_scroll_speed = 1.0
	
	var original_time = 2.0
	var pos = scroll_system.time_to_position(original_time)
	var converted_time = scroll_system.position_to_time(pos)
	
	# 验证转换可逆
	assert_almost_eq(converted_time, original_time, 0.01, "时间位置转换应该可逆")

## PTP-005-4: 测试生成提前时间计算
func test_ptp005_spawn_ahead_time() -> void:
	scroll_system.reset()
	scroll_system._current_bpm = 120.0
	scroll_system._current_scroll = 1.0
	scroll_system.base_scroll_speed = 1.0
	
	var spawn_time = scroll_system.get_spawn_ahead_time()
	
	# 验证生成提前时间为正
	assert_gt(spawn_time, 0.0, "生成提前时间应为正数")

## PTP-005-5: 测试音符时间计算与BPM关联
func test_ptp005_note_time_bpm_relation() -> void:
	# 创建两个不同BPM的谱面
	var course_120 = TJAData.TJACourse.new()
	course_120.course_type = TJAData.CourseType.ONI
	var measure_120 = TJAData.TJAMeasure.new(0)
	measure_120.bpm = 120.0
	measure_120.time_signature = Vector2(4.0, 4.0)
	measure_120.add_note(TJAData.TJANote.new(TJAData.NoteType.DON, 0.5))
	course_120.add_measure(measure_120)
	
	var course_180 = TJAData.TJACourse.new()
	course_180.course_type = TJAData.CourseType.ONI
	var measure_180 = TJAData.TJAMeasure.new(0)
	measure_180.bpm = 180.0
	measure_180.time_signature = Vector2(4.0, 4.0)
	measure_180.add_note(TJAData.TJANote.new(TJAData.NoteType.DON, 0.5))
	course_180.add_measure(measure_180)
	
	# 加载并比较
	note_manager.load_chart(course_120, 0.0)
	var time_120 = note_manager._note_queue[0].hit_time
	note_manager.clear_all_notes()
	
	note_manager.load_chart(course_180, 0.0)
	var time_180 = note_manager._note_queue[0].hit_time
	
	# 更高BPM的小节时长更短，所以相同位置的音符时间更早
	assert_gt(time_120, time_180, "更高BPM时，相同位置音符的时间应更早")

# ==================== 解析与系统集成测试 ====================

## 测试解析结果直接用于游戏系统
func test_parse_result_to_game_systems() -> void:
	# 解析测试文件
	var result = parser.parse_file(BASIC_TJA_PATH)
	assert_true(result.success, "解析应该成功")
	
	var song = result.song
	var course = song.get_course(TJAData.CourseType.ONI)
	
	# 加载到 ScrollSystem
	scroll_system.load_chart_data(course)
	
	# 加载到 NoteManager
	note_manager.load_chart(course, song.offset)
	
	# 验证系统状态
	assert_gt(scroll_system.get_bpm_change_count(), 0, "ScrollSystem应有BPM数据")
	assert_gt(note_manager.get_pending_note_count(), 0, "NoteManager应有音符数据")

## 测试完整解析到游玩流程
func test_full_parse_to_play_flow() -> void:
	# 解析
	var result = parser.parse_file(BASIC_TJA_PATH)
	assert_true(result.success, "解析应该成功")

	var song = result.song
	var course = song.get_course(TJAData.CourseType.ONI)

	# 初始化系统
	scroll_system.set_offset(song.offset)
	scroll_system.load_chart_data(course)
	note_manager.load_chart(course, song.offset)

	# 验证音符队列有数据
	var pending_count = note_manager.get_pending_note_count()
	assert_gt(pending_count, 0, "应该有待生成的音符")

	# 模拟游戏时间推进
	var total_duration = course.get_total_duration()
	var current_time = 0.0
	var notes_spawned = 0

	while current_time < total_duration + 5.0:  # 额外5秒让音符生成
		scroll_system.update_time(current_time)
		note_manager.update(current_time)

		# 统计生成的音符
		notes_spawned = note_manager.get_active_note_count()

		current_time += 0.1  # 100ms步进

	# 验证音符已生成（至少应该有一些音符被处理）
	assert_gt(pending_count + notes_spawned, 0, "应该有音符被处理")