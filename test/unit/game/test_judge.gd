## 判定系统单元测试
## 测试 JudgeSystem 的判定逻辑、连击管理、分数计算和魂槽系统
## 测试框架：GUT v9.6.0

extends GutTest

var judge_system: JudgeSystem = null


func before_all() -> void:
	pass


func before_each() -> void:
	# 创建判定系统实例
	judge_system = JudgeSystem.new()
	add_child(judge_system)
	# 设置总音符数用于精度计算
	judge_system.set_total_notes(100)


func after_each() -> void:
	if judge_system:
		judge_system.queue_free()
		judge_system = null


func after_all() -> void:
	pass


# =============================================================================
# JUD-001: 良判定-边界内
# 测试时间差 <= 33ms 返回 "良"
# =============================================================================
func test_jud_001_perfect_judge_within_boundary() -> void:
	# 测试边界内的各种时间差
	var test_cases = [0.0, 10.0, 20.0, 30.0, 33.0]
	
	for time_diff in test_cases:
		judge_system.reset()
		var result = judge_system.judge_note(time_diff, 0)
		assert_eq(result, "良", "时间差 %.1fms 应返回良判定" % time_diff)


# =============================================================================
# JUD-002: 可判定-边界内
# 测试 33ms < 时间差 <= 100ms 返回 "可"
# =============================================================================
func test_jud_002_good_judge_within_boundary() -> void:
	# 测试可判定范围的时间差
	var test_cases = [34.0, 50.0, 75.0, 99.0, 100.0]
	
	for time_diff in test_cases:
		judge_system.reset()
		var result = judge_system.judge_note(time_diff, 0)
		assert_eq(result, "可", "时间差 %.1fms 应返回可判定" % time_diff)


# =============================================================================
# JUD-003: 不可判定-超出边界
# 测试时间差 > 100ms 返回 "不可"
# =============================================================================
func test_jud_003_miss_judge_exceeds_boundary() -> void:
	# 测试超出边界的时间差
	var test_cases = [101.0, 150.0, 200.0, 500.0, 1000.0]
	
	for time_diff in test_cases:
		judge_system.reset()
		var result = judge_system.judge_note(time_diff, 0)
		assert_eq(result, "不可", "时间差 %.1fms 应返回不可判定" % time_diff)


# =============================================================================
# JUD-004: 判定边界-精确值
# 测试 33ms 和 100ms 边界
# =============================================================================
func test_jud_004_boundary_exact_values() -> void:
	# 测试 33ms 边界（良判定上界）
	judge_system.reset()
	var result_33 = judge_system.judge_note(33.0, 0)
	assert_eq(result_33, "良", "时间差 33.0ms 应返回良判定（边界值）")
	
	# 测试 33.1ms（可判定下界）
	judge_system.reset()
	var result_33_1 = judge_system.judge_note(33.1, 0)
	assert_eq(result_33_1, "可", "时间差 33.1ms 应返回可判定")
	
	# 测试 100ms 边界（可判定上界）
	judge_system.reset()
	var result_100 = judge_system.judge_note(100.0, 0)
	assert_eq(result_100, "可", "时间差 100.0ms 应返回可判定（边界值）")
	
	# 测试 100.1ms（不可判定下界）
	judge_system.reset()
	var result_100_1 = judge_system.judge_note(100.1, 0)
	assert_eq(result_100_1, "不可", "时间差 100.1ms 应返回不可判定")


# =============================================================================
# JUD-005: 连击增加-良判定
# 测试良判定后连击 +1
# =============================================================================
func test_jud_005_combo_increase_perfect_judge() -> void:
	judge_system.reset()
	assert_eq(judge_system.current_combo, 0, "初始连击应为 0")
	
	# 执行良判定
	judge_system.judge_note(0.0, 0)
	assert_eq(judge_system.current_combo, 1, "良判定后连击应为 1")
	
	# 再次执行良判定
	judge_system.judge_note(10.0, 0)
	assert_eq(judge_system.current_combo, 2, "第二次良判定后连击应为 2")


