## 音符类单元测试
## 测试 GameNote 的音符类型判断、输入需求、状态管理
## 测试框架：GUT v9.6.0

extends GutTest

var note: GameNote = null
var TJAData = preload("res://src/parser/tja_data.gd")


func before_all() -> void:
	pass


func before_each() -> void:
	# 创建音符实例
	note = GameNote.new()
	add_child(note)


func after_each() -> void:
	if note:
		note.queue_free()
		note = null


func after_all() -> void:
	pass


# =============================================================================
# NOTE-001: 大音符判断
# 测试 is_big 方法
# =============================================================================
func test_note_001_is_big() -> void:
	# 测试大音符类型
	var big_types = [
		TJAData.NoteType.DON_BIG,
		TJAData.NoteType.KA_BIG,
		TJAData.NoteType.RENDA_BIG,
		TJAData.NoteType.DON_DOUBLE,
		TJAData.NoteType.KA_DOUBLE
	]

	for note_type in big_types:
		note.note_type = note_type
		assert_true(note.is_big(), TJAData.NoteType.keys()[note_type] + " 应为大音符")

	# 测试非大音符类型
	var small_types = [
		TJAData.NoteType.DON,
		TJAData.NoteType.KA,
		TJAData.NoteType.RENDA,
		TJAData.NoteType.BALLOON,
		TJAData.NoteType.KUSUDAMA,
		TJAData.NoteType.ADLIB
	]

	for note_type in small_types:
		note.note_type = note_type
		assert_false(note.is_big(), TJAData.NoteType.keys()[note_type] + " 不应为大音符")


# =============================================================================
# NOTE-002: 连打判断
# 测试 is_renda 方法
# =============================================================================
func test_note_002_is_renda() -> void:
	# 测试连打类型
	var renda_types = [
		TJAData.NoteType.RENDA,
		TJAData.NoteType.RENDA_BIG,
		TJAData.NoteType.BALLOON,
		TJAData.NoteType.KUSUDAMA
	]

	for note_type in renda_types:
		note.note_type = note_type
		assert_true(note.is_renda(), TJAData.NoteType.keys()[note_type] + " 应为连打类型")

	# 测试非连打类型
	var non_renda_types = [
		TJAData.NoteType.DON,
		TJAData.NoteType.KA,
		TJAData.NoteType.DON_BIG,
		TJAData.NoteType.KA_BIG,
		TJAData.NoteType.DON_DOUBLE,
		TJAData.NoteType.KA_DOUBLE,
		TJAData.NoteType.ADLIB
	]

	for note_type in non_renda_types:
		note.note_type = note_type
		assert_false(note.is_renda(), TJAData.NoteType.keys()[note_type] + " 不应为连打类型")


# =============================================================================
# NOTE-003: 可打击判断
# 测试 is_hittable 方法
# =============================================================================
func test_note_003_is_hittable() -> void:
	# 测试可打击类型
	var hittable_types = [
		TJAData.NoteType.DON,
		TJAData.NoteType.KA,
		TJAData.NoteType.DON_BIG,
		TJAData.NoteType.KA_BIG,
		TJAData.NoteType.RENDA,
		TJAData.NoteType.RENDA_BIG,
		TJAData.NoteType.BALLOON,
		TJAData.NoteType.KUSUDAMA,
		TJAData.NoteType.DON_DOUBLE,
		TJAData.NoteType.KA_DOUBLE,
		TJAData.NoteType.ADLIB
	]

	for note_type in hittable_types:
		note.note_type = note_type
		assert_true(note.is_hittable(), TJAData.NoteType.keys()[note_type] + " 应为可打击音符")

	# 测试不可打击类型
	var non_hittable_types = [
		TJAData.NoteType.NONE,
		TJAData.NoteType.END,
		TJAData.NoteType.BOMB,
		TJAData.NoteType.SWAP
	]

	for note_type in non_hittable_types:
		note.note_type = note_type
		assert_false(note.is_hittable(), TJAData.NoteType.keys()[note_type] + " 不应为可打击音符")


