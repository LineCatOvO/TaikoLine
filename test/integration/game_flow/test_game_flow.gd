## 游戏流程集成测试
## 测试 GameController、NoteManager、JudgeSystem、ScrollSystem 之间的协作
## 测试框架：GUT v9.6.0
##
## 测试用例：
## - GF-001: 完整游戏流程（加载→开始→游玩→结束）
## - GF-002: 暂停恢复流程
## - GF-003: 重试流程
## - GF-006: 游戏结束判定
## - GF-007: 结果数据完整性

extends GutTest

# ==================== 测试常量 ====================

const TJAData = preload("res://src/parser/tja_data.gd")
const TJAParser = preload("res://src/parser/tja_parser.gd")
const GameController = preload("res://src/game/game_controller.gd")
const NoteManager = preload("res://src/game/note_manager.gd")
const JudgeSystem = preload("res://src/game/judge.gd")
const ScrollSystem = preload("res://src/game/scroll.gd")

# 测试文件路径
const BASIC_TJA_PATH = "res://test/fixtures/sample_tja/basic.tja"
const BRANCHING_TJA_PATH = "res://test/fixtures/sample_tja/branching.tja"

# ==================== 测试变量 ====================

var game_controller: GameController = null
var parser: TJAParser = null

# ==================== 测试生命周期 ====================

func before_all() -> void:
	# 预加载资源
	pass

func before_each() -> void:
	# 创建 GameController 实例
	game_controller = GameController.new()
	game_controller.auto_play = false
	game_controller.practice_mode = false
	add_child_autofree(game_controller)
	
	# 创建解析器
	parser = TJAParser.new()

func after_each() -> void:
	# 清理
	if game_controller:
		game_controller.queue_free()
	game_controller = null

func after_all() -> void:
	pass

# ==================== 辅助方法 ====================

## 创建简单的测试谱面数据
func _create_test_course() -> TJAData.TJACourse:
	var course = TJAData.TJACourse.new()
	course.course_type = TJAData.CourseType.ONI
	course.level = 5
	course.score_init = 1000
	course.score_diff = 100
	
	# 创建几个小节
	for i in range(4):
		var measure = TJAData.TJAMeasure.new(i)
		measure.bpm = 120.0
		measure.scroll = 1.0
		measure.time_signature = Vector2(4.0, 4.0)
		
		# 添加一些音符
		var note1 = TJAData.TJANote.new(TJAData.NoteType.DON, 0.0)
		var note2 = TJAData.TJANote.new(TJAData.NoteType.KA, 0.5)
		measure.add_note(note1)
		measure.add_note(note2)
		
		course.add_measure(measure)
	
	return course

## 创建简单的测试歌曲数据
func _create_test_song() -> TJAData.TJASong:
	var song = TJAData.TJASong.new()
	song.title = "Test Song"
	song.bpm = 120.0
	song.offset = 0.0
	song.wave = ""
	
	var course = _create_test_course()
	song.add_course(course)
	
	return song

## 等待信号并超时
func _wait_for_signal(signal_obj: Signal, timeout: float = 1.0) -> bool:
	return await wait_for_signal(signal_obj, timeout)

# ==================== GF-001: 完整游戏流程测试 ====================

## GF-001-1: 测试游戏加载流程
func test_gf001_game_loading_flow() -> void:
	# 解析测试文件
	var result = parser.parse_file(BASIC_TJA_PATH)
	assert_true(result.success, "TJA文件解析应该成功")
	assert_not_null(result.song, "解析结果应包含歌曲数据")
	
	# 验证初始状态
	assert_eq(game_controller.current_state, GameController.PlayState.IDLE, "初始状态应为IDLE")

