## 性能监控组件
## 功能：监控游戏性能指标，包括FPS、内存使用、渲染性能
## 作者：TaikoLine Team
## 日期：2026-04-04
##
## 性能优化说明：
## - 使用低频率更新，减少性能监控本身的开销
## - 提供详细的性能统计和警告阈值

class_name PerformanceMonitor
extends Node

## 信号
signal fps_updated(fps: float)
signal fps_warning(fps: float)
signal memory_updated(memory_mb: float)
signal performance_report(report: Dictionary)

## 配置
@export var update_interval: float = 0.5  ## 更新间隔（秒）
@export var fps_warning_threshold: float = 55.0  ## FPS警告阈值
@export var fps_critical_threshold: float = 30.0  ## FPS严重警告阈值
@export var memory_warning_threshold: float = 500.0  ## 内存警告阈值（MB）
@export var enable_logging: bool = false  ## 是否记录日志

## 性能统计数据
var _fps_history: Array[float] = []
var _fps_min: float = 60.0
var _fps_max: float = 60.0
var _fps_avg: float = 60.0
var _current_fps: float = 60.0

var _frame_time_history: Array[float] = []
var _frame_time_avg: float = 16.67  ## 平均帧时间（毫秒）

var _memory_history: Array[float] = []
var _memory_current: float = 0.0
var _memory_peak: float = 0.0

var _object_count: int = 0
var _node_count: int = 0

## 时间追踪
var _last_update_time: float = 0.0
var _frame_count: int = 0
var _update_timer: float = 0.0

## 报告间隔
var _report_interval: float = 5.0  ## 报告间隔（秒）
var _report_timer: float = 0.0

## 历史记录最大长度
const HISTORY_MAX_LENGTH: int = 60


func _ready() -> void:
	_last_update_time = Time.get_ticks_msec()


func _process(delta: float) -> void:
	_frame_count += 1
	_update_timer += delta
	_report_timer += delta

	# 按间隔更新性能数据
	if _update_timer >= update_interval:
		_update_performance_data()
		_update_timer = 0.0

	# 按间隔生成报告
	if _report_timer >= _report_interval:
		_generate_report()
		_report_timer = 0.0


## 更新性能数据
func _update_performance_data() -> void:
	# 计算FPS
	var current_time = Time.get_ticks_msec()
	var elapsed_ms = current_time - _last_update_time
	_last_update_time = current_time

	if elapsed_ms > 0:
		_current_fps = (_frame_count * 1000.0) / elapsed_ms
		_frame_count = 0

		# 更新FPS历史
		_add_to_history(_fps_history, _current_fps)
		_calculate_fps_stats()

		# 发射信号
		fps_updated.emit(_current_fps)

		# 检查FPS警告
		if _current_fps < fps_critical_threshold:
			if enable_logging:
				push_warning("[PerformanceMonitor] Critical FPS: %.1f" % _current_fps)
			fps_warning.emit(_current_fps)
		elif _current_fps < fps_warning_threshold:
			if enable_logging:
				push_warning("[PerformanceMonitor] Low FPS: %.1f" % _current_fps)
			fps_warning.emit(_current_fps)

	# 更新帧时间
	var frame_time_ms = delta * 1000.0
	_add_to_history(_frame_time_history, frame_time_ms)
	_calculate_frame_time_stats()

	# 更新内存使用
	_update_memory_stats()

	# 更新对象计数
	_update_object_counts()


## 添加到历史记录
func _add_to_history(history: Array, value: float) -> void:
	history.append(value)
	if history.size() > HISTORY_MAX_LENGTH:
		history.pop_front()


## 计算FPS统计
func _calculate_fps_stats() -> void:
	if _fps_history.is_empty():
		return

	_fps_min = _fps_history.min()
	_fps_max = _fps_history.max()

	var total: float = 0.0
	for fps in _fps_history:
		total += fps
	_fps_avg = total / _fps_history.size()


## 计算帧时间统计
func _calculate_frame_time_stats() -> void:
	if _frame_time_history.is_empty():
		return

	var total: float = 0.0
	for frame_time in _frame_time_history:
		total += frame_time
	_frame_time_avg = total / _frame_time_history.size()


## 更新内存统计
func _update_memory_stats() -> void:
	# Godot 4.x 内存统计
	_memory_current = _get_memory_usage()

	_add_to_history(_memory_history, _memory_current)

	if _memory_current > _memory_peak:
		_memory_peak = _memory_current

	memory_updated.emit(_memory_current)

	# 检查内存警告
	if _memory_current > memory_warning_threshold:
		if enable_logging:
			push_warning("[PerformanceMonitor] High memory usage: %.1f MB" % _memory_current)


## 获取内存使用（MB）
func _get_memory_usage() -> float:
	# Godot 4.x 使用 Performance 类
	var static_mem = Performance.get_monitor(Performance.MONITOR_MEMORY_STATIC)
	var dynamic_mem = Performance.get_monitor(Performance.MONITOR_MEMORY_DYNAMIC)

	# 转换为 MB
	return (static_mem + dynamic_mem) / (1024.0 * 1024.0)


