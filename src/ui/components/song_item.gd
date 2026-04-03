class_name SongItem
extends PanelContainer
## 歌曲列表项组件
## 显示单个歌曲的信息，支持悬停效果和选中状态
## 参考 Taiko no Tatsujin 虹版设计风格
## 作者：TaikoLine Team
## 日期：2026-04-03
## 更新：完善 UI 组件，添加封面显示区域和动画效果

## 信号
signal selected
signal preview_requested

## 难度类型映射
const DIFFICULTY_NAMES = ["Easy", "Normal", "Hard", "Oni"]
const DIFFICULTY_COLORS = [
	Color(0.3, 0.8, 0.3),  # 绿色 - Easy
	Color(0.3, 0.6, 1.0),  # 蓝色 - Normal
	Color(1.0, 0.6, 0.0),  # 橙色 - Hard
	Color(1.0, 0.2, 0.2)   # 红色 - Oni
]

## 歌曲数据
var song_data: Dictionary = {}

## UI节点引用 - 封面区域
@onready var _cover_container: PanelContainer = $MainHBox/CoverContainer
@onready var _cover_placeholder: ColorRect = $MainHBox/CoverContainer/CoverPlaceholder
@onready var _cover_icon: TextureRect = $MainHBox/CoverContainer/CoverIcon

## UI节点引用 - 信息区域
@onready var _title_label: Label = $MainHBox/InfoVBox/TitleLabel
@onready var _subtitle_label: Label = $MainHBox/InfoVBox/SubtitleLabel
@onready var _bpm_label: Label = $MainHBox/InfoVBox/InfoHBox/BPMLabel
@onready var _genre_label: Label = $MainHBox/InfoVBox/InfoHBox/GenreLabel
@onready var _difficulty_container: HBoxContainer = $MainHBox/InfoVBox/InfoHBox/DifficultyContainer

## UI节点引用 - 按钮区域
@onready var _preview_button: Button = $MainHBox/ButtonVBox/PreviewBtn
@onready var _select_button: Button = $MainHBox/ButtonVBox/SelectBtn

## 悬停状态
var _is_hovered: bool = false

## 选中状态
var _is_selected: bool = false

## 动画速度
@export var animation_speed: float = 0.15

## 样式资源
var _normal_style: StyleBoxFlat
var _hover_style: StyleBoxFlat
var _selected_style: StyleBoxFlat


func _ready() -> void:
	_setup_styles()
	_connect_signals()
	_setup_mouse_events()


## 设置样式
func _setup_styles() -> void:
	# 创建样式资源
	_normal_style = StyleBoxFlat.new()
	_normal_style.bg_color = Color(0.15, 0.1, 0.35, 0.85)
	_normal_style.set_corner_radius_all(10)
	_normal_style.shadow_color = Color(0, 0, 0, 0.3)
	_normal_style.shadow_size = 3
	_normal_style.shadow_offset = Vector2(1, 1)

	_hover_style = StyleBoxFlat.new()
	_hover_style.bg_color = Color(0.25, 0.18, 0.5, 0.95)
	_hover_style.set_corner_radius_all(10)
	_hover_style.shadow_color = Color(0.4, 0.25, 0.7, 0.4)
	_hover_style.shadow_size = 6
	_hover_style.shadow_offset = Vector2(0, 0)
	_hover_style.border_color = Color(0.5, 0.35, 0.8, 1.0)
	_hover_style.set_border_width_all(2)

	_selected_style = StyleBoxFlat.new()
	_selected_style.bg_color = Color(0.3, 0.2, 0.6, 1.0)
	_selected_style.set_corner_radius_all(10)
	_selected_style.shadow_color = Color(0.6, 0.4, 0.9, 0.5)
	_selected_style.shadow_size = 8
	_selected_style.shadow_offset = Vector2(0, 0)
	_selected_style.border_color = Color(0.8, 0.5, 1.0, 1.0)
	_selected_style.set_border_width_all(3)

	# 应用默认样式
	add_theme_stylebox_override("panel", _normal_style)


## 连接信号
func _connect_signals() -> void:
	_preview_button.pressed.connect(_on_preview_pressed)
	_select_button.pressed.connect(_on_select_pressed)


## 设置鼠标事件
func _setup_mouse_events() -> void:
	# 确保可以接收鼠标事件
	mouse_filter = Control.MOUSE_FILTER_PASS