# =============================================================================
# NOTE-004: 红音符输入需求
# 测试 needs_don_input 方法
# =============================================================================
func test_note_004_needs_don_input() -> void:
	# 测试需要红音符输入的类型
	var don_types = [
		TJAData.NoteType.DON,
		TJAData.NoteType.DON_BIG,
		TJAData.NoteType.RENDA,
		TJAData.NoteType.RENDA_BIG,
		TJAData.NoteType.DON_DOUBLE
	]

	for note_type in don_types:
		note.note_type = note_type
		assert_true(note.needs_don_input(), TJAData.NoteType.keys()[note_type] + " 应需要红音符输入")

	# 测试不需要红音符输入的类型
	var non_don_types = [
		TJAData.NoteType.KA,
		TJAData.NoteType.KA_BIG,
		TJAData.NoteType.KA_DOUBLE,
		TJAData.NoteType.BALLOON,
		TJAData.NoteType.KUSUDAMA
	]

	for note_type in non_don_types:
		note.note_type = note_type
		assert_false(note.needs_don_input(), TJAData.NoteType.keys()[note_type] + " 不应需要红音符输入")


# =============================================================================
# NOTE-005: 蓝音符输入需求
# 测试 needs_ka_input 方法
# =============================================================================
func test_note_005_needs_ka_input() -> void:
	# 测试需要蓝音符输入的类型
	var ka_types = [
		TJAData.NoteType.KA,
		TJAData.NoteType.KA_BIG,
		TJAData.NoteType.KA_DOUBLE
	]

	for note_type in ka_types:
		note.note_type = note_type
		assert_true(note.needs_ka_input(), TJAData.NoteType.keys()[note_type] + " 应需要蓝音符输入")

	# 测试不需要蓝音符输入的类型
	var non_ka_types = [
		TJAData.NoteType.DON,
		TJAData.NoteType.DON_BIG,
		TJAData.NoteType.RENDA,
		TJAData.NoteType.RENDA_BIG,
		TJAData.NoteType.DON_DOUBLE,
		TJAData.NoteType.BALLOON,
		TJAData.NoteType.KUSUDAMA
	]

	for note_type in non_ka_types:
		note.note_type = note_type
		assert_false(note.needs_ka_input(), TJAData.NoteType.keys()[note_type] + " 不应需要蓝音符输入")


# =============================================================================
# NOTE-008: 重置功能
# 测试 reset 方法恢复初始状态
# =============================================================================
func test_note_008_reset() -> void:
	# 建立一些状态
	note.note_state = GameNote.NoteState.JUDGED
	note.scale = Vector2(1.5, 1.5)
	note.modulate = Color.RED
	note.balloon_hits = 10
	note.renda_count = 20

	# 验证状态已改变
	assert_eq(note.note_state, GameNote.NoteState.JUDGED, "状态应为JUDGED")
	assert_eq(note.scale, Vector2(1.5, 1.5), "缩放应为1.5")
	assert_eq(note.balloon_hits, 10, "气球打击数应为10")
	assert_eq(note.renda_count, 20, "连打数应为20")

	# 执行重置
	note.reset()

	# 验证状态恢复初始值
	assert_eq(note.note_state, GameNote.NoteState.WAITING, "重置后状态应为WAITING")
	assert_eq(note.scale, Vector2(1.0, 1.0), "重置后缩放应为1.0")
	assert_eq(note.modulate, Color.WHITE, "重置后颜色应为白色")
	assert_eq(note.balloon_hits, 0, "重置后气球打击数应为0")
	assert_eq(note.renda_count, 0, "重置后连打数应为0")


# =============================================================================
# NOTE-009: 数据设置
# 测试 setup 方法设置音符数据
# =============================================================================
func test_note_009_setup() -> void:
	# 创建音符数据
	var note_data = TJAData.TJANote.new()
	note_data.note_type = TJAData.NoteType.DON_BIG
	note_data.position = 0.5
	note_data.balloon_hits = 15
	note_data.renda_count = 30

	# 设置音符数据
	note.setup(note_data, 5.0)

	# 验证数据设置正确
	assert_eq(note.note_type, TJAData.NoteType.DON_BIG, "音符类型应为DON_BIG")
	assert_eq(note.position_ratio, 0.5, "位置比例应为0.5")
	assert_eq(note.balloon_hits, 15, "气球打击数应为15")
	assert_eq(note.renda_count, 30, "连打数应为30")
	assert_eq(note.hit_time, 5.0, "打击时间应为5.0")


