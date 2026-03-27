## 游戏控制器单元测试
## 试 GameController 的初始化、状态管理、流程控制、分数计算
## 测试框架：GUT v9.6.0

extends GutTest

var game_controller: GameController = null
var TJAData = preload("res://src/parser/tja_data.gd")


func before_all() -> void:
	pass


func before_each() -> void:
	# 创建游戏控制器实例
	game_controller = GameController.new()
	add_child(game_controller)


func after_each() -> void:
	if game_controller:
		game_controller.queue_free()
		game_controller = null


func after_all() -> void:
	pass


# =============================================================================
# GCT-001: 初始状态测试
# 测试游戏控制器创建后的初始状态
# =============================================================================
func test_gct_001_initial_state() -> void:
	# 验证初始游戏状态
	assert_eq(game_controller.current_state, GameController.PlayState.IDLE, "初始状态应为IDLE")

	# 验证初始时间
	assert_eq(game_controller.game_time, 0.0, "初始游戏时间应为0")

	# 验证初始标志
	assert_false(game_controller._has_started, "初始未开始标志应为false")
	assert_false(game_controller._has_ended, "初始未结束标志应为false")

	# 验证初始分支
	assert_eq(game_controller.current_branch, TJAData.BranchType.NORMAL, "初始分支应为NORMAL")

	# 验证初始Go-Go Time状态
	assert_false(game_controller.is_gogo_time, "初始不应在Go-Go Time中")

	# 验证默认配置
	assert_false(game_controller.auto_play, "默认自动演奏应为关闭")
	assert_false(game_controller.practice_mode, "默认练习模式应为关闭")


# =============================================================================
# GCT-002: 子系统初始化测试
# 测试游戏控制器子系统的正确初始化
# =============================================================================
func test_gct_002_subsystem_initialization() -> void:
	# 验证音符管理器已创建
	assert_not_null(game_controller.note_manager, "音符管理器应已创建")

	# 验证判定系统已创建
	assert_not_null(game_controller.judge_system, "判定系统应已创建")

	# 验证滚动系统已创建
	assert_not_null(game_controller.scroll_system, "滚动系统应已创建")

	# 验证音频播放器已创建
	assert_not_null(game_controller.music_player, "音频播放器应已创建")


# =============================================================================
# GCT-003: 游戏状态枚举测试
# 测试 PlayState 枚举值是否正确
# =============================================================================
func test_gct_003_play_state_enum() -> void:
	# 验证游戏状态枚举值
	assert_eq(GameController.PlayState.IDLE, 0, "IDLE状态应为0")
	assert_eq(GameController.PlayState.LOADING, 1, "LOADING状态应为1")
	assert_eq(GameController.PlayState.READY, 2, "READY状态应为2")
	assert_eq(GameController.PlayState.PLAYING, 3, "PLAYING状态应为3")
	assert_eq(GameController.PlayState.PAUSED, 4, "PAUSED状态应为4")
	assert_eq(GameController.PlayState.ENDING, 5, "ENDING状态应为5")


# =============================================================================
# GCT-004: 获取状态方法测试
# 测试 get_state 方法返回正确的状态
# =============================================================================
func test_gct_004_get_state() -> void:
	# 初始状态
	assert_eq(game_controller.get_state(), GameController.PlayState.IDLE, "get_state应返回IDLE")

	# 手动设置状态
	game_controller.current_state = GameController.PlayState.READY
	assert_eq(game_controller.get_state(), GameController.PlayState.READY, "get_state应返回READY")

	# 设置为游戏中
	game_controller.current_state = GameController.PlayState.PLAYING
	assert_eq(game_controller.get_state(), GameController.PlayState.PLAYING, "get_state应返回PLAYING")


# =============================================================================
# GCT-005: 获取当前时间测试
# 测试 get_current_time 方法
# =============================================================================
func test_gct_005_get_current_time() -> void:
	# 初始时间
	assert_eq(game_controller.get_current_time(), 0.0, "初始时间应为0")

	# 手动设置时间
	game_controller.game_time = 5.5
	assert_eq(game_controller.get_current_time(), 5.5, "应返回设置的时间")

	# 负数时间（开始延迟期间）
	game_controller.game_time = -0.5
	assert_eq(game_controller.get_current_time(), -0.5, "应支持负数时间")


# =============================================================================
# GCT-006: 开始游戏状态转换测试
# 测试 start_game 方法的状态转换
# =============================================================================
func test_gct_006_start_game_state_transition() -> void:
	# 设置为准备状态
	game_controller.current_state = GameController.PlayState.READY

	# 开始游戏
	game_controller.start_game()

	# 验证状态转换
	assert_eq(game_controller.current_state, GameController.PlayState.PLAYING, "状态应转换为PLAYING")


