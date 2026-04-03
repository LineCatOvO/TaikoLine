# 音符管理器单元测试
# 测试 NoteManager 的初始化、对象池、谱面加载、分支系统、更新管理
# 测试框架：GUT v9.6.0

extends GutTest

const NoteManager = preload("res://src/game/note_manager.gd")
const TJAData = preload("res://src/parser/tja_data.gd")
const GameNote = preload("res://src/game/note.gd")

var note_manager: NoteManager = null


func before_all() -> void:
	pass


func before_each() -> void:
	# 创建音符管理器实例
	note_manager = NoteManager.new()
	add_child(note_manager)


func after_each() -> void:
	if note_manager:
		note_manager.queue_free()
		note_manager = null


func after_all() -> void:
	pass


# =============================================================================
# NM-001: 初始状态测试
# 测试音符管理器创建后的初始状态
# =============================================================================
func test_nm_001_initial_state() -> void:
	# 验证初始音符池已创建
	assert_not_null(note_manager._note_pool, "音符池应已创建")
	assert_eq(note_manager._note_pool.size(), note_manager.pool_size, "音符池大小应为配置值")

	# 验证初始活动音符列表为空
	assert_eq(note_manager._active_notes.size(), 0, "初始活动音符应为空")

	# 验证初始音符队列为空
	assert_eq(note_manager._note_queue.size(), 0, "初始音符队列应为空")

	# 验证初始分支
	assert_eq(note_manager.current_branch, TJAData.BranchType.NORMAL, "初始分支应为NORMAL")

	# 验证初始分支状态
	assert_false(note_manager._has_branch, "初始应无分支")


# =============================================================================
# NM-002: 对象池初始化测试
# 测试对象池的正确初始化
# =============================================================================
func test_nm_002_pool_initialization() -> void:
	# 验证池中所有音符都是 GameNote 类型
	for note in note_manager._note_pool:
		assert_is(note, GameNote, "池中对象应为 GameNote 类型")

	# 验证池中音符初始不可见
	for note in note_manager._note_pool:
		assert_false(note.visible, "池中音符初始应不可见")


# =============================================================================
# NM-003: 对象池大小配置测试
# 测试对象池大小配置
# =============================================================================
func test_nm_003_pool_size_config() -> void:
	# 默认池大小
	assert_eq(note_manager.pool_size, 100, "默认池大小应为100")

	# 创建自定义池大小的管理器
	var custom_manager = NoteManager.new()
	custom_manager.pool_size = 50
	add_child(custom_manager)

	assert_eq(custom_manager._note_pool.size(), 50, "自定义池大小应生效")

	custom_manager.queue_free()


# =============================================================================
# NM-004: 清除所有音符测试
# 测试 clear_all_notes 方法
# =============================================================================
func test_nm_004_clear_all_notes() -> void:
	# 添加一些模拟数据
	note_manager._note_queue.append({"test": "data"})
	note_manager._has_branch = true
	note_manager.current_branch = TJAData.BranchType.EXPERT

	# 清除
	note_manager.clear_all_notes()

	# 验证清除结果
	assert_eq(note_manager._active_notes.size(), 0, "活动音符应被清除")
	assert_eq(note_manager._note_queue.size(), 0, "音符队列应被清除")
	assert_eq(note_manager.current_branch, TJAData.BranchType.NORMAL, "分支应重置为NORMAL")
	assert_false(note_manager._has_branch, "分支状态应重置")


# =============================================================================
# NM-005: 获取活动音符数量测试
# 测试 get_active_note_count 方法
# =============================================================================
func test_nm_005_get_active_note_count() -> void:
	# 初始应为0
	assert_eq(note_manager.get_active_note_count(), 0, "初始活动音符数应为0")

	# 手动添加活动音符
	var note = note_manager._get_note_from_pool()
	note_manager._active_notes.append(note)

	assert_eq(note_manager.get_active_note_count(), 1, "应返回正确的活动音符数")


