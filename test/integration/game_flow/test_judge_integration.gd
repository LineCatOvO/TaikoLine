## 判定系统集成测试
## 测试 JudgeSystem、NoteManager、GameNote、GameState 之间的协作
## 测试框架：GUT v9.6.0
##
## 测试用例：
## - JI-001: 输入到判定流程
## - JI-002: 判定到分数更新
## - JI-003: 判定到连击更新
## - JI-004: 判定到魂槽更新
## - JI-005: 信号正确传递

extends GutTest

# ==================== 测试常量 ====================

const TJAData = preload("res://src/parser/tja_data.gd")
const JudgeSystem = preload("res://src/game/judge.gd")
const NoteManager = preload("res://src/game/note_manager.gd")
const ScrollSystem = preload("res://src/game/scroll.gd")
const GameNote = preload("res://src/game/note.gd")

# ==================== 测试变量 ====================

var judge_system: JudgeSystem = null
var note_manager: NoteManager = null
var scroll_system: ScrollSystem = null

# ==================== 测试生命周期 ====================

func before_all() -> void:
	pass

func before_each() -> void:
	# 创建判定系统
	judge_system = JudgeSystem.new()
	add_child_autofree(judge_system)
	
	# 创建滚动系统
	scroll_system = ScrollSystem.new()
	add_child_autofree(scroll_system)
	
	# 创建音符管理器
	note_manager = NoteManager.new()
	add_child_autofree(note_manager)
	note_manager.set_scroll_system(scroll_system)
	note_manager.set_judge_system(judge_system)

func after_each() -> void:
	# 清理
	if judge_system:
		judge_system.reset()
	if note_manager:
		note_manager.clear_all_notes()
	if scroll_system:
		scroll_system.reset()

func after_all() -> void:
	pass

# ==================== 辅助方法 ====================

## 创建测试音符
func _create_test_note(note_type: TJAData.NoteType, hit_time: float) -> GameNote:
	var note_data = TJAData.TJANote.new(note_type, 0.0)
	var note = GameNote.new()
	note.setup(note_data, hit_time)
	return note

## 创建测试谱面数据
func _create_test_course_for_judge() -> TJAData.TJACourse:
	var course = TJAData.TJACourse.new()
	course.course_type = TJAData.CourseType.ONI
	course.level = 5
	course.score_init = 1000
	course.score_diff = 100
	
	var measure = TJAData.TJAMeasure.new(0)
	measure.bpm = 120.0
	measure.scroll = 1.0
	measure.time_signature = Vector2(4.0, 4.0)
	
	# 添加各种音符
	measure.add_note(TJAData.TJANote.new(TJAData.NoteType.DON, 0.0))
	measure.add_note(TJAData.TJANote.new(TJAData.NoteType.KA, 0.25))
	measure.add_note(TJAData.TJANote.new(TJAData.NoteType.DON_BIG, 0.5))
	measure.add_note(TJAData.TJANote.new(TJAData.NoteType.KA_BIG, 0.75))
	
	course.add_measure(measure)
	return course

# ==================== JI-001: 输入到判定流程测试 ====================

## JI-001-1: 测试正确输入匹配
func test_ji001_correct_input_matching() -> void:
	# 创建红音符
	var note = _create_test_note(TJAData.NoteType.DON, 0.0)
	add_child_autofree(note)
	
	# 测试红音符接受don输入
	assert_true(note.needs_don_input(), "红音符应该需要don输入")
	assert_false(note.needs_ka_input(), "红音符不应该需要ka输入")

## JI-001-2: 测试蓝音符输入匹配
func test_ji001_ka_input_matching() -> void:
	# 创建蓝音符
	var note = _create_test_note(TJAData.NoteType.KA, 0.0)
	add_child_autofree(note)
	
	# 测试蓝音符接受ka输入
	assert_false(note.needs_don_input(), "蓝音符不应该需要don输入")
	assert_true(note.needs_ka_input(), "蓝音符应该需要ka输入")