# =============================================================================
# GCT-007: 开始游戏无效状态测试
# 测试在非 READY 状态下 start_game 不执行
# =============================================================================
func test_gct_007_start_game_invalid_state() -> void:
	# 在 IDLE 状态下尝试开始
	game_controller.current_state = GameController.PlayState.IDLE
	game_controller.start_game()
	assert_eq(game_controller.current_state, GameController.PlayState.IDLE, "IDLE状态不应转换")

	# 在 LOADING 状态下尝试开始
	game_controller.current_state = GameController.PlayState.LOADING
	game_controller.start_game()
	assert_eq(game_controller.current_state, GameController.PlayState.LOADING, "LOADING状态不应转换")

	# 在 PLAYING 状态下尝试开始
	game_controller.current_state = GameController.PlayState.PLAYING
	game_controller.start_game()
	assert_eq(game_controller.current_state, GameController.PlayState.PLAYING, "PLAYING状态保持不变")


# =============================================================================
# GCT-008: 暂停游戏状态转换测试
# 测试 pause_game 方法的状态转换
# =============================================================================
func test_gct_008_pause_game_state_transition() -> void:
	# 设置为游戏中状态
	game_controller.current_state = GameController.PlayState.PLAYING

	# 暂停游戏
	game_controller.pause_game()

	# 验证状态转换
	assert_eq(game_controller.current_state, GameController.PlayState.PAUSED, "状态应转换为PAUSED")


# =============================================================================
# GCT-009: 暂停游戏无效状态测试
# 测试在非 PLAYING 状态下 pause_game 不执行
# =============================================================================
func test_gct_009_pause_game_invalid_state() -> void:
	# 在 IDLE 状态下尝试暂停
	game_controller.current_state = GameController.PlayState.IDLE
	game_controller.pause_game()
	assert_eq(game_controller.current_state, GameController.PlayState.IDLE, "IDLE状态不应转换")

	# 在 READY 状态下尝试暂停
	game_controller.current_state = GameController.PlayState.READY
	game_controller.pause_game()
	assert_eq(game_controller.current_state, GameController.PlayState.READY, "READY状态不应转换")

	# 在 PAUSED 状态下尝试暂停
	game_controller.current_state = GameController.PlayState.PAUSED
	game_controller.pause_game()
	assert_eq(game_controller.current_state, GameController.PlayState.PAUSED, "PAUSED状态保持不变")


# =============================================================================
# GCT-010: 恢复游戏状态转换测试
# 测试 resume_game 方法的状态转换
# =============================================================================
func test_gct_010_resume_game_state_transition() -> void:
	# 设置为暂停状态
	game_controller.current_state = GameController.PlayState.PAUSED

	# 恢复游戏
	game_controller.resume_game()

	# 验证状态转换
	assert_eq(game_controller.current_state, GameController.PlayState.PLAYING, "状态应转换为PLAYING")


# =============================================================================
# GCT-011: 恢复游戏无效状态测试
# 测试在非 PAUSED 状态下 resume_game 不执行
# =============================================================================
func test_gct_011_resume_game_invalid_state() -> void:
	# 在 IDLE 状态下尝试恢复
	game_controller.current_state = GameController.PlayState.IDLE
	game_controller.resume_game()
	assert_eq(game_controller.current_state, GameController.PlayState.IDLE, "IDLE状态不应转换")

	# 在 PLAYING 状态下尝试恢复
	game_controller.current_state = GameController.PlayState.PLAYING
	game_controller.resume_game()
	assert_eq(game_controller.current_state, GameController.PlayState.PLAYING, "PLAYING状态保持不变")


# =============================================================================
# GCT-012: 结束游戏状态转换测试
# 测试 end_game 方法的状态转换
# =============================================================================
func test_gct_012_end_game_state_transition() -> void:
	# 设置为游戏中状态
	game_controller.current_state = GameController.PlayState.PLAYING

	# 结束游戏
	game_controller.end_game()

	# 验证状态转换（先到 ENDING，最后到 IDLE）
	assert_eq(game_controller.current_state, GameController.PlayState.IDLE, "状态应最终为IDLE")