## 处理鼠标进入
func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_ENTER:
		_on_mouse_entered()
	elif what == NOTIFICATION_MOUSE_EXIT:
		_on_mouse_exited()


## 鼠标进入事件
func _on_mouse_entered() -> void:
	_is_hovered = true
	if not _is_selected:
		_apply_hover_style()
		# 添加缩放动画
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_QUAD)
		tween.tween_property(self, "scale", Vector2(1.02, 1.02), animation_speed)


## 鼠标离开事件
func _on_mouse_exited() -> void:
	_is_hovered = false
	if not _is_selected:
		_apply_normal_style()
		# 恢复缩放
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_QUAD)
		tween.tween_property(self, "scale", Vector2.ONE, animation_speed)


## 应用普通样式
func _apply_normal_style() -> void:
	add_theme_stylebox_override("panel", _normal_style)


## 应用悬停样式
func _apply_hover_style() -> void:
	add_theme_stylebox_override("panel", _hover_style)


## 应用选中样式
func _apply_selected_style() -> void:
	add_theme_stylebox_override("panel", _selected_style)


## 设置歌曲数据
func set_song_data(data: Dictionary) -> void:
	song_data = data
	_update_display()


## 更新显示
func _update_display() -> void:
	if song_data.is_empty():
		return

	# 更新标题
	_title_label.text = song_data.get("title", "Unknown")

	# 更新副标题
	var subtitle = song_data.get("subtitle", "")
	if subtitle != "":
		_subtitle_label.text = subtitle
		_subtitle_label.visible = true
	else:
		var genre = song_data.get("genre", "")
		if genre != "":
			_subtitle_label.text = genre
			_subtitle_label.visible = true
		else:
			_subtitle_label.visible = false

	# 更新 BPM
	var bpm = song_data.get("bpm", 120.0)
	_bpm_label.text = "BPM: %.0f" % bpm

	# 更新流派
	var genre = song_data.get("genre", "")
	_genre_label.text = "Genre: %s" % (genre if genre != "" else "---")
	_genre_label.visible = genre != ""

	# 更新难度显示
	_update_difficulty_display()

	# 尝试加载封面
	_load_cover_image()


## 更新难度显示
func _update_difficulty_display() -> void:
	# 清除现有难度显示
	for child in _difficulty_container.get_children():
		child.queue_free()

	var courses = song_data.get("courses", {})

	for i in range(DIFFICULTY_NAMES.size()):
		if courses.has(i):
			var course = courses[i]
			var level = course.get("level", 0)

			# 创建难度标签
			var diff_label = Label.new()
			diff_label.text = "%s Lv.%d" % [DIFFICULTY_NAMES[i], level]
			diff_label.add_theme_font_size_override("font_size", 11)
			diff_label.add_theme_color_override("font_color", DIFFICULTY_COLORS[i])
			_difficulty_container.add_child(diff_label)


## 加载封面图片
func _load_cover_image() -> void:
	# 尝试从歌曲目录加载封面
	var base_dir = song_data.get("base_dir", "")

	if base_dir == "":
		_cover_placeholder.visible = true
		_cover_icon.visible = false
		return

	# 尝试常见的封面文件名
	var cover_names = ["cover.png", "cover.jpg", "cover.jpeg", "album.png", "album.jpg"]
	var cover_path = ""

	for name in cover_names:
		var path = base_dir + "/" + name
		if ResourceLoader.exists(path):
			cover_path = path
			break

	if cover_path != "":
		var texture = load(cover_path)
		if texture:
			_cover_icon.texture = texture
			_cover_placeholder.visible = false
			_cover_icon.visible = true
	else:
		_cover_placeholder.visible = true
		_cover_icon.visible = false


## 设置选中状态
func set_selected(selected: bool) -> void:
	_is_selected = selected

	if selected:
		_apply_selected_style()
		# 选中动画
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_BACK)
		tween.tween_property(self, "scale", Vector2(1.05, 1.05), animation_speed)
	else:
		_apply_normal_style()
		# 恢复动画
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_QUAD)
		tween.tween_property(self, "scale", Vector2.ONE, animation_speed)


## 选择按钮按下
func _on_select_pressed() -> void:
	selected.emit()


## 预览按钮按下
func _on_preview_pressed() -> void:
	preview_requested.emit()


## 获取歌曲标题
func get_title() -> String:
	return song_data.get("title", "Unknown")


## 获取歌曲文件路径
func get_file_path() -> String:
	return song_data.get("file_path", "")