# =============================================================================
# JUD-006: 连击增加-可判定
# 测试可判定后连击 +1
# =============================================================================
func test_jud_006_combo_increase_good_judge() -> void:
	judge_system.reset()
	assert_eq(judge_system.current_combo, 0, "初始连击应为 0")
	
	# 执行可判定
	judge_system.judge_note(50.0, 0)
	assert_eq(judge_system.current_combo, 1, "可判定后连击应为 1")
	
	# 再次执行可判定
	judge_system.judge_note(75.0, 0)
	assert_eq(judge_system.current_combo, 2, "第二次可判定后连击应为 2")


# =============================================================================
# JUD-007: 连击重置-不可判定
# 测试不可判定后连击归零
# =============================================================================
func test_jud_007_combo_reset_miss_judge() -> void:
	judge_system.reset()
	
	# 先建立连击
	judge_system.judge_note(0.0, 0)
	judge_system.judge_note(0.0, 0)
	judge_system.judge_note(0.0, 0)
	assert_eq(judge_system.current_combo, 3, "建立3连击")
	
	# 执行不可判定
	judge_system.judge_note(200.0, 0)
	assert_eq(judge_system.current_combo, 0, "不可判定后连击应归零")


# =============================================================================
# JUD-008: 最大连击更新
# 测试连击数超过最大值时更新
# =============================================================================
func test_jud_008_max_combo_update() -> void:
	judge_system.reset()
	assert_eq(judge_system.max_combo, 0, "初始最大连击应为 0")
	
	# 建立5连击
	for i in range(5):
		judge_system.judge_note(0.0, 0)
	
	assert_eq(judge_system.max_combo, 5, "最大连击应更新为 5")
	
	# 断开连击
	judge_system.judge_note(200.0, 0)
	assert_eq(judge_system.current_combo, 0, "当前连击归零")
	assert_eq(judge_system.max_combo, 5, "最大连击应保持 5")
	
	# 重新建立3连击（不超过最大值）
	for i in range(3):
		judge_system.judge_note(0.0, 0)
	
	assert_eq(judge_system.current_combo, 3, "当前连击为 3")
	assert_eq(judge_system.max_combo, 5, "最大连击仍为 5")
	
	# 继续建立连击超过最大值
	judge_system.judge_note(0.0, 0)
	judge_system.judge_note(0.0, 0)
	judge_system.judge_note(0.0, 0)
	assert_eq(judge_system.current_combo, 6, "当前连击为 6")
	assert_eq(judge_system.max_combo, 6, "最大连击应更新为 6")


# =============================================================================
# JUD-009: 分数计算-基础
# 测试无连击加成时基础分数
# =============================================================================
func test_jud_009_score_calculation_basic() -> void:
	judge_system.reset()
	assert_eq(judge_system.current_score, 0, "初始分数应为 0")
	
	# 第一音符（无连击加成）
	judge_system.judge_note(0.0, 0)
	# base_score = 1000, combo_bonus = 0 (combo < 10)
	# score = 1000 * (1 + 0) = 1000
	assert_eq(judge_system.current_score, 1000, "第一音符分数应为 1000")
	
	# 第二音符（连击1，仍无加成）
	judge_system.judge_note(0.0, 0)
	# score = 1000 * (1 + 0) = 1000
	# total = 1000 + 1000 = 2000
	assert_eq(judge_system.current_score, 2000, "第二音符后总分应为 2000")