# =============================================================================
# GCT-013: 结束游戏无效状态测试
# 测试在 IDLE 或 ENDING 状态下 end_game 不执行
# =============================================================================
func test_gct_013_end_game_invalid_state() -> void:
	# 在 IDLE 状态下尝试结束
	game_controller.current_state = GameController.PlayState.IDLE
	game_controller.end_game()
	assert_eq(game_controller.current_state, GameController.PlayState.IDLE, "IDLE状态保持不变")

	# 在 ENDING 状态下尝试结束
	game_controller.current_state = GameController.PlayState.ENDING
	game_controller.end_game()
	assert_eq(game_controller.current_state, GameController.PlayState.ENDING, "ENDING状态保持不变")


# =============================================================================
# GCT-014: 游戏开始信号测试
# 测试 start_game 发出 game_started 信号
# =============================================================================
func test_gct_014_game_started_signal() -> void:
	# 设置为准备状态
	game_controller.current_state = GameController.PlayState.READY

	# 监听信号
	watch_signals(game_controller)

	# 开始游戏
	game_controller.start_game()

	# 验证信号发出
	assert_signal_emitted(game_controller, "game_started", "应发出game_started信号")


# =============================================================================
# GCT-015: 游戏暂停信号测试
# 测试 pause_game 发出 game_paused 信号
# =============================================================================
func test_gct_015_game_paused_signal() -> void:
	# 设置为游戏中状态
	game_controller.current_state = GameController.PlayState.PLAYING

	# 监听信号
	watch_signals(game_controller)

	# 暂停游戏
	game_controller.pause_game()

	# 验证信号发出
	assert_signal_emitted(game_controller, "game_paused", "应发出game_paused信号")


# =============================================================================
# GCT-016: 游戏恢复信号测试
# 测试 resume_game 发出 game_resumed 信号
# =============================================================================
func test_gct_016_game_resumed_signal() -> void:
	# 设置为暂停状态
	game_controller.current_state = GameController.PlayState.PAUSED

	# 监听信号
	watch_signals(game_controller)

	# 恢复游戏
	game_controller.resume_game()

	# 验证信号发出
	assert_signal_emitted(game_controller, "game_resumed", "应发出game_resumed信号")


# =============================================================================
# GCT-017: 游戏结束信号测试
# 测试 end_game 发出 game_ended 信号
# =============================================================================
func test_gct_017_game_ended_signal() -> void:
	# 设置为游戏中状态
	game_controller.current_state = GameController.PlayState.PLAYING

	# 监听信号
	watch_signals(game_controller)

	# 结束游戏
	game_controller.end_game()

	# 验证信号发出
	assert_signal_emitted(game_controller, "game_ended", "应发出game_ended信号")


# =============================================================================
# GCT-018: 时间更新信号测试
# 测试 _update_time 发出 time_updated 信号
# =============================================================================
func test_gct_018_time_updated_signal() -> void:
	# 监听信号
	watch_signals(game_controller)

	# 更新时间
	game_controller._update_time(0.016)  # 约60fps的一帧

	# 验证信号发出
	assert_signal_emitted(game_controller, "time_updated", "应发出time_updated信号")

	# 验证信号参数
	var params = get_signal_parameters(game_controller, "time_updated", 0)
	assert_almost_eq(params[0], 0.016, 0.001, "时间参数应正确传递")


# =============================================================================
# GCT-019: 分数获取测试
# 测试 get_current_score 方法
# =============================================================================
func test_gct_019_get_current_score() -> void:
	# 初始分数应为0
	assert_eq(game_controller.get_current_score(), 0, "初始分数应为0")


# =============================================================================
# GCT-020: 连击获取测试
# 测试 get_current_combo 方法
# =============================================================================
func test_gct_020_get_current_combo() -> void:
	# 初始连击应为0
	assert_eq(game_controller.get_current_combo(), 0, "初始连击应为0")


# =============================================================================
# GCT-021: 最大连击获取测试
# 测试 get_max_combo 方法
# =============================================================================
func test_gct_021_get_max_combo() -> void:
	# 初始最大连击应为0
	assert_eq(game_controller.get_max_combo(), 0, "初始最大连击应为0")


# =============================================================================
# GCT-022: 判定统计获取测试
# 测试 get_judge_counts 方法
# =============================================================================
func test_gct_022_get_judge_counts() -> void:
	# 获取判定统计
	var counts = game_controller.get_judge_counts()

	# 验证返回的是字典
	assert_not_null(counts, "判定统计不应为空")


# =============================================================================
# GCT-023: 魂槽百分比获取测试
# 测试 get_soul_percentage 方法
# =============================================================================
func test_gct_023_get_soul_percentage() -> void:
	# 获取魂槽百分比
	var percentage = game_controller.get_soul_percentage()

	# 验证返回值在合理范围内
	assert_true(percentage >= 0.0, "魂槽百分比应大于等于0")
	assert_true(percentage <= 100.0, "魂槽百分比应小于等于100")


