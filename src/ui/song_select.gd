class_name SongSelectUI
extends Control
## 选曲界面
## 显示歌曲列表，允许选择歌曲和难度
## 作者：TaikoLine Team
## 日期：2026-03-27

const SongDatabase = preload("res://src/ui/song_database.gd")
const SongItem = preload("res://src/ui/components/song_item.gd")

## 信号
signal song_selected(song_data: Dictionary, course_type: int)
signal back_requested

## 难度类型映射
const DIFFICULTY_NAMES = ["Easy", "Normal", "Hard", "Oni"]
const DIFFICULTY_COLORS = [
	Color(0.3, 0.8, 0.3),  # 绿色 - Easy
	Color(0.3, 0.6, 1.0),  # 蓝色 - Normal
	Color(1.0, 0.6, 0.0),  # 橙色 - Hard
	Color(1.0, 0.2, 0.2)   # 红色 - Oni
]

## UI节点引用 - 左侧面板
@onready var _song_count_label: Label = $MainContainer/LeftPanel/HeaderPanel/HeaderHBox/SongCountLabel
@onready var _search_input: LineEdit = $MainContainer/LeftPanel/SearchPanel/SearchHBox/SearchInput
@onready var _song_list_scroll: ScrollContainer = $MainContainer/LeftPanel/SongListScroll
@onready var _song_list_container: VBoxContainer = $MainContainer/LeftPanel/SongListScroll/SongListContainer

## UI节点引用 - 右侧面板
@onready var _title_label: Label = $MainContainer/RightPanel/SongInfoPanel/SongInfoVBox/TitleSection/TitleLabel
@onready var _subtitle_label: Label = $MainContainer/RightPanel/SongInfoPanel/SongInfoVBox/TitleSection/SubtitleLabel
@onready var _bpm_value: Label = $MainContainer/RightPanel/SongInfoPanel/SongInfoVBox/StatsSection/BPMValue
@onready var _genre_value: Label = $MainContainer/RightPanel/SongInfoPanel/SongInfoVBox/StatsSection/GenreValue
@onready var _maker_value: Label = $MainContainer/RightPanel/SongInfoPanel/SongInfoVBox/StatsSection/MakerValue
@onready var _level_display: Label = $MainContainer/RightPanel/SongInfoPanel/SongInfoVBox/DifficultySection/LevelDisplay
@onready var _difficulty_buttons: HBoxContainer = $MainContainer/RightPanel/SongInfoPanel/SongInfoVBox/DifficultySection/DifficultyButtons

## UI节点引用 - 底部栏
@onready var _back_btn: Button = $BottomBar/BottomHBox/BackBtn
@onready var _preview_btn: Button = $MainContainer/RightPanel/ActionPanel/ActionHBox/PreviewBtn
@onready var _start_btn: Button = $MainContainer/RightPanel/ActionPanel/ActionHBox/StartBtn

## 音频节点
@onready var _preview_player: AudioStreamPlayer = $PreviewPlayer
@onready var _navigate_sound: AudioStreamPlayer = $NavigateSound
@onready var _confirm_sound: AudioStreamPlayer = $ConfirmSound

## 歌曲数据库
var _song_database: SongDatabase

## 当前显示的歌曲列表（可能被搜索过滤）
var _displayed_songs: Array[Dictionary] = []

## 当前选中的歌曲索引
var _current_song_index: int = -1

## 当前选中的难度
var _current_difficulty: int = 3  # 默认 Oni

## 导航是否启用
var _navigation_enabled: bool = true

## 场景过渡动画时长
const TRANSITION_DURATION: float = 0.3


func _ready() -> void:
	_setup_song_database()
	_setup_difficulty_buttons()
	_setup_sounds()
	_scan_songs()


## 设置歌曲数据库
func _setup_song_database() -> void:
	_song_database = SongDatabase.new()


## 设置难度按钮
func _setup_difficulty_buttons() -> void:
	# 创建按钮组
	var group = ButtonGroup.new()

	for i in range(_difficulty_buttons.get_child_count()):
		var btn: Button = _difficulty_buttons.get_child(i)
		btn.button_group = group
		btn.add_theme_color_override("font_color", DIFFICULTY_COLORS[i])
		btn.add_theme_color_override("font_hover_color", DIFFICULTY_COLORS[i])

	# 默认选中 Oni
	var oni_btn: Button = _difficulty_buttons.get_child(3)
	oni_btn.button_pressed = true


## 设置音效
func _setup_sounds() -> void:
	var navigate_stream = _load_sound_if_exists("res://resources/sounds/ui/navigate.wav")
	var confirm_stream = _load_sound_if_exists("res://resources/sounds/ui/confirm.wav")

	if navigate_stream:
		_navigate_sound.stream = navigate_stream
	if confirm_stream:
		_confirm_sound.stream = confirm_stream