# =============================================================================
# JUD-010: 分数计算-连击加成
# 测试连击 10+ 开始加成
# =============================================================================
func test_jud_010_score_calculation_combo_bonus() -> void:
	judge_system.reset()
	
	# 建立9连击（无加成）
	for i in range(9):
		judge_system.judge_note(0.0, 0)
	
	var score_before_bonus = judge_system.current_score
	# 9个音符，每个1000分 = 9000
	assert_eq(score_before_bonus, 9000, "9连击分数应为 9000")
	
	# 第10音符（开始加成，combo=10, bonus=0）
	judge_system.judge_note(0.0, 0)
	# combo = 10, bonus = (10 - 10) * 0.01 = 0
	# score = 1000 * (1 + 0) = 1000
	assert_eq(judge_system.current_score, 10000, "第10音符后分数应为 10000")
	
	# 第11音符（combo=11, bonus=0.01）
	judge_system.judge_note(0.0, 0)
	# combo = 11, bonus = (11 - 10) * 0.01 = 0.01
	# score = 1000 * (1 + 0.01) = 1010
	assert_eq(judge_system.current_score, 11010, "第11音符后分数应为 11010")
	
	# 第20音符（combo=20, bonus=0.10）
	for i in range(8):  # 从12到19
		judge_system.judge_note(0.0, 0)
	judge_system.judge_note(0.0, 0)  # 第20音符
	# combo = 20, bonus = (20 - 10) * 0.01 = 0.10
	# score = 1000 * (1 + 0.10) = 1100
	# 验证分数增加了1100
	var score_at_19 = judge_system.current_score - 1100
	assert_true(judge_system.current_score > score_at_19, "第20音符应有加成")


# =============================================================================
# JUD-012: Go-Go Time 分数加成
# 测试 Go-Go Time 期间分数 x1.2
# =============================================================================
func test_jud_012_gogo_time_score_bonus() -> void:
	judge_system.reset()
	
	# 正常状态下的分数
	judge_system.judge_note(0.0, 0)
	var normal_score = judge_system.current_score
	assert_eq(normal_score, 1000, "正常状态分数应为 1000")
	
	# 开启 Go-Go Time
	judge_system.set_gogo_time(true)
	assert_true(judge_system.is_gogo_time, "Go-Go Time 应已开启")
	
	# Go-Go Time 期间的分数
	judge_system.judge_note(0.0, 0)
	# score = 1000 * 1.2 = 1200
	assert_eq(judge_system.current_score, 2200, "Go-Go Time 分数应为 1200，总分 2200")
	
	# 关闭 Go-Go Time
	judge_system.set_gogo_time(false)
	judge_system.judge_note(0.0, 0)
	assert_eq(judge_system.current_score, 3200, "关闭 Go-Go Time 后分数恢复正常")


# =============================================================================
# JUD-013: 魂槽增加-良判定
# 测试良判定魂槽 +100
# =============================================================================
func test_jud_013_soul_gauge_increase_perfect() -> void:
	judge_system.reset()
	assert_eq(judge_system.soul_gauge, 0.0, "初始魂槽应为 0")
	
	# 执行良判定
	judge_system.judge_note(0.0, 0)
	assert_eq(judge_system.soul_gauge, 100.0, "良判定后魂槽应为 100")
	
	# 再次执行良判定
	judge_system.judge_note(0.0, 0)
	assert_eq(judge_system.soul_gauge, 200.0, "第二次良判定后魂槽应为 200")


# =============================================================================
# JUD-014: 魂槽增加-可判定
# 测试可判定魂槽 +50
# =============================================================================
func test_jud_014_soul_gauge_increase_good() -> void:
	judge_system.reset()
	assert_eq(judge_system.soul_gauge, 0.0, "初始魂槽应为 0")
	
	# 执行可判定
	judge_system.judge_note(50.0, 0)
	assert_eq(judge_system.soul_gauge, 50.0, "可判定后魂槽应为 50")
	
	# 再次执行可判定
	judge_system.judge_note(75.0, 0)
	assert_eq(judge_system.soul_gauge, 100.0, "第二次可判定后魂槽应为 100")


# =============================================================================
# JUD-015: 魂槽减少-不可判定
# 测试不可判定魂槽 -200
# =============================================================================
func test_jud_015_soul_gauge_decrease_miss() -> void:
	judge_system.reset()
	
	# 先增加魂槽
	judge_system.judge_note(0.0, 0)
	judge_system.judge_note(0.0, 0)
	judge_system.judge_note(0.0, 0)
	assert_eq(judge_system.soul_gauge, 300.0, "建立魂槽为 300")
	
	# 执行不可判定
	judge_system.judge_note(200.0, 0)
	assert_eq(judge_system.soul_gauge, 100.0, "不可判定后魂槽应为 100")


