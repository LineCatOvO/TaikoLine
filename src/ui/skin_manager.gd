extends Node
# class_name SkinManager removed to avoid conflict with autoload singleton
## 皮肤管理器
## 管理游戏皮肤资源的加载、切换和查询

## 皮肤切换信号
signal skin_changed(skin_name: String)

## 默认皮肤路径
const DEFAULT_SKIN_PATH := "res://resources/skins/default/skin.json"

## 当前皮肤数据
var _current_skin: Dictionary = {}
var _current_skin_name: String = "default"

## 皮肤缓存
var _skin_cache: Dictionary = {}


func _ready() -> void:
	load_skin("default")


## 加载皮肤
func load_skin(skin_name: String) -> bool:
	# 检查缓存
	if skin_name in _skin_cache:
		_current_skin = _skin_cache[skin_name]
		_current_skin_name = skin_name
		skin_changed.emit(skin_name)
		return true
	
	# 构建皮肤路径
	var skin_path := "res://resources/skins/%s/skin.json" % skin_name
	
	# 检查文件是否存在
	if not FileAccess.file_exists(skin_path):
		push_warning("皮肤文件不存在: %s，使用默认皮肤" % skin_path)
		if skin_name != "default":
			return load_skin("default")
		return false
	
	# 读取JSON文件
	var file := FileAccess.open(skin_path, FileAccess.READ)
	if file == null:
		push_error("无法打开皮肤文件: %s" % skin_path)
		return false
	
	var json_string := file.get_as_text()
	file.close()
	
	# 解析JSON
	var json := JSON.new()
	var parse_result := json.parse(json_string)
	if parse_result != OK:
		push_error("皮肤JSON解析失败: %s" % skin_path)
		return false
	
	var skin_data: Dictionary = json.data
	
	# 验证皮肤数据
	if not _validate_skin_data(skin_data):
		push_error("皮肤数据验证失败: %s" % skin_path)
		return false
	
	# 缓存并设置当前皮肤
	_skin_cache[skin_name] = skin_data
	_current_skin = skin_data
	_current_skin_name = skin_name
	
	skin_changed.emit(skin_name)
	return true


## 验证皮肤数据
func _validate_skin_data(data: Dictionary) -> bool:
	if not data.has("name"):
		push_warning("皮肤缺少name字段")
		return false
	if not data.has("notes"):
		push_warning("皮肤缺少notes字段")
		return false
	return true


## 获取当前皮肤名称
func get_current_skin_name() -> String:
	return _current_skin_name


## 获取音符颜色
func get_note_color(note_type: String) -> Color:
	var notes: Dictionary = _current_skin.get("notes", {})
	var note_config: Dictionary = notes.get(note_type, notes.get("don", {}))
	var color_string: String = note_config.get("color", "#FF3333")
	return Color.from_string(color_string, Color.RED)


## 获取音符大小
func get_note_size(note_type: String) -> float:
	var notes: Dictionary = _current_skin.get("notes", {})
	var note_config: Dictionary = notes.get(note_type, notes.get("don", {}))
	return note_config.get("size", 40.0)


## 获取音符轮廓颜色
func get_note_outline_color(note_type: String) -> Color:
	var notes: Dictionary = _current_skin.get("notes", {})
	var note_config: Dictionary = notes.get(note_type, notes.get("don", {}))
	var color_string: String = note_config.get("outline_color", "#CC0000")
	return Color.from_string(color_string, Color.DARK_RED)


## 获取音符轮廓宽度
func get_note_outline_width(note_type: String) -> float:
	var notes: Dictionary = _current_skin.get("notes", {})
	var note_config: Dictionary = notes.get(note_type, notes.get("don", {}))
	return note_config.get("outline_width", 2.0)


## 获取判定线颜色
func get_judge_line_color() -> Color:
	var judge_line: Dictionary = _current_skin.get("judge_line", {})
	var color_string: String = judge_line.get("color", "#FFD700")
	return Color.from_string(color_string, Color.GOLD)