## 尝试加载音效资源
func _load_sound_if_exists(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		return load(path)
	return null


## 扫描歌曲
func _scan_songs() -> void:
	_song_database.scan_songs()
	_displayed_songs = _song_database.get_songs()
	_update_song_list()
	_update_song_count()


## 更新歌曲列表
func _update_song_list() -> void:
	# 清空现有列表
	for child in _song_list_container.get_children():
		child.queue_free()

	# 等待节点释放
	await get_tree().process_frame

	# 创建歌曲列表项
	for i in range(_displayed_songs.size()):
		var song = _displayed_songs[i]
		var song_item = _create_song_item(song, i)
		_song_list_container.add_child(song_item)


## 创建歌曲列表项
func _create_song_item(song: Dictionary, index: int) -> Control:
	# 创建容器
	var container = PanelContainer.new()
	container.custom_minimum_size = Vector2(0, 70)

	# 创建内容
	var hbox = HBoxContainer.new()
	container.add_child(hbox)

	# 左侧信息
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)

	# 标题
	var title = Label.new()
	title.text = song.title
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	info_vbox.add_child(title)

	# 副标题/流派
	var subtitle = Label.new()
	var subtitle_text = ""
	if song.subtitle != "":
		subtitle_text = song.subtitle
	elif song.genre != "":
		subtitle_text = song.genre
	subtitle.text = subtitle_text
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	subtitle.visible = subtitle_text != ""
	info_vbox.add_child(subtitle)

	# BPM 和难度
	var info_hbox = HBoxContainer.new()
	info_vbox.add_child(info_hbox)

	var bpm = Label.new()
	bpm.text = "BPM: %.0f" % song.bpm
	bpm.add_theme_font_size_override("font_size", 12)
	bpm.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
	info_hbox.add_child(bpm)

	# 显示可用难度
	for course_type in song.courses.keys():
		var level = song.courses[course_type].level
		var diff_label = Label.new()
		diff_label.text = " %s Lv.%d" % [DIFFICULTY_NAMES[course_type], level]
		diff_label.add_theme_font_size_override("font_size", 11)
		diff_label.add_theme_color_override("font_color", DIFFICULTY_COLORS[course_type])
		info_hbox.add_child(diff_label)

	# 右侧按钮
	var btn_vbox = VBoxContainer.new()
	btn_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(btn_vbox)

	# 选择按钮
	var select_btn = Button.new()
	select_btn.text = "Select"
	select_btn.custom_minimum_size = Vector2(80, 30)
	select_btn.pressed.connect(_on_song_selected.bind(index))
	btn_vbox.add_child(select_btn)

	# 连接鼠标事件
	container.gui_input.connect(_on_song_item_gui_input.bind(index))

	return container


## 歌曲列表项输入事件
func _on_song_item_gui_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_select_song(index)


## 更新歌曲数量显示
func _update_song_count() -> void:
	_song_count_label.text = "Songs: %d" % _displayed_songs.size()


## 选择歌曲
func _select_song(index: int) -> void:
	if index < 0 or index >= _displayed_songs.size():
		return

	_current_song_index = index
	var song = _displayed_songs[index]

	# 更新信息显示
	_title_label.text = song.title
	_subtitle_label.text = song.subtitle
	_subtitle_label.visible = song.subtitle != ""

	_bpm_value.text = "%.0f" % song.bpm
	_genre_value.text = song.genre if song.genre != "" else "---"
	_maker_value.text = song.maker if song.maker != "" else "---"

	# 更新难度等级显示
	_update_level_display()

	# 更新难度按钮可用状态
	_update_difficulty_buttons(song)

	# 启用开始按钮
	_start_btn.disabled = false

	# 播放导航音效
	_play_navigate_sound()


## 更新难度等级显示
func _update_level_display() -> void:
	if _current_song_index < 0:
		_level_display.text = "Level: ---"
		_level_display.add_theme_color_override("font_color", Color.WHITE)
		return

	var song = _displayed_songs[_current_song_index]

	if song.courses.has(_current_difficulty):
		var level = song.courses[_current_difficulty].level
		_level_display.text = "Level: %d" % level
		_level_display.add_theme_color_override("font_color", DIFFICULTY_COLORS[_current_difficulty])
	else:
		_level_display.text = "Level: N/A"
		_level_display.add_theme_color_override("font_color", Color.GRAY)


## 更新难度按钮可用状态
func _update_difficulty_buttons(song: Dictionary) -> void:
	for i in range(_difficulty_buttons.get_child_count()):
		var btn: Button = _difficulty_buttons.get_child(i)
		var has_course = song.courses.has(i)
		btn.disabled = not has_course
		btn.modulate.a = 1.0 if has_course else 0.5


## 搜索文本改变
func _on_search_text_changed(text: String) -> void:
	if text.is_empty():
		_displayed_songs = _song_database.get_songs()
	else:
		_displayed_songs = _song_database.search_by_title(text)

	_current_song_index = -1
	_update_song_list()
	_update_song_count()
	_reset_song_info()


## 重置歌曲信息显示
func _reset_song_info() -> void:
	_title_label.text = "Select a Song"
	_subtitle_label.text = ""
	_subtitle_label.visible = false
	_bpm_value.text = "---"
	_genre_value.text = "---"
	_maker_value.text = "---"
	_level_display.text = "Level: ---"
	_start_btn.disabled = true