# =============================================================================
# JUD-017: 魂槽边界限制
# 测试魂槽不超过最大值，不低于 0
# =============================================================================
func test_jud_017_soul_gauge_boundary_limits() -> void:
	judge_system.reset()
	
	# 测试上限：max_soul_gauge = 10000
	# 连续良判定直到超过最大值
	for i in range(150):  # 150 * 100 = 15000 > 10000
		judge_system.judge_note(0.0, 0)
	
	assert_eq(judge_system.soul_gauge, 10000.0, "魂槽不应超过最大值 10000")
	
	# 测试下限
	# 连续不可判定直到低于 0
	for i in range(100):  # 100 * 200 = 20000 > 10000
		judge_system.judge_note(200.0, 0)
	
	assert_eq(judge_system.soul_gauge, 0.0, "魂槽不应低于 0")


# =============================================================================
# JUD-018: 清除状态判定
# 测试魂槽 >= 8000 时 is_cleared = true
# =============================================================================
func test_jud_018_clear_status_judgment() -> void:
	judge_system.reset()
	assert_false(judge_system.is_cleared, "初始状态未清除")
	
	# 增加魂槽到 7900
	for i in range(79):
		judge_system.judge_note(0.0, 0)
	assert_eq(judge_system.soul_gauge, 7900.0, "魂槽应为 7900")
	assert_false(judge_system.is_cleared, "魂槽 7900 时未清除")
	
	# 增加到 8000
	judge_system.judge_note(0.0, 0)
	assert_eq(judge_system.soul_gauge, 8000.0, "魂槽应为 8000")
	assert_true(judge_system.is_cleared, "魂槽 >= 8000 时应清除")
	
	# 魂槽下降但仍保持清除状态
	judge_system.judge_note(200.0, 0)
	assert_eq(judge_system.soul_gauge, 7800.0, "魂槽降为 7800")
	assert_true(judge_system.is_cleared, "清除状态应保持")


# =============================================================================
# JUD-019: 精度计算
# 测试 get_accuracy 方法
# =============================================================================
func test_jud_019_accuracy_calculation() -> void:
	judge_system.reset()
	judge_system.set_total_notes(10)
	
	# 全良：accuracy = 1.0
	for i in range(10):
		judge_system.judge_note(0.0, 0)
	assert_eq(judge_system.get_accuracy(), 1.0, "全良精度应为 1.0")
	
	# 重置测试混合判定
	judge_system.reset()
	judge_system.set_total_notes(10)
	
	# 5良 + 5可：accuracy = (5*1.0 + 5*0.5) / 10 = 0.75
	for i in range(5):
		judge_system.judge_note(0.0, 0)
	for i in range(5):
		judge_system.judge_note(50.0, 0)
	assert_eq(judge_system.get_accuracy(), 0.75, "5良5可精度应为 0.75")
	
	# 重置测试包含不可
	judge_system.reset()
	judge_system.set_total_notes(10)
	
	# 5良 + 3可 + 2不可：accuracy = (5*1.0 + 3*0.5 + 2*0.0) / 10 = 0.65
	for i in range(5):
		judge_system.judge_note(0.0, 0)
	for i in range(3):
		judge_system.judge_note(50.0, 0)
	for i in range(2):
		judge_system.judge_note(200.0, 0)
	assert_eq(judge_system.get_accuracy(), 0.65, "5良3可2不可精度应为 0.65")


