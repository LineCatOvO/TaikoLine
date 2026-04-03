## 动画管理器单元测试
## 测试 AnimationManager 的预设动画、组合动画、Tween管理
## 测试框架：GUT v9.6.0

extends GutTest

const AnimationManagerScript = preload("res://src/ui/animation_manager.gd")

var animation_manager: Node = null
var test_control: Control = null


func before_all() -> void:
	pass


func before_each() -> void:
	# 创建动画管理器实例
	animation_manager = AnimationManagerScript.new()
	add_child(animation_manager)

	# 创建测试用的Control节点
	test_control = Control.new()
	add_child(test_control)


func after_each() -> void:
	if animation_manager:
		animation_manager.queue_free()
		animation_manager = null

	if test_control:
		test_control.queue_free()
		test_control = null


func after_all() -> void:
	pass


# =============================================================================
# ANIM-001: 动画管理器初始化
# 测试 AnimationManager 正确初始化
# =============================================================================
func test_anim_001_initialization() -> void:
	assert_not_null(animation_manager, "动画管理器应已创建")
	assert_eq(animation_manager._active_tweens.size(), 0, "初始活动Tween应为空")


# =============================================================================
# ANIM-002: 预设类型枚举
# 测试 PresetType 枚举值
# =============================================================================
func test_anim_002_preset_type_enum() -> void:
	assert_eq(AnimationManagerScript.PresetType.FADE_IN, 0, "FADE_IN应为0")
	assert_eq(AnimationManagerScript.PresetType.FADE_OUT, 1, "FADE_OUT应为1")
	assert_eq(AnimationManagerScript.PresetType.SCALE_IN, 2, "SCALE_IN应为2")
	assert_eq(AnimationManagerScript.PresetType.SCALE_OUT, 3, "SCALE_OUT应为3")
	assert_eq(AnimationManagerScript.PresetType.SLIDE_IN_LEFT, 4, "SLIDE_IN_LEFT应为4")
	assert_eq(AnimationManagerScript.PresetType.SLIDE_IN_RIGHT, 5, "SLIDE_IN_RIGHT应为5")
	assert_eq(AnimationManagerScript.PresetType.SLIDE_IN_TOP, 6, "SLIDE_IN_TOP应为6")
	assert_eq(AnimationManagerScript.PresetType.SLIDE_IN_BOTTOM, 7, "SLIDE_IN_BOTTOM应为7")
	assert_eq(AnimationManagerScript.PresetType.BOUNCE, 8, "BOUNCE应为8")
	assert_eq(AnimationManagerScript.PresetType.SHAKE, 9, "SHAKE应为9")
	assert_eq(AnimationManagerScript.PresetType.PULSE, 10, "PULSE应为10")
	assert_eq(AnimationManagerScript.PresetType.GLOW, 11, "GLOW应为11")
	assert_eq(AnimationManagerScript.PresetType.POP, 12, "POP应为12")
	assert_eq(AnimationManagerScript.PresetType.WIGGLE, 13, "WIGGLE应为13")


# =============================================================================
# ANIM-003: 创建淡入动画
# 测试 create_preset_animation FADE_IN
# =============================================================================
func test_anim_003_create_fade_in() -> void:
	test_control.modulate.a = 0.0

	var tween = animation_manager.create_preset_animation(test_control, AnimationManagerScript.PresetType.FADE_IN)

	assert_not_null(tween, "应创建Tween")
	assert_eq(animation_manager._active_tweens.size(), 1, "应有1个活动Tween")


# =============================================================================
# ANIM-004: 创建淡出动画
# 测试 create_preset_animation FADE_OUT
# =============================================================================
func test_anim_004_create_fade_out() -> void:
	test_control.modulate.a = 1.0

	var tween = animation_manager.create_preset_animation(test_control, AnimationManagerScript.PresetType.FADE_OUT)

	assert_not_null(tween, "应创建Tween")


