## 动画管理器
## 功能：统一管理UI动画效果，提供动画预设和性能优化
## 作者：TaikoLine Team
## 日期：2026-03-27

extends Node

## 动画预设类型
enum PresetType {
	FADE_IN,        ## 淡入
	FADE_OUT,       ## 淡出
	SCALE_IN,       ## 缩放进入
	SCALE_OUT,      ## 缩放退出
	SLIDE_IN_LEFT,  ## 从左侧滑入
	SLIDE_IN_RIGHT, ## 从右侧滑入
	SLIDE_IN_TOP,   ## 从顶部滑入
	SLIDE_IN_BOTTOM,## 从底部滑入
	BOUNCE,         ## 弹跳效果
	SHAKE,          ## 抖动效果
	PULSE,          ## 脉冲效果
	GLOW,           ## 发光效果
	POP,            ## 弹出效果
	WIGGLE          ## 摆动效果
}

## 缓动类型映射
const EASE_MAP = {
	PresetType.FADE_IN: Tween.EASE_OUT,
	PresetType.FADE_OUT: Tween.EASE_IN,
	PresetType.SCALE_IN: Tween.EASE_OUT,
	PresetType.SCALE_OUT: Tween.EASE_IN,
	PresetType.SLIDE_IN_LEFT: Tween.EASE_OUT,
	PresetType.SLIDE_IN_RIGHT: Tween.EASE_OUT,
	PresetType.SLIDE_IN_TOP: Tween.EASE_OUT,
	PresetType.SLIDE_IN_BOTTOM: Tween.EASE_OUT,
	PresetType.BOUNCE: Tween.EASE_OUT,
	PresetType.SHAKE: Tween.EASE_OUT,
	PresetType.PULSE: Tween.EASE_IN_OUT,
	PresetType.GLOW: Tween.EASE_IN_OUT,
	PresetType.POP: Tween.EASE_OUT,
	PresetType.WIGGLE: Tween.EASE_IN_OUT
}

## 过渡类型映射
const TRANS_MAP = {
	PresetType.FADE_IN: Tween.TRANS_QUAD,
	PresetType.FADE_OUT: Tween.TRANS_QUAD,
	PresetType.SCALE_IN: Tween.TRANS_BACK,
	PresetType.SCALE_OUT: Tween.TRANS_QUAD,
	PresetType.SLIDE_IN_LEFT: Tween.TRANS_QUART,
	PresetType.SLIDE_IN_RIGHT: Tween.TRANS_QUART,
	PresetType.SLIDE_IN_TOP: Tween.TRANS_QUART,
	PresetType.SLIDE_IN_BOTTOM: Tween.TRANS_QUART,
	PresetType.BOUNCE: Tween.TRANS_ELASTIC,
	PresetType.SHAKE: Tween.TRANS_QUAD,
	PresetType.PULSE: Tween.TRANS_SINE,
	PresetType.GLOW: Tween.TRANS_SINE,
	PresetType.POP: Tween.TRANS_BACK,
	PresetType.WIGGLE: Tween.TRANS_SINE
}

## 默认动画时长
const DEFAULT_DURATION = 0.3

## 动画时长预设
const DURATION_FAST = 0.15
const DURATION_NORMAL = 0.3
const DURATION_SLOW = 0.5

## 活动的Tween列表（用于性能管理）
var _active_tweens: Array[Tween] = []

## 最大同时活动的Tween数量
const MAX_ACTIVE_TWEENS = 50