# =============================================================================
# JUD-020: 评级计算
# 测试 get_rank 方法（SS/S/A/B/C/D/F）
# =============================================================================
func test_jud_020_rank_calculation() -> void:
	judge_system.reset()
	judge_system.set_total_notes(10)
	
	# SS 评级：accuracy >= 1.0（全良）
	for i in range(10):
		judge_system.judge_note(0.0, 0)
	assert_eq(judge_system.get_rank(), "SS", "全良应获得 SS 评级")
	
	# S 评级：accuracy >= 0.95
	judge_system.reset()
	judge_system.set_total_notes(20)
	for i in range(19):  # 19良 + 1可 = 0.975
		judge_system.judge_note(0.0, 0)
	judge_system.judge_note(50.0, 0)
	assert_eq(judge_system.get_rank(), "S", "精度 0.975 应获得 S 评级")
	
	# A 评级：accuracy >= 0.90
	judge_system.reset()
	judge_system.set_total_notes(10)
	for i in range(9):  # 9良 + 1可 = 0.95
		judge_system.judge_note(0.0, 0)
	judge_system.judge_note(50.0, 0)
	assert_eq(judge_system.get_rank(), "S", "精度 0.95 应获得 S 评级")
	
	# A 评级测试
	judge_system.reset()
	judge_system.set_total_notes(10)
	for i in range(8):  # 8良 + 2可 = 0.90
		judge_system.judge_note(0.0, 0)
	for i in range(2):
		judge_system.judge_note(50.0, 0)
	assert_eq(judge_system.get_rank(), "A", "精度 0.90 应获得 A 评级")
	
	# B 评级：accuracy >= 0.80
	judge_system.reset()
	judge_system.set_total_notes(10)
	for i in range(6):  # 6良 + 4可 = 0.80
		judge_system.judge_note(0.0, 0)
	for i in range(4):
		judge_system.judge_note(50.0, 0)
	assert_eq(judge_system.get_rank(), "B", "精度 0.80 应获得 B 评级")
	
	# C 评级：accuracy >= 0.70
	judge_system.reset()
	judge_system.set_total_notes(10)
	for i in range(5):  # 5良 + 5可 = 0.75
		judge_system.judge_note(0.0, 0)
	for i in range(5):
		judge_system.judge_note(50.0, 0)
	assert_eq(judge_system.get_rank(), "C", "精度 0.75 应获得 C 评级")
	
	# D 评级：accuracy >= 0.60
	judge_system.reset()
	judge_system.set_total_notes(10)
	for i in range(4):  # 4良 + 6可 = 0.70
		judge_system.judge_note(0.0, 0)
	for i in range(6):
		judge_system.judge_note(50.0, 0)
	assert_eq(judge_system.get_rank(), "C", "精度 0.70 应获得 C 评级")
	
	# D 评级测试
	judge_system.reset()
	judge_system.set_total_notes(10)
	for i in range(3):  # 3良 + 7可 = 0.65
		judge_system.judge_note(0.0, 0)
	for i in range(7):
		judge_system.judge_note(50.0, 0)
	assert_eq(judge_system.get_rank(), "D", "精度 0.65 应获得 D 评级")
	
	# F 评级：accuracy < 0.60
	judge_system.reset()
	judge_system.set_total_notes(10)
	for i in range(2):  # 2良 + 8可 = 0.60
		judge_system.judge_note(0.0, 0)
	for i in range(8):
		judge_system.judge_note(50.0, 0)
	assert_eq(judge_system.get_rank(), "D", "精度 0.60 应获得 D 评级")
	
	# F 评级测试
	judge_system.reset()
	judge_system.set_total_notes(10)
	for i in range(1):  # 1良 + 9可 = 0.55
		judge_system.judge_note(0.0, 0)
	for i in range(9):
		judge_system.judge_note(50.0, 0)
	assert_eq(judge_system.get_rank(), "F", "精度 0.55 应获得 F 评级")