## JI-001-3: 测试大音符输入匹配
func test_ji001_big_note_input_matching() -> void:
	# 创建大红音符
	var don_big = _create_test_note(TJAData.NoteType.DON_BIG, 0.0)
	add_child_autofree(don_big)
	
	assert_true(don_big.needs_don_input(), "大红音符应该需要don输入")
	assert_true(don_big.is_big(), "应该是大音符")
	
	# 创建大蓝音符
	var ka_big = _create_test_note(TJAData.NoteType.KA_BIG, 0.0)
	add_child_autofree(ka_big)
	
	assert_true(ka_big.needs_ka_input(), "大蓝音符应该需要ka输入")
	assert_true(ka_big.is_big(), "应该是大音符")

## JI-001-4: 测试判定时间窗口
func test_ji001_judge_time_window() -> void:
	# 设置判定窗口
	judge_system.perfect_window = 33.0
	judge_system.good_window = 100.0
	
	# 测试良判定 (在perfect窗口内)
	var result_perfect = judge_system.judge_note(20.0, TJAData.NoteType.DON)
	assert_eq(result_perfect, "良", "20ms应该在良窗口内")
	
	# 测试可判定 (在good窗口内)
	var result_good = judge_system.judge_note(60.0, TJAData.NoteType.DON)
	assert_eq(result_good, "可", "60ms应该在可窗口内")
	
	# 测试不可判定 (超出窗口)
	var result_miss = judge_system.judge_note(150.0, TJAData.NoteType.DON)
	assert_eq(result_miss, "不可", "150ms应该超出判定窗口")

## JI-001-5: 测试输入到判定完整流程
func test_ji001_input_to_judge_flow() -> void:
	# 创建音符并设置状态
	var note = _create_test_note(TJAData.NoteType.DON, 0.0)
	add_child_autofree(note)
	note.note_state = GameNote.NoteState.JUDGING
	
	# 尝试判定
	var result = note.try_judge("don", 0.0)
	
	# 验证判定结果
	assert_eq(result, "良", "完美时机应该得到良判定")
	assert_eq(note.note_state, GameNote.NoteState.JUDGED, "音符状态应为已判定")

# ==================== JI-002: 判定到分数更新测试 ====================

## JI-002-1: 测试良判定分数更新
func test_ji002_perfect_score_update() -> void:
	judge_system.reset()
	judge_system.set_score_params(1000, 100)
	
	# 执行良判定
	judge_system.judge_note(0.0, TJAData.NoteType.DON)
	
	# 验证分数
	assert_eq(judge_system.get_score(), 1000, "良判定应得基础分数1000")

## JI-002-2: 测试可判定分数更新
func test_ji002_good_score_update() -> void:
	judge_system.reset()
	judge_system.set_score_params(1000, 100)
	
	# 执行可判定
	judge_system.judge_note(50.0, TJAData.NoteType.DON)
	
	# 可判定不计入分数，但连击增加
	assert_eq(judge_system.get_combo(), 1, "可判定应增加连击")

## JI-002-3: 测试不可判定分数更新
func test_ji002_miss_score_update() -> void:
	judge_system.reset()
	judge_system.set_score_params(1000, 100)
	
	# 先获得一些分数
	judge_system.judge_note(0.0, TJAData.NoteType.DON)
	var score_before = judge_system.get_score()
	
	# 执行不可判定
	judge_system.judge_note(200.0, TJAData.NoteType.DON)
	
	# 分数不应减少
	assert_eq(judge_system.get_score(), score_before, "不可判定不应减少分数")

## JI-002-4: 测试连击加成分数
func test_ji002_combo_bonus_score() -> void:
	judge_system.reset()
	judge_system.set_score_params(1000, 100)
	
	# 执行多次判定以获得连击加成
	for i in range(15):
		judge_system.judge_note(0.0, TJAData.NoteType.DON)
	
	# 验证连击加成生效
	# 连击超过10后开始加成
	var score = judge_system.get_score()
	var expected_base = 1000 * 15  # 无加成的基础分数
	assert_gt(score, expected_base, "有连击加成时分数应高于基础分数")

