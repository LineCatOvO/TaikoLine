class_name TimelineView
extends Control
## 时间线视图
## 显示小节线、音符、当前位置，支持缩放和滚动
## 支持音符拖拽、多选、框选、右键菜单

const EditorData = preload("res://src/editor/editor_data.gd")

## 信号
signal measure_clicked(measure_index: int, position: float)
signal position_changed(time: float)
signal zoom_changed(zoom: float)
signal note_clicked(note: EditorData.EditorNote, shift_pressed: bool)
signal note_dragged(note: EditorData.EditorNote, new_measure: int, new_position: float)
signal notes_selected(notes: Array)
signal selection_cleared()
signal playhead_dragged(time: float)
signal context_menu_requested(position: Vector2, note: EditorData.EditorNote)

## 编辑器控制器引用
var controller: EditorController = null

## 缩放级别
var zoom: float = 1.0:
	set(value):
		zoom = clamp(value, 0.25, 4.0)
		_update_layout()
		zoom_changed.emit(zoom)

## 水平滚动偏移
var scroll_offset: float = 0.0:
	set(value):
		scroll_offset = max(0.0, value)
		queue_redraw()

## 当前播放位置（秒）
var play_position: float = 0.0

## 是否正在播放
var is_playing: bool = false

## 小节宽度（基础值）
const MEASURE_WIDTH: float = 200.0

## 音符高度
const NOTE_HEIGHT: float = 40.0

## 时间线高度
const TIMELINE_HEIGHT: float = 30.0

## 小节线颜色
const MEASURE_LINE_COLOR: Color = Color(0.5, 0.5, 0.5)

## 当前位置线颜色
const PLAYHEAD_COLOR: Color = Color(1.0, 0.0, 0.0)

## Go-Go Time背景颜色
const GOGO_BG_COLOR: Color = Color(1.0, 0.8, 0.2, 0.3)

## 网格颜色
const GRID_COLOR: Color = Color(0.3, 0.3, 0.3, 0.5)

## 分支背景颜色
const BRANCH_NORMAL_COLOR: Color = Color(0.25, 0.25, 0.3, 0.3)
const BRANCH_EXPERT_COLOR: Color = Color(0.2, 0.3, 0.5, 0.3)
const BRANCH_MASTER_COLOR: Color = Color(0.4, 0.2, 0.4, 0.3)

## 分支条件标记颜色
const BRANCH_CONDITION_COLOR: Color = Color(1.0, 0.8, 0.0, 0.8)

## 选择框颜色
const SELECTION_BOX_COLOR: Color = Color(0.3, 0.6, 1.0, 0.3)
const SELECTION_BOX_BORDER: Color = Color(0.3, 0.6, 1.0, 0.8)

## 音符点击容差（像素）
const NOTE_CLICK_TOLERANCE: float = 10.0

## 播放头点击容差（像素）
const PLAYHEAD_CLICK_TOLERANCE: float = 8.0

## 拖拽模式枚举
enum DragMode {
	NONE,       ## 无拖拽
	NOTE,       ## 拖拽音符
	SELECTION,  ## 框选
	PLAYHEAD,   ## 拖拽播放头
	SCROLL      ## 拖拽滚动
}

## 当前拖拽模式
var _drag_mode: DragMode = DragMode.NONE

## 正在拖拽的音符
var _dragging_note: EditorData.EditorNote = null

## 拖拽起始位置
var _drag_start_pos: Vector2 = Vector2.ZERO

## 拖拽起始时的音符位置
var _drag_note_start: Vector2 = Vector2(-1, 0.0)

## 框选起始位置
var _selection_start: Vector2 = Vector2.ZERO

## 框选结束位置
var _selection_end: Vector2 = Vector2.ZERO

## 是否正在框选
var _is_selecting: bool = false

## 是否正在拖拽播放头
var _is_dragging_playhead: bool = false

## 鼠标位置
var _mouse_pos: Vector2 = Vector2.ZERO

## 悬停的音符
var _hovered_note: EditorData.EditorNote = null

## 悬停的播放头
var _is_hovering_playhead: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS


func _gui_input(event: InputEvent) -> void:
	if controller == null:
		return

	# 鼠标移动
	if event is InputEventMouseMotion:
		_mouse_pos = event.position
		_handle_mouse_motion(event)

	# 鼠标按钮
	elif event is InputEventMouseButton:
		_handle_mouse_button(event)

	# 键盘事件
	elif event is InputEventKey and event.pressed:
		_handle_key(event)


## 处理鼠标移动
func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	# 更新悬停状态
	_update_hover_state(event.position)

	# 处理拖拽
	match _drag_mode:
		DragMode.NOTE:
			_handle_note_drag(event.position)
		DragMode.SELECTION:
			_handle_selection_drag(event.position)
		DragMode.PLAYHEAD:
			_handle_playhead_drag(event.position)
		DragMode.SCROLL:
			scroll_offset -= event.relative.x / zoom

	# 中键拖拽滚动
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
		scroll_offset -= event.relative.x / zoom
		accept_event()

	queue_redraw()


## 处理鼠标按钮
func _handle_mouse_button(event: InputEventMouseButton) -> void:
	match event.button_index:
		MOUSE_BUTTON_LEFT:
			if event.pressed:
				_handle_left_press(event.position, event.shift_pressed, event.ctrl_pressed)
			else:
				_handle_left_release(event.position)
		MOUSE_BUTTON_RIGHT:
			if event.pressed:
				_handle_right_press(event.position)
		MOUSE_BUTTON_WHEEL_UP:
			if event.ctrl_pressed:
				zoom *= 1.1
			else:
				zoom *= 1.05
			accept_event()
		MOUSE_BUTTON_WHEEL_DOWN:
			if event.ctrl_pressed:
				zoom /= 1.1
			else:
				zoom /= 1.05
			accept_event()


## 处理左键按下
func _handle_left_press(position: Vector2, shift_pressed: bool, ctrl_pressed: bool) -> void:
	# 检查是否点击了播放头
	if _is_hovering_playhead:
		_drag_mode = DragMode.PLAYHEAD
		_drag_start_pos = position
		_is_dragging_playhead = true
		accept_event()
		return

	# 检查是否点击了音符
	var clicked_note = _get_note_at_position(position)
	if clicked_note != null:
		if shift_pressed:
			# Shift+点击：添加到选择
			controller.select_note(clicked_note, true)
		elif ctrl_pressed:
			# Ctrl+点击：切换选择
			if clicked_note.selected:
				controller.deselect_note(clicked_note)
			else:
				controller.select_note(clicked_note, true)
		else:
			# 普通点击：选择并开始拖拽
			if not clicked_note.selected:
				controller.deselect_all()
				controller.select_note(clicked_note, false)
			_start_note_drag(clicked_note, position)
		note_clicked.emit(clicked_note, shift_pressed)
		accept_event()
		return

	# 检查是否在时间线区域（设置播放位置）
	if position.y < TIMELINE_HEIGHT:
		var time = _x_to_time(position.x)
		playhead_dragged.emit(time)
		accept_event()
		return

	# 开始框选
	if shift_pressed or ctrl_pressed:
		# Shift/Ctrl + 空白区域：开始框选
		_start_selection(position)
		accept_event()
		return

	# 普通点击空白区域：取消选择并添加音符
	controller.deselect_all()
	selection_cleared.emit()
	_handle_click(position)
	accept_event()


## 处理左键释放
func _handle_left_release(position: Vector2) -> void:
	match _drag_mode:
		DragMode.NOTE:
			_end_note_drag(position)
		DragMode.SELECTION:
			_end_selection()
		DragMode.PLAYHEAD:
			_is_dragging_playhead = false

	_drag_mode = DragMode.NONE
	queue_redraw()


## 处理右键按下
func _handle_right_press(position: Vector2) -> void:
	var clicked_note = _get_note_at_position(position)
	context_menu_requested.emit(position, clicked_note)
	accept_event()


## 处理键盘事件
func _handle_key(event: InputEventKey) -> void:
	match event.keycode:
		KEY_A:
			if event.ctrl_pressed:
				# Ctrl+A: 全选
				controller.select_all()
				accept_event()
		KEY_DELETE:
			# Delete: 删除选中音符
			controller.delete_selected()
			accept_event()
		KEY_ESCAPE:
			# Escape: 取消选择
			controller.deselect_all()
			_drag_mode = DragMode.NONE
			accept_event()