## GF-001-2: 测试游戏开始流程
func test_gf001_game_start_flow() -> void:
	# 设置测试数据
	game_controller.current_song = _create_test_song()
	game_controller.current_course = _create_test_course()
	game_controller._initialize_game_systems()
	
	# 验证准备状态
	assert_eq(game_controller.current_state, GameController.PlayState.IDLE, "初始化后状态应为IDLE")
	
	# 开始游戏
	game_controller.current_state = GameController.PlayState.READY
	game_controller.start_game()
	
	assert_eq(game_controller.current_state, GameController.PlayState.PLAYING, "开始后状态应为PLAYING")

## GF-001-3: 测试游戏结束流程
func test_gf001_game_end_flow() -> void:
	# 设置测试数据
	game_controller.current_song = _create_test_song()
	game_controller.current_course = _create_test_course()
	game_controller._initialize_game_systems()
	game_controller.current_state = GameController.PlayState.PLAYING
	
	# 结束游戏
	game_controller.end_game()
	
	assert_eq(game_controller.current_state, GameController.PlayState.IDLE, "结束后状态应为IDLE")

## GF-001-4: 测试完整游戏流程信号
func test_gf001_complete_flow_signals() -> void:
	# 设置测试数据
	game_controller.current_song = _create_test_song()
	game_controller.current_course = _create_test_course()
	game_controller._initialize_game_systems()
	
	# 监听信号（使用字典存储以解决闭包捕获问题）
	var signal_data = {"started": false, "ended": false}
	
	game_controller.game_started.connect(func(): signal_data.started = true)
	game_controller.game_ended.connect(func(_result): signal_data.ended = true)
	
	# 执行流程
	game_controller.current_state = GameController.PlayState.READY
	game_controller.start_game()
	
	assert_true(signal_data.started, "应该触发game_started信号")
	
	# 结束游戏
	game_controller.end_game()
	
	assert_true(signal_data.ended, "应该触发game_ended信号")

# ==================== GF-002: 暂停恢复流程测试 ====================

## GF-002-1: 测试暂停流程
func test_gf002_pause_flow() -> void:
	# 设置游戏为播放状态
	game_controller.current_song = _create_test_song()
	game_controller.current_course = _create_test_course()
	game_controller._initialize_game_systems()
	game_controller.current_state = GameController.PlayState.PLAYING
	
	# 暂停游戏
	game_controller.pause_game()
	
	assert_eq(game_controller.current_state, GameController.PlayState.PAUSED, "暂停后状态应为PAUSED")

## GF-002-2: 测试恢复流程
func test_gf002_resume_flow() -> void:
	# 设置游戏为暂停状态
	game_controller.current_song = _create_test_song()
	game_controller.current_course = _create_test_course()
	game_controller._initialize_game_systems()
	game_controller.current_state = GameController.PlayState.PAUSED
	
	# 恢复游戏
	game_controller.resume_game()
	
	assert_eq(game_controller.current_state, GameController.PlayState.PLAYING, "恢复后状态应为PLAYING")

## GF-002-3: 测试暂停恢复信号
func test_gf002_pause_resume_signals() -> void:
	# 设置游戏为播放状态
	game_controller.current_song = _create_test_song()
	game_controller.current_course = _create_test_course()
	game_controller._initialize_game_systems()
	game_controller.current_state = GameController.PlayState.PLAYING
	
	# 监听信号（使用字典存储以解决闭包捕获问题）
	var signal_data = {"paused": false, "resumed": false}
	
	game_controller.game_paused.connect(func(): signal_data.paused = true)
	game_controller.game_resumed.connect(func(): signal_data.resumed = true)
	
	# 暂停
	game_controller.pause_game()
	assert_true(signal_data.paused, "应该触发game_paused信号")
	
	# 恢复
	game_controller.resume_game()
	assert_true(signal_data.resumed, "应该触发game_resumed信号")

