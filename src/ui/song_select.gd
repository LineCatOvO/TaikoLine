class_name SongSelectUI
extends Control
## 选曲界面
## 显示歌曲列表，允许选择歌曲和难度

const TJAData = preload("res://src/parser/tja_data.gd")
const TJAParser = preload("res://src/parser/tja_parser.gd")
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
	Color(1.0, 0.0, 0.0)   # 红色 - Oni
]

## UI节点引用
var _song_list_container: VBoxContainer
var _song_list_scroll: ScrollContainer
var _song_info_panel: PanelContainer
var _difficulty_buttons: HBoxContainer
var _start_button: Button
var _back_button: Button
var _preview_button: Button
var _title_label: Label
var _subtitle_label: Label
var _bpm_label: Label
var _level_label: Label

## 歌曲数据
var _songs: Array[Dictionary] = []
var _current_song_index: int = -1
var _current_difficulty: int = 3  # 默认Oni

## 预览播放器
var _preview_player: AudioStreamPlayer


func _ready() -> void:
	_setup_ui()
	_scan_songs()
	_update_ui()


## 设置UI布局
func _setup_ui() -> void:
	# 设置全屏
	anchors_preset = Control.PRESET_FULL_RECT
	offset_right = 0
	offset_bottom = 0
	
	# 创建主容器
	var main_vbox = VBoxContainer.new()
	add_child(main_vbox)
	main_vbox.anchors_preset = Control.PRESET_FULL_RECT
	main_vbox.offset_right = 0
	main_vbox.offset_bottom = 0
	
	# 顶部标题栏
	_setup_header(main_vbox)
	
	# 中间内容区域
	var content_hbox = HBoxContainer.new()
	content_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(content_hbox)
	
	# 左侧歌曲列表
	_setup_song_list(content_hbox)
	
	# 右侧歌曲信息面板
	_setup_song_info_panel(content_hbox)
	
	# 底部按钮栏
	_setup_footer(main_vbox)


## 设置顶部标题栏
func _setup_header(parent: Control) -> void:
	var header = PanelContainer.new()
	header.custom_minimum_size = Vector2(0, 60)
	parent.add_child(header)
	
	var hbox = HBoxContainer.new()
	header.add_child(hbox)
	
	# 标题
	var title = Label.new()
	title.text = "Song Select"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	hbox.add_child(title)
	
	# 弹性空间
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)
	
	# 歌曲数量
	var count_label = Label.new()
	count_label.text = "Songs: 0"
	count_label.name = "SongCountLabel"
	hbox.add_child(count_label)


## 设置歌曲列表
func _setup_song_list(parent: Control) -> void:
	# 滚动容器
	_song_list_scroll = ScrollContainer.new()
	_song_list_scroll.custom_minimum_size = Vector2(400, 0)
	_song_list_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(_song_list_scroll)
	
	# 歌曲列表容器
	_song_list_container = VBoxContainer.new()
	_song_list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_song_list_scroll.add_child(_song_list_container)


## 设置歌曲信息面板
func _setup_song_info_panel(parent: Control) -> void:
	_song_info_panel = PanelContainer.new()
	_song_info_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(_song_info_panel)
	
	var info_vbox = VBoxContainer.new()
	_song_info_panel.add_child(info_vbox)
	
	# 歌曲标题
	_title_label = Label.new()
	_title_label.text = "Select a song"
	_title_label.add_theme_font_size_override("font_size", 28)
	_title_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	info_vbox.add_child(_title_label)
	
	# 副标题
	_subtitle_label = Label.new()
	_subtitle_label.text = ""
	_subtitle_label.add_theme_font_size_override("font_size", 16)
	_subtitle_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	info_vbox.add_child(_subtitle_label)
	
	# BPM
	_bpm_label = Label.new()
	_bpm_label.text = "BPM: ---"
	_bpm_label.add_theme_font_size_override("font_size", 18)
	_bpm_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
	info_vbox.add_child(_bpm_label)
	
	# 难度等级
	_level_label = Label.new()
	_level_label.text = "Level: ---"
	_level_label.add_theme_font_size_override("font_size", 18)
	info_vbox.add_child(_level_label)
	
	# 分隔线
	var separator = HSeparator.new()
	info_vbox.add_child(separator)
	
	# 难度选择标签
	var diff_label = Label.new()
	diff_label.text = "Select Difficulty:"
	diff_label.add_theme_font_size_override("font_size", 16)
	info_vbox.add_child(diff_label)
	
	# 难度按钮
	_difficulty_buttons = HBoxContainer.new()
	info_vbox.add_child(_difficulty_buttons)
	
	for i in range(DIFFICULTY_NAMES.size()):
		var btn = Button.new()
		btn.text = DIFFICULTY_NAMES[i]
		btn.custom_minimum_size = Vector2(80, 40)
		btn.toggle_mode = true
		btn.button_group = _get_or_create_button_group()
		btn.pressed.connect(_on_difficulty_button_pressed.bind(i))
		_difficulty_buttons.add_child(btn)
	
	# 设置默认选中Oni
	_difficulty_buttons.get_child(_current_difficulty).button_pressed = true
	
	# 弹性空间
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info_vbox.add_child(spacer)


