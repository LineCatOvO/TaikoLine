class_name ScrollSystem
extends Node
## 滚动系统
## 实现音符滚动、BPM变化处理、SCROLL命令处理和时间到位置转换

## 信号
signal scroll_speed_changed(new_speed: float)
signal bpm_changed(new_bpm: float)

## 配置
@export var base_scroll_speed: float = 1.0  ## 基础滚动速度
@export var judge_line_x: float = 400.0     ## 判定线X坐标
@export var pixels_per_beat: float = 100.0  ## 每拍像素数

## BPM变化数据
class BPMChange:
	var time: float    ## 变化发生时间（秒）
	var bpm: float     ## 新BPM值
	
	func _init(p_time: float, p_bpm: float) -> void:
		time = p_time
		bpm = p_bpm

## 滚动速度变化数据
class ScrollChange:
	var time: float    ## 变化发生时间（秒）
	var scroll: float  ## 新滚动速度
	
	func _init(p_time: float, p_scroll: float) -> void:
		time = p_time
		scroll = p_scroll

## BPM变化列表
var _bpm_changes: Array[BPMChange] = []

## 滚动速度变化列表
var _scroll_changes: Array[ScrollChange] = []

## 当前BPM
var _current_bpm: float = 120.0

## 当前滚动速度
var _current_scroll: float = 1.0

## 当前时间
var _current_time: float = 0.0

## 音符偏移
var _offset: float = 0.0


func _ready() -> void:
	reset()


## 重置滚动系统
func reset() -> void:
	_bpm_changes.clear()
	_scroll_changes.clear()
	_current_bpm = 120.0
	_current_scroll = 1.0
	_current_time = 0.0
	_offset = 0.0


## 设置偏移
func set_offset(offset: float) -> void:
	_offset = offset


## 设置基础滚动速度
func set_base_scroll_speed(speed: float) -> void:
	base_scroll_speed = speed


## 加载谱面数据
func load_chart_data(course) -> void:
	reset()
	
	var current_time = _offset
	var current_bpm = 120.0
	var current_scroll = 1.0
	var first_bpm_added = false
	var first_scroll_added = false
	
	# 遍历所有小节，收集BPM和滚动速度变化
	for measure in course.measures:
		# 检查BPM变化（第一个小节总是添加初始BPM）
		if not first_bpm_added or measure.bpm != current_bpm:
			_bpm_changes.append(BPMChange.new(current_time, measure.bpm))
			current_bpm = measure.bpm
			first_bpm_added = true
		
		# 检查滚动速度变化（第一个小节总是添加初始滚动速度）
		if not first_scroll_added or measure.scroll != current_scroll:
			_scroll_changes.append(ScrollChange.new(current_time, measure.scroll))
			current_scroll = measure.scroll
			first_scroll_added = true
		
		# 处理命令中的变化
		for command in measure.commands:
			match command.command_type:
				1:  # BPMCHANGE
					var new_bpm = command.params[0] if command.params.size() > 0 else current_bpm
					_bpm_changes.append(BPMChange.new(current_time, new_bpm))
					current_bpm = new_bpm
				3:  # SCROLL
					var new_scroll = command.params[0] if command.params.size() > 0 else current_scroll
					_scroll_changes.append(ScrollChange.new(current_time, new_scroll))
					current_scroll = new_scroll
		
		current_time += measure.get_duration()
	
	# 设置初始BPM
	if _bpm_changes.size() > 0:
		_current_bpm = _bpm_changes[0].bpm


## 更新当前时间
func update_time(time: float) -> void:
	_current_time = time
	
	# 更新当前BPM
	_update_current_bpm()
	
	# 更新当前滚动速度
	_update_current_scroll()


## 更新当前BPM
func _update_current_bpm() -> void:
	for i in range(_bpm_changes.size() - 1, -1, -1):
		if _bpm_changes[i].time <= _current_time:
			if _current_bpm != _bpm_changes[i].bpm:
				_current_bpm = _bpm_changes[i].bpm
				bpm_changed.emit(_current_bpm)
			break