## GF-002-4: 测试无效状态下的暂停恢复
func test_gf002_invalid_pause_resume() -> void:
	# 在IDLE状态下尝试暂停
	game_controller.current_state = GameController.PlayState.IDLE
	game_controller.pause_game()
	assert_eq(game_controller.current_state, GameController.PlayState.IDLE, "IDLE状态下暂停应无效")
	
	# 在IDLE状态下尝试恢复
	game_controller.resume_game()
	assert_eq(game_controller.current_state, GameController.PlayState.IDLE, "IDLE状态下恢复应无效")

# ==================== GF-003: 重试流程测试 ====================

## GF-003-1: 测试重试初始化
func test_gf003_retry_initialization() -> void:
	# 设置游戏数据
	game_controller.current_song = _create_test_song()
	game_controller.current_course = _create_test_course()
	game_controller._initialize_game_systems()
	game_controller.current_state = GameController.PlayState.PLAYING
	
	# 模拟一些游戏进度
	game_controller.game_time = 10.0
	game_controller.judge_system.current_score = 5000
	game_controller.judge_system.current_combo = 10
	
	# 重试游戏
	game_controller.retry_game()
	
	# 验证状态重置
	assert_eq(game_controller.current_state, GameController.PlayState.READY, "重试后状态应为READY")
	assert_eq(game_controller.game_time, -game_controller.start_delay, "游戏时间应重置")
	assert_eq(game_controller.judge_system.current_score, 0, "分数应重置")
	assert_eq(game_controller.judge_system.current_combo, 0, "连击应重置")

## GF-003-2: 测试重试后音符重置
func test_gf003_retry_notes_reset() -> void:
	# 设置游戏数据
	game_controller.current_song = _create_test_song()
	game_controller.current_course = _create_test_course()
	game_controller._initialize_game_systems()
	
	# 获取初始音符数量
	var initial_pending = game_controller.note_manager.get_pending_note_count()
	
	# 模拟游戏进度
	game_controller.game_time = 5.0
	game_controller.note_manager.update(5.0)
	
	# 重试
	game_controller.retry_game()
	
	# 验证音符队列恢复
	var after_retry_pending = game_controller.note_manager.get_pending_note_count()
	assert_eq(after_retry_pending, initial_pending, "重试后音符队列应恢复")

## GF-003-3: 测试无数据时重试
func test_gf003_retry_without_data() -> void:
	# 没有歌曲数据时重试
	game_controller.current_song = null
	game_controller.current_course = null
	
	# 重试应该不崩溃
	game_controller.retry_game()
	
	assert_eq(game_controller.current_state, GameController.PlayState.IDLE, "无数据时重试状态应保持IDLE")

# ==================== GF-006: 游戏结束判定测试 ====================

## GF-006-1: 测试所有音符处理完毕判定
func test_gf006_all_notes_processed() -> void:
	# 设置游戏数据
	game_controller.current_song = _create_test_song()
	game_controller.current_course = _create_test_course()
	game_controller._initialize_game_systems()
	game_controller.current_state = GameController.PlayState.PLAYING
	
	# 清空音符队列（模拟所有音符已处理）
	game_controller.note_manager._note_queue.clear()
	game_controller.note_manager._active_notes.clear()
	
	# 检查是否所有音符已处理
	assert_true(game_controller.note_manager.is_all_notes_processed(), "应该检测到所有音符已处理")

## GF-006-2: 测试游戏结束条件
func test_gf006_game_end_condition() -> void:
	# 设置游戏数据
	game_controller.current_song = _create_test_song()
	game_controller.current_course = _create_test_course()
	game_controller._initialize_game_systems()
	game_controller.current_state = GameController.PlayState.PLAYING
	
	# 监听结束信号
	var ended = false
	game_controller.game_ended.connect(func(_result): ended = true)
	
	# 清空音符并设置时间
	game_controller.note_manager._note_queue.clear()
	game_controller.note_manager._active_notes.clear()
	game_controller.game_time = 100.0  # 超过结束延迟
	game_controller._has_started = true
	
	# 检查游戏结束
	game_controller._check_game_end()
	
	assert_true(game_controller._has_ended, "应该标记为已结束")