## 难度按钮按下
func _on_difficulty_pressed(difficulty: int) -> void:
	_current_difficulty = difficulty
	_update_level_display()
	_play_navigate_sound()


## 预览按钮按下
func _on_preview_pressed() -> void:
	_play_preview()


## 播放预览
func _play_preview() -> void:
	if _current_song_index < 0:
		return

	var song = _displayed_songs[_current_song_index]

	# 停止当前预览
	_preview_player.stop()

	# 加载音频文件
	if song.wave.is_empty():
		push_warning("[SongSelect] 歌曲没有音频文件: " + song.title)
		return

	var audio_path = song.base_dir + "/" + song.wave

	# 检查文件是否存在
	if not FileAccess.file_exists(audio_path):
		push_warning("[SongSelect] 音频文件不存在: " + audio_path)
		return

	# 加载音频
	var audio_stream = load(audio_path)
	if audio_stream == null:
		push_warning("[SongSelect] 无法加载音频: " + audio_path)
		return

	_preview_player.stream = audio_stream
	_preview_player.play(song.demo_start)
	_play_confirm_sound()


## 开始按钮按下
func _on_start_pressed() -> void:
	if _current_song_index < 0:
		return

	if not _navigation_enabled:
		return

	_navigation_enabled = false

	# 停止预览
	_preview_player.stop()

	var song = _displayed_songs[_current_song_index]

	# 保存到全局状态
	GameState.current_song = song
	GameState.current_course = DIFFICULTY_NAMES[_current_difficulty]

	# 发送信号
	song_selected.emit(song, _current_difficulty)

	# 播放确认音效
	_play_confirm_sound()

	# 切换到游戏场景
	_change_scene("res://scenes/gameplay.tscn")


## 返回按钮按下
func _on_back_pressed() -> void:
	if not _navigation_enabled:
		return

	_navigation_enabled = false

	# 停止预览
	_preview_player.stop()

	# 播放确认音效
	_play_confirm_sound()

	# 切换到主菜单
	_change_scene("res://scenes/main.tscn")


## 切换场景（带过渡动画）
func _change_scene(scene_path: String) -> void:
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "modulate:a", 0.0, TRANSITION_DURATION)

	await tween.finished
	get_tree().change_scene_to_file(scene_path)


## 播放导航音效
func _play_navigate_sound() -> void:
	if _navigate_sound and _navigate_sound.stream:
		_navigate_sound.play()


## 播放确认音效
func _play_confirm_sound() -> void:
	if _confirm_sound and _confirm_sound.stream:
		_confirm_sound.play()


## 输入处理（键盘导航）
func _input(event: InputEvent) -> void:
	if not _navigation_enabled:
		return

	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_UP:
				_navigate_up()
				get_viewport().set_input_as_handled()
			KEY_DOWN:
				_navigate_down()
				get_viewport().set_input_as_handled()
			KEY_ENTER:
				_confirm_selection()
				get_viewport().set_input_as_handled()
			KEY_SPACE:
				_play_preview()
				get_viewport().set_input_as_handled()
			KEY_ESCAPE:
				_on_back_pressed()
				get_viewport().set_input_as_handled()


## 向上导航
func _navigate_up() -> void:
	if _displayed_songs.is_empty():
		return

	var new_index = _current_song_index - 1
	if new_index < 0:
		new_index = _displayed_songs.size() - 1

	_select_song(new_index)
	_scroll_to_song(new_index)


## 向下导航
func _navigate_down() -> void:
	if _displayed_songs.is_empty():
		return

	var new_index = _current_song_index + 1
	if new_index >= _displayed_songs.size():
		new_index = 0

	_select_song(new_index)
	_scroll_to_song(new_index)


## 滚动到指定歌曲
func _scroll_to_song(index: int) -> void:
	if index < 0 or index >= _song_list_container.get_child_count():
		return

	var song_item = _song_list_container.get_child(index)
	var scroll_height = _song_list_scroll.size.y
	var item_pos = song_item.position.y
	var item_height = song_item.size.y

	# 计算滚动位置
	var scroll_y = item_pos - scroll_height / 2 + item_height / 2
	scroll_y = clamp(scroll_y, 0, _song_list_container.size.y - scroll_height)

	# 平滑滚动
	var tween = create_tween()
	tween.tween_property(_song_list_scroll, "scroll_vertical", scroll_y, 0.2)


## 确认当前选择
func _confirm_selection() -> void:
	if _current_song_index >= 0:
		_on_start_pressed()


## 歌曲列表项选中
func _on_song_selected(index: int) -> void:
	_select_song(index)


## 获取当前选中的歌曲
func get_selected_song() -> Dictionary:
	if _current_song_index >= 0 and _current_song_index < _displayed_songs.size():
		return _displayed_songs[_current_song_index]
	return {}


## 获取当前选中的难度
func get_selected_difficulty() -> int:
	return _current_difficulty