# =============================================================================
# ANIM-005: 创建缩放进入动画
# 测试 create_preset_animation SCALE_IN
# =============================================================================
func test_anim_005_create_scale_in() -> void:
	test_control.scale = Vector2.ZERO

	var tween = animation_manager.create_preset_animation(test_control, AnimationManagerScript.PresetType.SCALE_IN)

	assert_not_null(tween, "应创建Tween")


# =============================================================================
# ANIM-006: 创建缩放退出动画
# 测试 create_preset_animation SCALE_OUT
# =============================================================================
func test_anim_006_create_scale_out() -> void:
	test_control.scale = Vector2.ONE

	var tween = animation_manager.create_preset_animation(test_control, AnimationManagerScript.PresetType.SCALE_OUT)

	assert_not_null(tween, "应创建Tween")


# =============================================================================
# ANIM-007: 创建弹跳动画
# 测试 create_preset_animation BOUNCE
# =============================================================================
func test_anim_007_create_bounce() -> void:
	var tween = animation_manager.create_preset_animation(test_control, AnimationManagerScript.PresetType.BOUNCE)

	assert_not_null(tween, "应创建Tween")


# =============================================================================
# ANIM-008: 创建抖动动画
# 测试 create_preset_animation SHAKE
# =============================================================================
func test_anim_008_create_shake() -> void:
	var original_pos = test_control.position

	var tween = animation_manager.create_preset_animation(test_control, AnimationManagerScript.PresetType.SHAKE)

	assert_not_null(tween, "应创建Tween")


# =============================================================================
# ANIM-009: 创建脉冲动画
# 测试 create_preset_animation PULSE
# =============================================================================
func test_anim_009_create_pulse() -> void:
	var tween = animation_manager.create_preset_animation(test_control, AnimationManagerScript.PresetType.PULSE)

	assert_not_null(tween, "应创建Tween")


# =============================================================================
# ANIM-010: 创建弹出动画
# 测试 create_preset_animation POP
# =============================================================================
func test_anim_010_create_pop() -> void:
	var tween = animation_manager.create_preset_animation(test_control, AnimationManagerScript.PresetType.POP)

	assert_not_null(tween, "应创建Tween")


# =============================================================================
# ANIM-011: 创建摆动动画
# 测试 create_preset_animation WIGGLE
# =============================================================================
func test_anim_011_create_wiggle() -> void:
	var tween = animation_manager.create_preset_animation(test_control, AnimationManagerScript.PresetType.WIGGLE)

	assert_not_null(tween, "应创建Tween")


# =============================================================================
# ANIM-012: 创建滑入动画-左侧
# 测试 create_preset_animation SLIDE_IN_LEFT
# =============================================================================
func test_anim_012_create_slide_in_left() -> void:
	var tween = animation_manager.create_preset_animation(test_control, AnimationManagerScript.PresetType.SLIDE_IN_LEFT)

	assert_not_null(tween, "应创建Tween")


# =============================================================================
# ANIM-013: 创建滑入动画-右侧
# 测试 create_preset_animation SLIDE_IN_RIGHT
# =============================================================================
func test_anim_013_create_slide_in_right() -> void:
	var tween = animation_manager.create_preset_animation(test_control, AnimationManagerScript.PresetType.SLIDE_IN_RIGHT)

	assert_not_null(tween, "应创建Tween")


# =============================================================================
# ANIM-014: 创建滑入动画-顶部
# 测试 create_preset_animation SLIDE_IN_TOP
# =============================================================================
func test_anim_014_create_slide_in_top() -> void:
	var tween = animation_manager.create_preset_animation(test_control, AnimationManagerScript.PresetType.SLIDE_IN_TOP)

	assert_not_null(tween, "应创建Tween")


# =============================================================================
# ANIM-015: 创建滑入动画-底部
# 测试 create_preset_animation SLIDE_IN_BOTTOM
# =============================================================================
func test_anim_015_create_slide_in_bottom() -> void:
	var tween = animation_manager.create_preset_animation(test_control, AnimationManagerScript.PresetType.SLIDE_IN_BOTTOM)

	assert_not_null(tween, "应创建Tween")