# =============================================================================
# 附加测试：音符状态枚举
# =============================================================================
func test_note_state_enum() -> void:
	# 验证音符状态枚举值
	assert_eq(GameNote.NoteState.WAITING, 0, "WAITING状态应为0")
	assert_eq(GameNote.NoteState.APPROACHING, 1, "APPROACHING状态应为1")
	assert_eq(GameNote.NoteState.JUDGING, 2, "JUDGING状态应为2")
	assert_eq(GameNote.NoteState.JUDGED, 3, "JUDGED状态应为3")
	assert_eq(GameNote.NoteState.MISSED, 4, "MISSED状态应为4")


# =============================================================================
# 附加测试：判定窗口常量
# =============================================================================
func test_judge_window_constants() -> void:
	# 验证判定窗口常量
	assert_eq(GameNote.PERFECT_WINDOW, 33.0, "良判定窗口应为33ms")
	assert_eq(GameNote.GOOD_WINDOW, 100.0, "可判定窗口应为100ms")


# =============================================================================
# 附加测试：初始状态
# =============================================================================
func test_initial_state() -> void:
	# 创建新音符测试初始状态
	var new_note = GameNote.new()
	add_child(new_note)

	assert_eq(new_note.note_type, TJAData.NoteType.DON, "默认音符类型应为DON")
	assert_eq(new_note.note_state, GameNote.NoteState.WAITING, "初始状态应为WAITING")
	assert_eq(new_note.hit_time, 0.0, "初始打击时间应为0")
	assert_eq(new_note.position_ratio, 0.0, "初始位置比例应为0")
	assert_eq(new_note.balloon_hits, 0, "初始气球打击数应为0")
	assert_eq(new_note.renda_count, 0, "初始连打数应为0")

	new_note.queue_free()


# =============================================================================
# 附加测试：所有音符类型遍历
# =============================================================================
func test_all_note_types() -> void:
	# 测试所有音符类型的设置
	var all_types = [
		TJAData.NoteType.NONE,
		TJAData.NoteType.DON,
		TJAData.NoteType.KA,
		TJAData.NoteType.DON_BIG,
		TJAData.NoteType.KA_BIG,
		TJAData.NoteType.RENDA,
		TJAData.NoteType.RENDA_BIG,
		TJAData.NoteType.BALLOON,
		TJAData.NoteType.END,
		TJAData.NoteType.KUSUDAMA,
		TJAData.NoteType.DON_DOUBLE,
		TJAData.NoteType.KA_DOUBLE,
		TJAData.NoteType.BOMB,
		TJAData.NoteType.ADLIB,
		TJAData.NoteType.SWAP
	]

	for note_type in all_types:
		note.note_type = note_type
		assert_eq(note.note_type, note_type, "音符类型应正确设置为" + str(note_type))


# =============================================================================
# 附加测试：连打音符接受任意输入
# =============================================================================
func test_renda_accepts_any_input() -> void:
	# 连打类型可以接受任意输入
	var renda_types = [
		TJAData.NoteType.RENDA,
		TJAData.NoteType.RENDA_BIG,
		TJAData.NoteType.BALLOON,
		TJAData.NoteType.KUSUDAMA
	]

	for note_type in renda_types:
		note.note_type = note_type
		# 连打不需要特定输入，但可以接受任意输入
		assert_true(note.is_renda(), TJAData.NoteType.keys()[note_type] + " 是连打类型")


# =============================================================================
# 附加测试：双人合作音符
# =============================================================================
func test_double_notes() -> void:
	# 测试双人合作音符
	note.note_type = TJAData.NoteType.DON_DOUBLE
	assert_true(note.is_big(), "DON_DOUBLE应为大音符")
	assert_true(note.is_hittable(), "DON_DOUBLE应为可打击音符")
	assert_true(note.needs_don_input(), "DON_DOUBLE应需要红音符输入")

	note.note_type = TJAData.NoteType.KA_DOUBLE
	assert_true(note.is_big(), "KA_DOUBLE应为大音符")
	assert_true(note.is_hittable(), "KA_DOUBLE应为可打击音符")
	assert_true(note.needs_ka_input(), "KA_DOUBLE应需要蓝音符输入")