## 创建预设动画
## 参数 target: 目标节点
## 参数 preset: 预设类型
## 参数 duration: 动画时长（可选）
## 返回: 创建的Tween
func create_preset_animation(target: Node, preset: PresetType, duration: float = DEFAULT_DURATION) -> Tween:
	if not target:
		return null

	# 检查Tween数量限制
	if _active_tweens.size() >= MAX_ACTIVE_TWEENS:
		_cleanup_finished_tweens()

	var tween = target.create_tween()
	tween.set_ease(EASE_MAP.get(preset, Tween.EASE_OUT))
	tween.set_trans(TRANS_MAP.get(preset, Tween.TRANS_QUAD))

	# 根据预设类型设置动画
	match preset:
		PresetType.FADE_IN:
			target.modulate.a = 0.0
			tween.tween_property(target, "modulate:a", 1.0, duration)

		PresetType.FADE_OUT:
			tween.tween_property(target, "modulate:a", 0.0, duration)

		PresetType.SCALE_IN:
			target.scale = Vector2.ZERO
			tween.tween_property(target, "scale", Vector2.ONE, duration)

		PresetType.SCALE_OUT:
			tween.tween_property(target, "scale", Vector2.ZERO, duration)

		PresetType.SLIDE_IN_LEFT:
			var original_pos = target.position
			target.position.x -= target.size.x if target is Control else 200
			tween.tween_property(target, "position:x", original_pos.x, duration)

		PresetType.SLIDE_IN_RIGHT:
			var original_pos = target.position
			target.position.x += target.size.x if target is Control else 200
			tween.tween_property(target, "position:x", original_pos.x, duration)

		PresetType.SLIDE_IN_TOP:
			var original_pos = target.position
			target.position.y -= target.size.y if target is Control else 200
			tween.tween_property(target, "position:y", original_pos.y, duration)

		PresetType.SLIDE_IN_BOTTOM:
			var original_pos = target.position
			target.position.y += target.size.y if target is Control else 200
			tween.tween_property(target, "position:y", original_pos.y, duration)

		PresetType.BOUNCE:
			var original_scale = target.scale
			target.scale = Vector2.ZERO
			tween.tween_property(target, "scale", original_scale * 1.2, duration * 0.6)
			tween.tween_property(target, "scale", original_scale * 0.9, duration * 0.2)
			tween.tween_property(target, "scale", original_scale, duration * 0.2)

		PresetType.SHAKE:
			var original_pos = target.position
			tween.tween_property(target, "position:x", original_pos.x + 10, 0.05)
			tween.tween_property(target, "position:x", original_pos.x - 10, 0.05)
			tween.tween_property(target, "position:x", original_pos.x + 5, 0.05)
			tween.tween_property(target, "position:x", original_pos.x, 0.05)

		PresetType.PULSE:
			var original_scale = target.scale
			tween.tween_property(target, "scale", original_scale * 1.1, duration * 0.5)
			tween.tween_property(target, "scale", original_scale, duration * 0.5)

		PresetType.GLOW:
			var original_modulate = target.modulate
			tween.tween_property(target, "modulate:v", 1.3, duration * 0.5)
			tween.tween_property(target, "modulate", original_modulate, duration * 0.5)

		PresetType.POP:
			var original_scale = target.scale
			target.scale = Vector2(0.5, 0.5)
			tween.tween_property(target, "scale", original_scale * 1.15, duration * 0.5)
			tween.tween_property(target, "scale", original_scale, duration * 0.3)

		PresetType.WIGGLE:
			var original_rotation = target.rotation
			tween.tween_property(target, "rotation", original_rotation + 0.1, duration * 0.25)
			tween.tween_property(target, "rotation", original_rotation - 0.1, duration * 0.25)
			tween.tween_property(target, "rotation", original_rotation, duration * 0.25)

	# 添加到活动列表
	_active_tweens.append(tween)
	tween.finished.connect(_on_tween_finished.bind(tween))

	return tween


## 创建组合动画（淡入+缩放）
## 参数 target: 目标节点
## 参数 duration: 动画时长
## 返回: 创建的Tween
func create_fade_scale_in(target: Node, duration: float = DEFAULT_DURATION) -> Tween:
	if not target:
		return null

	target.modulate.a = 0.0
	target.scale = Vector2(0.8, 0.8)

	var tween = target.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)

	tween.set_parallel(true)
	tween.tween_property(target, "modulate:a", 1.0, duration)
	tween.tween_property(target, "scale", Vector2.ONE, duration)

	_active_tweens.append(tween)
	tween.finished.connect(_on_tween_finished.bind(tween))

	return tween


## 创建组合动画（淡出+缩放）
## 参数 target: 目标节点
## 参数 duration: 动画时长
## 返回: 创建的Tween
func create_fade_scale_out(target: Node, duration: float = DEFAULT_DURATION) -> Tween:
	if not target:
		return null

	var tween = target.create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_QUAD)

	tween.set_parallel(true)
	tween.tween_property(target, "modulate:a", 0.0, duration)
	tween.tween_property(target, "scale", Vector2(0.8, 0.8), duration)

	_active_tweens.append(tween)
	tween.finished.connect(_on_tween_finished.bind(tween))

	return tween


## 创建按钮悬停动画
## 参数 target: 目标节点
## 参数 hover_scale: 悬停时的缩放倍数
## 参数 duration: 动画时长
## 返回: 创建的Tween
func create_hover_animation(target: Node, hover_scale: float = 1.1, duration: float = DURATION_FAST) -> Tween:
	if not target:
		return null

	var tween = target.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(target, "scale", Vector2(hover_scale, hover_scale), duration)

	_active_tweens.append(tween)
	tween.finished.connect(_on_tween_finished.bind(tween))

	return tween


## 创建按钮按下动画
## 参数 target: 目标节点
## 参数 press_scale: 按下时的缩放倍数
## 参数 duration: 动画时长
## 返回: 创建的Tween
func create_press_animation(target: Node, press_scale: float = 0.95, duration: float = 0.05) -> Tween:
	if not target:
		return null

	var tween = target.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(target, "scale", Vector2(press_scale, press_scale), duration)
	tween.tween_property(target, "scale", Vector2.ONE, duration)

	_active_tweens.append(tween)
	tween.finished.connect(_on_tween_finished.bind(tween))

	return tween