# =============================================================================
# NM-006: 获取待生成音符数量测试
# 测试 get_pending_note_count 方法
# =============================================================================
func test_nm_006_get_pending_note_count() -> void:
	# 初始应为0
	assert_eq(note_manager.get_pending_note_count(), 0, "初始待生成音符数应为0")

	# 添加模拟数据
	note_manager._note_queue.append({"hit_time": 1.0})
	note_manager._note_queue.append({"hit_time": 2.0})

	assert_eq(note_manager.get_pending_note_count(), 2, "应返回正确的待生成音符数")


# =============================================================================
# NM-007: 获取总音符数量测试
# 测试 get_total_note_count 方法
# =============================================================================
func test_nm_007_get_total_note_count() -> void:
	# 初始应为0
	assert_eq(note_manager.get_total_note_count(), 0, "初始总音符数应为0")

	# 添加活动音符
	var note = note_manager._get_note_from_pool()
	note_manager._active_notes.append(note)

	# 添加待生成音符
	note_manager._note_queue.append({"hit_time": 1.0})

	assert_eq(note_manager.get_total_note_count(), 2, "应返回活动+待生成的总数")


# =============================================================================
# NM-008: 检查所有音符处理完成测试
# 测试 is_all_notes_processed 方法
# =============================================================================
func test_nm_008_is_all_notes_processed() -> void:
	# 空状态应为true
	assert_true(note_manager.is_all_notes_processed(), "空状态应返回true")

	# 有活动音符时应为false
	var note = note_manager._get_note_from_pool()
	note_manager._active_notes.append(note)
	assert_false(note_manager.is_all_notes_processed(), "有活动音符应返回false")

	# 清除后应为true
	note_manager._active_notes.clear()
	assert_true(note_manager.is_all_notes_processed(), "清除后应返回true")


# =============================================================================
# NM-009: 设置滚动系统测试
# 测试 set_scroll_system 方法
# =============================================================================
func test_nm_009_set_scroll_system() -> void:
	var mock_scroll_system = Node.new()

	note_manager.set_scroll_system(mock_scroll_system)

	assert_eq(note_manager.scroll_system, mock_scroll_system, "滚动系统应被设置")

	mock_scroll_system.queue_free()


# =============================================================================
# NM-010: 设置判定系统测试
# 测试 set_judge_system 方法
# =============================================================================
func test_nm_010_set_judge_system() -> void:
	var mock_judge_system = Node.new()

	note_manager.set_judge_system(mock_judge_system)

	assert_eq(note_manager.judge_system, mock_judge_system, "判定系统应被设置")

	mock_judge_system.queue_free()


# =============================================================================
# NM-011: 从池中获取音符测试
# 测试 _get_note_from_pool 方法
# =============================================================================
func test_nm_011_get_note_from_pool() -> void:
	var initial_pool_size = note_manager._note_pool.size()

	# 获取音符
	var note = note_manager._get_note_from_pool()

	# 验证音符
	assert_not_null(note, "应返回有效音符")
	assert_is(note, GameNote, "应为 GameNote 类型")
	assert_true(note.visible, "音符应可见")

	# 验证池大小减少
	assert_eq(note_manager._note_pool.size(), initial_pool_size - 1, "池大小应减少1")


# =============================================================================
# NM-012: 池耗尽时创建新音符测试
# 测试池为空时创建新音符
# =============================================================================
func test_nm_012_pool_exhaustion() -> void:
	# 清空池
	while not note_manager._note_pool.is_empty():
		var note = note_manager._note_pool.pop_back()
		note.queue_free()

	# 获取音符（池为空）
	var note = note_manager._get_note_from_pool()

	# 应创建新音符
	assert_not_null(note, "池空时应创建新音符")
	assert_is(note, GameNote, "新音符应为 GameNote 类型")


