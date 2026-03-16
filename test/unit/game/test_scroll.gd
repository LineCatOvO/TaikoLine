## 滚动系统单元测试
## 测试 ScrollSystem 的时间位置转换、BPM变化处理、滚动速度变化处理
## 测试框架：GUT v9.6.0

extends GutTest

var scroll_system: ScrollSystem = null


func before_all() -> void:
	pass


func before_each() -> void:
	# 创建滚动系统实例
	scroll_system = ScrollSystem.new()
	add_child(scroll_system)
	# 使用默认配置
	scroll_system.base_scroll_speed = 1.0
	scroll_system.judge_line_x = 400.0
	scroll_system.pixels_per_beat = 100.0


func after_each() -> void:
	if scroll_system:
		scroll_system.queue_free()
		scroll_system = null


func after_all() -> void:
	pass


# =============================================================================
# SCR-001: 时间转位置-基础
# 测试 time_to_position 方法的基本功能
# =============================================================================
func test_scr_001_time_to_position_basic() -> void:
	scroll_system.reset()
	scroll_system.update_time(0.0)

	# 测试时间差为0时，位置应在判定线
	var pos_zero = scroll_system.time_to_position(0.0)
	assert_eq(pos_zero, scroll_system.judge_line_x, "时间差为0时位置应在判定线")

	# 测试正时间差（未来音符）
	# 默认BPM=120, pixels_per_beat=100
	# pixels_per_second = 100 * 120 / 60 = 200
	# 位置 = 400 + 1.0 * 1.0 * 200 * time_diff
	var pos_future = scroll_system.time_to_position(1.0)
	assert_eq(pos_future, 600.0, "时间差1秒位置应为600（判定线400 + 200像素）")

	# 测试负时间差（过去音符）
	var pos_past = scroll_system.time_to_position(-1.0)
	assert_eq(pos_past, 200.0, "时间差-1秒位置应为200（判定线400 - 200像素）")


# =============================================================================
# SCR-002: 位置转时间-基础
# 测试 position_to_time 方法的基本功能
# =============================================================================
func test_scr_002_position_to_time_basic() -> void:
	scroll_system.reset()
	scroll_system.update_time(0.0)

	# 测试判定线位置转换为0时间差
	var time_zero = scroll_system.position_to_time(scroll_system.judge_line_x)
	assert_eq(time_zero, 0.0, "判定线位置时间差应为0")

	# 测试未来位置转换为正时间差
	# pixels_per_second = 200
	# time_diff = (position - 400) / (1.0 * 1.0 * 200)
	var time_future = scroll_system.position_to_time(600.0)
	assert_eq(time_future, 1.0, "位置600时间差应为1秒")

	# 测试过去位置转换为负时间差
	var time_past = scroll_system.position_to_time(200.0)
	assert_eq(time_past, -1.0, "位置200时间差应为-1秒")


# =============================================================================
# SCR-003: 时间位置互逆
# 测试 time_to_position 和 position_to_time 互为逆运算
# =============================================================================
func test_scr_003_time_position_inverse() -> void:
	scroll_system.reset()
	scroll_system.update_time(0.0)

	# 测试多个时间值的互逆性
	var test_times = [0.0, 0.5, 1.0, 2.0, -0.5, -1.0, -2.0]

	for time_diff in test_times:
		var position = scroll_system.time_to_position(time_diff)
		var converted_time = scroll_system.position_to_time(position)
		assert_almost_eq(converted_time, time_diff, 0.001, 
			"时间%.2f转换后应可逆".format([time_diff]))

	# 测试多个位置值的互逆性
	var test_positions = [400.0, 500.0, 600.0, 800.0, 300.0, 200.0, 0.0]

	for position in test_positions:
		var time_diff = scroll_system.position_to_time(position)
		var converted_pos = scroll_system.time_to_position(time_diff)
		assert_almost_eq(converted_pos, position, 0.001, 
			"位置%.2f转换后应可逆".format([position]))