## 更新悬停状态
func _update_hover_state(position: Vector2) -> void:
	# 检查是否悬停在播放头上
	var playhead_x = _time_to_x(play_position)
	_is_hovering_playhead = abs(position.x - playhead_x) < PLAYHEAD_CLICK_TOLERANCE

	# 检查是否悬停在音符上
	_hovered_note = _get_note_at_position(position)

	# 更新鼠标光标
	if _is_hovering_playhead or _hovered_note != null:
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	else:
		mouse_default_cursor_shape = Control.CURSOR_ARROW


## 开始音符拖拽
func _start_note_drag(note: EditorData.EditorNote, position: Vector2) -> void:
	_drag_mode = DragMode.NOTE
	_dragging_note = note
	_drag_start_pos = position
	_drag_note_start = Vector2(note.measure_index, note.position)


## 处理音符拖拽
func _handle_note_drag(position: Vector2) -> void:
	if _dragging_note == null:
		return

	# 计算新位置
	var new_pos = _screen_to_note_position(position)
	if new_pos.x < 0:
		return

	# 应用网格吸附
	if snap_enabled:
		new_pos.y = snap_position_to_grid(new_pos.y)

	# 实时更新预览（不实际移动，只重绘）
	queue_redraw()


## 结束音符拖拽
func _end_note_drag(position: Vector2) -> void:
	if _dragging_note == null:
		return

	var new_pos = _screen_to_note_position(position)
	if new_pos.x < 0:
		_dragging_note = null
		return

	# 应用网格吸附
	if snap_enabled:
		new_pos.y = snap_position_to_grid(new_pos.y)

	# 检查位置是否改变
	if new_pos.x != _drag_note_start.x or abs(new_pos.y - _drag_note_start.y) > 0.001:
		# 移动音符
		controller.move_note(_dragging_note, int(new_pos.x), new_pos.y)
		note_dragged.emit(_dragging_note, int(new_pos.x), new_pos.y)

	_dragging_note = null


## 开始框选
func _start_selection(position: Vector2) -> void:
	_drag_mode = DragMode.SELECTION
	_is_selecting = true
	_selection_start = position
	_selection_end = position


## 处理框选拖拽
func _handle_selection_drag(position: Vector2) -> void:
	_selection_end = position
	_select_notes_in_rect(_get_selection_rect())
	queue_redraw()


## 结束框选
func _end_selection() -> void:
	_is_selecting = false
	_drag_mode = DragMode.NONE


## 处理播放头拖拽
func _handle_playhead_drag(position: Vector2) -> void:
	var time = _x_to_time(position.x)
	playhead_dragged.emit(time)
	position_changed.emit(time)


## 获取选择框矩形
func _get_selection_rect() -> Rect2:
	var min_x = min(_selection_start.x, _selection_end.x)
	var min_y = min(_selection_start.y, _selection_end.y)
	var max_x = max(_selection_start.x, _selection_end.x)
	var max_y = max(_selection_start.y, _selection_end.y)
	return Rect2(min_x, min_y, max_x - min_x, max_y - min_y)


## 选择框内的音符
func _select_notes_in_rect(rect: Rect2) -> void:
	if controller == null:
		return

	var course = controller.get_current_course()
	if course == null:
		return

	var measure_width = MEASURE_WIDTH * zoom
	var selected: Array = []

	for measure in course.measures:
		var measure_x = measure.index * measure_width - scroll_offset
		if measure_x > rect.end.x:
			break
		if measure_x + measure_width < rect.position.x:
			continue

		for note in measure.notes:
			var note_x = measure_x + note.position * measure_width
			var note_y = TIMELINE_HEIGHT + 10 + NOTE_HEIGHT / 2

			if rect.has_point(Vector2(note_x, note_y)):
				selected.append(note)
				note.selected = true
			else:
				note.selected = false

	controller._on_selection_changed(selected)
	notes_selected.emit(selected)


