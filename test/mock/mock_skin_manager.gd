# Mock Skin Manager
# Use this for testing without actual skin loading
# This mock provides default values for skin-related methods

extends RefCounted
class_name MockSkinManager

## 默认音符颜色
const DEFAULT_NOTE_COLOR := Color.RED
const DEFAULT_NOTE_SIZE := 40.0
const DEFAULT_OUTLINE_COLOR := Color.DARK_RED
const DEFAULT_OUTLINE_WIDTH := 2.0

## TJAData引用
const TJAData = preload("res://src/parser/tja_data.gd")


## 根据音符类型获取皮肤配置键名
static func get_note_type_key(note_type: int) -> String:
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


## 获取音符颜色
static func get_note_color(note_type: String) -> Color:
	match note_type:
		"don", "don_big", "renda", "renda_big":
			return Color.RED
		"ka", "ka_big":
			return Color.BLUE
		"balloon", "kusudama":
			return Color.YELLOW
		_:
			return DEFAULT_NOTE_COLOR


## 获取音符大小
static func get_note_size(note_type: String) -> float:
	match note_type:
		"don_big", "ka_big", "renda_big":
			return 60.0
		_:
			return DEFAULT_NOTE_SIZE


## 获取音符轮廓颜色
static func get_note_outline_color(note_type: String) -> Color:
	match note_type:
		"don", "don_big", "renda", "renda_big":
			return Color.DARK_RED
		"ka", "ka_big":
			return Color.DARK_BLUE
		_:
			return DEFAULT_OUTLINE_COLOR


## 获取音符轮廓宽度
static func get_note_outline_width(note_type: String) -> float:
	return DEFAULT_OUTLINE_WIDTH


## 获取判定线颜色
static func get_judge_line_color() -> Color:
	return Color.GOLD


## 获取判定线高度
static func get_judge_line_height() -> float:
	return 4.0


## 获取判定线X位置
static func get_judge_line_x() -> float:
	return 200.0


## 获取背景颜色
static func get_background_color() -> Color:
	return Color.DARK_SLATE_GRAY


## 获取音符区域背景颜色
static func get_note_area_color() -> Color:
	return Color.DARK_BLUE


## 获取连击颜色
static func get_combo_color() -> Color:
	return Color.WHITE


## 获取连击高亮颜色
static func get_combo_highlight_color() -> Color:
	return Color.GOLD


## 获取分数颜色
static func get_score_color() -> Color:
	return Color.WHITE


## 获取魂槽颜色
static func get_soul_gauge_color() -> Color:
	return Color.CORAL


## 获取魂槽清除颜色
static func get_soul_gauge_clear_color() -> Color:
	return Color.MEDIUM_TURQUOISE


## 获取Go-Go Time覆盖层颜色
static func get_gogo_overlay_color() -> Color:
	return Color(Color.ORANGE, 0.2)


## 获取Go-Go Time音符发光颜色
static func get_gogo_note_glow_color() -> Color:
	return Color.GOLD