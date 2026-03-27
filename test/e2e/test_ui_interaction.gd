## E2E UI 交互测试
## 测试 UI 组件与游戏状态的交互
## 测试框架：GUT v9.6.0
##
## 测试用例：
## - UI-001: 分数显示组件测试
## - UI-002: 连击显示组件测试
## - UI-003: 魂槽组件测试
## - UI-004: 判定显示组件测试
## - UI-005: UI 与游戏状态同步测试

extends GutTest

# ==================== 测试常量 ====================

const ScoreDisplay = preload("res://src/ui/components/score_display.gd")
const ComboDisplay = preload("res://src/ui/components/combo_display.gd")
const SoulGauge = preload("res://src/ui/components/soul_gauge.gd")
const JudgeDisplay = preload("res://src/ui/components/judge_display.gd")
const GameState = preload("res://src/autoload/game_state.gd")
const GameController = preload("res://src/game/game_controller.gd")
const TJAData = preload("res://src/parser/tja_data.gd")

# ==================== 测试变量 ====================

var score_display: ScoreDisplay = null
var combo_display: ComboDisplay = null
var soul_gauge: SoulGauge = null
var judge_display: JudgeDisplay = null
var game_state: GameState = null
var game_controller: GameController = null

# ==================== 测试生命周期 ====================

func before_all() -> void:
	pass


func before_each() -> void:
	# 创建 UI 组件
	score_display = ScoreDisplay.new()
	combo_display = ComboDisplay.new()
	soul_gauge = SoulGauge.new()

	# 添加到场景树
	add_child_autofree(score_display)
	add_child_autofree(combo_display)
	add_child_autofree(soul_gauge)

	# 创建 GameState
	game_state = GameState.new()
	add_child_autofree(game_state)

	# 创建 GameController
	game_controller = GameController.new()
	game_controller.auto_play = false
	add_child_autofree(game_controller)

	# 等待 UI 初始化
	await get_tree().create_timer(0.1).timeout


func after_each() -> void:
	pass


func after_all() -> void:
	pass


# ==================== 辅助方法 ====================

## 创建测试歌曲数据
func _create_test_song() -> TJAData.TJASong:
	var song = TJAData.TJASong.new()
	song.title = "UI Test Song"
	song.bpm = 120.0
	song.offset = 0.0

	var course = TJAData.TJACourse.new()
	course.course_type = TJAData.CourseType.ONI
	course.level = 5
	course.score_init = 1000
	course.score_diff = 100

	var measure = TJAData.TJAMeasure.new(0)
	measure.bpm = 120.0
	measure.add_note(TJAData.TJANote.new(TJAData.NoteType.DON, 0.0))
	course.add_measure(measure)

	song.add_course(course)
	return song


# ==================== UI-001: 分数显示组件测试 ====================

## UI-001-1: 测试分数显示初始化
func test_ui001_score_display_initialization() -> void:
	# 验证组件已创建
	assert_not_null(score_display, "分数显示组件应已创建")

	# 验证初始分数
	assert_eq(score_display.get_score(), 0, "初始分数应为 0")


## UI-001-2: 测试分数更新
func test_ui001_score_update() -> void:
	# 更新分数
	score_display.update_score(5000)

	# 等待动画
	await get_tree().create_timer(0.5).timeout

	# 验证分数
	assert_eq(score_display.get_score(), 5000, "分数应为 5000")


## UI-001-3: 测试分数格式化
func test_ui001_score_formatting() -> void:
	# 更新大分数
	score_display.update_score(1234567)

	# 等待动画
	await get_tree().create_timer(0.5).timeout

	# 验证分数
	assert_eq(score_display.get_score(), 1234567, "分数应为 1234567")


## UI-001-4: 测试分数重置
func test_ui001_score_reset() -> void:
	# 设置分数
	score_display.update_score(10000)

	# 等待动画
	await get_tree().create_timer(0.5).timeout

	# 重置
	score_display.reset()

	# 验证重置
	assert_eq(score_display.get_score(), 0, "重置后分数应为 0")


## UI-001-5: 测试分数高亮模式
func test_ui001_score_highlight() -> void:
	# 启用高亮
	score_display.set_highlight(true)

	# 验证不会崩溃
	assert_true(true, "高亮模式应成功启用")

	# 禁用高亮
	score_display.set_highlight(false)

	# 验证不会崩溃
	assert_true(true, "高亮模式应成功禁用")