## 获取指定位置的音符
func _get_note_at_position(screen_pos: Vector2) -> EditorData.EditorNote:
	if controller == null:
		return null

	var course = controller.get_current_course()
	if course == null:
		return null

	var measure_width = MEASURE_WIDTH * zoom
	var note_width = measure_width * 0.1

	for measure in course.measures:
		var measure_x = measure.index * measure_width - scroll_offset
		if measure_x > screen_pos.x + note_width:
			break
		if measure_x + measure_width < screen_pos.x - note_width:
			continue

		for note in measure.notes:
			var note_x = measure_x + note.position * measure_width
			var note_y = TIMELINE_HEIGHT + 10

			# 检查点击是否在音符范围内
			if abs(screen_pos.x - note_x) < note_width / 2 + NOTE_CLICK_TOLERANCE:
				if screen_pos.y >= note_y and screen_pos.y <= note_y + NOTE_HEIGHT + NOTE_CLICK_TOLERANCE:
					return note

	return null


## 屏幕坐标转音符位置
func _screen_to_note_position(screen_pos: Vector2) -> Vector2:
	# 返回 Vector2(measure_index, position_in_measure)
	if controller == null:
		return Vector2(-1, 0.0)

	var course = controller.get_current_course()
	if course == null:
		return Vector2(-1, 0.0)

	var measure_width = MEASURE_WIDTH * zoom
	var adjusted_x = screen_pos.x + scroll_offset
	var measure_index = int(adjusted_x / measure_width)
	var position_in_measure = (adjusted_x - measure_index * measure_width) / measure_width

	# 限制范围
	measure_index = clamp(measure_index, 0, course.measures.size() - 1)
	position_in_measure = clamp(position_in_measure, 0.0, 1.0)

	return Vector2(measure_index, position_in_measure)


## 处理点击
func _handle_click(position: Vector2) -> void:
	if controller == null:
		return

	var course = controller.get_current_course()
	if course == null:
		return

	# 计算点击的小节和位置
	var measure_width = MEASURE_WIDTH * zoom
	var adjusted_x = position.x + scroll_offset
	var measure_index = int(adjusted_x / measure_width)
	var position_in_measure = (adjusted_x - measure_index * measure_width) / measure_width

	# 应用网格吸附
	if snap_enabled:
		position_in_measure = snap_position_to_grid(position_in_measure)

	if measure_index >= 0 and measure_index < course.measures.size():
		measure_clicked.emit(measure_index, clamp(position_in_measure, 0.0, 1.0))


func _draw() -> void:
	if controller == null:
		return

	var course = controller.get_current_course()
	if course == null:
		return

	var measure_width = MEASURE_WIDTH * zoom
	var total_width = course.measures.size() * measure_width

	# 绘制背景
	draw_rect(Rect2(0, 0, size.x, size.y), Color(0.15, 0.15, 0.15))

	# 绘制时间线区域
	_draw_timeline(course, measure_width)

	# 绘制小节
	for i in range(course.measures.size()):
		var x = i * measure_width - scroll_offset
		if x > size.x:
			break
		if x + measure_width < 0:
			continue

		var measure = course.measures[i]
		_draw_measure(measure, x, measure_width)

	# 绘制播放位置线（始终显示，不只是播放时）
	_draw_playhead()

	# 绘制拖拽预览
	if _drag_mode == DragMode.NOTE and _dragging_note != null:
		_draw_drag_preview()

	# 绘制框选框
	if _is_selecting:
		_draw_selection_box()

	# 绘制悬停提示
	if _hovered_note != null and _drag_mode == DragMode.NONE:
		_draw_note_tooltip(_hovered_note)


## 绘制时间线
func _draw_timeline(course: EditorData.EditorCourse, measure_width: float) -> void:
	# 时间线背景
	draw_rect(Rect2(0, 0, size.x, TIMELINE_HEIGHT), Color(0.2, 0.2, 0.2))

	# 绘制小节标记
	for i in range(course.measures.size()):
		var x = i * measure_width - scroll_offset
		if x > size.x:
			break
		if x < -measure_width:
			continue

		# 小节编号
		var text = str(i + 1)
		var font = ThemeDB.fallback_font
		var font_size = 12
		draw_string(font, Vector2(x + 5, TIMELINE_HEIGHT - 8), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)

		# 小节分隔线
		draw_line(Vector2(x, 0), Vector2(x, TIMELINE_HEIGHT), MEASURE_LINE_COLOR, 1.0)