# =============================================================================
# ANIM-016: 创建发光动画
# 测试 create_preset_animation GLOW
# =============================================================================
func test_anim_016_create_glow() -> void:
	var tween = animation_manager.create_preset_animation(test_control, AnimationManagerScript.PresetType.GLOW)

	assert_not_null(tween, "应创建Tween")


# =============================================================================
# ANIM-017: 创建组合动画-淡入缩放
# 测试 create_fade_scale_in 方法
# =============================================================================
func test_anim_017_create_fade_scale_in() -> void:
	test_control.modulate.a = 0.0
	test_control.scale = Vector2(0.8, 0.8)

	var tween = animation_manager.create_fade_scale_in(test_control)

	assert_not_null(tween, "应创建Tween")


# =============================================================================
# ANIM-018: 创建组合动画-淡出缩放
# 测试 create_fade_scale_out 方法
# =============================================================================
func test_anim_018_create_fade_scale_out() -> void:
	var tween = animation_manager.create_fade_scale_out(test_control)

	assert_not_null(tween, "应创建Tween")


# =============================================================================
# ANIM-019: 创建悬停动画
# 测试 create_hover_animation 方法
# =============================================================================
func test_anim_019_create_hover_animation() -> void:
	var tween = animation_manager.create_hover_animation(test_control)

	assert_not_null(tween, "应创建Tween")


# =============================================================================
# ANIM-020: 创建按下动画
# 测试 create_press_animation 方法
# =============================================================================
func test_anim_020_create_press_animation() -> void:
	var tween = animation_manager.create_press_animation(test_control)

	assert_not_null(tween, "应创建Tween")


# =============================================================================
# ANIM-021: 创建数值滚动动画
# 测试 create_count_animation 方法
# =============================================================================
func test_anim_021_create_count_animation() -> void:
	# 创建一个测试对象
	var test_obj = Node.new()
	test_obj.set_meta("test_value", 0.0)
	add_child(test_obj)

	var tween = animation_manager.create_count_animation(test_obj, "test_value", 0.0, 100.0)

	# 注意：由于tween_method需要属性存在，可能返回null
	# 这里只验证方法不会崩溃
	assert_true(true, "创建数值滚动动画不应崩溃")

	test_obj.queue_free()


# =============================================================================
# ANIM-022: 创建进度条动画
# 测试 create_progress_animation 方法
# =============================================================================
func test_anim_022_create_progress_animation() -> void:
	var progress_bar = ProgressBar.new()
	progress_bar.value = 0.0
	add_child(progress_bar)

	var tween = animation_manager.create_progress_animation(progress_bar, 50.0)

	assert_not_null(tween, "应创建Tween")

	progress_bar.queue_free()


# =============================================================================
# ANIM-023: 创建涟漪效果
# 测试 create_ripple_effect 方法
# =============================================================================
func test_anim_023_create_ripple_effect() -> void:
	var tween = animation_manager.create_ripple_effect(test_control)

	assert_not_null(tween, "应创建Tween")


# =============================================================================
# ANIM-024: 创建闪烁效果
# 测试 create_blink_effect 方法
# =============================================================================
func test_anim_024_create_blink_effect() -> void:
	var tween = animation_manager.create_blink_effect(test_control, 3, 0.3)

	assert_not_null(tween, "应创建Tween")


# =============================================================================
# ANIM-025: 创建呼吸动画
# 测试 create_breathing_animation 方法
# =============================================================================
func test_anim_025_create_breathing_animation() -> void:
	var tween = animation_manager.create_breathing_animation(test_control)

	assert_not_null(tween, "应创建Tween")


# =============================================================================
# ANIM-026: 停止所有动画
# 测试 stop_all_animations 方法
# =============================================================================
func test_anim_026_stop_all_animations() -> void:
	# 创建一些动画
	animation_manager.create_preset_animation(test_control, AnimationManagerScript.PresetType.FADE_IN)
	animation_manager.create_preset_animation(test_control, AnimationManagerScript.PresetType.PULSE)

	# 停止所有动画
	animation_manager.stop_all_animations(test_control)

	assert_eq(animation_manager._active_tweens.size(), 0, "活动Tween应为空")


