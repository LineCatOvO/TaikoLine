## 游戏状态单元测试
## 测试 GameState 的状态管理、判定添加、连击更新
## 测试框架：GUT v9.6.0

extends GutTest

var game_state: Node = null


func before_all() -> void:
	pass


func before_each() -> void:
	# 创建游戏状态实例（模拟autoload）
	game_state = load("res://src/autoload/game_state.gd").new()
	add_child(game_state)


func after_each() -> void:
	if game_state:
		game_state.queue_free()
		game_state = null


func after_all() -> void:
	pass


# =============================================================================
# GST-001: 状态重置
# 测试 reset_game_state 方法恢复初始状态
# =============================================================================
func test_gst_001_state_reset() -> void:
	# 建立一些状态
	game_state.current_score = 10000
	game_state.current_combo = 50
	game_state.max_combo = 100
	game_state.judge_counts = {"良": 10, "可": 5, "不可": 3}
	game_state.current_song = {"title": "Test Song"}
	game_state.current_course = "Oni"

	# 验证状态已改变
	assert_eq(game_state.current_score, 10000, "分数应为10000")
	assert_eq(game_state.current_combo, 50, "连击应为50")
	assert_eq(game_state.max_combo, 100, "最大连击应为100")

	# 执行重置
	game_state.reset_game_state()

	# 验证状态恢复初始值
	assert_eq(game_state.current_score, 0, "重置后分数应为0")
	assert_eq(game_state.current_combo, 0, "重置后连击应为0")
	assert_eq(game_state.max_combo, 0, "重置后最大连击应为0")
	assert_eq(game_state.judge_counts["良"], 0, "重置后良计数应为0")
	assert_eq(game_state.judge_counts["可"], 0, "重置后可计数应为0")
	assert_eq(game_state.judge_counts["不可"], 0, "重置后不可计数应为0")

	# 注意：current_song 和 current_course 不应被重置
	assert_eq(game_state.current_song, {"title": "Test Song"}, "歌曲信息不应被重置")
	assert_eq(game_state.current_course, "Oni", "难度不应被重置")


# =============================================================================
# GST-002: 判定添加-良
# 测试添加良判定
# =============================================================================
func test_gst_002_add_judge_perfect() -> void:
	game_state.reset_game_state()

	# 添加良判定
	game_state.add_judge("良")

	# 验证判定统计
	assert_eq(game_state.judge_counts["良"], 1, "良计数应为1")
	assert_eq(game_state.judge_counts["可"], 0, "可计数应为0")
	assert_eq(game_state.judge_counts["不可"], 0, "不可计数应为0")

	# 验证连击
	assert_eq(game_state.current_combo, 1, "连击应为1")

	# 添加更多良判定
	game_state.add_judge("良")
	game_state.add_judge("良")

	assert_eq(game_state.judge_counts["良"], 3, "良计数应为3")
	assert_eq(game_state.current_combo, 3, "连击应为3")


# =============================================================================
# GST-003: 判定添加-可
# 测试添加可判定
# =============================================================================
func test_gst_003_add_judge_good() -> void:
	game_state.reset_game_state()

	# 添加可判定
	game_state.add_judge("可")

	# 验证判定统计
	assert_eq(game_state.judge_counts["良"], 0, "良计数应为0")
	assert_eq(game_state.judge_counts["可"], 1, "可计数应为1")
	assert_eq(game_state.judge_counts["不可"], 0, "不可计数应为0")

	# 验证连击
	assert_eq(game_state.current_combo, 1, "连击应为1")

	# 添加更多可判定
	game_state.add_judge("可")
	game_state.add_judge("可")

	assert_eq(game_state.judge_counts["可"], 3, "可计数应为3")
	assert_eq(game_state.current_combo, 3, "连击应为3")


# =============================================================================
# GST-004: 判定添加-不可
# 测试添加不可判定
# =============================================================================
func test_gst_004_add_judge_miss() -> void:
	game_state.reset_game_state()

	# 先建立连击
	game_state.add_judge("良")
	game_state.add_judge("良")
	game_state.add_judge("良")
	assert_eq(game_state.current_combo, 3, "建立3连击")

	# 添加不可判定
	game_state.add_judge("不可")

	# 验证判定统计
	assert_eq(game_state.judge_counts["良"], 3, "良计数应为3")
	assert_eq(game_state.judge_counts["不可"], 1, "不可计数应为1")

	# 验证连击归零
	assert_eq(game_state.current_combo, 0, "不可判定后连击应归零")


# =============================================================================
# GST-005: 最大连击更新
# 测试最大连击的更新逻辑
# =============================================================================
func test_gst_005_max_combo_update() -> void:
	game_state.reset_game_state()

	# 初始最大连击为0
	assert_eq(game_state.max_combo, 0, "初始最大连击应为0")

	# 建立5连击
	for i in range(5):
		game_state.add_judge("良")

	assert_eq(game_state.current_combo, 5, "当前连击应为5")
	assert_eq(game_state.max_combo, 5, "最大连击应更新为5")

	# 断开连击
	game_state.add_judge("不可")
	assert_eq(game_state.current_combo, 0, "当前连击归零")
	assert_eq(game_state.max_combo, 5, "最大连击应保持5")

	# 重新建立3连击（不超过最大值）
	for i in range(3):
		game_state.add_judge("良")

	assert_eq(game_state.current_combo, 3, "当前连击为3")
	assert_eq(game_state.max_combo, 5, "最大连击仍为5")

	# 继续建立连击超过最大值
	game_state.add_judge("良")
	game_state.add_judge("良")
	game_state.add_judge("良")
	assert_eq(game_state.current_combo, 6, "当前连击为6")
	assert_eq(game_state.max_combo, 6, "最大连击应更新为6")