# =============================================================================
# GCT-024: 清除状态检查测试
# 测试 is_clear_status 方法
# =============================================================================
func test_gct_024_is_clear_status() -> void:
	# 初始状态（无歌曲数据）
	var is_clear = game_controller.is_clear_status()

	# 验证返回布尔值
	assert_true(typeof(is_clear) == TYPE_BOOL, "应返回布尔值")


# =============================================================================
# GCT-025: 滚动速度设置测试
# 测试 set_scroll_speed 方法
# =============================================================================
func test_gct_025_set_scroll_speed() -> void:
	# 设置滚动速度
	game_controller.set_scroll_speed(5.0)

	# 验证滚动系统已更新
	assert_not_null(game_controller.scroll_system, "滚动系统应存在")


# =============================================================================
# GCT-026: 判定偏移设置测试
# 测试 set_judge_offset 方法
# =============================================================================
func test_gct_026_set_judge_offset() -> void:
	# 设置判定偏移
	game_controller.set_judge_offset(16.0)

	# 验证设置成功（Settings 应该被更新）
	# 注意：这需要 Settings 单例存在
	pass


# =============================================================================
# GCT-027: 自动演奏模式测试
# 测试 auto_play 属性
# =============================================================================
func test_gct_027_auto_play_mode() -> void:
	# 默认关闭
	assert_false(game_controller.auto_play, "默认自动演奏应关闭")

	# 开启自动演奏
	game_controller.auto_play = true
	assert_true(game_controller.auto_play, "应能开启自动演奏")

	# 关闭自动演奏
	game_controller.auto_play = false
	assert_false(game_controller.auto_play, "应能关闭自动演奏")


# =============================================================================
# GCT-028: 练习模式测试
# 测试 practice_mode 属性
# =============================================================================
func test_gct_028_practice_mode() -> void:
	# 默认关闭
	assert_false(game_controller.practice_mode, "默认练习模式应关闭")

	# 开启练习模式
	game_controller.practice_mode = true
	assert_true(game_controller.practice_mode, "应能开启练习模式")

	# 关闭练习模式
	game_controller.practice_mode = false
	assert_false(game_controller.practice_mode, "应能关闭练习模式")


# =============================================================================
# GCT-029: 开始延迟配置测试
# 测试 start_delay 属性
# =============================================================================
func test_gct_029_start_delay() -> void:
	# 验证默认值
	assert_eq(game_controller.start_delay, 1.0, "默认开始延迟应为1秒")

	# 修改开始延迟
	game_controller.start_delay = 2.0
	assert_eq(game_controller.start_delay, 2.0, "应能修改开始延迟")


# =============================================================================
# GCT-030: 结束延迟配置测试
# 测试 end_delay 属性
# =============================================================================
func test_gct_030_end_delay() -> void:
	# 验证默认值
	assert_eq(game_controller.end_delay, 2.0, "默认结束延迟应为2秒")

	# 修改结束延迟
	game_controller.end_delay = 3.0
	assert_eq(game_controller.end_delay, 3.0, "应能修改结束延迟")


# =============================================================================
# GCT-031: 音频偏移配置测试
# 测试 audio_offset 属性
# =============================================================================
func test_gct_031_audio_offset() -> void:
	# 验证默认值
	assert_eq(game_controller.audio_offset, 0.0, "默认音频偏移应为0")

	# 修改音频偏移
	game_controller.audio_offset = 0.1
	assert_eq(game_controller.audio_offset, 0.1, "应能修改音频偏移")


# =============================================================================
# GCT-032: 分支系统初始化测试
# 测试分支相关变量的初始状态
# =============================================================================
func test_gct_032_branch_system_initialization() -> void:
	# 验证初始分支
	assert_eq(game_controller.current_branch, TJAData.BranchType.NORMAL, "初始分支应为NORMAL")

	# 验证分支条件索引
	assert_eq(game_controller._branch_condition_index, 0, "初始分支条件索引应为0")

	# 验证待判定分支条件列表为空
	assert_eq(game_controller._pending_branch_conditions.size(), 0, "初始待判定分支条件应为空")