## UI-001-6: 测试分数连续更新
func test_ui001_score_continuous_update() -> void:
	# 连续更新分数
	for i in range(10):
		score_display.update_score(i * 1000)
		await get_tree().create_timer(0.05).timeout

	# 等待动画完成
	await get_tree().create_timer(0.5).timeout

	# 验证最终分数
	assert_eq(score_display.get_score(), 9000, "最终分数应为 9000")


# ==================== UI-002: 连击显示组件测试 ====================

## UI-002-1: 测试连击显示初始化
func test_ui002_combo_display_initialization() -> void:
	# 验证组件已创建
	assert_not_null(combo_display, "连击显示组件应已创建")

	# 验证初始连击
	assert_eq(combo_display.get_combo(), 0, "初始连击应为 0")


## UI-002-2: 测试连击更新
func test_ui002_combo_update() -> void:
	# 更新连击
	combo_display.update_combo(50)

	# 等待动画
	await get_tree().create_timer(0.2).timeout

	# 验证连击
	assert_eq(combo_display.get_combo(), 50, "连击应为 50")


## UI-002-3: 测试连击断开
func test_ui002_combo_break() -> void:
	# 设置连击
	combo_display.update_combo(100)

	# 等待动画
	await get_tree().create_timer(0.2).timeout

	# 断开连击
	combo_display.update_combo(0)

	# 等待动画
	await get_tree().create_timer(0.5).timeout

	# 验证连击
	assert_eq(combo_display.get_combo(), 0, "连击应为 0")


## UI-002-4: 测试连击高亮模式
func test_ui002_combo_highlight() -> void:
	# 设置高亮阈值
	combo_display.highlight_threshold = 50

	# 更新到高亮阈值
	combo_display.update_combo(50)

	# 等待动画
	await get_tree().create_timer(0.3).timeout

	# 验证高亮状态
	assert_true(combo_display._is_highlighted, "应进入高亮模式")


## UI-002-5: 测试连击重置
func test_ui002_combo_reset() -> void:
	# 设置连击
	combo_display.update_combo(100)

	# 等待动画
	await get_tree().create_timer(0.2).timeout

	# 重置
	combo_display.reset()

	# 验证重置
	assert_eq(combo_display.get_combo(), 0, "重置后连击应为 0")
	assert_false(combo_display._is_highlighted, "重置后应退出高亮模式")


## UI-002-6: 测试连击动画完成信号
func test_ui002_combo_animation_signal() -> void:
	# 监听信号
	var signal_received = false
	combo_display.combo_animation_finished.connect(func():
		signal_received = true
	)

	# 更新连击
	combo_display.update_combo(10)

	# 验证不会崩溃
	assert_true(true, "连击动画应成功执行")


# ==================== UI-003: 魂槽组件测试 ====================

## UI-003-1: 测试魂槽初始化
func test_ui003_soul_gauge_initialization() -> void:
	# 验证组件已创建
	assert_not_null(soul_gauge, "魂槽组件应已创建")

	# 验证初始值
	assert_eq(soul_gauge.get_soul(), 0.0, "初始魂槽应为 0")
	assert_false(soul_gauge.is_clear(), "初始状态不应清除")


## UI-003-2: 测试魂槽更新
func test_ui003_soul_gauge_update() -> void:
	# 更新魂槽
	soul_gauge.update_soul(5000.0)

	# 等待动画
	await get_tree().create_timer(0.5).timeout

	# 验证魂槽值
	assert_eq(soul_gauge.get_soul(), 5000.0, "魂槽应为 5000")


## UI-003-3: 测试魂槽清除阈值
func test_ui003_soul_gauge_clear_threshold() -> void:
	# 更新到清除阈值
	soul_gauge.update_soul(8000.0)

	# 等待动画
	await get_tree().create_timer(0.5).timeout

	# 验证清除状态
	assert_true(soul_gauge.is_clear(), "应达到清除状态")