## GF-006-3: 测试游戏结束结果
func test_gf006_game_end_result() -> void:
	# 设置游戏数据
	game_controller.current_song = _create_test_song()
	game_controller.current_course = _create_test_course()
	game_controller._initialize_game_systems()
	
	# 模拟一些判定
	game_controller.judge_system.judge_note(0.0, TJAData.NoteType.DON)  # 良
	game_controller.judge_system.judge_note(50.0, TJAData.NoteType.KA)  # 可
	
	# 获取结果
	var result = game_controller.judge_system.check_game_end()
	
	assert_not_null(result, "应该返回结果字典")
	assert_has(result, "score", "结果应包含分数")
	assert_has(result, "max_combo", "结果应包含最大连击")
	assert_has(result, "perfect_count", "结果应包含良计数")
	assert_has(result, "good_count", "结果应包含可计数")
	assert_has(result, "miss_count", "结果应包含不可计数")

# ==================== GF-007: 结果数据完整性测试 ====================

## GF-007-1: 测试结果数据结构
func test_gf007_result_data_structure() -> void:
	# 设置游戏数据
	game_controller.current_song = _create_test_song()
	game_controller.current_course = _create_test_course()
	game_controller._initialize_game_systems()
	
	# 获取结果
	var result = game_controller.judge_system.check_game_end()
	
	# 验证数据结构
	assert_has(result, "cleared", "结果应有cleared字段")
	assert_has(result, "full_combo", "结果应有full_combo字段")
	assert_has(result, "dondoko_full_combo", "结果应有dondoko_full_combo字段")
	assert_has(result, "score", "结果应有score字段")
	assert_has(result, "max_combo", "结果应有max_combo字段")
	assert_has(result, "perfect_count", "结果应有perfect_count字段")
	assert_has(result, "good_count", "结果应有good_count字段")
	assert_has(result, "miss_count", "结果应有miss_count字段")

## GF-007-2: 测试分数计算完整性
func test_gf007_score_calculation_integrity() -> void:
	# 设置游戏数据
	game_controller.current_song = _create_test_song()
	game_controller.current_course = _create_test_course()
	game_controller._initialize_game_systems()
	
	# 设置总音符数
	game_controller.judge_system.set_total_notes(10)
	
	# 执行多次判定
	for i in range(10):
		game_controller.judge_system.judge_note(0.0, TJAData.NoteType.DON)
	
	# 验证分数
	var result = game_controller.judge_system.check_game_end()
	assert_gt(result.score, 0, "分数应大于0")
	assert_eq(result.perfect_count, 10, "应有10个良")
	assert_eq(result.good_count, 0, "应没有可")
	assert_eq(result.miss_count, 0, "应没有不可")

## GF-007-3: 测试连击数据完整性
func test_gf007_combo_data_integrity() -> void:
	# 设置游戏数据
	game_controller.current_song = _create_test_song()
	game_controller.current_course = _create_test_course()
	game_controller._initialize_game_systems()
	
	# 执行判定序列
	game_controller.judge_system.judge_note(0.0, TJAData.NoteType.DON)  # 良, combo=1
	game_controller.judge_system.judge_note(0.0, TJAData.NoteType.DON)  # 良, combo=2
	game_controller.judge_system.judge_note(1000.0, TJAData.NoteType.DON)  # 不可, combo=0
	game_controller.judge_system.judge_note(0.0, TJAData.NoteType.DON)  # 良, combo=1
	
	# 验证连击数据
	assert_eq(game_controller.judge_system.get_max_combo(), 2, "最大连击应为2")
	assert_eq(game_controller.judge_system.get_combo(), 1, "当前连击应为1")