## JI-002-5: 测试Go-Go Time分数加成
func test_ji002_gogo_score_bonus() -> void:
	judge_system.reset()
	judge_system.set_score_params(1000, 100)
	
	# 正常判定
	judge_system.judge_note(0.0, TJAData.NoteType.DON)
	var normal_score = judge_system.get_score()
	
	# 重置并启用Go-Go Time
	judge_system.reset()
	judge_system.set_gogo_time(true)
	judge_system.judge_note(0.0, TJAData.NoteType.DON)
	var gogo_score = judge_system.get_score()
	
	# Go-Go Time分数应为1.2倍
	assert_gt(gogo_score, normal_score, "Go-Go Time分数应高于正常分数")

## JI-002-6: 测试分数更新信号
func test_ji002_score_update_signal() -> void:
	judge_system.reset()
	
	# 监听分数更新信号（使用字典存储以解决闭包捕获问题）
	var score_data = {"received": 0}
	judge_system.score_updated.connect(func(score): score_data.received = score)
	
	# 执行判定
	judge_system.judge_note(0.0, TJAData.NoteType.DON)
	
	# 验证信号触发
	assert_eq(score_data.received, judge_system.get_score(), "分数更新信号应携带正确分数")

# ==================== JI-003: 判定到连击更新测试 ====================

## JI-003-1: 测试良判定连击增加
func test_ji003_perfect_combo_increase() -> void:
	judge_system.reset()
	
	# 执行良判定
	judge_system.judge_note(0.0, TJAData.NoteType.DON)
	
	assert_eq(judge_system.get_combo(), 1, "良判定应增加连击")

## JI-003-2: 测试可判定连击增加
func test_ji003_good_combo_increase() -> void:
	judge_system.reset()
	
	# 执行可判定
	judge_system.judge_note(50.0, TJAData.NoteType.DON)
	
	assert_eq(judge_system.get_combo(), 1, "可判定应增加连击")

## JI-003-3: 测试不可判定连击重置
func test_ji003_miss_combo_reset() -> void:
	judge_system.reset()
	
	# 先建立连击
	for i in range(5):
		judge_system.judge_note(0.0, TJAData.NoteType.DON)
	
	assert_eq(judge_system.get_combo(), 5, "应建立5连击")
	
	# 执行不可判定
	judge_system.judge_note(200.0, TJAData.NoteType.DON)
	
	assert_eq(judge_system.get_combo(), 0, "不可判定应重置连击")

## JI-003-4: 测试最大连击更新
func test_ji003_max_combo_update() -> void:
	judge_system.reset()
	
	# 建立连击
	for i in range(10):
		judge_system.judge_note(0.0, TJAData.NoteType.DON)
	
	assert_eq(judge_system.get_max_combo(), 10, "最大连击应为10")
	
	# 断开连击
	judge_system.judge_note(200.0, TJAData.NoteType.DON)
	
	# 最大连击应保持
	assert_eq(judge_system.get_max_combo(), 10, "最大连击应保持10")
	
	# 重新建立连击
	for i in range(5):
		judge_system.judge_note(0.0, TJAData.NoteType.DON)
	
	# 最大连击仍应为10
	assert_eq(judge_system.get_max_combo(), 10, "最大连击应保持10")

## JI-003-5: 测试连击更新信号
func test_ji003_combo_update_signal() -> void:
	judge_system.reset()
	
	# 监听连击更新信号（使用字典存储以解决闭包捕获问题）
	var combo_data = {"received": 0}
	judge_system.combo_updated.connect(func(combo): combo_data.received = combo)
	
	# 执行判定
	judge_system.judge_note(0.0, TJAData.NoteType.DON)
	
	# 验证信号触发
	assert_eq(combo_data.received, 1, "连击更新信号应携带正确连击数")

# ==================== JI-004: 判定到魂槽更新测试 ====================

## JI-004-1: 测试良判定魂槽增加
func test_ji004_perfect_soul_gauge_increase() -> void:
	judge_system.reset()
	
	var initial_soul = judge_system.soul_gauge
	
	# 执行良判定
	judge_system.judge_note(0.0, TJAData.NoteType.DON)
	
	# 验证魂槽增加
	assert_gt(judge_system.soul_gauge, initial_soul, "良判定应增加魂槽")