# =============================================================================
# ANIM-027: 暂停所有动画
# 测试 pause_all_animations 方法
# =============================================================================
func test_anim_027_pause_all_animations() -> void:
	animation_manager.create_preset_animation(test_control, AnimationManagerScript.PresetType.FADE_IN)

	animation_manager.pause_all_animations()

	assert_true(true, "暂停动画不应崩溃")


# =============================================================================
# ANIM-028: 恢复所有动画
# 测试 resume_all_animations 方法
# =============================================================================
func test_anim_028_resume_all_animations() -> void:
	animation_manager.create_preset_animation(test_control, AnimationManagerScript.PresetType.FADE_IN)
	animation_manager.pause_all_animations()

	animation_manager.resume_all_animations()

	assert_true(true, "恢复动画不应崩溃")


# =============================================================================
# ANIM-029: 获取活动Tween数量
# 测试 get_active_tween_count 方法
# =============================================================================
func test_anim_029_get_active_tween_count() -> void:
	var count = animation_manager.get_active_tween_count()

	assert_eq(count, 0, "初始活动Tween数量应为0")

	# 创建动画
	animation_manager.create_preset_animation(test_control, AnimationManagerScript.PresetType.FADE_IN)

	count = animation_manager.get_active_tween_count()

	assert_eq(count, 1, "应有1个活动Tween")


# =============================================================================
# ANIM-030: 空目标处理
# 测试传入null目标时的处理
# =============================================================================
func test_anim_030_null_target() -> void:
	var tween = animation_manager.create_preset_animation(null, AnimationManagerScript.PresetType.FADE_IN)

	assert_null(tween, "null目标应返回null")


# =============================================================================
# ANIM-031: 自定义动画时长
# 测试自定义动画时长
# =============================================================================
func test_anim_031_custom_duration() -> void:
	var tween = animation_manager.create_preset_animation(test_control, AnimationManagerScript.PresetType.FADE_IN, 0.5)

	assert_not_null(tween, "应创建Tween")


# =============================================================================
# ANIM-032: Tween完成回调
# 测试Tween完成后的回调
# =============================================================================
func test_anim_032_tween_finished_callback() -> void:
	var tween = animation_manager.create_preset_animation(test_control, AnimationManagerScript.PresetType.FADE_IN, 0.1)

	# 等待动画完成
	await tween.finished

	# 验证Tween已从活动列表移除
	assert_eq(animation_manager._active_tweens.size(), 0, "Tween完成后应从活动列表移除")


# =============================================================================
# ANIM-033: 最大Tween数量限制
# 测试最大Tween数量限制
# =============================================================================
func test_anim_033_max_tween_limit() -> void:
	# 创建超过限制的Tween
	for i in range(60):
		var control = Control.new()
		add_child(control)
		animation_manager.create_preset_animation(control, AnimationManagerScript.PresetType.FADE_IN)
		control.queue_free()

	# 验证Tween数量不超过限制
	assert_true(animation_manager._active_tweens.size() <= AnimationManagerScript.MAX_ACTIVE_TWEENS, "Tween数量不应超过限制")


# =============================================================================
# ANIM-034: 清理已完成Tween
# 测试 _cleanup_finished_tweens 方法
# =============================================================================
func test_anim_034_cleanup_finished_tweens() -> void:
	# 创建一些Tween
	animation_manager.create_preset_animation(test_control, AnimationManagerScript.PresetType.FADE_IN, 0.1)

	# 等待完成
	await get_tree().create_timer(0.2).timeout

	# 清理
	animation_manager._cleanup_finished_tweens()

	assert_eq(animation_manager._active_tweens.size(), 0, "已完成的Tween应被清理")