## 更新对象计数
func _update_object_counts() -> void:
	_object_count = Performance.get_monitor(Performance.MONITOR_OBJECT_COUNT)
	_node_count = Performance.get_monitor(Performance.MONITOR_OBJECT_NODE_COUNT)


## 生成性能报告
func _generate_report() -> void:
	var report = {
		"fps": {
			"current": _current_fps,
			"min": _fps_min,
			"max": _fps_max,
			"avg": _fps_avg
		},
		"frame_time": {
			"avg_ms": _frame_time_avg
		},
		"memory": {
			"current_mb": _memory_current,
			"peak_mb": _memory_peak
		},
		"objects": {
			"total": _object_count,
			"nodes": _node_count
		},
		"render": {
			"draw_calls": Performance.get_monitor(Performance.MONITOR_RENDER_DRAW_CALLS),
			"vertices": Performance.get_monitor(Performance.MONITOR_RENDER_VERTEX_COUNT),
			"objects_in_frame": Performance.get_monitor(Performance.MONITOR_RENDER_OBJECTS_IN_FRAME)
		},
		"physics": {
			"fps": Performance.get_monitor(Performance.MONITOR_PHYSICS_FPS),
			"time_ms": Performance.get_monitor(Performance.MONITOR_PHYSICS_TIME)
		},
		"timestamp": Time.get_ticks_msec()
	}

	performance_report.emit(report)

	if enable_logging:
		_log_report(report)


## 记录报告日志
func _log_report(report: Dictionary) -> void:
	print("[PerformanceMonitor] FPS: %.1f (min: %.1f, max: %.1f, avg: %.1f)" % [
		report.fps.current, report.fps.min, report.fps.max, report.fps.avg
	])
	print("[PerformanceMonitor] Memory: %.1f MB (peak: %.1f MB)" % [
		report.memory.current_mb, report.memory.peak_mb
	])
	print("[PerformanceMonitor] Objects: %d, Nodes: %d" % [
		report.objects.total, report.objects.nodes
	])
	print("[PerformanceMonitor] Draw calls: %d, Vertices: %d" % [
		report.render.draw_calls, report.render.vertices
	])


## ==================== 公共方法 ====================

## 获取当前FPS
func get_fps() -> float:
	return _current_fps


## 获取FPS统计
func get_fps_stats() -> Dictionary:
	return {
		"current": _current_fps,
		"min": _fps_min,
		"max": _fps_max,
		"avg": _fps_avg
	}


## 获取帧时间统计
func get_frame_time_stats() -> Dictionary:
	return {
		"avg_ms": _frame_time_avg
	}


## 获取内存统计
func get_memory_stats() -> Dictionary:
	return {
		"current_mb": _memory_current,
		"peak_mb": _memory_peak
	}


## 获取对象统计
func get_object_stats() -> Dictionary:
	return {
		"total": _object_count,
		"nodes": _node_count
	}


## 获取完整报告
func get_full_report() -> Dictionary:
	return {
		"fps": get_fps_stats(),
		"frame_time": get_frame_time_stats(),
		"memory": get_memory_stats(),
		"objects": get_object_stats(),
		"render": {
			"draw_calls": Performance.get_monitor(Performance.MONITOR_RENDER_DRAW_CALLS),
			"vertices": Performance.get_monitor(Performance.MONITOR_RENDER_VERTEX_COUNT),
			"objects_in_frame": Performance.get_monitor(Performance.MONITOR_RENDER_OBJECTS_IN_FRAME)
		}
	}


## 检查性能是否良好
func is_performance_good() -> bool:
	return _current_fps >= fps_warning_threshold and _memory_current < memory_warning_threshold


## 检查FPS是否良好
func is_fps_good() -> bool:
	return _current_fps >= fps_warning_threshold


## 检查内存是否良好
func is_memory_good() -> bool:
	return _memory_current < memory_warning_threshold


## 重置统计数据
func reset_stats() -> void:
	_fps_history.clear()
	_frame_time_history.clear()
	_memory_history.clear()
	_fps_min = 60.0
	_fps_max = 60.0
	_fps_avg = 60.0
	_current_fps = 60.0
	_frame_time_avg = 16.67
	_memory_current = 0.0
	_memory_peak = 0.0
	_object_count = 0
	_node_count = 0
	_frame_count = 0


## 设置更新间隔
func set_update_interval(interval: float) -> void:
	update_interval = max(0.1, interval)


## 设置FPS警告阈值
func set_fps_warning_threshold(threshold: float) -> void:
	fps_warning_threshold = threshold


## 设置内存警告阈值
func set_memory_warning_threshold(threshold: float) -> void:
	memory_warning_threshold = threshold


## 启用/禁用日志
func set_logging(enabled: bool) -> void:
	enable_logging = enabled