## JI-004-2: 测试可判定魂槽增加
func test_ji004_good_soul_gauge_increase() -> void:
	judge_system.reset()
	
	var initial_soul = judge_system.soul_gauge
	
	# 执行可判定
	judge_system.judge_note(50.0, TJAData.NoteType.DON)
	
	# 验证魂槽增加（可判定增加较少）
	assert_gt(judge_system.soul_gauge, initial_soul, "可判定应增加魂槽")

## JI-004-3: 测试不可判定魂槽减少
func test_ji004_miss_soul_gauge_decrease() -> void:
	judge_system.reset()
	
	# 先增加一些魂槽
	judge_system.judge_note(0.0, TJAData.NoteType.DON)
	var soul_before_miss = judge_system.soul_gauge
	
	# 执行不可判定
	judge_system.judge_note(200.0, TJAData.NoteType.DON)
	
	# 验证魂槽减少
	assert_lt(judge_system.soul_gauge, soul_before_miss, "不可判定应减少魂槽")

## JI-004-4: 测试魂槽上下限
func test_ji004_soul_gauge_limits() -> void:
	judge_system.reset()
	
	# 测试上限
	for i in range(200):
		judge_system.judge_note(0.0, TJAData.NoteType.DON)
	
	assert_lt(judge_system.soul_gauge, judge_system.max_soul_gauge + 1, "魂槽不应超过上限")
	
	# 重置并测试下限
	judge_system.reset()
	
	for i in range(200):
		judge_system.judge_note(200.0, TJAData.NoteType.DON)
	
	assert_gt(judge_system.soul_gauge, -1, "魂槽不应低于0")

## JI-004-5: 测试清除状态判定
func test_ji004_clear_status() -> void:
	judge_system.reset()
	
	# 初始状态未清除
	assert_false(judge_system.is_clear_status(), "初始状态应未清除")
	
	# 增加魂槽到清除阈值
	while judge_system.soul_gauge < judge_system.soul_threshold_clear:
		judge_system.judge_note(0.0, TJAData.NoteType.DON)
	
	# 验证清除状态
	assert_true(judge_system.is_clear_status(), "魂槽达到阈值应清除")

## JI-004-6: 测试魂槽更新信号
func test_ji004_soul_gauge_signal() -> void:
	judge_system.reset()
	
	# 监听魂槽更新信号（使用字典存储以解决闭包捕获问题）
	var soul_data = {"received": 0.0}
	judge_system.soul_gauge_updated.connect(func(gauge): soul_data.received = gauge)
	
	# 执行判定
	judge_system.judge_note(0.0, TJAData.NoteType.DON)
	
	# 验证信号触发
	assert_eq(soul_data.received, judge_system.soul_gauge, "魂槽更新信号应携带正确值")

# ==================== JI-005: 信号正确传递测试 ====================

## JI-005-1: 测试判定结果信号
func test_ji005_judge_result_signal() -> void:
	judge_system.reset()
	
	# 监听判定结果信号（使用字典存储以解决闭包捕获问题）
	var result_data = {"judge_type": "", "note_type": 0}
	judge_system.judge_result.connect(func(judge_type, note_type): 
		result_data.judge_type = judge_type
		result_data.note_type = note_type
	)
	
	# 执行判定
	judge_system.judge_note(0.0, TJAData.NoteType.DON)
	
	# 验证信号参数
	assert_eq(result_data.judge_type, "良", "判定类型应为良")
	assert_eq(result_data.note_type, TJAData.NoteType.DON, "音符类型应正确")

## JI-005-2: 测试全连信号
func test_ji005_full_combo_signal() -> void:
	judge_system.reset()
	judge_system.set_total_notes(5)
	
	# 监听全连信号（使用字典存储以解决闭包捕获问题）
	var full_combo_data = {"received": false}
	judge_system.full_combo_achieved.connect(func(): full_combo_data.received = true)
	
	# 执行全部良判定
	for i in range(5):
		judge_system.judge_note(0.0, TJAData.NoteType.DON)
	
	# 检查游戏结束状态
	var result = judge_system.check_game_end()
	
	assert_true(result.full_combo, "应该达成全连")
	assert_true(full_combo_data.received, "应该触发全连信号")