# =============================================================================
# SCR-004: BPM影响
# 测试BPM对时间位置转换的影响
# =============================================================================
func test_scr_004_bpm_effect() -> void:
	scroll_system.reset()
	scroll_system.update_time(0.0)

	# 默认BPM=120, pixels_per_second = 200
	var pos_120_bpm = scroll_system.time_to_position(1.0)
	assert_eq(pos_120_bpm, 600.0, "BPM=120时1秒位置应为600")

	# 手动设置BPM（通过内部变量）
	scroll_system._current_bpm = 60.0
	var pos_60_bpm = scroll_system.time_to_position(1.0)
	# pixels_per_second = 100 * 60 / 60 = 100
	# position = 400 + 1.0 * 1.0 * 100 * 1 = 500
	assert_eq(pos_60_bpm, 500.0, "BPM=60时1秒位置应为500")

	# 测试更高BPM
	scroll_system._current_bpm = 180.0
	var pos_180_bpm = scroll_system.time_to_position(1.0)
	# pixels_per_second = 100 * 180 / 60 = 300
	# position = 400 + 1.0 * 1.0 * 300 * 1 = 700
	assert_eq(pos_180_bpm, 700.0, "BPM=180时1秒位置应为700")


# =============================================================================
# SCR-005: 滚动速度影响
# 测试滚动速度对时间位置转换的影响
# =============================================================================
func test_scr_005_scroll_speed_effect() -> void:
	scroll_system.reset()
	scroll_system.update_time(0.0)

	# 默认滚动速度=1.0
	var pos_normal = scroll_system.time_to_position(1.0)
	assert_eq(pos_normal, 600.0, "滚动速度=1.0时1秒位置应为600")

	# 设置滚动速度为2.0
	scroll_system._current_scroll = 2.0
	var pos_double = scroll_system.time_to_position(1.0)
	# effective_speed = 1.0 * 2.0 = 2.0
	# position = 400 + 2.0 * 200 * 1 = 800
	assert_eq(pos_double, 800.0, "滚动速度=2.0时1秒位置应为800")

	# 设置滚动速度为0.5
	scroll_system._current_scroll = 0.5
	var pos_half = scroll_system.time_to_position(1.0)
	# effective_speed = 1.0 * 0.5 = 0.5
	# position = 400 + 0.5 * 200 * 1 = 500
	assert_eq(pos_half, 500.0, "滚动速度=0.5时1秒位置应为500")


# =============================================================================
# SCR-006: BPM变化处理
# 测试BPM变化点的处理
# =============================================================================
func test_scr_006_bpm_change_handling() -> void:
	scroll_system.reset()

	# 添加BPM变化点
	scroll_system._bpm_changes.append(scroll_system.BPMChange.new(0.0, 120.0))
	scroll_system._bpm_changes.append(scroll_system.BPMChange.new(5.0, 180.0))
	scroll_system._bpm_changes.append(scroll_system.BPMChange.new(10.0, 90.0))

	# 初始BPM
	scroll_system.update_time(0.0)
	assert_eq(scroll_system.get_current_bpm(), 120.0, "时间0时BPM应为120")

	# 在第一个变化点之后
	scroll_system.update_time(6.0)
	assert_eq(scroll_system.get_current_bpm(), 180.0, "时间6时BPM应为180")

	# 在第二个变化点之后
	scroll_system.update_time(12.0)
	assert_eq(scroll_system.get_current_bpm(), 90.0, "时间12时BPM应为90")

	# 测试BPM变化点数量
	assert_eq(scroll_system.get_bpm_change_count(), 3, "应有3个BPM变化点")


# =============================================================================
# SCR-007: 滚动速度变化处理
# 测试滚动速度变化点的处理
# =============================================================================
func test_scr_007_scroll_change_handling() -> void:
	scroll_system.reset()

	# 添加滚动速度变化点
	scroll_system._scroll_changes.append(scroll_system.ScrollChange.new(0.0, 1.0))
	scroll_system._scroll_changes.append(scroll_system.ScrollChange.new(3.0, 2.0))
	scroll_system._scroll_changes.append(scroll_system.ScrollChange.new(8.0, 0.5))

	# 初始滚动速度
	scroll_system.update_time(0.0)
	assert_eq(scroll_system.get_current_scroll(), 1.0, "时间0时滚动速度应为1.0")

	# 在第一个变化点之后
	scroll_system.update_time(5.0)
	assert_eq(scroll_system.get_current_scroll(), 2.0, "时间5时滚动速度应为2.0")

	# 在第二个变化点之后
	scroll_system.update_time(10.0)
	assert_eq(scroll_system.get_current_scroll(), 0.5, "时间10时滚动速度应为0.5")

	# 测试滚动速度变化点数量
	assert_eq(scroll_system.get_scroll_change_count(), 3, "应有3个滚动速度变化点")