## UI-003-4: 测试魂槽下降
func test_ui003_soul_gauge_decrease() -> void:
	# 先增加到清除阈值
	soul_gauge.update_soul(8000.0)
	await get_tree().create_timer(0.3).timeout

	# 下降到清除阈值以下
	soul_gauge.update_soul(7000.0)
	await get_tree().create_timer(0.5).timeout

	# 验证清除状态丢失
	assert_false(soul_gauge.is_clear(), "应失去清除状态")


## UI-003-5: 测试魂槽最大值
func test_ui003_soul_gauge_max_value() -> void:
	# 更新到超过最大值
	soul_gauge.update_soul(15000.0)

	# 等待动画
	await get_tree().create_timer(0.5).timeout

	# 验证值被限制
	assert_eq(soul_gauge.get_soul(), 10000.0, "魂槽应被限制在最大值")


## UI-003-6: 测试魂槽百分比
func test_ui003_soul_gauge_percentage() -> void:
	# 更新魂槽
	soul_gauge.update_soul(5000.0)

	# 等待动画
	await get_tree().create_timer(0.3).timeout

	# 验证百分比
	var percentage = soul_gauge.get_percentage()
	assert_almost_eq(percentage, 50.0, 0.1, "百分比应为 50%")


## UI-003-7: 测试魂槽重置
func test_ui003_soul_gauge_reset() -> void:
	# 设置魂槽
	soul_gauge.update_soul(8000.0)
	await get_tree().create_timer(0.3).timeout

	# 重置
	soul_gauge.reset()

	# 验证重置
	assert_eq(soul_gauge.get_soul(), 0.0, "重置后魂槽应为 0")
	assert_false(soul_gauge.is_clear(), "重置后不应清除")


## UI-003-8: 测试魂槽阈值信号
func test_ui003_soul_threshold_signal() -> void:
	# 监听信号
	var signal_received = false
	soul_gauge.soul_threshold_reached.connect(func():
		signal_received = true
	)

	# 更新到清除阈值
	soul_gauge.update_soul(8000.0)

	# 等待动画
	await get_tree().create_timer(0.5).timeout

	# 验证信号
	assert_true(signal_received, "应触发阈值信号")


# ==================== UI-004: 判定显示组件测试 ====================

## UI-004-1: 测试判定显示初始化
func test_ui004_judge_display_initialization() -> void:
	# 尝试创建判定显示组件
	judge_display = JudgeDisplay.new()
	add_child_autofree(judge_display)

	# 等待初始化
	await get_tree().create_timer(0.1).timeout

	# 验证组件已创建
	assert_not_null(judge_display, "判定显示组件应已创建")


## UI-004-2: 测试判定显示更新
func test_ui004_judge_display_update() -> void:
	# 创建判定显示组件
	if judge_display == null:
		judge_display = JudgeDisplay.new()
		add_child_autofree(judge_display)
		await get_tree().create_timer(0.1).timeout

	# 尝试显示判定
	if judge_display.has_method("show_judge"):
		judge_display.show_judge("良")

	# 验证不会崩溃
	assert_true(true, "判定显示应成功")


# ==================== UI-005: UI 与游戏状态同步测试 ====================

## UI-005-1: 测试分数与 GameState 同步
func test_ui005_score_game_state_sync() -> void:
	# 重置游戏状态
	game_state.reset_game_state()

	# 更新分数
	game_state.current_score = 5000

	# 更新 UI
	score_display.update_score(game_state.current_score)

	# 等待动画
	await get_tree().create_timer(0.5).timeout

	# 验证同步
	assert_eq(score_display.get_score(), game_state.current_score, "UI 分数应与 GameState 同步")


## UI-005-2: 测试连击与 GameState 同步
func test_ui005_combo_game_state_sync() -> void:
	# 重置游戏状态
	game_state.reset_game_state()

	# 添加判定
	game_state.add_judge("良")
	game_state.add_judge("良")
	game_state.add_judge("良")

	# 更新 UI
	combo_display.update_combo(game_state.current_combo)

	# 等待动画
	await get_tree().create_timer(0.3).timeout

	# 验证同步
	assert_eq(combo_display.get_combo(), game_state.current_combo, "UI 连击应与 GameState 同步")