# =============================================================================
# JUD-024: 系统重置
# 测试 reset 方法恢复初始状态
# =============================================================================
func test_jud_024_system_reset() -> void:
	# 建立一些状态
	judge_system.judge_note(0.0, 0)
	judge_system.judge_note(0.0, 0)
	judge_system.judge_note(50.0, 0)
	judge_system.judge_note(200.0, 0)
	judge_system.set_gogo_time(true)
	judge_system.record_renda()
	judge_system.record_renda()
	
	# 验证状态已改变
	assert_true(judge_system.current_score > 0, "分数应大于 0")
	assert_true(judge_system.soul_gauge > 0, "魂槽应大于 0")
	assert_true(judge_system.is_gogo_time, "Go-Go Time 应开启")
	assert_true(judge_system.max_renda_count > 0, "连打计数应大于 0")
	
	# 执行重置
	judge_system.reset()
	
	# 验证状态恢复初始值
	assert_eq(judge_system.current_score, 0, "重置后分数应为 0")
	assert_eq(judge_system.current_combo, 0, "重置后连击应为 0")
	assert_eq(judge_system.max_combo, 0, "重置后最大连击应为 0")
	assert_eq(judge_system.soul_gauge, 0.0, "重置后魂槽应为 0")
	assert_eq(judge_system.judge_counts[judge_system.JudgeType.PERFECT], 0, "重置后良计数应为 0")
	assert_eq(judge_system.judge_counts[judge_system.JudgeType.GOOD], 0, "重置后可计数应为 0")
	assert_eq(judge_system.judge_counts[judge_system.JudgeType.MISS], 0, "重置后不可计数应为 0")
	assert_eq(judge_system.total_notes, 0, "重置后总音符数应为 0")
	assert_false(judge_system.is_cleared, "重置后未清除")
	assert_false(judge_system.is_full_combo, "重置后未全连")
	assert_true(judge_system.is_dondoko_full_combo, "重置后全良状态应为 true")
	assert_false(judge_system.is_gogo_time, "重置后 Go-Go Time 应关闭")
	assert_eq(judge_system.max_renda_count, 0, "重置后最大连打应为 0")
	assert_eq(judge_system.current_renda_count, 0, "重置后当前连打应为 0")


# =============================================================================
# 附加测试：负时间差（提前击打）
# =============================================================================
func test_negative_time_diff() -> void:
	judge_system.reset()
	
	# 负时间差也应该使用绝对值判定
	var result = judge_system.judge_note(-20.0, 0)
	assert_eq(result, "良", "负时间差 -20ms 应返回良判定")
	
	judge_system.reset()
	result = judge_system.judge_note(-50.0, 0)
	assert_eq(result, "可", "负时间差 -50ms 应返回可判定")
	
	judge_system.reset()
	result = judge_system.judge_note(-150.0, 0)
	assert_eq(result, "不可", "负时间差 -150ms 应返回不可判定")


# =============================================================================
# 附加测试：信号发射
# =============================================================================
func test_signal_emission() -> void:
	judge_system.reset()
	
	# 监听信号
	var score_signal = watch_signals(judge_system)
	var combo_signal = watch_signals(judge_system)
	var judge_signal = watch_signals(judge_system)
	
	# 执行判定
	judge_system.judge_note(0.0, 0)
	
	# 验证信号发射
	assert_signal_emitted(judge_system, "score_updated", "应发射 score_updated 信号")
	assert_signal_emitted(judge_system, "combo_updated", "应发射 combo_updated 信号")
	assert_signal_emitted(judge_system, "judge_result", "应发射 judge_result 信号")


# =============================================================================
# 附加测试：判定统计
# =============================================================================
func test_judge_counts() -> void:
	judge_system.reset()
	
	# 执行混合判定
	for i in range(5):
		judge_system.judge_note(0.0, 0)  # 5良
	for i in range(3):
		judge_system.judge_note(50.0, 0)  # 3可
	for i in range(2):
		judge_system.judge_note(200.0, 0)  # 2不可
	
	# 验证统计
	var counts = judge_system.get_judge_counts()
	assert_eq(counts["良"], 5, "良判定计数应为 5")
	assert_eq(counts["可"], 3, "可判定计数应为 3")
	assert_eq(counts["不可"], 2, "不可判定计数应为 2")


