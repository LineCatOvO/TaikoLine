class_name NoteEditor
extends Control
## 音符编辑组件
## 处理音符的放置、删除、移动操作

const EditorData = preload("res://src/editor/editor_data.gd")

## 信号
signal note_placed(note: EditorData.EditorNote)
signal note_removed(note: EditorData.EditorNote)
signal note_selected(note: EditorData.EditorNote)
signal request_add_note(measure_index: int, position: float)

## 编辑器控制器引用
var controller: EditorController = null

## 当前编辑的小节索引
var current_measure_index: int = 0

## 音符放置网格大小（0表示自由放置）
var grid_size: float = 0.0

## 是否吸附到网格
var snap_to_grid: bool = true

## 网格细分数量
var grid_subdivision: int = 16

## 鼠标位置
var _mouse_position: Vector2 = Vector2.ZERO

## 是否正在拖拽
var _is_dragging: bool = false

## 拖拽的音符
var _dragging_note: EditorData.EditorNote = null

## 拖拽起始位置
var _drag_start_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	# 设置鼠标过滤
	mouse_filter = Control.MOUSE_FILTER_PASS


func _gui_input(event: InputEvent) -> void:
	if controller == null:
		return

	# 鼠标移动
	if event is InputEventMouseMotion:
		_mouse_position = event.position
		_handle_drag(event.position)

	# 鼠标点击
	elif event is InputEventMouseButton:
		if event.pressed:
			match event.button_index:
				MOUSE_BUTTON_LEFT:
					_handle_left_click(event.position, event.shift_pressed)
				MOUSE_BUTTON_RIGHT:
					_handle_right_click(event.position)
				MOUSE_BUTTON_MIDDLE:
					_handle_middle_click(event.position)

		else:
			if event.button_index == MOUSE_BUTTON_LEFT:
				_end_drag()


## 处理左键点击
func _handle_left_click(position: Vector2, shift_pressed: bool) -> void:
	# 检查是否点击了音符
	var clicked_note = _get_note_at_position(position)

	if clicked_note != null:
		# 选中或添加到选择
		controller.select_note(clicked_note, shift_pressed)
		note_selected.emit(clicked_note)

		# 开始拖拽
		_start_drag(clicked_note, position)
	else:
		# 取消选择
		if not shift_pressed:
			controller.deselect_all()

		# 放置新音符
		var note_pos = _calculate_note_position(position)
		if note_pos.x >= 0:  # 有效的小节索引
			var note = controller.add_note(note_pos.x, note_pos.y)
			if note != null:
				note_placed.emit(note)


## 处理右键点击
func _handle_right_click(position: Vector2) -> void:
	# 检查是否点击了音符
	var clicked_note = _get_note_at_position(position)

	if clicked_note != null:
		# 删除音符
		controller.remove_note(clicked_note)
		note_removed.emit(clicked_note)


## 处理中键点击
func _handle_middle_click(position: Vector2) -> void:
	# 中键可以用于其他功能，如设置预览位置
	pass


## 开始拖拽
func _start_drag(note: EditorData.EditorNote, position: Vector2) -> void:
	_is_dragging = true
	_dragging_note = note
	_drag_start_position = position


## 结束拖拽
func _end_drag() -> void:
	if _is_dragging and _dragging_note != null:
		# 计算新位置
		var new_pos = _calculate_note_position(_mouse_position)
		if new_pos.x >= 0:
			controller.move_note(_dragging_note, new_pos.x, new_pos.y)

	_is_dragging = false
	_dragging_note = null


## 处理拖拽
func _handle_drag(position: Vector2) -> void:
	if not _is_dragging or _dragging_note == null:
		return

	# 可以在这里添加实时预览
	queue_redraw()


## 获取指定位置的音符
func _get_note_at_position(position: Vector2) -> EditorData.EditorNote:
	if controller == null:
		return null

	var course = controller.get_current_course()
	if course == null:
		return null

	# 计算点击位置对应的小节和位置
	var note_pos = _calculate_note_position(position)
	if note_pos.x < 0:
		return null

	var measure_index = int(note_pos.x)
	var note_position = note_pos.y

	if measure_index < 0 or measure_index >= course.measures.size():
		return null

	var measure = course.measures[measure_index]
	return measure.get_note_at_position(note_position, _get_hit_tolerance())