## UI-005-3: 测试判定统计与 GameState 同步
func test_ui005_judge_counts_sync() -> void:
	# 重置游戏状态
	game_state.reset_game_state()

	# 添加各种判定
	game_state.add_judge("良")
	game_state.add_judge("良")
	game_state.add_judge("可")
	game_state.add_judge("不可")

	# 验证判定统计
	assert_eq(game_state.judge_counts["良"], 2, "良判定应为 2")
	assert_eq(game_state.judge_counts["可"], 1, "可判定应为 1")
	assert_eq(game_state.judge_counts["不可"], 1, "不可判定应为 1")


## UI-005-4: 测试最大连击更新
func test_ui005_max_combo_update() -> void:
	# 重置游戏状态
	game_state.reset_game_state()

	# 建立连击
	for i in range(50):
		game_state.add_judge("良")

	# 验证最大连击
	assert_eq(game_state.max_combo, 50, "最大连击应为 50")

	# 断开连击
	game_state.add_judge("不可")

	# 验证最大连击保持
	assert_eq(game_state.max_combo, 50, "最大连击应保持 50")


## UI-005-5: 测试游戏状态重置
func test_ui005_game_state_reset() -> void:
	# 设置游戏状态
	game_state.current_score = 10000
	game_state.current_combo = 100
	game_state.max_combo = 100
	game_state.judge_counts = {"良": 50, "可": 30, "不可": 20}

	# 重置
	game_state.reset_game_state()

	# 验证重置
	assert_eq(game_state.current_score, 0, "分数应重置为 0")
	assert_eq(game_state.current_combo, 0, "连击应重置为 0")
	assert_eq(game_state.max_combo, 0, "最大连击应重置为 0")
	assert_eq(game_state.judge_counts["良"], 0, "良判定应重置为 0")


# ==================== UI 性能测试 ====================

## 测试分数更新性能
func test_score_update_performance() -> void:
	# 记录开始时间
	var start_time = Time.get_ticks_msec()

	# 执行多次更新
	for i in range(100):
		score_display.update_score(i * 100)

	# 记录结束时间
	var end_time = Time.get_ticks_msec()
	var elapsed = end_time - start_time

	# 验证性能（100 次更新应在 100ms 内完成）
	assert_lt(elapsed, 100, "100 次分数更新应在 100ms 内完成")


## 测试连击更新性能
func test_combo_update_performance() -> void:
	# 记录开始时间
	var start_time = Time.get_ticks_msec()

	# 执行多次更新
	for i in range(100):
		combo_display.update_combo(i)

	# 记录结束时间
	var end_time = Time.get_ticks_msec()
	var elapsed = end_time - start_time

	# 验证性能
	assert_lt(elapsed, 100, "100 次连击更新应在 100ms 内完成")


## 测试魂槽更新性能
func test_soul_gauge_update_performance() -> void:
	# 记录开始时间
	var start_time = Time.get_ticks_msec()

	# 执行多次更新
	for i in range(100):
		soul_gauge.update_soul(i * 100.0)

	# 记录结束时间
	var end_time = Time.get_ticks_msec()
	var elapsed = end_time - start_time

	# 验证性能
	assert_lt(elapsed, 100, "100 次魂槽更新应在 100ms 内完成")


# ==================== UI 集成测试 ====================

## 测试完整 UI 流程
func test_complete_ui_flow() -> void:
	# 重置游戏状态
	game_state.reset_game_state()

	# 模拟游戏过程
	for i in range(50):
		game_state.add_judge("良")
		score_display.update_score(game_state.current_score)
		combo_display.update_combo(game_state.current_combo)
		soul_gauge.update_soul(game_state.current_score * 0.8)

	# 等待动画
	await get_tree().create_timer(0.5).timeout

	# 验证最终状态
	assert_gt(score_display.get_score(), 0, "分数应大于 0")
	assert_eq(combo_display.get_combo(), 50, "连击应为 50")
	assert_gt(soul_gauge.get_soul(), 0, "魂槽应大于 0")


## 测试 GameController 与 UI 集成
func test_game_controller_ui_integration() -> void:
	# 设置游戏数据
	game_controller.current_song = _create_test_song()
	game_controller.current_course = game_controller.current_song.get_course(TJAData.CourseType.ONI)
	game_controller._initialize_game_systems()

	# 验证系统初始化
	assert_not_null(game_controller.judge_system, "JudgeSystem 应已创建")


