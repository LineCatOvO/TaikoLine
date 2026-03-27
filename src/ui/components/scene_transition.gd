## 场景过渡动画组件
## 功能：提供场景切换时的过渡动画效果
## 作者：TaikoLine Team
## 日期：2026-03-27

extends CanvasLayer

## 过渡类型
enum TransitionType {
	FADE,           ## 淡入淡出
	SLIDE_LEFT,     ## 向左滑动
	SLIDE_RIGHT,    ## 向右滑动
	SLIDE_UP,       ## 向上滑动
	SLIDE_DOWN,     ## 向下滑动
	ZOOM,           ## 缩放
	ZOOM_FADE,      ## 缩放+淡入淡出
	CIRCLE_WIPE,    ## 圆形擦除
	DIAGONAL_WIPE   ## 对角线擦除
}

## 信号
signal transition_in_completed
signal transition_out_completed

## 配置
@export var transition_type: TransitionType = TransitionType.FADE
@export var transition_duration: float = 0.3
@export var pause_between: float = 0.1
@export var color: Color = Color(0, 0, 0)

## UI节点
var _overlay: ColorRect
var _tween: Tween

## 是否正在过渡
var _is_transitioning: bool = false

## 待切换的场景路径
var _pending_scene_path: String = ""

## 过渡完成回调
var _transition_callback: Callable


func _ready() -> void:
	layer = 100  # 确保在最上层
	_setup_overlay()


## 设置遮罩层
func _setup_overlay() -> void:
	_overlay = ColorRect.new()
	_overlay.color = color
	_overlay.modulate.a = 0.0
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)

	# 设置全屏锚点
	_overlay.anchors_preset = Control.PRESET_FULL_RECT
	_overlay.offset_left = 0
	_overlay.offset_right = 0
	_overlay.offset_top = 0
	_overlay.offset_bottom = 0


## 开始过渡进入动画
func transition_in() -> void:
	if _is_transitioning:
		return

	_is_transitioning = true
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	match transition_type:
		TransitionType.FADE:
			_fade_in()
		TransitionType.SLIDE_LEFT:
			_slide_in_left()
		TransitionType.SLIDE_RIGHT:
			_slide_in_right()
		TransitionType.SLIDE_UP:
			_slide_in_up()
		TransitionType.SLIDE_DOWN:
			_slide_in_down()
		TransitionType.ZOOM:
			_zoom_in()
		TransitionType.ZOOM_FADE:
			_zoom_fade_in()
		TransitionType.CIRCLE_WIPE:
			_circle_wipe_in()
		TransitionType.DIAGONAL_WIPE:
			_diagonal_wipe_in()


## 开始过渡退出动画
func transition_out() -> void:
	if _is_transitioning:
		return

	_is_transitioning = true
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	match transition_type:
		TransitionType.FADE:
			_fade_out()
		TransitionType.SLIDE_LEFT:
			_slide_out_left()
		TransitionType.SLIDE_RIGHT:
			_slide_out_right()
		TransitionType.SLIDE_UP:
			_slide_out_up()
		TransitionType.SLIDE_DOWN:
			_slide_out_down()
		TransitionType.ZOOM:
			_zoom_out()
		TransitionType.ZOOM_FADE:
			_zoom_fade_out()
		TransitionType.CIRCLE_WIPE:
			_circle_wipe_out()
		TransitionType.DIAGONAL_WIPE:
			_diagonal_wipe_out()


## 切换场景（带过渡动画）
## 参数 scene_path: 场景路径
## 参数 callback: 过渡完成回调（可选）
func change_scene(scene_path: String, callback: Callable = Callable()) -> void:
	_pending_scene_path = scene_path
	_transition_callback = callback
	transition_in()


## 淡入
func _fade_in() -> void:
	_overlay.modulate.a = 0.0

	if _tween:
		_tween.kill()

	_tween = create_tween()
	_tween.set_ease(Tween.EASE_IN)
	_tween.set_trans(Tween.TRANS_QUAD)
	_tween.tween_property(_overlay, "modulate:a", 1.0, transition_duration)
	_tween.tween_callback(_on_transition_in_completed)


## 淡出
func _fade_out() -> void:
	_overlay.modulate.a = 1.0

	if _tween:
		_tween.kill()

	_tween = create_tween()
	_tween.set_ease(Tween.EASE_OUT)
	_tween.set_trans(Tween.TRANS_QUAD)
	_tween.tween_property(_overlay, "modulate:a", 0.0, transition_duration)
	_tween.tween_callback(_on_transition_out_completed)