## 更新当前滚动速度
func _update_current_scroll() -> void:
	for i in range(_scroll_changes.size() - 1, -1, -1):
		if _scroll_changes[i].time <= _current_time:
			if _current_scroll != _scroll_changes[i].scroll:
				_current_scroll = _scroll_changes[i].scroll
				scroll_speed_changed.emit(_current_scroll)
			break


## 时间转换为位置
## @param time_diff: 时间差（秒），正数表示未来，负数表示过去
## @return: X坐标位置
func time_to_position(time_diff: float) -> float:
	# 计算有效滚动速度
	var effective_speed = base_scroll_speed * _current_scroll
	
	# 计算每秒像素数
	# BPM = 每分钟拍数，每拍 = 60/BPM 秒
	# 每秒像素数 = pixels_per_beat * BPM / 60
	var pixels_per_second = pixels_per_beat * _current_bpm / 60.0
	
	# 计算位置
	# 判定线位置 + 时间差 * 滚动速度 * 每秒像素数
	var position = judge_line_x + time_diff * effective_speed * pixels_per_second
	
	return position


## 位置转换为时间
## @param position: X坐标位置
## @return: 时间差（秒）
func position_to_time(position: float) -> float:
	var effective_speed = base_scroll_speed * _current_scroll
	var pixels_per_second = pixels_per_beat * _current_bpm / 60.0
	
	if effective_speed == 0 or pixels_per_second <= 0:
		return 0.0
	
	# 允许负滚动速度产生负时间差
	return (position - judge_line_x) / (effective_speed * pixels_per_second)


## 获取生成提前时间
## @return: 音符应该提前多少秒生成
func get_spawn_ahead_time() -> float:
	# 假设音符从屏幕右侧生成
	var spawn_position = 1280.0  ## 屏幕宽度
	var distance = spawn_position - judge_line_x
	
	var effective_speed = base_scroll_speed * _current_scroll
	var pixels_per_second = pixels_per_beat * _current_bpm / 60.0
	
	if effective_speed <= 0 or pixels_per_second <= 0:
		return 5.0  ## 默认5秒
	
	return distance / (effective_speed * pixels_per_second)


## 获取当前BPM
func get_current_bpm() -> float:
	return _current_bpm


## 获取当前滚动速度
func get_current_scroll() -> float:
	return _current_scroll


## 获取有效滚动速度
func get_effective_scroll_speed() -> float:
	return base_scroll_speed * _current_scroll


## 计算时间范围内的距离
## @param start_time: 开始时间
## @param end_time: 结束时间
## @return: 距离（像素）
func calculate_distance(start_time: float, end_time: float) -> float:
	var time_diff = end_time - start_time
	var effective_speed = base_scroll_speed * _current_scroll
	var pixels_per_second = pixels_per_beat * _current_bpm / 60.0
	
	return abs(time_diff) * effective_speed * pixels_per_second


## 获取BPM变化点数量
func get_bpm_change_count() -> int:
	return _bpm_changes.size()


## 获取滚动速度变化点数量
func get_scroll_change_count() -> int:
	return _scroll_changes.size()


## 获取下一个BPM变化时间
func get_next_bpm_change_time() -> float:
	for change in _bpm_changes:
		if change.time > _current_time:
			return change.time
	return -1.0  ## 没有更多变化


## 获取下一个滚动速度变化时间
func get_next_scroll_change_time() -> float:
	for change in _scroll_changes:
		if change.time > _current_time:
			return change.time
	return -1.0  ## 没有更多变化


## 检查时间点是否有BPM变化
func has_bpm_change_at(time: float, tolerance: float = 0.01) -> bool:
	for change in _bpm_changes:
		if abs(change.time - time) <= tolerance:
			return true
	return false


## 检查时间点是否有滚动速度变化
func has_scroll_change_at(time: float, tolerance: float = 0.01) -> bool:
	for change in _scroll_changes:
		if abs(change.time - time) <= tolerance:
			return true
	return false