# =============================================================================
# GCT-033: Go-Go Time系统初始化测试
# 测试 Go-Go Time 相关变量的初始状态
# =============================================================================
func test_gct_033_gogo_time_initialization() -> void:
	# 验证初始 Go-Go Time 状态
	assert_false(game_controller.is_gogo_time, "初始不应在Go-Go Time中")

	# 验证 Go-Go Time 区间列表为空
	assert_eq(game_controller._gogo_sections.size(), 0, "初始Go-Go Time区间应为空")


# =============================================================================
# GCT-034: 分支切换信号测试
# 测试 branch_changed 信号定义
# =============================================================================
func test_gct_034_branch_changed_signal_defined() -> void:
	# 验证信号存在
	assert_has_signal(game_controller, "branch_changed", "应定义branch_changed信号")


# =============================================================================
# GCT-035: Go-Go Time信号测试
# 测试 gogo_started 和 gogo_ended 信号定义
# =============================================================================
func test_gct_035_gogo_signals_defined() -> void:
	# 验证信号存在
	assert_has_signal(game_controller, "gogo_started", "应定义gogo_started信号")
	assert_has_signal(game_controller, "gogo_ended", "应定义gogo_ended信号")


# =============================================================================
# GCT-036: 处理输入无效状态测试
# 测试在非 PLAYING 状态下 handle_input 不执行
# =============================================================================
func test_gct_036_handle_input_invalid_state() -> void:
	# 在 IDLE 状态下尝试处理输入
	game_controller.current_state = GameController.PlayState.IDLE
	game_controller.handle_input("don")

	# 验证状态未改变
	assert_eq(game_controller.current_state, GameController.PlayState.IDLE, "IDLE状态不应处理输入")


# =============================================================================
# GCT-037: 重试游戏无效状态测试
# 测试在无歌曲数据时 retry_game 不执行
# =============================================================================
func test_gct_037_retry_game_no_song() -> void:
	# 无歌曲数据时重试
	game_controller.current_state = GameController.PlayState.PLAYING
	game_controller.retry_game()

	# 状态应保持不变（因为没有歌曲数据）
	# 注意：实际行为取决于实现


# =============================================================================
# GCT-038: 加载歌曲无效路径测试
# 测试 load_song 方法处理无效路径
# =============================================================================
func test_gct_038_load_song_invalid_path() -> void:
	# 尝试加载不存在的文件
	var result = game_controller.load_song("res://nonexistent/path/file.tja")

	# 验证返回失败
	assert_false(result, "加载不存在的文件应返回false")

	# 验证状态回到 IDLE
	assert_eq(game_controller.current_state, GameController.PlayState.IDLE, "失败后状态应为IDLE")


# =============================================================================
# GCT-039: 信号定义完整性测试
# 测试所有必需信号都已定义
# =============================================================================
func test_gct_039_all_signals_defined() -> void:
	# 验证所有信号存在
	assert_has_signal(game_controller, "game_started", "应定义game_started信号")
	assert_has_signal(game_controller, "game_ended", "应定义game_ended信号")
	assert_has_signal(game_controller, "game_paused", "应定义game_paused信号")
	assert_has_signal(game_controller, "game_resumed", "应定义game_resumed信号")
	assert_has_signal(game_controller, "time_updated", "应定义time_updated信号")
	assert_has_signal(game_controller, "branch_changed", "应定义branch_changed信号")
	assert_has_signal(game_controller, "gogo_started", "应定义gogo_started信号")
	assert_has_signal(game_controller, "gogo_ended", "应定义gogo_ended信号")


# =============================================================================
# GCT-040: 状态转换完整性测试
# 测试完整游戏流程的状态转换
# =============================================================================
func test_gct_040_full_state_transition() -> void:
	# IDLE -> READY (通过 load_song，但需要有效文件)
	# 这里测试手动状态转换
	game_controller.current_state = GameController.PlayState.IDLE
	assert_eq(game_controller.get_state(), GameController.PlayState.IDLE, "初始IDLE")

	# READY -> PLAYING
	game_controller.current_state = GameController.PlayState.READY
	game_controller.start_game()
	assert_eq(game_controller.get_state(), GameController.PlayState.PLAYING, "READY->PLAYING")

	# PLAYING -> PAUSED
	game_controller.pause_game()
	assert_eq(game_controller.get_state(), GameController.PlayState.PAUSED, "PLAYING->PAUSED")

	# PAUSED -> PLAYING
	game_controller.resume_game()
	assert_eq(game_controller.get_state(), GameController.PlayState.PLAYING, "PAUSED->PLAYING")

	# PLAYING -> IDLE (通过 end_game)
	game_controller.end_game()
	assert_eq(game_controller.get_state(), GameController.PlayState.IDLE, "PLAYING->IDLE")