# =============================================================================
# SCR-013: 系统重置
# 测试 reset 方法恢复初始状态
# =============================================================================
func test_scr_013_system_reset() -> void:
	# 建立一些状态
	scroll_system._bpm_changes.append(scroll_system.BPMChange.new(1.0, 150.0))
	scroll_system._scroll_changes.append(scroll_system.ScrollChange.new(2.0, 1.5))
	scroll_system._current_bpm = 150.0
	scroll_system._current_scroll = 1.5
	scroll_system._current_time = 10.0
	scroll_system._offset = 0.5

	# 验证状态已改变
	assert_eq(scroll_system.get_bpm_change_count(), 1, "应有1个BPM变化点")
	assert_eq(scroll_system.get_scroll_change_count(), 1, "应有1个滚动速度变化点")
	assert_eq(scroll_system.get_current_bpm(), 150.0, "当前BPM应为150")

	# 执行重置
	scroll_system.reset()

	# 验证状态恢复初始值
	assert_eq(scroll_system.get_bpm_change_count(), 0, "重置后BPM变化点应为0")
	assert_eq(scroll_system.get_scroll_change_count(), 0, "重置后滚动速度变化点应为0")
	assert_eq(scroll_system.get_current_bpm(), 120.0, "重置后BPM应为默认值120")
	assert_eq(scroll_system.get_current_scroll(), 1.0, "重置后滚动速度应为默认值1.0")
	assert_eq(scroll_system._current_time, 0.0, "重置后当前时间应为0")
	assert_eq(scroll_system._offset, 0.0, "重置后偏移应为0")


# =============================================================================
# 附加测试：有效滚动速度计算
# =============================================================================
func test_effective_scroll_speed() -> void:
	scroll_system.reset()

	# 默认值
	assert_eq(scroll_system.get_effective_scroll_speed(), 1.0, "默认有效滚动速度应为1.0")

	# 修改基础滚动速度
	scroll_system.base_scroll_speed = 2.0
	assert_eq(scroll_system.get_effective_scroll_speed(), 2.0, "基础速度2.0时有效速度应为2.0")

	# 修改当前滚动速度
	scroll_system._current_scroll = 0.5
	assert_eq(scroll_system.get_effective_scroll_speed(), 1.0, "基础2.0*当前0.5=1.0")


# =============================================================================
# 附加测试：生成提前时间计算
# =============================================================================
func test_spawn_ahead_time() -> void:
	scroll_system.reset()
	scroll_system.update_time(0.0)

	# 默认配置下的生成提前时间
	# spawn_position = 1280, judge_line_x = 400
	# distance = 880
	# pixels_per_second = 200
	# time = 880 / 200 = 4.4
	var spawn_time = scroll_system.get_spawn_ahead_time()
	assert_almost_eq(spawn_time, 4.4, 0.1, "生成提前时间应约为4.4秒")


# =============================================================================
# 附加测试：距离计算
# =============================================================================
func test_calculate_distance() -> void:
	scroll_system.reset()
	scroll_system.update_time(0.0)

	# 测试时间范围内的距离
	# pixels_per_second = 200
	# distance = 1.0 * 200 * 1.0 = 200
	var distance = scroll_system.calculate_distance(0.0, 1.0)
	assert_eq(distance, 200.0, "1秒时间差距离应为200像素")

	# 测试负时间差（应使用绝对值）
	distance = scroll_system.calculate_distance(1.0, 0.0)
	assert_eq(distance, 200.0, "负时间差距离应为正值")