# =============================================================================
# 附加测试：混合判定
# =============================================================================
func test_mixed_judges() -> void:
	game_state.reset_game_state()

	# 混合判定
	game_state.add_judge("良")
	game_state.add_judge("可")
	game_state.add_judge("良")
	game_state.add_judge("不可")
	game_state.add_judge("良")

	# 验证统计
	assert_eq(game_state.judge_counts["良"], 3, "良计数应为3")
	assert_eq(game_state.judge_counts["可"], 1, "可计数应为1")
	assert_eq(game_state.judge_counts["不可"], 1, "不可计数应为1")

	# 验证连击（不可后重置，然后1连击）
	assert_eq(game_state.current_combo, 1, "当前连击应为1")


# =============================================================================
# 附加测试：无效判定类型
# =============================================================================
func test_invalid_judge_type() -> void:
	game_state.reset_game_state()

	# 添加无效判定类型
	game_state.add_judge("invalid")

	# 验证不会崩溃，且不增加任何计数
	assert_eq(game_state.judge_counts["良"], 0, "良计数应为0")
	assert_eq(game_state.judge_counts["可"], 0, "可计数应为0")
	assert_eq(game_state.judge_counts["不可"], 0, "不可计数应为0")


# =============================================================================
# 附加测试：连击保持（良和可）
# =============================================================================
func test_combo_maintained_with_good() -> void:
	game_state.reset_game_state()

	# 良判定保持连击
	game_state.add_judge("良")
	assert_eq(game_state.current_combo, 1, "良判定连击+1")

	# 可判定也保持连击
	game_state.add_judge("可")
	assert_eq(game_state.current_combo, 2, "可判定连击+1")

	# 再次良判定
	game_state.add_judge("良")
	assert_eq(game_state.current_combo, 3, "良判定连击+1")


# =============================================================================
# 附加测试：初始状态
# =============================================================================
func test_initial_state() -> void:
	# 创建新实例测试初始状态
	var new_state = load("res://src/autoload/game_state.gd").new()
	add_child(new_state)

	assert_eq(new_state.current_score, 0, "初始分数应为0")
	assert_eq(new_state.current_combo, 0, "初始连击应为0")
	assert_eq(new_state.max_combo, 0, "初始最大连击应为0")
	assert_eq(new_state.current_song, {}, "初始歌曲应为空字典")
	assert_eq(new_state.current_course, "Oni", "默认难度应为Oni")

	new_state.queue_free()


# =============================================================================
# 附加测试：歌曲和难度设置
# =============================================================================
func test_song_and_course_setting() -> void:
	game_state.reset_game_state()

	# 设置歌曲
	game_state.current_song = {
		"title": "Test Song",
		"artist": "Test Artist",
		"bpm": 120.0
	}
	assert_eq(game_state.current_song["title"], "Test Song", "歌曲标题应正确")

	# 设置难度
	game_state.current_course = "Hard"
	assert_eq(game_state.current_course, "Hard", "难度应正确设置")

	# 重置游戏状态不应影响歌曲和难度
	game_state.reset_game_state()
	assert_eq(game_state.current_song["title"], "Test Song", "重置后歌曲应保持")
	assert_eq(game_state.current_course, "Hard", "重置后难度应保持")


# =============================================================================
# 附加测试：大量连击
# =============================================================================
func test_large_combo() -> void:
	game_state.reset_game_state()

	# 建立大量连击
	for i in range(1000):
		game_state.add_judge("良")

	assert_eq(game_state.current_combo, 1000, "连击应为1000")
	assert_eq(game_state.max_combo, 1000, "最大连击应为1000")
	assert_eq(game_state.judge_counts["良"], 1000, "良计数应为1000")


# =============================================================================
# 附加测试：连击重置后重建
# =============================================================================
func test_combo_rebuild_after_reset() -> void:
	game_state.reset_game_state()

	# 建立连击
	for i in range(10):
		game_state.add_judge("良")
	assert_eq(game_state.max_combo, 10, "最大连击为10")

	# 断开连击
	game_state.add_judge("不可")
	assert_eq(game_state.current_combo, 0, "连击归零")

	# 重建连击
	for i in range(15):
		game_state.add_judge("良")
	assert_eq(game_state.current_combo, 15, "新连击为15")
	assert_eq(game_state.max_combo, 15, "最大连击更新为15")


# =============================================================================
# 附加测试：判定统计完整性
# =============================================================================
func test_judge_counts_total() -> void:
	game_state.reset_game_state()

	# 执行混合判定
	var perfect_count = 50
	var good_count = 30
	var miss_count = 20

	for i in range(perfect_count):
		game_state.add_judge("良")
	for i in range(good_count):
		game_state.add_judge("可")
	for i in range(miss_count):
		game_state.add_judge("不可")

	# 验证总数
	var total = game_state.judge_counts["良"] + game_state.judge_counts["可"] + game_state.judge_counts["不可"]
	assert_eq(total, 100, "总判定数应为100")


# =============================================================================
# 附加测试：连续不可判定
# =============================================================================
func test_consecutive_misses() -> void:
	game_state.reset_game_state()

	# 连续不可判定
	for i in range(10):
		game_state.add_judge("不可")

	assert_eq(game_state.judge_counts["不可"], 10, "不可计数应为10")
	assert_eq(game_state.current_combo, 0, "连击应保持0")
	assert_eq(game_state.max_combo, 0, "最大连击应为0")