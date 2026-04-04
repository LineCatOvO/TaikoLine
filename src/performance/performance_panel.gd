## 性能面板组件
## 功能：显示完整的性能信息面板
## 作者：TaikoLine Team
## 日期：2026-04-04
##
## 使用方法：
## 1. 将此场景添加到场景树中
## 2. 调用 toggle_panel() 切换显示/隐藏
## 3. 调用 set_display_mode() 设置显示模式

class_name PerformancePanel
extends Control

## 显示模式
enum DisplayMode {
	MINIMAL,    ## 最小模式（仅FPS）
	STANDARD,   ## 标准模式（FPS、内存、对象）
	DETAILED,   ## 详细模式（包含渲染信息）
	DEBUG       ## 调试模式（包含所有信息）
}

## 配置
@export var display_mode: DisplayMode = DisplayMode.STANDARD
@export var update_interval: float = 0.5
@export var show_toggle_button: bool = true

## UI节点
var _background: ColorRect
var _title_label: Label
var _fps_label: Label
var _memory_label: Label
var _objects_label: Label
var _render_label: Label
var _audio_label: Label
var _toggle_button: Button

## 性能监控器
var _performance_monitor: PerformanceMonitor

## 更新计时器
var _update_timer: float = 0.0

## 颜色配置
const COLOR_GOOD: Color = Color(0.3, 0.9, 0.3)
const COLOR_WARNING: Color = Color(1.0, 0.8, 0.0)
const COLOR_CRITICAL: Color = Color(1.0, 0.3, 0.3)
const COLOR_BG: Color = Color(0.0, 0.0, 0.0, 0.7)


func _ready() -> void:
	_setup_ui()
	_find_performance_monitor()


## 设置UI
func _setup_ui() -> void:
	# 设置面板属性
	anchors_preset = Control.PRESET_TOP_RIGHT
	offset_left = -250
	offset_right = 0
	offset_top = 0
	offset_bottom = 200
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# 创建背景
	_background = ColorRect.new()
	_background.color = COLOR_BG
	_background.anchors_preset = Control.PRESET_FULL_RECT
	add_child(_background)

	# 创建容器
	var vbox = VBoxContainer.new()
	vbox.anchors_preset = Control.PRESET_FULL_RECT
	vbox.offset_left = 10
	vbox.offset_right = -10
	vbox.offset_top = 10
	vbox.offset_bottom = -10
	add_child(vbox)

	# 标题
	_title_label = Label.new()
	_title_label.text = "Performance Monitor"
	_title_label.add_theme_font_size_override("font_size", 14)
	_title_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(_title_label)

	# FPS标签
	_fps_label = Label.new()
	_fps_label.text = "FPS: --"
	_fps_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(_fps_label)

	# 内存标签
	_memory_label = Label.new()
	_memory_label.text = "Memory: -- MB"
	_memory_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(_memory_label)

	# 对象标签
	_objects_label = Label.new()
	_objects_label.text = "Objects: --"
	_objects_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(_objects_label)

	# 渲染标签
	_render_label = Label.new()
	_render_label.text = "Draw Calls: --"
	_render_label.add_theme_font_size_override("font_size", 12)
	_render_label.visible = display_mode >= DisplayMode.DETAILED
	vbox.add_child(_render_label)

	# 音频标签
	_audio_label = Label.new()
	_audio_label.text = "Audio: --"
	_audio_label.add_theme_font_size_override("font_size", 12)
	_audio_label.visible = display_mode >= DisplayMode.DEBUG
	vbox.add_child(_audio_label)

	# 切换按钮
	if show_toggle_button:
		_toggle_button = Button.new()
		_toggle_button.text = "Hide"
		_toggle_button.pressed.connect(_on_toggle_pressed)
		vbox.add_child(_toggle_button)


## 查找性能监控器
func _find_performance_monitor() -> void:
	var tree = get_tree()
	if tree and tree.root:
		for child in tree.root.get_children():
			if child is PerformanceMonitor:
				_performance_monitor = child
				break

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

	# 更新FPS
	var fps_stats = _performance_monitor.get_fps_stats()
	var fps_color = _get_fps_color(fps_stats.current)
	_fps_label.text = "FPS: %.1f (min: %.1f, max: %.1f)" % [fps_stats.current, fps_stats.min, fps_stats.max]
	_fps_label.add_theme_color_override("font_color", fps_color)

	# 更新内存
	var memory_stats = _performance_monitor.get_memory_stats()
	_memory_label.text = "Memory: %.1f MB (peak: %.1f MB)" % [memory_stats.current_mb, memory_stats.peak_mb]

	# 更新对象
	var object_stats = _performance_monitor.get_object_stats()
	_objects_label.text = "Objects: %d | Nodes: %d" % [object_stats.total, object_stats.nodes]

	# 更新渲染信息
	if display_mode >= DisplayMode.DETAILED:
		var report = _performance_monitor.get_full_report()
		_render_label.text = "Draw Calls: %d | Vertices: %d" % [report.render.draw_calls, report.render.vertices]
		_render_label.visible = true

	# 更新音频信息
	if display_mode >= DisplayMode.DEBUG:
		_update_audio_stats()


## 更新音频统计
func _update_audio_stats() -> void:
	# 检查 AudioManager 是否存在
	if not has_node("/root/AudioManager"):
		_audio_label.text = "Audio: N/A"
		return

	var audio_manager = get_node("/root/AudioManager")
	if audio_manager and audio_manager.has_method("get_sfx_stats"):
		var stats = audio_manager.get_sfx_stats()
		_audio_label.text = "Audio: %d plays, %d skips, Pool: %d/%d" % [
			stats.play_count, stats.skip_count, stats.pool_size, stats.pool_max
		]
	_audio_label.visible = true


## 获取FPS对应的颜色
func _get_fps_color(fps: float) -> Color:
	if fps < 30:
		return COLOR_CRITICAL
	elif fps < 55:
		return COLOR_WARNING
	else:
		return COLOR_GOOD


## 切换按钮回调
func _on_toggle_pressed() -> void:
	visible = not visible
	if _toggle_button:
		_toggle_button.text = "Show" if not visible else "Hide"


## 切换面板显示
func toggle_panel() -> void:
	visible = not visible


## 设置显示模式
func set_display_mode(mode: DisplayMode) -> void:
	display_mode = mode
	_render_label.visible = mode >= DisplayMode.DETAILED
	_audio_label.visible = mode >= DisplayMode.DEBUG


## 设置更新间隔
func set_update_interval(interval: float) -> void:
	update_interval = max(0.1, interval)


## 获取性能监控器
func get_performance_monitor() -> PerformanceMonitor:
	return _performance_monitor