# =============================================================================
# NM-013: 返回音符到池中测试
# 测试 _return_note_to_pool 方法
# =============================================================================
func test_nm_013_return_note_to_pool() -> void:
	# 获取音符
	var note = note_manager._get_note_from_pool()
	var pool_size_before = note_manager._note_pool.size()

	# 返回池中
	note_manager._return_note_to_pool(note)

	# 验证池大小增加
	assert_eq(note_manager._note_pool.size(), pool_size_before + 1, "池大小应增加")

	# 验证音符不可见
	assert_false(note.visible, "返回池的音符应不可见")


# =============================================================================
# NM-014: 池满时释放音符测试
# 测试池满时释放音符
# =============================================================================
func test_nm_014_pool_full_release() -> void:
	# 记录初始池大小
	var max_pool_size = note_manager.pool_size

	# 创建额外音符并尝试返回
	var extra_note = GameNote.new()
	add_child(extra_note)

	# 填满池
	while note_manager._note_pool.size() < max_pool_size:
		var note = GameNote.new()
		add_child(note)
		note_manager._note_pool.append(note)

	# 尝试返回额外音符
	var pool_size_before = note_manager._note_pool.size()
	note_manager._return_note_to_pool(extra_note)

	# 池大小不应超过最大值
	assert_eq(note_manager._note_pool.size(), pool_size_before, "池满时不应增加")


# =============================================================================
# NM-015: 分支队列初始化测试
# 测试分支音符队列的初始化
# =============================================================================
func test_nm_015_branch_queue_initialization() -> void:
	# 验证分支队列存在
	assert_not_null(note_manager._branch_note_queues, "分支队列应存在")

	# 验证三个分支都有队列
	assert(note_manager._branch_note_queues.has(TJAData.BranchType.NORMAL), "应有NORMAL分支队列")
	assert(note_manager._branch_note_queues.has(TJAData.BranchType.EXPERT), "应有EXPERT分支队列")
	assert(note_manager._branch_note_queues.has(TJAData.BranchType.MASTER), "应有MASTER分支队列")

	# 验证初始为空
	for branch_type in note_manager._branch_note_queues.keys():
		assert_eq(note_manager._branch_note_queues[branch_type].size(), 0, "分支队列初始应为空")


# =============================================================================
# NM-016: 切换分支无效状态测试
# 测试在无分支时切换分支不执行
# =============================================================================
func test_nm_016_switch_branch_no_branch() -> void:
	# 无分支状态
	note_manager._has_branch = false
	note_manager.current_branch = TJAData.BranchType.NORMAL

	# 尝试切换
	note_manager.switch_branch(TJAData.BranchType.EXPERT)

	# 应保持不变
	assert_eq(note_manager.current_branch, TJAData.BranchType.NORMAL, "无分支时不应切换")


# =============================================================================
# NM-017: 切换分支相同分支测试
# 测试切换到相同分支不执行
# =============================================================================
func test_nm_017_switch_branch_same_branch() -> void:
	# 设置有分支
	note_manager._has_branch = true
	note_manager.current_branch = TJAData.BranchType.NORMAL

	# 切换到相同分支
	note_manager.switch_branch(TJAData.BranchType.NORMAL)

	# 应保持不变
	assert_eq(note_manager.current_branch, TJAData.BranchType.NORMAL, "相同分支不应切换")


# =============================================================================
# NM-018: 更新无滚动系统测试
# 测试无滚动系统时更新不崩溃
# =============================================================================
func test_nm_018_update_no_scroll_system() -> void:
	# 确保无滚动系统
	note_manager.scroll_system = null

	# 更新不应崩溃
	note_manager.update(0.0)
	note_manager.update(1.0)

	# 验证状态正常
	assert_eq(note_manager._current_time, 1.0, "时间应更新")


# =============================================================================
# NM-019: 更新时间记录测试
# 测试 update 方法正确记录当前时间
# =============================================================================
func test_nm_019_update_time_tracking() -> void:
	# 更新时间
	note_manager.update(5.5)

	assert_eq(note_manager._current_time, 5.5, "应正确记录当前时间")

	note_manager.update(10.0)

	assert_eq(note_manager._current_time, 10.0, "应更新当前时间")