# =============================================================================
# 附加测试：下一个变化时间
# =============================================================================
func test_next_change_time() -> void:
	scroll_system.reset()

	# 添加变化点
	scroll_system._bpm_changes.append(scroll_system.BPMChange.new(5.0, 150.0))
	scroll_system._bpm_changes.append(scroll_system.BPMChange.new(10.0, 180.0))
	scroll_system._scroll_changes.append(scroll_system.ScrollChange.new(3.0, 2.0))

	# 当前时间0，下一个BPM变化在5秒
	scroll_system.update_time(0.0)
	assert_eq(scroll_system.get_next_bpm_change_time(), 5.0, "下一个BPM变化应在5秒")

	# 当前时间6，下一个BPM变化在10秒
	scroll_system.update_time(6.0)
	assert_eq(scroll_system.get_next_bpm_change_time(), 10.0, "下一个BPM变化应在10秒")

	# 当前时间12，没有更多BPM变化
	scroll_system.update_time(12.0)
	assert_eq(scroll_system.get_next_bpm_change_time(), -1.0, "没有更多BPM变化")

	# 滚动速度变化
	scroll_system.update_time(0.0)
	assert_eq(scroll_system.get_next_scroll_change_time(), 3.0, "下一个滚动速度变化应在3秒")


# =============================================================================
# 附加测试：检查变化点存在
# =============================================================================
func test_has_change_at() -> void:
	scroll_system.reset()

	# 添加变化点
	scroll_system._bpm_changes.append(scroll_system.BPMChange.new(5.0, 150.0))
	scroll_system._scroll_changes.append(scroll_system.ScrollChange.new(3.0, 2.0))

	# 检查BPM变化点
	assert_true(scroll_system.has_bpm_change_at(5.0), "应在5秒有BPM变化")
	assert_false(scroll_system.has_bpm_change_at(4.0), "不应在4秒有BPM变化")
	assert_true(scroll_system.has_bpm_change_at(5.01, 0.02), "容差范围内应有BPM变化")

	# 检查滚动速度变化点
	assert_true(scroll_system.has_scroll_change_at(3.0), "应在3秒有滚动速度变化")
	assert_false(scroll_system.has_scroll_change_at(2.0), "不应在2秒有滚动速度变化")


# =============================================================================
# 附加测试：设置偏移
# =============================================================================
func test_set_offset() -> void:
	scroll_system.reset()

	scroll_system.set_offset(0.5)
	assert_eq(scroll_system._offset, 0.5, "偏移应设置为0.5")


# =============================================================================
# 附加测试：设置基础滚动速度
# =============================================================================
func test_set_base_scroll_speed() -> void:
	scroll_system.reset()

	scroll_system.set_base_scroll_speed(2.0)
	assert_eq(scroll_system.base_scroll_speed, 2.0, "基础滚动速度应设置为2.0")


# =============================================================================
# 附加测试：信号发射
# =============================================================================
func test_signal_emission() -> void:
	scroll_system.reset()

	# 添加BPM变化点
	scroll_system._bpm_changes.append(scroll_system.BPMChange.new(0.0, 120.0))
	scroll_system._bpm_changes.append(scroll_system.BPMChange.new(5.0, 150.0))

	# 监听信号
	watch_signals(scroll_system)

	# 更新时间触发BPM变化
	scroll_system.update_time(6.0)

	# 验证信号发射
	assert_signal_emitted(scroll_system, "bpm_changed", "应发射bpm_changed信号")


# =============================================================================
# 附加测试：边界条件
# =============================================================================
func test_boundary_conditions() -> void:
	scroll_system.reset()
	scroll_system.update_time(0.0)

	# 测试零滚动速度
	scroll_system._current_scroll = 0.0
	var time = scroll_system.position_to_time(600.0)
	assert_eq(time, 0.0, "零滚动速度时应返回0")

	# 测试零BPM
	scroll_system._current_bpm = 0.0
	scroll_system._current_scroll = 1.0
	time = scroll_system.position_to_time(600.0)
	assert_eq(time, 0.0, "零BPM时应返回0")

	# 测试负滚动速度
	scroll_system._current_bpm = 120.0
	scroll_system._current_scroll = -1.0
	time = scroll_system.position_to_time(600.0)
	# 负滚动速度仍应计算，但方向相反
	assert_true(time < 0, "负滚动速度应产生负时间差")