## 从左滑入
func _slide_in_left() -> void:
	var screen_size = get_viewport().get_visible_rect().size
	_overlay.position = Vector2(-screen_size.x, 0)
	_overlay.modulate.a = 1.0

	if _tween:
		_tween.kill()

	_tween = create_tween()
	_tween.set_ease(Tween.EASE_OUT)
	_tween.set_trans(Tween.TRANS_QUART)
	_tween.tween_property(_overlay, "position:x", 0, transition_duration)
	_tween.tween_callback(_on_transition_in_completed)


## 向左滑出
func _slide_out_left() -> void:
	var screen_size = get_viewport().get_visible_rect().size
	_overlay.position = Vector2(0, 0)
	_overlay.modulate.a = 1.0

	if _tween:
		_tween.kill()

	_tween = create_tween()
	_tween.set_ease(Tween.EASE_IN)
	_tween.set_trans(Tween.TRANS_QUART)
	_tween.tween_property(_overlay, "position:x", -screen_size.x, transition_duration)
	_tween.tween_callback(_on_transition_out_completed)


## 从右滑入
func _slide_in_right() -> void:
	var screen_size = get_viewport().get_visible_rect().size
	_overlay.position = Vector2(screen_size.x, 0)
	_overlay.modulate.a = 1.0

	if _tween:
		_tween.kill()

	_tween = create_tween()
	_tween.set_ease(Tween.EASE_OUT)
	_tween.set_trans(Tween.TRANS_QUART)
	_tween.tween_property(_overlay, "position:x", 0, transition_duration)
	_tween.tween_callback(_on_transition_in_completed)


## 向右滑出
func _slide_out_right() -> void:
	var screen_size = get_viewport().get_visible_rect().size
	_overlay.position = Vector2(0, 0)
	_overlay.modulate.a = 1.0

	if _tween:
		_tween.kill()

	_tween = create_tween()
	_tween.set_ease(Tween.EASE_IN)
	_tween.set_trans(Tween.TRANS_QUART)
	_tween.tween_property(_overlay, "position:x", screen_size.x, transition_duration)
	_tween.tween_callback(_on_transition_out_completed)


## 从上滑入
func _slide_in_up() -> void:
	var screen_size = get_viewport().get_visible_rect().size
	_overlay.position = Vector2(0, -screen_size.y)
	_overlay.modulate.a = 1.0

	if _tween:
		_tween.kill()

	_tween = create_tween()
	_tween.set_ease(Tween.EASE_OUT)
	_tween.set_trans(Tween.TRANS_QUART)
	_tween.tween_property(_overlay, "position:y", 0, transition_duration)
	_tween.tween_callback(_on_transition_in_completed)


## 向上滑出
func _slide_out_up() -> void:
	var screen_size = get_viewport().get_visible_rect().size
	_overlay.position = Vector2(0, 0)
	_overlay.modulate.a = 1.0

	if _tween:
		_tween.kill()

	_tween = create_tween()
	_tween.set_ease(Tween.EASE_IN)
	_tween.set_trans(Tween.TRANS_QUART)
	_tween.tween_property(_overlay, "position:y", -screen_size.y, transition_duration)
	_tween.tween_callback(_on_transition_out_completed)


## 从下滑入
func _slide_in_down() -> void:
	var screen_size = get_viewport().get_visible_rect().size
	_overlay.position = Vector2(0, screen_size.y)
	_overlay.modulate.a = 1.0

	if _tween:
		_tween.kill()

	_tween = create_tween()
	_tween.set_ease(Tween.EASE_OUT)
	_tween.set_trans(Tween.TRANS_QUART)
	_tween.tween_property(_overlay, "position:y", 0, transition_duration)
	_tween.tween_callback(_on_transition_in_completed)


## 向下滑出
func _slide_out_down() -> void:
	var screen_size = get_viewport().get_visible_rect().size
	_overlay.position = Vector2(0, 0)
	_overlay.modulate.a = 1.0

	if _tween:
		_tween.kill()

	_tween = create_tween()
	_tween.set_ease(Tween.EASE_IN)
	_tween.set_trans(Tween.TRANS_QUART)
	_tween.tween_property(_overlay, "position:y", screen_size.y, transition_duration)
	_tween.tween_callback(_on_transition_out_completed)


## 缩放进入
func _zoom_in() -> void:
	_overlay.scale = Vector2.ZERO
	_overlay.modulate.a = 1.0
	_overlay.position = Vector2.ZERO

	if _tween:
		_tween.kill()

	_tween = create_tween()
	_tween.set_ease(Tween.EASE_OUT)
	_tween.set_trans(Tween.TRANS_BACK)
	_tween.tween_property(_overlay, "scale", Vector2.ONE, transition_duration)
	_tween.tween_callback(_on_transition_in_completed)