## 绘制小节
func _draw_measure(measure: EditorData.EditorMeasure, x: float, width: float) -> void:
	var note_area_y = TIMELINE_HEIGHT
	var note_area_height = size.y - TIMELINE_HEIGHT

	# 分支背景色（如果有分支）
	if controller != null and controller.has_branch():
		var branch_color = _get_branch_color(controller.get_current_branch())
		draw_rect(Rect2(x, note_area_y, width, note_area_height), branch_color)

	# Go-Go Time背景
	if measure.is_gogo:
		draw_rect(Rect2(x, note_area_y, width, note_area_height), GOGO_BG_COLOR)

	# 绘制网格线
	_draw_grid_lines(x, note_area_y, width, note_area_height, measure.time_signature)

	# 绘制音符
	for note in measure.notes:
		var note_x = x + note.position * width
		_draw_note(note, note_x, note_area_y + 10, width * 0.1)

	# 绘制小节线
	draw_line(Vector2(x, note_area_y), Vector2(x, size.y), MEASURE_LINE_COLOR, 2.0)

	# 绘制BPM标记
	var bpm_text = "BPM: %.1f" % measure.bpm
	var font = ThemeDB.fallback_font
	draw_string(font, Vector2(x + 5, size.y - 5), bpm_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.7, 0.7, 0.7))

	# 绘制分支条件标记
	_draw_branch_condition_marker(measure.index, x, note_area_y, width)


## 绘制网格线
func _draw_grid_lines(x: float, y: float, width: float, height: float, time_signature: Vector2) -> void:
	# 根据网格细分绘制细网格线
	var grid_step = 1.0 / float(grid_subdivision)
	var grid_width = width * grid_step

	# 绘制细网格线（较淡）
	for i in range(1, grid_subdivision):
		var line_x = x + i * grid_width
		var grid_color = Color(0.25, 0.25, 0.25, 0.3)
		draw_line(Vector2(line_x, y), Vector2(line_x, y + height), grid_color, 1.0)

	# 根据拍号绘制拍线（较亮）
	var beats = int(time_signature.x)
	var beat_width = width / beats

	for i in range(1, beats):
		var line_x = x + i * beat_width
		draw_line(Vector2(line_x, y), Vector2(line_x, y + height), GRID_COLOR, 1.0)


## 绘制音符
func _draw_note(note: EditorData.EditorNote, x: float, y: float, width: float) -> void:
	var color = _get_note_color(note.note_type)
	var rect = Rect2(x - width / 2, y, width, NOTE_HEIGHT)

	# 选中状态
	if note.selected:
		draw_rect(rect.grow(3), Color.YELLOW, false, 2.0)

	# 音符主体
	draw_rect(rect, color)

	# 音符类型标记
	match note.note_type:
		EditorData.NoteType.DON, EditorData.NoteType.DON_BIG:
			draw_circle(rect.get_center(), width * 0.3, Color(0.8, 0.1, 0.1))
		EditorData.NoteType.KA, EditorData.NoteType.KA_BIG:
			draw_circle(rect.get_center(), width * 0.3, Color(0.1, 0.3, 0.8))
		EditorData.NoteType.RENDA, EditorData.NoteType.RENDA_BIG:
			# 连打标记
			var center = rect.get_center()
			draw_line(Vector2(center.x - width * 0.3, center.y), Vector2(center.x + width * 0.3, center.y), Color.WHITE, 2.0)
		EditorData.NoteType.BALLOON, EditorData.NoteType.KUSUDAMA:
			# 气球标记
			draw_circle(rect.get_center(), width * 0.35, Color(1.0, 0.5, 0.0))


## 绘制播放位置线
func _draw_playhead() -> void:
	if controller == null:
		return

	var course = controller.get_current_course()
	if course == null:
		return

	# 计算播放位置对应的X坐标
	var x = _time_to_x(play_position)
	if x >= 0 and x <= size.x:
		draw_line(Vector2(x, 0), Vector2(x, size.y), PLAYHEAD_COLOR, 2.0)
		# 绘制三角形标记
		var points = PackedVector2Array([
			Vector2(x - 8, 0),
			Vector2(x + 8, 0),
			Vector2(x, 12)
		])
		draw_colored_polygon(points, PLAYHEAD_COLOR)


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


