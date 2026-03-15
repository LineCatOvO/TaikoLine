class_name NoteManager
extends Node
## 音符管理器
## 实现音符的生成和管理，使用对象池模式

const TJAData = preload("res://src/parser/tja_data.gd")
const GameNote = preload("res://src/game/note.gd")

## 信号
signal all_notes_processed
signal note_spawned(note: GameNote)
signal note_judged(note: GameNote, result: String)
signal note_missed(note: GameNote)

## 配置
@export var pool_size: int = 100  ## 对象池大小
@export var spawn_position_x: float = 1200.0  ## 生成位置X坐标

## 音符池
var _note_pool: Array[GameNote] = []
var _active_notes: Array[GameNote] = []

## 音符数据队列
var _note_queue: Array[Dictionary] = []

## 当前时间
var _current_time: float = 0.0

## 滚动系统引用
var scroll_system: Node = null

## 判定系统引用
var judge_system: Node = null


func _ready() -> void:
	_initialize_pool()


## 初始化对象池
func _initialize_pool() -> void:
	for i in range(pool_size):
		var note = _create_note()
		note.visible = false
		_note_pool.append(note)


## 创建新音符
func _create_note() -> GameNote:
	var note = GameNote.new()
	note.note_judged.connect(_on_note_judged)
	note.note_missed.connect(_on_note_missed)
	add_child(note)
	return note


## 从池中获取音符
func _get_note_from_pool() -> GameNote:
	if _note_pool.is_empty():
		# 池为空，创建新音符
		return _create_note()
	
	var note = _note_pool.pop_back()
	note.visible = true
	note.reset()
	return note


## 将音符返回池中
func _return_note_to_pool(note: GameNote) -> void:
	note.visible = false
	note.reset()
	
	if _note_pool.size() < pool_size:
		_note_pool.append(note)
	else:
		# 池已满，释放音符
		note.queue_free()


## 加载谱面数据
func load_chart(course: TJAData.TJACourse, offset: float = 0.0) -> void:
	clear_all_notes()
	
	# 构建音符队列
	var current_time = offset
	var current_bpm = 120.0
	var current_scroll = 1.0
	
	for measure in course.measures:
		# 更新BPM和滚动速度
		current_bpm = measure.bpm
		current_scroll = measure.scroll
		
		# 计算小节时长
		var measure_duration = measure.get_duration()
		
		# 处理命令
		for command in measure.commands:
			_process_command(command, current_time)
		
		# 生成音符
		for note in measure.notes:
			if note.is_hittable():
				var note_time = current_time + note.position * measure_duration
				_note_queue.append({
					"note_data": note,
					"hit_time": note_time,
					"bpm": current_bpm,
					"scroll": current_scroll
				})
		
		current_time += measure_duration
	
	# 按时间排序
	_note_queue.sort_custom(func(a, b): return a.hit_time < b.hit_time)


## 处理命令
func _process_command(command: TJAData.TJACommand, time: float) -> void:
	# 命令处理逻辑（可扩展）
	match command.command_type:
		TJAData.TJACommand.CommandType.BPMCHANGE:
			# BPM变化已在measure中处理
			pass
		TJAData.TJACommand.CommandType.SCROLL:
			# 滚动速度变化已在measure中处理
			pass
		TJAData.TJACommand.CommandType.GOGOSTART:
			# Go-Go Time开始
			pass
		TJAData.TJACommand.CommandType.GOGOEND:
			# Go-Go Time结束
			pass


## 更新音符管理
func update(current_time: float) -> void:
	_current_time = current_time
	
	# 检查需要生成的音符
	_spawn_pending_notes()
	
	# 更新活动音符位置
	_update_active_notes()
	
	# 检查错过的音符
	_check_missed_notes()


## 生成待处理的音符
func _spawn_pending_notes() -> void:
	if scroll_system == null:
		return
	
	var spawn_ahead_time = scroll_system.get_spawn_ahead_time()
	
	var i = 0
	while i < _note_queue.size():
		var note_info = _note_queue[i]
		var time_until_hit = note_info.hit_time - _current_time
		
		# 检查是否应该生成
		if time_until_hit <= spawn_ahead_time:
			_spawn_note(note_info)
			_note_queue.remove_at(i)
		else:
			i += 1


## 生成单个音符
func _spawn_note(note_info: Dictionary) -> void:
	var note = _get_note_from_pool()
	note.setup(note_info.note_data, note_info.hit_time)
	note.scroll_speed = note_info.scroll
	note.visible = true
	
	_active_notes.append(note)
	note_spawned.emit(note)


## 更新活动音符
func _update_active_notes() -> void:
	if scroll_system == null:
		return
	
	for note in _active_notes:
		note.update_position(_current_time, scroll_system)


## 检查错过的音符
func _check_missed_notes() -> void:
	var notes_to_remove: Array[GameNote] = []
	
	for note in _active_notes:
		if note.note_state == GameNote.NoteState.MISSED:
			notes_to_remove.append(note)
			note_missed.emit(note)
	
	# 移除错过的音符
	for note in notes_to_remove:
		_active_notes.erase(note)
		_return_note_to_pool(note)


## 处理输入
func handle_input(input_type: String) -> Dictionary:
	var results: Array[Dictionary] = []
	
	# 找到最接近判定线的音符
	var closest_note: GameNote = null
	var closest_distance: float = INF
	
	for note in _active_notes:
		if note.note_state == GameNote.NoteState.JUDGING:
			var distance = abs(note.position.x - note.judge_line_x)
			if distance < closest_distance:
				closest_distance = distance
				closest_note = note
	
	# 尝试判定
	if closest_note != null:
		var result = closest_note.try_judge(input_type, _current_time)
		if result != "":
			results.append({
				"note": closest_note,
				"result": result
			})
			
			# 从活动列表移除
			_active_notes.erase(closest_note)
			_return_note_to_pool(closest_note)
	
	return {"results": results}


## 音符判定回调
func _on_note_judged(note: GameNote, result: String) -> void:
	note_judged.emit(note, result)


## 音符错过回调
func _on_note_missed(note: GameNote) -> void:
	# 已在_check_missed_notes中处理
	pass


## 清除所有音符
func clear_all_notes() -> void:
	# 返回活动音符到池中
	for note in _active_notes:
		_return_note_to_pool(note)
	_active_notes.clear()
	
	# 清空队列
	_note_queue.clear()


## 获取活动音符数量
func get_active_note_count() -> int:
	return _active_notes.size()


## 获取待生成音符数量
func get_pending_note_count() -> int:
	return _note_queue.size()


## 获取总音符数量
func get_total_note_count() -> int:
	return get_active_note_count() + get_pending_note_count()


## 检查是否所有音符都已处理
func is_all_notes_processed() -> bool:
	return _note_queue.is_empty() and _active_notes.is_empty()


## 设置滚动系统
func set_scroll_system(system: Node) -> void:
	scroll_system = system


## 设置判定系统
func set_judge_system(system: Node) -> void:
	judge_system = system