## 缩放退出
func _zoom_out() -> void:
	_overlay.scale = Vector2.ONE
	_overlay.modulate.a = 1.0

	if _tween:
		_tween.kill()

	_tween = create_tween()
	_tween.set_ease(Tween.EASE_IN)
	_tween.set_trans(Tween.TRANS_QUAD)
	_tween.tween_property(_overlay, "scale", Vector2.ZERO, transition_duration)
	_tween.tween_callback(_on_transition_out_completed)


## 缩放+淡入
func _zoom_fade_in() -> void:
	_overlay.scale = Vector2(0.5, 0.5)
	_overlay.modulate.a = 0.0
	_overlay.position = Vector2.ZERO

	if _tween:
		_tween.kill()

	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.set_ease(Tween.EASE_OUT)
	_tween.set_trans(Tween.TRANS_BACK)
	_tween.tween_property(_overlay, "scale", Vector2.ONE, transition_duration)
	_tween.tween_property(_overlay, "modulate:a", 1.0, transition_duration)
	_tween.tween_callback(_on_transition_in_completed)


## 缩放+淡出
func _zoom_fade_out() -> void:
	_overlay.scale = Vector2.ONE
	_overlay.modulate.a = 1.0

	if _tween:
		_tween.kill()

	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.set_ease(Tween.EASE_IN)
	_tween.set_trans(Tween.TRANS_QUAD)
	_tween.tween_property(_overlay, "scale", Vector2(0.5, 0.5), transition_duration)
	_tween.tween_property(_overlay, "modulate:a", 0.0, transition_duration)
	_tween.tween_callback(_on_transition_out_completed)


## 圆形擦除进入（使用shader实现简化版）
func _circle_wipe_in() -> void:
	# 简化实现：使用缩放模拟
	_overlay.scale = Vector2.ZERO
	_overlay.modulate.a = 1.0

	if _tween:
		_tween.kill()

	_tween = create_tween()
	_tween.set_ease(Tween.EASE_OUT)
	_tween.set_trans(Tween.TRANS_QUART)
	_tween.tween_property(_overlay, "scale", Vector2.ONE, transition_duration)
	_tween.tween_callback(_on_transition_in_completed)


## 圆形擦除退出
func _circle_wipe_out() -> void:
	_overlay.scale = Vector2.ONE
	_overlay.modulate.a = 1.0

	if _tween:
		_tween.kill()

	_tween = create_tween()
	_tween.set_ease(Tween.EASE_IN)
	_tween.set_trans(Tween.TRANS_QUART)
	_tween.tween_property(_overlay, "scale", Vector2.ZERO, transition_duration)
	_tween.tween_callback(_on_transition_out_completed)


## 对角线擦除进入
func _diagonal_wipe_in() -> void:
	# 简化实现：使用淡入
	_overlay.modulate.a = 0.0

	if _tween:
		_tween.kill()

	_tween = create_tween()
	_tween.set_ease(Tween.EASE_OUT)
	_tween.set_trans(Tween.TRANS_QUART)
	_tween.tween_property(_overlay, "modulate:a", 1.0, transition_duration)
	_tween.tween_callback(_on_transition_in_completed)


## 对角线擦除退出
func _diagonal_wipe_out() -> void:
	_overlay.modulate.a = 1.0

	if _tween:
		_tween.kill()

	_tween = create_tween()
	_tween.set_ease(Tween.EASE_IN)
	_tween.set_trans(Tween.TRANS_QUART)
	_tween.tween_property(_overlay, "modulate:a", 0.0, transition_duration)
	_tween.tween_callback(_on_transition_out_completed)


## 过渡进入完成回调
func _on_transition_in_completed() -> void:
	transition_in_completed.emit()

	# 如果有待切换的场景
	if _pending_scene_path != "":
		# 执行回调
		if _transition_callback.is_valid():
			_transition_callback.call()

		# 切换场景
		get_tree().change_scene_to_file(_pending_scene_path)
		_pending_scene_path = ""

		# 等待一帧后开始过渡退出
		await get_tree().process_frame
		await get_tree().create_timer(pause_between).timeout
		transition_out()
	else:
		_is_transitioning = false
		_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE


## 过渡退出完成回调
func _on_transition_out_completed() -> void:
	_is_transitioning = false
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transition_out_completed.emit()


## 检查是否正在过渡
func is_transitioning() -> bool:
	return _is_transitioning


## 设置过渡类型
func set_transition_type(type: TransitionType) -> void:
	transition_type = type


## 设置过渡时长
func set_transition_duration(duration: float) -> void:
	transition_duration = duration


## 设置过渡颜色
func set_transition_color(new_color: Color) -> void:
	color = new_color
	_overlay.color = color