## 创建数值滚动动画
## 参数 target: 目标对象
## 参数 property: 属性名
## 参数 from: 起始值
## 参数 to: 结束值
## 参数 duration: 动画时长
## 返回: 创建的Tween
func create_count_animation(target: Object, property: String, from: float, to: float, duration: float = DEFAULT_DURATION) -> Tween:
	if not target:
		return null

	var tween = target.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_method(_set_property.bind(target, property), from, to, duration)

	_active_tweens.append(tween)
	tween.finished.connect(_on_tween_finished.bind(tween))

	return tween


## 创建进度条动画
## 参数 progress_bar: 进度条节点
## 参数 target_value: 目标值（0-100）
## 参数 duration: 动画时长
## 返回: 创建的Tween
func create_progress_animation(progress_bar: ProgressBar, target_value: float, duration: float = DEFAULT_DURATION) -> Tween:
	if not progress_bar:
		return null

	var tween = progress_bar.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(progress_bar, "value", target_value, duration)

	_active_tweens.append(tween)
	tween.finished.connect(_on_tween_finished.bind(tween))

	return tween


## 创建列表项入场动画
## 参数 items: 列表项数组
## 参数 stagger_delay: 每项之间的延迟
## 参数 preset: 动画预设
func create_list_enter_animation(items: Array, stagger_delay: float = 0.05, preset: PresetType = PresetType.SLIDE_IN_RIGHT) -> void:
	for i in range(items.size()):
		var item = items[i]
		if not item:
			continue

		# 设置初始状态
		item.modulate.a = 0.0

		# 延迟创建动画
		await get_tree().create_timer(i * stagger_delay).timeout
		create_preset_animation(item, preset, DEFAULT_DURATION)


## 创建涟漪效果
## 参数 target: 目标节点
## 参数 duration: 动画时长
## 返回: 创建的Tween
func create_ripple_effect(target: Node, duration: float = 0.4) -> Tween:
	if not target:
		return null

	var tween = target.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)

	# 缩放动画
	tween.tween_property(target, "scale", Vector2(1.05, 1.05), duration * 0.3)
	tween.tween_property(target, "scale", Vector2.ONE, duration * 0.7)

	_active_tweens.append(tween)
	tween.finished.connect(_on_tween_finished.bind(tween))

	return tween


## 创建闪烁效果
## 参数 target: 目标节点
## 参数 times: 闪烁次数
## 参数 duration: 总时长
## 返回: 创建的Tween
func create_blink_effect(target: Node, times: int = 3, duration: float = 0.3) -> Tween:
	if not target:
		return null

	var tween = target.create_tween()
	var single_duration = duration / (times * 2)

	for i in range(times):
		tween.tween_property(target, "modulate:a", 0.0, single_duration)
		tween.tween_property(target, "modulate:a", 1.0, single_duration)

	_active_tweens.append(tween)
	tween.finished.connect(_on_tween_finished.bind(tween))

	return tween


## 创建呼吸动画（循环）
## 参数 target: 目标节点
## 参数 min_scale: 最小缩放
## 参数 max_scale: 最大缩放
## 参数 cycle_duration: 一个周期的时长
## 返回: 创建的Tween
func create_breathing_animation(target: Node, min_scale: float = 0.98, max_scale: float = 1.02, cycle_duration: float = 2.0) -> Tween:
	if not target:
		return null

	var tween = target.create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_loops()  # 无限循环

	tween.tween_property(target, "scale", Vector2(max_scale, max_scale), cycle_duration * 0.5)
	tween.tween_property(target, "scale", Vector2(min_scale, min_scale), cycle_duration * 0.5)

	_active_tweens.append(tween)

	return tween


## 停止目标的所有动画
## 参数 target: 目标节点
func stop_all_animations(target: Node) -> void:
	for tween in _active_tweens:
		if tween and tween.is_valid():
			tween.kill()
	_active_tweens.clear()


## 暂停所有动画
func pause_all_animations() -> void:
	for tween in _active_tweens:
		if tween and tween.is_valid():
			tween.pause()


## 恢复所有动画
func resume_all_animations() -> void:
	for tween in _active_tweens:
		if tween and tween.is_valid():
			tween.play()


## 设置属性的辅助方法
func _set_property(value: float, target: Object, property: String) -> void:
	if target and target.has_method("set"):
		target.set(property, value)


## Tween完成回调
func _on_tween_finished(tween: Tween) -> void:
	_active_tweens.erase(tween)


## 清理已完成的Tween
func _cleanup_finished_tweens() -> void:
	var finished_tweens: Array[Tween] = []
	for tween in _active_tweens:
		if not tween or not tween.is_valid():
			finished_tweens.append(tween)

	for tween in finished_tweens:
		_active_tweens.erase(tween)


## 获取活动Tween数量
func get_active_tween_count() -> int:
	return _active_tweens.size()