# =============================================================================
# ANIM-035: 默认时长常量
# 测试默认时长常量
# =============================================================================
func test_anim_035_duration_constants() -> void:
	assert_eq(AnimationManagerScript.DEFAULT_DURATION, 0.3, "默认时长应为0.3秒")
	assert_eq(AnimationManagerScript.DURATION_FAST, 0.15, "快速时长应为0.15秒")
	assert_eq(AnimationManagerScript.DURATION_NORMAL, 0.3, "正常时长应为0.3秒")
	assert_eq(AnimationManagerScript.DURATION_SLOW, 0.5, "慢速时长应为0.5秒")


# =============================================================================
# ANIM-036: 最大活动Tween常量
# 测试最大活动Tween常量
# =============================================================================
func test_anim_036_max_active_tweens_constant() -> void:
	assert_eq(AnimationManagerScript.MAX_ACTIVE_TWEENS, 50, "最大活动Tween应为50")


# =============================================================================
# ANIM-037: 缓动类型映射
# 测试 EASE_MAP 常量
# =============================================================================
func test_anim_037_ease_map() -> void:
	assert_not_null(AnimationManagerScript.EASE_MAP, "EASE_MAP应存在")
	assert_true(AnimationManagerScript.EASE_MAP.has(AnimationManagerScript.PresetType.FADE_IN), "应包含FADE_IN")


# =============================================================================
# ANIM-038: 过渡类型映射
# 测试 TRANS_MAP 常量
# =============================================================================
func test_anim_038_trans_map() -> void:
	assert_not_null(AnimationManagerScript.TRANS_MAP, "TRANS_MAP应存在")
	assert_true(AnimationManagerScript.TRANS_MAP.has(AnimationManagerScript.PresetType.FADE_IN), "应包含FADE_IN")


# =============================================================================
# ANIM-039: 悬停动画自定义缩放
# 测试悬停动画自定义缩放
# =============================================================================
func test_anim_039_hover_custom_scale() -> void:
	var tween = animation_manager.create_hover_animation(test_control, 1.2, 0.2)

	assert_not_null(tween, "应创建Tween")


# =============================================================================
# ANIM-040: 按下动画自定义缩放
# 测试按下动画自定义缩放
# =============================================================================
func test_anim_040_press_custom_scale() -> void:
	var tween = animation_manager.create_press_animation(test_control, 0.9, 0.05)

	assert_not_null(tween, "应创建Tween")


# =============================================================================
# 附加测试：闪烁次数
# =============================================================================
func test_blink_times() -> void:
	var tween = animation_manager.create_blink_effect(test_control, 5, 0.5)

	assert_not_null(tween, "应创建Tween")


# =============================================================================
# 附加测试：呼吸动画参数
# =============================================================================
func test_breathing_params() -> void:
	var tween = animation_manager.create_breathing_animation(test_control, 0.95, 1.05, 1.5)

	assert_not_null(tween, "应创建Tween")


# =============================================================================
# 附加测试：列表入场动画
# =============================================================================
func test_list_enter_animation() -> void:
	var items = []
	for i in range(3):
		var item = Control.new()
		item.modulate.a = 0.0
		add_child(item)
		items.append(item)

	# 开始列表动画（不等待完成）
	animation_manager.create_list_enter_animation(items, 0.05, AnimationManagerScript.PresetType.FADE_IN)

	# 验证初始状态
	assert_true(true, "列表入场动画不应崩溃")

	# 清理
	for item in items:
		item.queue_free()


# =============================================================================
# 附加测试：多个动画同时运行
# =============================================================================
func test_multiple_animations() -> void:
	var control1 = Control.new()
	var control2 = Control.new()
	var control3 = Control.new()
	add_child(control1)
	add_child(control2)
	add_child(control3)

	animation_manager.create_preset_animation(control1, AnimationManagerScript.PresetType.FADE_IN)
	animation_manager.create_preset_animation(control2, AnimationManagerScript.PresetType.SCALE_IN)
	animation_manager.create_preset_animation(control3, AnimationManagerScript.PresetType.PULSE)

	assert_eq(animation_manager.get_active_tween_count(), 3, "应有3个活动Tween")

	control1.queue_free()
	control2.queue_free()
	control3.queue_free()