## 时间转X坐标
func _time_to_x(time: float) -> float:
	if controller == null:
		return -1.0

	var course = controller.get_current_course()
	if course == null:
		return -1.0

	var current_time = 0.0
	var measure_width = MEASURE_WIDTH * zoom

	for measure in course.measures:
		var measure_duration = measure.get_duration()
		if time >= current_time and time < current_time + measure_duration:
			var progress = (time - current_time) / measure_duration
			return measure.index * measure_width + progress * measure_width - scroll_offset
		current_time += measure_duration

	return -1.0


## X坐标转时间
func _x_to_time(x: float) -> float:
	if controller == null:
		return 0.0

	var course = controller.get_current_course()
	if course == null:
		return 0.0

	var measure_width = MEASURE_WIDTH * zoom
	var adjusted_x = x + scroll_offset
	var measure_index = int(adjusted_x / measure_width)
	var position_in_measure = (adjusted_x - measure_index * measure_width) / measure_width

	if measure_index < 0 or measure_index >= course.measures.size():
		return 0.0

	# 计算时间
	var time = 0.0
	for i in range(measure_index):
		time += course.measures[i].get_duration()

	time += course.measures[measure_index].get_duration() * position_in_measure

	return time


## 更新布局
func _update_layout() -> void:
	queue_redraw()


## 设置播放位置
func set_play_position(time: float) -> void:
	play_position = time
	queue_redraw()
	
	# 自动滚动到播放位置（如果启用）
	if is_playing and _auto_scroll_enabled:
		_auto_scroll_to_playhead()


## 设置播放状态
func set_playing(playing: bool) -> void:
	is_playing = playing
	queue_redraw()


## 是否启用自动滚动
var _auto_scroll_enabled: bool = true

## 网格细分数量（4, 8, 16, 32）
var grid_subdivision: int = 16

## 是否启用吸附
var snap_enabled: bool = true


## 设置网格细分
func set_grid_subdivision(subdivision: int) -> void:
	grid_subdivision = max(1, subdivision)
	queue_redraw()


## 设置吸附启用状态
func set_snap_enabled(enabled: bool) -> void:
	snap_enabled = enabled


## 将位置吸附到网格
func snap_position_to_grid(position: float) -> float:
	if not snap_enabled:
		return position

	var grid_step = 1.0 / float(grid_subdivision)
	return round(position / grid_step) * grid_step


## 设置自动滚动
func set_auto_scroll(enabled: bool) -> void:
	_auto_scroll_enabled = enabled


## 自动滚动到播放位置
func _auto_scroll_to_playhead() -> void:
	var x = _time_to_x(play_position)
	if x < 50 or x > size.x - 50:
		# 播放位置接近边缘时自动滚动
		scroll_offset += x - size.x / 2


## 设置缩放
func set_zoom(value: float) -> void:
	zoom = value


## 设置滚动偏移
func set_scroll_offset(value: float) -> void:
	scroll_offset = value


## 滚动到指定小节
func scroll_to_measure(measure_index: int) -> void:
	var measure_width = MEASURE_WIDTH * zoom
	scroll_offset = measure_index * measure_width - size.x / 2


## 滚动到播放位置
func scroll_to_play_position() -> void:
	var x = _time_to_x(play_position)
	if x >= 0:
		scroll_offset += x - size.x / 2


## 设置控制器引用
func set_controller(p_controller: EditorController) -> void:
	controller = p_controller
	if controller:
		controller.data_changed.connect(_on_data_changed)


## 数据变化回调
func _on_data_changed() -> void:
	queue_redraw()


## 获取总宽度
func get_total_width() -> float:
	if controller == null:
		return 0.0

	var course = controller.get_current_course()
	if course == null:
		return 0.0

	return course.measures.size() * MEASURE_WIDTH * zoom


## 获取可见范围
func get_visible_range() -> Vector2:
	var measure_width = MEASURE_WIDTH * zoom
	var start_measure = int(scroll_offset / measure_width)
	var end_measure = int((scroll_offset + size.x) / measure_width)
	return Vector2(start_measure, end_measure)


## 获取分支颜色
func _get_branch_color(branch_type: int) -> Color:
	match branch_type:
		EditorData.BranchType.NORMAL: return BRANCH_NORMAL_COLOR
		EditorData.BranchType.EXPERT: return BRANCH_EXPERT_COLOR
		EditorData.BranchType.MASTER: return BRANCH_MASTER_COLOR
		_: return BRANCH_NORMAL_COLOR