# =============================================================================
# 附加测试：ADLIB隐藏音符
# =============================================================================
func test_adlib_note() -> void:
	note.note_type = TJAData.NoteType.ADLIB

	assert_true(note.is_hittable(), "ADLIB应为可打击音符")
	assert_false(note.is_big(), "ADLIB不应为大音符")
	assert_false(note.is_renda(), "ADLIB不应为连打类型")


# =============================================================================
# 附加测试：炸弹音符
# =============================================================================
func test_bomb_note() -> void:
	note.note_type = TJAData.NoteType.BOMB

	assert_false(note.is_hittable(), "BOMB不应为可打击音符")
	assert_false(note.is_big(), "BOMB不应为大音符")
	assert_false(note.is_renda(), "BOMB不应为连打类型")


# =============================================================================
# 附加测试：交换音符
# =============================================================================
func test_swap_note() -> void:
	note.note_type = TJAData.NoteType.SWAP

	assert_false(note.is_hittable(), "SWAP不应为可打击音符")
	assert_false(note.is_big(), "SWAP不应为大音符")
	assert_false(note.is_renda(), "SWAP不应为连打类型")


# =============================================================================
# 附加测试：久寿玉音符
# =============================================================================
func test_kusudama_note() -> void:
	note.note_type = TJAData.NoteType.KUSUDAMA

	assert_true(note.is_hittable(), "KUSUDAMA应为可打击音符")
	assert_true(note.is_renda(), "KUSUDAMA应为连打类型")
	assert_false(note.is_big(), "KUSUDAMA不应为大音符")


# =============================================================================
# 附加测试：气球音符
# =============================================================================
func test_balloon_note() -> void:
	note.note_type = TJAData.NoteType.BALLOON

	assert_true(note.is_hittable(), "BALLOON应为可打击音符")
	assert_true(note.is_renda(), "BALLOON应为连打类型")
	assert_false(note.is_big(), "BALLOON不应为大音符")


# =============================================================================
# 附加测试：大连打音符
# =============================================================================
func test_renda_big_note() -> void:
	note.note_type = TJAData.NoteType.RENDA_BIG

	assert_true(note.is_hittable(), "RENDA_BIG应为可打击音符")
	assert_true(note.is_renda(), "RENDA_BIG应为连打类型")
	assert_true(note.is_big(), "RENDA_BIG应为大音符")


# =============================================================================
# 附加测试：音符数据设置-边界值
# =============================================================================
func test_setup_boundary_values() -> void:
	# 测试边界位置
	var note_data = TJAData.TJANote.new()
	note_data.note_type = TJAData.NoteType.DON
	note_data.position = 0.0
	note.setup(note_data, 0.0)
	assert_eq(note.position_ratio, 0.0, "位置比例可以为0")

	note_data.position = 1.0
	note.setup(note_data, 1000.0)
	assert_eq(note.position_ratio, 1.0, "位置比例可以为1")
	assert_eq(note.hit_time, 1000.0, "打击时间可以很大")


# =============================================================================
# 附加测试：重置后可重新设置
# =============================================================================
func test_reset_and_setup() -> void:
	# 第一次设置
	var note_data1 = TJAData.TJANote.new()
	note_data1.note_type = TJAData.NoteType.DON_BIG
	note_data1.balloon_hits = 10
	note.setup(note_data1, 5.0)

	assert_eq(note.note_type, TJAData.NoteType.DON_BIG, "第一次设置正确")

	# 重置
	note.reset()

	# 第二次设置
	var note_data2 = TJAData.TJANote.new()
	note_data2.note_type = TJAData.NoteType.KA
	note_data2.balloon_hits = 5
	note.setup(note_data2, 3.0)

	assert_eq(note.note_type, TJAData.NoteType.KA, "重置后可重新设置")
	assert_eq(note.balloon_hits, 5, "重置后气球打击数正确")
	assert_eq(note.hit_time, 3.0, "重置后打击时间正确")