class_name LyricsDisplay
extends Control
## 歌词显示组件
## 显示同步歌词，支持渐入渐出效果

const VTTParser = preload("res://src/parser/vtt_parser.gd")

## 信号
signal lyrics_changed(text: String)

## 配置
@export var font_size: int = 24
@export var fade_duration: float = 0.3  ## 渐变持续时间
@export var display_duration: float = 3.0  ## 默认显示持续时间

## 颜色配置
@export var normal_color: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var highlight_color: Color = Color(1.0, 0.9, 0.3, 1.0)

## 歌词数据
var _lyrics_entries: Array[VTTParser.LyricsEntry] = []
var _current_index: int = -1
var _current_text: String = ""

## UI节点
var _label: Label
var _background: ColorRect

## 动画
var _fade_tween: Tween


func _ready() -> void:
	_setup_ui()


## 设置UI
func _setup_ui() -> void:
	# 创建背景
	_background = ColorRect.new()
	_background.color = Color(0.0, 0.0, 0.0, 0.5)
	_background.anchors_preset = Control.PRESET_FULL_RECT
	_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_background)
	
	# 创建标签
	_label = Label.new()
	_label.name = "LyricsLabel"
	_label.text = ""
	_label.add_theme_font_size_override("font_size", font_size)
	_label.add_theme_color_override("font_color", normal_color)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.anchors_preset = Control.PRESET_CENTER
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)
	
	# 设置自定义最小尺寸
	custom_minimum_size = Vector2(400, 60)


## 加载VTT歌词文件
func load_vtt_file(file_path: String) -> bool:
	var parser = VTTParser.new()
	var result = parser.parse_file(file_path)
	
	if not result.success:
		push_warning("加载歌词文件失败: " + result.error)
		return false
	
	_lyrics_entries = result.entries
	_current_index = -1
	_current_text = ""
	
	return true


## 加载歌词数据
func load_lyrics(entries: Array[VTTParser.LyricsEntry]) -> void:
	_lyrics_entries = entries
	_current_index = -1
	_current_text = ""


## 更新歌词显示
func update(current_time: float) -> void:
	if _lyrics_entries.is_empty():
		return
	
	# 查找当前应该显示的歌词
	var new_index = _find_lyrics_index(current_time)
	
	# 如果索引变化，更新显示
	if new_index != _current_index:
		_current_index = new_index
		
		if new_index >= 0 and new_index < _lyrics_entries.size():
			var entry = _lyrics_entries[new_index]
			_show_lyrics(entry.text)
		else:
			_hide_lyrics()


## 查找当前时间的歌词索引
func _find_lyrics_index(current_time: float) -> int:
	for i in range(_lyrics_entries.size()):
		var entry = _lyrics_entries[i]
		if current_time >= entry.start_time and current_time < entry.end_time:
			return i
	
	return -1


## 显示歌词
func _show_lyrics(text: String) -> void:
	if text == _current_text:
		return
	
	_current_text = text
	
	# 停止之前的动画
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	
	# 创建渐入动画
	_fade_tween = create_tween()
	_fade_tween.tween_property(_label, "modulate:a", 0.0, fade_duration / 2)
	_fade_tween.tween_callback(func(): _label.text = text)
	_fade_tween.tween_property(_label, "modulate:a", 1.0, fade_duration / 2)
	
	lyrics_changed.emit(text)


## 隐藏歌词
func _hide_lyrics() -> void:
	if _current_text.is_empty():
		return
	
	_current_text = ""
	
	# 停止之前的动画
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	
	# 创建渐出动画
	_fade_tween = create_tween()
	_fade_tween.tween_property(_label, "modulate:a", 0.0, fade_duration)
	_fade_tween.tween_callback(func(): _label.text = "")


## 设置高亮模式
func set_highlight(enabled: bool) -> void:
	if enabled:
		_label.add_theme_color_override("font_color", highlight_color)
	else:
		_label.add_theme_color_override("font_color", normal_color)


## 清除歌词
func clear() -> void:
	_lyrics_entries.clear()
	_current_index = -1
	_current_text = ""
	_label.text = ""
	_label.modulate.a = 1.0


## 获取当前歌词文本
func get_current_lyrics() -> String:
	return _current_text


## 检查是否有歌词
func has_lyrics() -> bool:
	return not _lyrics_entries.is_empty()


## 获取歌词总数
func get_lyrics_count() -> int:
	return _lyrics_entries.size()