## 计算音符位置
func _calculate_note_position(screen_position: Vector2) -> Vector2:
	# 返回 Vector2(measure_index, position_in_measure)
	# 需要子类实现具体逻辑
	return Vector2(-1, 0.0)


## 获取点击容差
func _get_hit_tolerance() -> float:
	return 0.05


## 吸附到网格
func snap_position_to_grid(position: float) -> float:
	if not snap_to_grid or grid_size <= 0:
		return position

	var grid_step = 1.0 / grid_subdivision
	return round(position / grid_step) * grid_step


## 设置网格细分
func set_grid_subdivision(subdivision: int) -> void:
	grid_subdivision = max(1, subdivision)


## 设置吸附模式
func set_snap_enabled(enabled: bool) -> void:
	snap_to_grid = enabled


## 设置当前编辑的小节
func set_current_measure(index: int) -> void:
	current_measure_index = index


## 获取当前编辑的小节
func get_current_measure() -> int:
	return current_measure_index


## 绘制音符
func draw_note(note: EditorData.EditorNote, rect: Rect2, selected: bool = false) -> void:
	var draw_color = _get_note_color(note.note_type)

	if selected:
		# 绘制选中边框
		var border_rect = rect.grow(2)
		draw_rect(border_rect, Color.YELLOW, false, 2.0)

	# 绘制音符
	draw_rect(rect, draw_color)

	# 绘制音符类型标记
	match note.note_type:
		EditorData.NoteType.DON, EditorData.NoteType.DON_BIG:
			# 红色圆点
			draw_circle(rect.get_center(), rect.size.x * 0.3, Color.RED)
		EditorData.NoteType.KA, EditorData.NoteType.KA_BIG:
			# 蓝色圆点
			draw_circle(rect.get_center(), rect.size.x * 0.3, Color.BLUE)
		EditorData.NoteType.RENDA, EditorData.NoteType.RENDA_BIG:
			# 连打标记
			draw_line(rect.position, rect.end, Color.YELLOW, 2.0)
		EditorData.NoteType.BALLOON, EditorData.NoteType.KUSUDAMA:
			# 气球标记
			draw_circle(rect.get_center(), rect.size.x * 0.4, Color.ORANGE)


## 获取音符颜色
func _get_note_color(note_type: EditorData.NoteType) -> Color:
	match note_type:
		EditorData.NoteType.DON: return Color(0.9, 0.2, 0.2)
		EditorData.NoteType.KA: return Color(0.2, 0.4, 0.9)
		EditorData.NoteType.DON_BIG: return Color(1.0, 0.3, 0.3)
		EditorData.NoteType.KA_BIG: return Color(0.3, 0.5, 1.0)
		EditorData.NoteType.RENDA: return Color(0.8, 0.8, 0.2)
		EditorData.NoteType.RENDA_BIG: return Color(1.0, 1.0, 0.3)
		EditorData.NoteType.BALLOON: return Color(1.0, 0.6, 0.2)
		EditorData.NoteType.END: return Color(0.5, 0.5, 0.5)
		EditorData.NoteType.KUSUDAMA: return Color(0.8, 0.4, 0.8)
		EditorData.NoteType.DON_DOUBLE: return Color(0.9, 0.4, 0.4)
		EditorData.NoteType.KA_DOUBLE: return Color(0.4, 0.5, 0.9)
		EditorData.NoteType.BOMB: return Color(0.3, 0.3, 0.3)
		EditorData.NoteType.ADLIB: return Color(0.5, 0.5, 0.5, 0.5)
		EditorData.NoteType.SWAP: return Color(0.6, 0.8, 0.6)
		_: return Color(0.3, 0.3, 0.3)


## 设置控制器引用
func set_controller(p_controller: EditorController) -> void:
	controller = p_controller