## 获取或创建按钮组
func _get_or_create_button_group() -> ButtonGroup:
	var group = ButtonGroup.new()
	return group


## 设置底部按钮栏
func _setup_footer(parent: Control) -> void:
	var footer = HBoxContainer.new()
	footer.custom_minimum_size = Vector2(0, 60)
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	parent.add_child(footer)
	
	# 返回按钮
	_back_button = Button.new()
	_back_button.text = "Back"
	_back_button.custom_minimum_size = Vector2(120, 40)
	_back_button.pressed.connect(_on_back_pressed)
	footer.add_child(_back_button)
	
	# 间隔
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(20, 0)
	footer.add_child(spacer1)
	
	# 预览按钮
	_preview_button = Button.new()
	_preview_button.text = "Preview"
	_preview_button.custom_minimum_size = Vector2(120, 40)
	_preview_button.pressed.connect(_on_preview_pressed)
	footer.add_child(_preview_button)
	
	# 间隔
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(20, 0)
	footer.add_child(spacer2)
	
	# 开始按钮
	_start_button = Button.new()
	_start_button.text = "Start Game"
	_start_button.custom_minimum_size = Vector2(150, 40)
	_start_button.disabled = true
	_start_button.pressed.connect(_on_start_pressed)
	footer.add_child(_start_button)
	
	# 创建预览播放器
	_preview_player = AudioStreamPlayer.new()
	add_child(_preview_player)


## 扫描歌曲目录
func _scan_songs() -> void:
	_songs.clear()

	var songs_dir = "res://songs"
	print("[SongSelect] 开始扫描歌曲目录: " + songs_dir)
	var dir = DirAccess.open(songs_dir)
	
	if dir == null:
		push_warning("无法打开歌曲目录: " + songs_dir)
		return
	
	# 遍历子目录
	dir.list_dir_begin()
	var folder_name = dir.get_next()
	
	while folder_name != "":
		if dir.current_is_dir() and not folder_name.begins_with("."):
			print("[SongSelect] 发现子目录: " + folder_name)
			var folder_path = songs_dir + "/" + folder_name
			_scan_song_folder(folder_path)
		folder_name = dir.get_next()
	
	dir.list_dir_end()
	
	# 更新歌曲数量显示
	var count_label = get_node_or_null("VBoxContainer/PanelContainer/HBoxContainer/SongCountLabel")
	if count_label:
		count_label.text = "Songs: %d" % _songs.size()


## 扫描单个歌曲文件夹
func _scan_song_folder(folder_path: String) -> void:
	print("[SongSelect] 扫描文件夹: " + folder_path)
	var dir = DirAccess.open(folder_path)
	
	if dir == null:
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".tja"):
			print("[SongSelect] 发现 TJA 文件: " + file_name)
			var tja_path = folder_path + "/" + file_name
			_load_song_info(tja_path)
		file_name = dir.get_next()
	
	dir.list_dir_end()


## 加载歌曲信息
func _load_song_info(tja_path: String) -> void:
	print("[SongSelect] 加载歌曲信息: " + tja_path)
	var parser = TJAParser.new()
	var result = parser.parse_file(tja_path)

	if not result.success:
		push_warning("解析TJA文件失败: " + tja_path + " - " + result.error)
		print("[SongSelect] 解析失败: " + result.error)
		return

	var song = result.song
	print("[SongSelect] 解析成功: " + song.title)
	
	# 构建歌曲数据
	var song_data = {
		"title": song.title,
		"title_en": song.title_en,
		"subtitle": song.subtitle,
		"bpm": song.bpm,
		"wave": song.wave,
		"offset": song.offset,
		"demo_start": song.demo_start,
		"genre": song.genre,
		"maker": song.maker,
		"file_path": tja_path,
		"base_dir": tja_path.get_base_dir(),
		"courses": {}
	}
	
	# 添加难度信息
	for course_type in song.courses:
		var course = song.courses[course_type]
		song_data.courses[course_type] = {
			"level": course.level,
			"score_init": course.score_init,
			"score_diff": course.score_diff,
			"total_notes": course.get_total_notes()
		}
	
	_songs.append(song_data)