## GF-007-4: 测试魂槽数据完整性
func test_gf007_soul_gauge_data_integrity() -> void:
	# 设置游戏数据
	game_controller.current_song = _create_test_song()
	game_controller.current_course = _create_test_course()
	game_controller._initialize_game_systems()
	
	# 执行判定
	game_controller.judge_system.judge_note(0.0, TJAData.NoteType.DON)  # 良
	game_controller.judge_system.judge_note(50.0, TJAData.NoteType.KA)  # 可
	game_controller.judge_system.judge_note(1000.0, TJAData.NoteType.DON)  # 不可
	
	# 验证魂槽
	var soul_percentage = game_controller.judge_system.get_soul_percentage()
	assert_gt(soul_percentage, 0.0, "魂槽应大于0（良和可增加）")
	
	# 验证清除状态
	# 由于只有少量判定，可能未达到清除阈值
	var is_clear = game_controller.judge_system.is_clear_status()
	assert_false(is_clear, "少量判定应未达到清除阈值")

## GF-007-5: 测试评级计算
func test_gf007_rank_calculation() -> void:
	# 设置游戏数据
	game_controller.current_song = _create_test_song()
	game_controller.current_course = _create_test_course()
	game_controller._initialize_game_systems()
	
	# 设置总音符数
	game_controller.judge_system.set_total_notes(10)
	
	# 全良
	for i in range(10):
		game_controller.judge_system.judge_note(0.0, TJAData.NoteType.DON)
	
	var rank = game_controller.judge_system.get_rank()
	assert_eq(rank, "SS", "全良应获得SS评级")

# ==================== 系统协作测试 ====================

## 测试 GameController 与 NoteManager 协作
func test_game_controller_note_manager_collaboration() -> void:
	# 设置游戏数据
	game_controller.current_song = _create_test_song()
	game_controller.current_course = _create_test_course()
	game_controller._initialize_game_systems()
	
	# 验证系统关联
	assert_not_null(game_controller.note_manager, "NoteManager应已创建")
	assert_not_null(game_controller.note_manager.scroll_system, "NoteManager应有ScrollSystem引用")
	assert_not_null(game_controller.note_manager.judge_system, "NoteManager应有JudgeSystem引用")

## 测试 GameController 与 JudgeSystem 协作
func test_game_controller_judge_system_collaboration() -> void:
	# 设置游戏数据
	game_controller.current_song = _create_test_song()
	game_controller.current_course = _create_test_course()
	game_controller._initialize_game_systems()
	
	# 验证系统关联
	assert_not_null(game_controller.judge_system, "JudgeSystem应已创建")
	
	# 测试分数更新回调
	game_controller.judge_system.judge_note(0.0, TJAData.NoteType.DON)
	
	# 验证 GameState 更新（如果已设置）
	# 注意：GameState 是 Autoload，在测试环境中可能不可用

## 测试 GameController 与 ScrollSystem 协作
func test_game_controller_scroll_system_collaboration() -> void:
	# 设置游戏数据
	game_controller.current_song = _create_test_song()
	game_controller.current_course = _create_test_course()
	game_controller._initialize_game_systems()
	
	# 验证系统关联
	assert_not_null(game_controller.scroll_system, "ScrollSystem应已创建")
	
	# 测试时间更新
	game_controller.scroll_system.update_time(1.0)
	assert_eq(game_controller.scroll_system._current_time, 1.0, "ScrollSystem时间应更新")

## 测试完整系统协作流程
func test_full_system_collaboration() -> void:
	# 设置游戏数据
	game_controller.current_song = _create_test_song()
	game_controller.current_course = _create_test_course()
	game_controller._initialize_game_systems()
	game_controller.current_state = GameController.PlayState.PLAYING
	
	# 模拟游戏帧更新
	game_controller.game_time = 0.0
	game_controller.scroll_system.update_time(0.0)
	game_controller.note_manager.update(0.0)
	
	# 验证系统状态一致
	assert_eq(game_controller.scroll_system._current_time, 0.0, "ScrollSystem时间应与游戏时间一致")