## 获取判定线高度
func get_judge_line_height() -> float:
	var judge_line: Dictionary = _current_skin.get("judge_line", {})
	return judge_line.get("height", 4.0)


## 获取判定线X位置
func get_judge_line_x() -> float:
	var judge_line: Dictionary = _current_skin.get("judge_line", {})
	return judge_line.get("x_position", 200.0)


## 获取背景颜色
func get_background_color() -> Color:
	var background: Dictionary = _current_skin.get("background", {})
	var color_string: String = background.get("color", "#1a1a2e")
	return Color.from_string(color_string, Color.DARK_SLATE_GRAY)


## 获取音符区域背景颜色
func get_note_area_color() -> Color:
	var background: Dictionary = _current_skin.get("background", {})
	var color_string: String = background.get("note_area_color", "#16213e")
	return Color.from_string(color_string, Color.DARK_BLUE)


## 获取连击颜色
func get_combo_color() -> Color:
	var ui: Dictionary = _current_skin.get("ui", {})
	var color_string: String = ui.get("combo_color", "#FFFFFF")
	return Color.from_string(color_string, Color.WHITE)


## 获取连击高亮颜色
func get_combo_highlight_color() -> Color:
	var ui: Dictionary = _current_skin.get("ui", {})
	var color_string: String = ui.get("combo_highlight_color", "#FFD700")
	return Color.from_string(color_string, Color.GOLD)


## 获取分数颜色
func get_score_color() -> Color:
	var ui: Dictionary = _current_skin.get("ui", {})
	var color_string: String = ui.get("score_color", "#FFFFFF")
	return Color.from_string(color_string, Color.WHITE)


## 获取魂槽颜色
func get_soul_gauge_color() -> Color:
	var ui: Dictionary = _current_skin.get("ui", {})
	var color_string: String = ui.get("soul_gauge_color", "#FF6B6B")
	return Color.from_string(color_string, Color.CORAL)


## 获取魂槽清除颜色
func get_soul_gauge_clear_color() -> Color:
	var ui: Dictionary = _current_skin.get("ui", {})
	var color_string: String = ui.get("soul_gauge_clear_color", "#4ECDC4")
	return Color.from_string(color_string, Color.MEDIUM_TURQUOISE)


## 获取Go-Go Time覆盖层颜色
func get_gogo_overlay_color() -> Color:
	var gogo: Dictionary = _current_skin.get("gogo", {})
	var color_string: String = gogo.get("overlay_color", "#FF6B0033")
	return Color.from_string(color_string, Color(Color.ORANGE, 0.2))


## 获取Go-Go Time音符发光颜色
func get_gogo_note_glow_color() -> Color:
	var gogo: Dictionary = _current_skin.get("gogo", {})
	var color_string: String = gogo.get("note_glow_color", "#FFD700")
	return Color.from_string(color_string, Color.GOLD)


## 根据音符类型获取皮肤配置键名
func get_note_type_key(note_type: int) -> String:
	match note_type:
		TJAData.NoteType.DON:
			return "don"
		TJAData.NoteType.KA:
			return "ka"
		TJAData.NoteType.DON_BIG:
			return "don_big"
		TJAData.NoteType.KA_BIG:
			return "ka_big"
		TJAData.NoteType.RENDA:
			return "renda"
		TJAData.NoteType.RENDA_BIG:
			return "renda_big"
		TJAData.NoteType.BALLOON:
			return "balloon"
		TJAData.NoteType.KUSUDAMA:
			return "kusudama"
		_:
			return "don"


## 获取所有可用皮肤列表
func get_available_skins() -> Array[String]:
	var skins: Array[String] = []
	var dir := DirAccess.open("res://resources/skins/")
	if dir == null:
		return skins
	
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if dir.current_is_dir() and not file_name.begins_with("."):
			var skin_file := "res://resources/skins/%s/skin.json" % file_name
			if FileAccess.file_exists(skin_file):
				skins.append(file_name)
		file_name = dir.get_next()
	
	return skins