# =============================================================================
# NM-020: 处理输入无活动音符测试
# 测试无活动音符时处理输入
# =============================================================================
func test_nm_020_handle_input_no_active_notes() -> void:
	# 无活动音符
	var result = note_manager.handle_input("don")

	# 应返回空结果
	assert_eq(result.results.size(), 0, "无活动音符应返回空结果")


# =============================================================================
# NM-021: 信号定义测试
# 测试所有必需信号都已定义
# =============================================================================
func test_nm_021_signals_defined() -> void:
	assert_has_signal(note_manager, "all_notes_processed", "应定义 all_notes_processed 信号")
	assert_has_signal(note_manager, "note_spawned", "应定义 note_spawned 信号")
	assert_has_signal(note_manager, "note_judged", "应定义 note_judged 信号")
	assert_has_signal(note_manager, "note_missed", "应定义 note_missed 信号")


# =============================================================================
# NM-022: note_spawned 信号测试
# 测试生成音符时发出信号
# =============================================================================
func test_nm_022_note_spawned_signal() -> void:
	# 监听信号
	watch_signals(note_manager)

	# 设置滚动系统
	var mock_scroll = Node.new()
	mock_scroll.set_script(GDScript.new())
	mock_scroll.get_script().source_code = "extends Node\nfunc get_spawn_ahead_time(): return 10.0"
	mock_scroll.get_script().reload()
	note_manager.scroll_system = mock_scroll

	# 添加待生成音符
	note_manager._note_queue.append({
		"note_data": TJAData.TJANote.new(),
		"hit_time": 1.0,
		"bpm": 120.0,
		"scroll": 1.0
	})

	# 更新触发生成
	note_manager.update(0.0)

	# 验证信号
	assert_signal_emitted(note_manager, "note_spawned", "应发出 note_spawned 信号")

	mock_scroll.queue_free()


# =============================================================================
# NM-023: 生成位置配置测试
# 测试生成位置配置
# =============================================================================
func test_nm_023_spawn_position_config() -> void:
	# 默认生成位置
	assert_eq(note_manager.spawn_position_x, 1200.0, "默认生成位置应为1200")

	# 修改生成位置
	note_manager.spawn_position_x = 1500.0
	assert_eq(note_manager.spawn_position_x, 1500.0, "应能修改生成位置")


# =============================================================================
# NM-024: 清除后池大小保持测试
# 测试清除后对象池大小保持不变
# =============================================================================
func test_nm_024_pool_size_after_clear() -> void:
	var initial_pool_size = note_manager._note_pool.size()

	# 获取一些音符
	var notes: Array = []
	for i in range(5):
		notes.append(note_manager._get_note_from_pool())

	# 添加到活动列表
	for note in notes:
		note_manager._active_notes.append(note)

	# 清除
	note_manager.clear_all_notes()

	# 验证池大小恢复
	assert_eq(note_manager._note_pool.size(), initial_pool_size, "清除后池大小应恢复")


# =============================================================================
# NM-025: 加载谱面清除旧数据测试
# 测试加载谱面前清除旧数据
# =============================================================================
func test_nm_025_load_chart_clears_old_data() -> void:
	# 添加一些旧数据
	note_manager._note_queue.append({"old": "data"})
	note_manager._active_notes.append(note_manager._get_note_from_pool())

	# 创建空谱面
	var course = TJAData.TJACourse.new()
	course.measures = []

	# 加载谱面
	note_manager.load_chart(course, 0.0)

	# 验证旧数据被清除
	assert_eq(note_manager._active_notes.size(), 0, "活动音符应被清除")
	# 队列应为空（无音符的谱面）
	assert_eq(note_manager._note_queue.size(), 0, "音符队列应为空")


