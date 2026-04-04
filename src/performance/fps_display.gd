## FPS 显示组件
## 功能：在屏幕上显示实时FPS和性能信息
## 作者：TaikoLine Team
## 日期：2026-04-04
##
## 性能优化说明：
## - 使用低频率更新文本，减少字符串操作
## - 可配置显示详细程度

class_name FPSDisplay
extends Control

## 显示模式
enum DisplayMode {
	SIMPLE,      ## 仅显示FPS
	NORMAL,      ## 显示FPS和内存
	DETAILED,    ## 显示完整性能信息
	DEBUG        ## 显示调试信息
}

## 配置
@export var display_mode: DisplayMode = DisplayMode.NORMAL
@export var font_size: int = 16
@export var update_interval: float = 0.5  ## 更新间隔（秒）
@export var show_warning_color: bool = true  ## 是否显示警告颜色
@export var position_offset: Vector2 = Vector2(10, 10)  ## 位置偏移

## 颜色配置
const COLOR_GOOD: Color = Color(0.3, 0.9, 0.3)      ## 绿色（性能良好）
const COLOR_WARNING: Color = Color(1.0, 0.8, 0.0)   ## 黄色（性能警告）
const COLOR_CRITICAL: Color = Color(1.0, 0.3, 0.3)  ## 红色（性能严重）

## UI节点
var _fps_label: Label
var _info_label: Label
var _background: ColorRect

## 性能监控器引用
var _performance_monitor: PerformanceMonitor

## 更新计时器
var _update_timer: float = 0.0

## FPS阈值
const FPS_WARNING_THRESHOLD: float = 55.0
const FPS_CRITICAL_THRESHOLD: float = 30.0


func _ready() -> void:
	_setup_ui()
	_find_performance_monitor()


## 设置UI
func _setup_ui() -> void:
	# 设置位置和大小
	anchors_preset = Control.PRESET_TOP_LEFT
	position = position_offset
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# 创建背景
	_background = ColorRect.new()
	_background.color = Color(0.0, 0.0, 0.0, 0.5)
	_background.custom_minimum_size = Vector2(120, 40)
	add_child(_background)

	# 创建FPS标签
	_fps_label = Label.new()
	_fps_label.add_theme_font_size_override("font_size", font_size)
	_fps_label.add_theme_color_override("font_color", COLOR_GOOD)
	_fps_label.position = Vector2(5, 5)
	add_child(_fps_label)

	# 创建信息标签
	_info_label = Label.new()
	_info_label.add_theme_font_size_override("font_size", font_size - 2)
	_info_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	_info_label.position = Vector2(5, 22)
	_info_label.visible = display_mode >= DisplayMode.NORMAL
	add_child(_info_label)

	# 更新背景大小
	_update_background_size()


## 查找性能监控器
func _find_performance_monitor() -> void:
	# 尝试从场景树中查找
	var tree = get_tree()
	if tree and tree.root:
		for child in tree.root.get_children():
			if child is PerformanceMonitor:
				_performance_monitor = child
				break

	# 如果没有找到，创建一个
	if _performance_monitor == null:
		_performance_monitor = PerformanceMonitor.new()
		_performance_monitor.name = "PerformanceMonitor"
		get_tree().root.add_child(_performance_monitor)


func _process(delta: float) -> void:
	_update_timer += delta

	if _update_timer >= update_interval:
		_update_display()
		_update_timer = 0.0


## 更新显示
func _update_display() -> void:
	if _performance_monitor == null:
		return

	var fps = _performance_monitor.get_fps()
	var fps_color = _get_fps_color(fps)

	# 更新FPS标签
	_fps_label.text = "FPS: %.1f" % fps
	_fps_label.add_theme_color_override("font_color", fps_color)

	# 根据显示模式更新信息
	match display_mode:
		DisplayMode.SIMPLE:
			_info_label.visible = false

		DisplayMode.NORMAL:
			_info_label.visible = true
			var memory = _performance_monitor.get_memory_stats()
			_info_label.text = "MEM: %.1f MB" % memory.current_mb

		DisplayMode.DETAILED:
			_info_label.visible = true
			var memory = _performance_monitor.get_memory_stats()
			var objects = _performance_monitor.get_object_stats()
			_info_label.text = "MEM: %.1f MB | OBJ: %d" % [memory.current_mb, objects.total]

		DisplayMode.DEBUG:
			_info_label.visible = true
			var report = _performance_monitor.get_full_report()
			_info_label.text = "MEM: %.1f MB | OBJ: %d | DRAW: %d" % [
				report.memory.current_mb,
				report.objects.total,
				report.render.draw_calls
			]

	# 更新背景大小
	_update_background_size()


## 获取FPS对应的颜色
func _get_fps_color(fps: float) -> Color:
	if not show_warning_color:
		return COLOR_GOOD

	if fps < FPS_CRITICAL_THRESHOLD:
		return COLOR_CRITICAL
	elif fps < FPS_WARNING_THRESHOLD:
		return COLOR_WARNING
	else:
		return COLOR_GOOD


## 更新背景大小
func _update_background_size() -> void:
	var fps_size = _fps_label.get_minimum_size()
	var info_size = _info_label.get_minimum_size() if _info_label.visible else Vector2.ZERO

	var width = max(fps_size.x, info_size.x) + 10
	var height = fps_size.y + (info_size.y if _info_label.visible else 0) + 10

	_background.custom_minimum_size = Vector2(width, height)
	_background.size = Vector2(width, height)


## 设置显示模式
func set_display_mode(mode: DisplayMode) -> void:
	display_mode = mode
	_info_label.visible = mode >= DisplayMode.NORMAL
	_update_background_size()


## 设置更新间隔
func set_update_interval(interval: float) -> void:
	update_interval = max(0.1, interval)


## 显示/隐藏FPS显示
func toggle_visibility() -> void:
	visible = not visible


## 获取性能监控器
func get_performance_monitor() -> PerformanceMonitor:
	return _performance_monitor