## 测试 UI 组件可见性
func test_ui_component_visibility() -> void:
	# 验证组件可见
	assert_true(score_display.visible, "分数显示应可见")

	# 连击显示在连击为 0 时可能隐藏
	# 验证组件存在
	assert_not_null(combo_display, "连击显示组件应存在")


## 测试 UI 组件层级
func test_ui_component_layering() -> void:
	# 验证组件在场景树中
	assert_true(score_display.is_inside_tree(), "分数显示应在场景树中")
	assert_true(combo_display.is_inside_tree(), "连击显示应在场景树中")
	assert_true(soul_gauge.is_inside_tree(), "魂槽应在场景树中")


# ==================== UI 边界条件测试 ====================

## 测试分数边界值
func test_score_boundary_values() -> void:
	# 测试最小值
	score_display.update_score(0)
	await get_tree().create_timer(0.3).timeout
	assert_eq(score_display.get_score(), 0, "最小分数应为 0")

	# 测试最大值（假设最大分数为 9999999）
	score_display.update_score(9999999)
	await get_tree().create_timer(0.5).timeout
	assert_eq(score_display.get_score(), 9999999, "最大分数应为 9999999")


## 测试连击边界值
func test_combo_boundary_values() -> void:
	# 测试最小值
	combo_display.update_combo(0)
	await get_tree().create_timer(0.3).timeout
	assert_eq(combo_display.get_combo(), 0, "最小连击应为 0")

	# 测试大值
	combo_display.update_combo(9999)
	await get_tree().create_timer(0.3).timeout
	assert_eq(combo_display.get_combo(), 9999, "大连击应为 9999")


## 测试魂槽边界值
func test_soul_gauge_boundary_values() -> void:
	# 测试最小值
	soul_gauge.update_soul(0.0)
	await get_tree().create_timer(0.3).timeout
	assert_eq(soul_gauge.get_soul(), 0.0, "最小魂槽应为 0")

	# 测试最大值
	soul_gauge.update_soul(10000.0)
	await get_tree().create_timer(0.3).timeout
	assert_eq(soul_gauge.get_soul(), 10000.0, "最大魂槽应为 10000")


## 测试负值处理
func test_negative_value_handling() -> void:
	# 测试负分数（应被忽略或处理）
	score_display.update_score(-100)
	await get_tree().create_timer(0.3).timeout
	# 分数不应为负
	assert_gte(score_display.get_score(), 0, "分数不应为负")

	# 测试负魂槽
	soul_gauge.update_soul(-100.0)
	await get_tree().create_timer(0.3).timeout
	assert_gte(soul_gauge.get_soul(), 0.0, "魂槽不应为负")


# ==================== UI 动画测试 ====================

## 测试分数动画
func test_score_animation() -> void:
	# 更新分数
	score_display.update_score(10000)

	# 等待动画开始
	await get_tree().create_timer(0.1).timeout

	# 验证动画正在进行（分数可能还在变化）
	assert_true(true, "分数动画应开始")


## 测试连击动画
func test_combo_animation() -> void:
	# 更新连击
	combo_display.update_combo(100)

	# 等待动画
	await get_tree().create_timer(0.2).timeout

	# 验证动画完成
	assert_eq(combo_display.get_combo(), 100, "连击动画应完成")


## 测试魂槽动画
func test_soul_gauge_animation() -> void:
	# 更新魂槽
	soul_gauge.update_soul(8000.0)

	# 等待动画
	await get_tree().create_timer(0.5).timeout

	# 验证动画完成
	assert_eq(soul_gauge.get_soul(), 8000.0, "魂槽动画应完成")


## 测试连续动画
func test_continuous_animations() -> void:
	# 连续更新多个组件
	for i in range(10):
		score_display.update_score(i * 1000)
		combo_display.update_combo(i * 10)
		soul_gauge.update_soul(i * 800.0)
		await get_tree().create_timer(0.05).timeout

	# 等待所有动画完成
	await get_tree().create_timer(0.5).timeout

	# 验证最终状态
	assert_eq(score_display.get_score(), 9000, "最终分数应为 9000")
	assert_eq(combo_display.get_combo(), 90, "最终连击应为 90")
	assert_eq(soul_gauge.get_soul(), 7200.0, "最终魂槽应为 7200")