# =============================================================================
# NM-026: 分支状态重置测试
# 测试加载谱面时分支状态重置
# =============================================================================
func test_nm_026_branch_state_reset_on_load() -> void:
	# 设置分支状态
	note_manager._has_branch = true
	note_manager.current_branch = TJAData.BranchType.EXPERT

	# 创建无分支谱面
	var course = TJAData.TJACourse.new()
	course.has_branch = false
	course.measures = []

	# 加载谱面
	note_manager.load_chart(course, 0.0)

	# 验证分支状态重置
	assert_false(note_manager._has_branch, "无分支谱面应重置分支状态")
	assert_eq(note_manager.current_branch, TJAData.BranchType.NORMAL, "分支应重置为NORMAL")


# =============================================================================
# NM-027: 处理输入返回类型测试
# 测试 handle_input 返回正确类型
# =============================================================================
func test_nm_027_handle_input_return_type() -> void:
	var result = note_manager.handle_input("don")

	# 验证返回类型
	assert_true(result is Dictionary, "应返回字典")
	assert_has(result, "results", "应包含 results 键")
	assert_true(result.results is Array, "results 应为数组")


# =============================================================================
# NM-028: 多次更新测试
# 测试多次连续更新
# =============================================================================
func test_nm_028_multiple_updates() -> void:
	# 设置滚动系统
	var mock_scroll = Node.new()
	note_manager.scroll_system = mock_scroll

	# 多次更新
	for i in range(10):
		note_manager.update(float(i) * 0.1)

	# 验证时间正确
	assert_eq(note_manager._current_time, 0.9, "时间应正确更新")

	mock_scroll.queue_free()


# =============================================================================
# NM-029: 空谱面加载测试
# 测试加载空谱面
# =============================================================================
func test_nm_029_load_empty_chart() -> void:
	var course = TJAData.TJACourse.new()
	course.measures = []

	note_manager.load_chart(course, 0.0)

	# 验证队列空
	assert_eq(note_manager._note_queue.size(), 0, "空谱面队列应为空")
	assert_true(note_manager.is_all_notes_processed(), "应为处理完成状态")


# =============================================================================
# NM-030: 偏移量加载测试
# 测试带偏移量加载谱面
# =============================================================================
func test_nm_030_load_chart_with_offset() -> void:
	var course = TJAData.TJACourse.new()
	course.measures = []

	var offset = 2.5
	note_manager.load_chart(course, offset)

	# 验证加载成功（无崩溃）
	assert_eq(note_manager._note_queue.size(), 0, "应成功加载")


# =============================================================================
# NM-031: 分支队列独立测试
# 测试各分支队列独立
# =============================================================================
func test_nm_031_branch_queues_independent() -> void:
	# 设置有分支
	note_manager._has_branch = true

	# 各分支添加不同数据
	note_manager._branch_note_queues[TJAData.BranchType.NORMAL] = [{"time": 1.0}]
	note_manager._branch_note_queues[TJAData.BranchType.EXPERT] = [{"time": 2.0}]
	note_manager._branch_note_queues[TJAData.BranchType.MASTER] = [{"time": 3.0}]

	# 验证各分支独立
	assert_eq(note_manager._branch_note_queues[TJAData.BranchType.NORMAL].size(), 1, "NORMAL队列应有1个")
	assert_eq(note_manager._branch_note_queues[TJAData.BranchType.EXPERT].size(), 1, "EXPERT队列应有1个")
	assert_eq(note_manager._branch_note_queues[TJAData.BranchType.MASTER].size(), 1, "MASTER队列应有1个")


# =============================================================================
# NM-032: 切换分支清除活动音符测试
# 测试切换分支时清除活动音符
# =============================================================================
func test_nm_032_switch_branch_clears_active_notes() -> void:
	# 设置有分支
	note_manager._has_branch = true
	note_manager.current_branch = TJAData.BranchType.NORMAL

	# 添加活动音符
	var note = note_manager._get_note_from_pool()
	note_manager._active_notes.append(note)

	# 准备目标分支队列
	note_manager._branch_note_queues[TJAData.BranchType.EXPERT] = []

	# 切换分支
	note_manager.switch_branch(TJAData.BranchType.EXPERT)

	# 验证活动音符被清除
	assert_eq(note_manager._active_notes.size(), 0, "切换分支应清除活动音符")