## JI-005-3: 测试全良信号
func test_ji005_dondoko_full_combo_signal() -> void:
	judge_system.reset()
	judge_system.set_total_notes(5)
	
	# 监听全良信号（使用字典存储以解决闭包捕获问题）
	var dondoko_data = {"received": false}
	judge_system.dondoko_full_combo_achieved.connect(func(): dondoko_data.received = true)
	
	# 执行全部良判定
	for i in range(5):
		judge_system.judge_note(0.0, TJAData.NoteType.DON)
	
	# 检查游戏结束状态
	var result = judge_system.check_game_end()
	
	assert_true(result.dondoko_full_combo, "应该达成全良")
	assert_true(dondoko_data.received, "应该触发全良信号")

## JI-005-4: 测试信号顺序
func test_ji005_signal_order() -> void:
	judge_system.reset()
	
	var signal_order: Array = []
	
	judge_system.judge_result.connect(func(_t, _n): signal_order.append("judge_result"))
	judge_system.score_updated.connect(func(_s): signal_order.append("score_updated"))
	judge_system.combo_updated.connect(func(_c): signal_order.append("combo_updated"))
	judge_system.soul_gauge_updated.connect(func(_g): signal_order.append("soul_gauge"))
	
	# 执行判定
	judge_system.judge_note(0.0, TJAData.NoteType.DON)
	
	# 验证信号顺序
	assert_eq(signal_order.size(), 4, "应该触发4个信号")
	assert_eq(signal_order[0], "judge_result", "第一个信号应为judge_result")

## JI-005-5: 测试音符判定信号传递
func test_ji005_note_judge_signal() -> void:
	# 创建音符
	var note = _create_test_note(TJAData.NoteType.DON, 0.0)
	add_child_autofree(note)
	note.note_state = GameNote.NoteState.JUDGING
	
	# 监听音符判定信号（使用字典存储以解决闭包捕获问题）
	var judge_data = {"result": ""}
	note.note_judged.connect(func(_note, result): judge_data.result = result)
	
	# 执行判定
	note.try_judge("don", 0.0)
	
	# 验证信号
	assert_eq(judge_data.result, "良", "音符判定信号应携带正确结果")

# ==================== 系统协作测试 ====================

## 测试NoteManager与JudgeSystem协作
func test_note_manager_judge_system_collaboration() -> void:
	# 创建测试谱面
	var course = _create_test_course_for_judge()
	
	# 加载谱面
	note_manager.load_chart(course, 0.0)
	
	# 验证系统关联
	assert_not_null(note_manager.judge_system, "NoteManager应有JudgeSystem引用")

## 测试判定结果影响GameState
func test_judge_affects_game_state() -> void:
	judge_system.reset()
	
	# 执行判定
	judge_system.judge_note(0.0, TJAData.NoteType.DON)
	
	# 验证判定统计
	var counts = judge_system.get_judge_counts()
	assert_eq(counts["良"], 1, "应有1个良判定")

## 测试完整判定流程
func test_complete_judge_flow() -> void:
	judge_system.reset()
	judge_system.set_total_notes(10)
	judge_system.set_score_params(1000, 100)
	
	# 监听所有信号
	var signals_received: Array = []
	judge_system.judge_result.connect(func(_t, _n): signals_received.append("judge"))
	judge_system.score_updated.connect(func(_s): signals_received.append("score"))
	judge_system.combo_updated.connect(func(_c): signals_received.append("combo"))
	judge_system.soul_gauge_updated.connect(func(_g): signals_received.append("soul"))
	
	# 执行判定序列
	for i in range(8):
		judge_system.judge_note(0.0, TJAData.NoteType.DON)
	
	judge_system.judge_note(50.0, TJAData.NoteType.KA)  # 可
	judge_system.judge_note(200.0, TJAData.NoteType.DON)  # 不可
	
	# 验证最终状态
	var result = judge_system.check_game_end()
	assert_eq(result.perfect_count, 8, "应有8个良")
	assert_eq(result.good_count, 1, "应有1个可")
	assert_eq(result.miss_count, 1, "应有1个不可")
	assert_eq(result.max_combo, 9, "最大连击应为9")
	assert_false(result.full_combo, "不应全连")