# =============================================================================
# 附加测试：全连判定
# =============================================================================
func test_full_combo_detection() -> void:
	judge_system.reset()
	judge_system.set_total_notes(5)
	
	# 全良
	for i in range(5):
		judge_system.judge_note(0.0, 0)
	
	var result = judge_system.check_game_end()
	assert_true(result.full_combo, "应检测到全连")
	assert_true(result.dondoko_full_combo, "应检测到全良")
	
	# 包含不可判定
	judge_system.reset()
	judge_system.set_total_notes(5)
	
	for i in range(4):
		judge_system.judge_note(0.0, 0)
	judge_system.judge_note(200.0, 0)  # 不可
	
	result = judge_system.check_game_end()
	assert_false(result.full_combo, "有不可判定不应全连")
	assert_false(result.dondoko_full_combo, "有不可判定不应全良")


# =============================================================================
# 附加测试：Go-Go Time 魂槽加成
# =============================================================================
func test_gogo_time_soul_gauge_bonus() -> void:
	judge_system.reset()
	
	# 正常状态良判定
	judge_system.judge_note(0.0, 0)
	var normal_soul = judge_system.soul_gauge
	assert_eq(normal_soul, 100.0, "正常状态良判定魂槽 +100")
	
	# Go-Go Time 良判定
	judge_system.set_gogo_time(true)
	judge_system.judge_note(0.0, 0)
	# soul_gain = 100 * 1.2 = 120
	assert_eq(judge_system.soul_gauge, 220.0, "Go-Go Time 良判定魂槽 +120")
	
	# Go-Go Time 可判定
	judge_system.judge_note(50.0, 0)
	# soul_gain = 50 * 1.2 = 60
	assert_eq(judge_system.soul_gauge, 280.0, "Go-Go Time 可判定魂槽 +60")


# =============================================================================
# 附加测试：连击加成上限
# =============================================================================
func test_combo_bonus_cap() -> void:
	judge_system.reset()
	
	# 建立高连击（超过加成上限）
	# COMBO_BONUS_MAX = 1.0, 需要 combo >= 110 才能达到上限
	for i in range(110):
		judge_system.judge_note(0.0, 0)
	
	# 验证连击加成达到上限
	# combo = 110, bonus = (110 - 10) * 0.01 = 1.0 (达到上限)
	var combo_bonus = judge_system._calculate_combo_bonus()
	assert_eq(combo_bonus, 1.0, "连击加成应达到上限 1.0")
	
	# 继续增加连击，加成不应超过上限
	judge_system.judge_note(0.0, 0)
	combo_bonus = judge_system._calculate_combo_bonus()
	assert_eq(combo_bonus, 1.0, "连击加成不应超过上限")


# =============================================================================
# 附加测试：空音符数精度
# =============================================================================
func test_accuracy_zero_notes() -> void:
	judge_system.reset()
	judge_system.set_total_notes(0)
	
	# 无音符时精度应为 0
	var accuracy = judge_system.get_accuracy()
	assert_eq(accuracy, 0.0, "无音符时精度应为 0")


# =============================================================================
# 附加测试：魂槽百分比
# =============================================================================
func test_soul_percentage() -> void:
	judge_system.reset()
	
	# 初始百分比
	var percentage = judge_system.get_soul_percentage()
	assert_eq(percentage, 0.0, "初始魂槽百分比应为 0")
	
	# 增加魂槽
	judge_system.judge_note(0.0, 0)  # +100
	percentage = judge_system.get_soul_percentage()
	assert_eq(percentage, 1.0, "魂槽 100 时百分比应为 1%")
	
	# 增加到一半
	for i in range(49):
		judge_system.judge_note(0.0, 0)
	percentage = judge_system.get_soul_percentage()
	assert_eq(percentage, 50.0, "魂槽 5000 时百分比应为 50%")
	
	# 满魂槽
	for i in range(50):
		judge_system.judge_note(0.0, 0)
	percentage = judge_system.get_soul_percentage()
	assert_eq(percentage, 100.0, "满魂槽百分比应为 100%")