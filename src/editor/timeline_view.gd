class_name TimelineView
extends Control
## 时间线视图
## 显示小节线、音符、当前位置，支持缩放和滚动

const EditorData = preload("res://src/editor/editor_data.gd")

## 信号
signal measure_clicked(measure_index: int, position: float)
signal position_changed(time: float)
signal zoom_changed(zoom: float)

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


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS


func _gui_input(event: InputEvent) -> void:
	# 鼠标滚轮缩放
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom *= 1.1
			accept_event()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom /= 1.1
			accept_event()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			_handle_click(event.position)

	# 拖拽滚动
	if event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
			scroll_offset -= event.relative.x / zoom
			accept_event()


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

	# 绘制播放位置线
	if is_playing:
		_draw_playhead()


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


## 绘制网格线
func _draw_grid_lines(x: float, y: float, width: float, height: float, time_signature: Vector2) -> void:
	# 根据拍号绘制网格
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