## 更新UI
func _update_ui() -> void:
	# 清空歌曲列表
	for child in _song_list_container.get_children():
		child.queue_free()
	
	# 创建歌曲列表项
	for i in range(_songs.size()):
		var song_item = SongItem.new()
		song_item.set_song_data(_songs[i])
		song_item.selected.connect(_on_song_item_selected.bind(i))
		song_item.preview_requested.connect(_on_song_item_preview.bind(i))
		_song_list_container.add_child(song_item)


## 歌曲列表项选中
func _on_song_item_selected(index: int) -> void:
	_select_song(index)


## 歌曲列表项预览
func _on_song_item_preview(index: int) -> void:
	_select_song(index)
	_play_preview()


## 选择歌曲
func _select_song(index: int) -> void:
	if index < 0 or index >= _songs.size():
		return
	
	_current_song_index = index
	var song = _songs[index]
	
	# 更新信息显示
	_title_label.text = song.title
	_subtitle_label.text = song.subtitle
	_subtitle_label.visible = song.subtitle != ""
	_bpm_label.text = "BPM: %.0f" % song.bpm
	
	# 更新难度等级显示
	_update_level_display()
	
	# 启用开始按钮
	_start_button.disabled = false


## 更新难度等级显示
func _update_level_display() -> void:
	if _current_song_index < 0:
		_level_label.text = "Level: ---"
		return
	
	var song = _songs[_current_song_index]
	var courses = song.courses
	
	if courses.has(_current_difficulty):
		var course = courses[_current_difficulty]
		_level_label.text = "Level: %d" % course.level
		_level_label.add_theme_color_override("font_color", DIFFICULTY_COLORS[_current_difficulty])
	else:
		_level_label.text = "Level: N/A"
		_level_label.add_theme_color_override("font_color", Color.GRAY)


## 难度按钮按下
func _on_difficulty_button_pressed(difficulty: int) -> void:
	_current_difficulty = difficulty
	_update_level_display()
	
	# 更新按钮颜色
	for i in range(_difficulty_buttons.get_child_count()):
		var btn = _difficulty_buttons.get_child(i)
		if i == difficulty:
			btn.add_theme_color_override("font_color", DIFFICULTY_COLORS[i])
		else:
			btn.add_theme_color_override("font_color", Color.WHITE)


## 预览按钮按下
func _on_preview_pressed() -> void:
	_play_preview()


## 播放预览
func _play_preview() -> void:
	if _current_song_index < 0:
		return
	
	var song = _songs[_current_song_index]
	
	# 停止当前预览
	_preview_player.stop()
	
	# 加载音频文件
	if song.wave.is_empty():
		return
	
	var audio_path = song.base_dir + "/" + song.wave
	
	if not FileAccess.file_exists(audio_path):
		push_warning("音频文件不存在: " + audio_path)
		return
	
	var audio_stream = load(audio_path)
	if audio_stream == null:
		return
	
	_preview_player.stream = audio_stream
	_preview_player.play(song.demo_start)


## 开始按钮按下
func _on_start_pressed() -> void:
	if _current_song_index < 0:
		return
	
	# 停止预览
	_preview_player.stop()
	
	var song = _songs[_current_song_index]
	
	# 保存到全局状态
	GameState.current_song = song
	GameState.current_course = DIFFICULTY_NAMES[_current_difficulty]
	
	# 发送信号
	song_selected.emit(song, _current_difficulty)
	
	# 切换到游戏场景
	get_tree().change_scene_to_file("res://scenes/gameplay.tscn")


## 返回按钮按下
func _on_back_pressed() -> void:
	# 停止预览
	_preview_player.stop()
	
	back_requested.emit()
	
	# 切换到主菜单
	get_tree().change_scene_to_file("res://scenes/main.tscn")


## 获取当前选中的歌曲
func get_selected_song() -> Dictionary:
	if _current_song_index >= 0 and _current_song_index < _songs.size():
		return _songs[_current_song_index]
	return {}


## 获取当前选中的难度
func get_selected_difficulty() -> int:
	return _current_difficulty