# =============================================================================
# NM-033: 切换分支更新当前分支测试
# 测试切换分支更新当前分支
# =============================================================================
func test_nm_033_switch_branch_updates_current() -> void:
	# 设置有分支
	note_manager._has_branch = true
	note_manager.current_branch = TJAData.BranchType.NORMAL

	# 准备目标分支队列
	note_manager._branch_note_queues[TJAData.BranchType.MASTER] = []

	# 切换分支
	note_manager.switch_branch(TJAData.BranchType.MASTER)

	# 验证当前分支更新
	assert_eq(note_manager.current_branch, TJAData.BranchType.MASTER, "当前分支应更新")


# =============================================================================
# NM-034: 输入类型处理测试
# 测试不同输入类型的处理
# =============================================================================
func test_nm_034_handle_input_types() -> void:
	# 测试 don 输入
	var result_don = note_manager.handle_input("don")
	assert_true(result_don is Dictionary, "don 输入应返回字典")

	# 测试 ka 输入
	var result_ka = note_manager.handle_input("ka")
	assert_true(result_ka is Dictionary, "ka 输入应返回字典")


# =============================================================================
# NM-035: 对象池重用测试
# 测试音符对象被正确重用
# =============================================================================
func test_nm_035_pool_reuse() -> void:
	# 获取音符
	var note1 = note_manager._get_note_from_pool()
	var note1_id = note1.get_instance_id()

	# 返回池中
	note_manager._return_note_to_pool(note1)

	# 再次获取
	var note2 = note_manager._get_note_from_pool()

	# 验证是同一个对象（重用）
	assert_eq(note2.get_instance_id(), note1_id, "应重用池中的音符对象")


# =============================================================================
# NM-036: 音符重置测试
# 测试返回池时音符被重置
# =============================================================================
func test_nm_036_note_reset_on_return() -> void:
	# 获取音符
	var note = note_manager._get_note_from_pool()
	note.visible = true

	# 返回池中
	note_manager._return_note_to_pool(note)

	# 验证音符被重置
	assert_false(note.visible, "返回池时音符应被重置为不可见")


# =============================================================================
# NM-037: 当前时间初始化测试
# 测试当前时间初始值
# =============================================================================
func test_nm_037_current_time_initial() -> void:
	assert_eq(note_manager._current_time, 0.0, "初始当前时间应为0")


# =============================================================================
# NM-038: 负时间更新测试
# 测试负时间更新（开始延迟期间）
# =============================================================================
func test_nm_038_negative_time_update() -> void:
	# 更新负时间
	note_manager.update(-1.0)

	# 验证时间正确
	assert_eq(note_manager._current_time, -1.0, "应支持负时间")


# =============================================================================
# NM-039: 大时间值更新测试
# 测试大时间值更新
# =============================================================================
func test_nm_039_large_time_update() -> void:
	# 更新大时间值
	note_manager.update(3600.0)  # 1小时

	# 验证时间正确
	assert_eq(note_manager._current_time, 3600.0, "应支持大时间值")


# =============================================================================
# NM-040: 完整流程测试
# 测试完整的音符管理流程
# =============================================================================
func test_nm_040_full_workflow() -> void:
	# 1. 初始化
	assert_eq(note_manager.get_active_note_count(), 0, "初始无活动音符")

	# 2. 设置系统
	var mock_scroll = Node.new()
	note_manager.set_scroll_system(mock_scroll)

	# 3. 加载空谱面
	var course = TJAData.TJACourse.new()
	course.measures = []
	note_manager.load_chart(course, 0.0)

	# 4. 更新
	note_manager.update(0.0)

	# 5. 处理输入
	note_manager.handle_input("don")

	# 6. 验证完成状态
	assert_true(note_manager.is_all_notes_processed(), "空谱面应为完成状态")

	# 7. 清除
	note_manager.clear_all_notes()

	# 8. 验证清除结果
	assert_eq(note_manager.get_active_note_count(), 0, "清除后无活动音符")

	mock_scroll.queue_free()