## 绘制分支条件标记
func _draw_branch_condition_marker(measure_index: int, x: float, y: float, width: float) -> void:
	if controller == null:
		return

	var conditions = controller.get_branch_conditions()
	for condition in conditions:
		if condition.measure_index == measure_index:
			# 绘制条件标记
			var marker_height = 20.0
			var marker_rect = Rect2(x, y, width, marker_height)

			# 背景
			draw_rect(marker_rect, BRANCH_CONDITION_COLOR)

			# 条件类型文字
			var font = ThemeDB.fallback_font
			var text = condition.get_condition_type_name()
			draw_string(font, Vector2(x + 5, y + 15), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.BLACK)

			# 阈值信息
			var threshold_text = "N:%.0f E:%.0f" % [condition.normal_threshold, condition.expert_threshold]
			draw_string(font, Vector2(x + 5, y + 35), threshold_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.3, 0.3, 0.3))


## 绘制拖拽预览
func _draw_drag_preview() -> void:
	if _dragging_note == null:
		return

	var new_pos = _screen_to_note_position(_mouse_pos)
	if new_pos.x < 0:
		return

	# 应用网格吸附
	if snap_enabled:
		new_pos.y = snap_position_to_grid(new_pos.y)

	var measure_width = MEASURE_WIDTH * zoom
	var note_width = measure_width * 0.1

	# 计算预览位置
	var preview_x = new_pos.x * measure_width - scroll_offset + new_pos.y * measure_width
	var preview_y = TIMELINE_HEIGHT + 10

	# 绘制半透明预览音符
	var color = _get_note_color(_dragging_note.note_type)
	color.a = 0.5
	var rect = Rect2(preview_x - note_width / 2, preview_y, note_width, NOTE_HEIGHT)

	# 绘制虚线边框
	draw_rect(rect, color, false, 2.0)

	# 绘制从原位置到新位置的连线
	var original_x = _drag_note_start.x * measure_width - scroll_offset + _drag_note_start.y * measure_width
	draw_line(
		Vector2(original_x, preview_y + NOTE_HEIGHT / 2),
		Vector2(preview_x, preview_y + NOTE_HEIGHT / 2),
		Color(1.0, 1.0, 0.0, 0.5),
		1.0
	)


## 绘制框选框
func _draw_selection_box() -> void:
	var rect = _get_selection_rect()

	# 填充
	draw_rect(rect, SELECTION_BOX_COLOR)

	# 边框
	draw_rect(rect, SELECTION_BOX_BORDER, false, 2.0)


## 绘制音符悬停提示
func _draw_note_tooltip(note: EditorData.EditorNote) -> void:
	if note == null:
		return

	var measure_width = MEASURE_WIDTH * zoom
	var note_x = note.measure_index * measure_width - scroll_offset + note.position * measure_width
	var note_y = TIMELINE_HEIGHT + 10 + NOTE_HEIGHT

	# 提示框位置
	var tooltip_x = note_x + 20
	var tooltip_y = note_y - 30

	# 提示文字
	var text = "%s\n小节: %d\n位置: %.3f" % [
		EditorData.get_note_type_name(note.note_type),
		note.measure_index + 1,
		note.position
	]

	# 计算提示框大小
	var font = ThemeDB.fallback_font
	var lines = text.split("\n")
	var max_width = 0.0
	for line in lines:
		var line_width = font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		if line_width > max_width:
			max_width = line_width

	var tooltip_width = max_width + 10
	var tooltip_height = lines.size() * 16 + 8

	# 绘制提示框背景
	var tooltip_rect = Rect2(tooltip_x, tooltip_y, tooltip_width, tooltip_height)
	draw_rect(tooltip_rect, Color(0.1, 0.1, 0.1, 0.9))
	draw_rect(tooltip_rect, Color(0.5, 0.5, 0.5), false, 1.0)

	# 绘制提示文字
	for i in range(lines.size()):
		draw_string(font, Vector2(tooltip_x + 5, tooltip_y + 14 + i * 16), lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)


## 检查控制器是否有分支
func has_branch() -> bool:
	if controller == null:
		return false
	var course = controller.get_current_course()
	if course == null:
		return false
	return course.has_branch


## 获取当前分支
func get_current_branch() -> int:
	if controller == null:
		return 0
	return controller.get_current_branch()