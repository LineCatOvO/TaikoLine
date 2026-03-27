class_name SongDatabase
extends RefCounted
## 歌曲数据库管理器
## 负责扫描、加载和缓存歌曲信息
## 作者：TaikoLine Team
## 日期：2026-03-27

const TJAParser = preload("res://src/parser/tja_parser.gd")

## 歌曲数据结构
## {
##   "title": String,
##   "title_en": String,
##   "subtitle": String,
##   "bpm": float,
##   "wave": String,
##   "offset": float,
##   "demo_start": float,
##   "genre": String,
##   "maker": String,
##   "file_path": String,
##   "base_dir": String,
##   "courses": Dictionary,
##   "preview_audio": String,
##   "sort_order": int
## }

## 歌曲列表
var _songs: Array[Dictionary] = []

## 是否已扫描
var _scanned: bool = false

## 扫描状态信号
signal scan_completed(songs: Array)
signal scan_progress(current: int, total: int, current_song: String)


## 获取所有歌曲
func get_songs() -> Array[Dictionary]:
	return _songs


## 获取歌曲数量
func get_song_count() -> int:
	return _songs.size()


## 根据索引获取歌曲
func get_song_by_index(index: int) -> Dictionary:
	if index >= 0 and index < _songs.size():
		return _songs[index]
	return {}


## 根据标题搜索歌曲
func search_by_title(title: String) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for song in _songs:
		if song.title.to_lower().contains(title.to_lower()):
			results.append(song)
		elif song.title_en.to_lower().contains(title.to_lower()):
			results.append(song)
	return results


## 根据流派筛选歌曲
func filter_by_genre(genre: String) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for song in _songs:
		if song.genre.to_lower() == genre.to_lower():
			results.append(song)
	return results


## 扫描歌曲目录
func scan_songs(songs_dir: String = "res://songs") -> Array[Dictionary]:
	print("[SongDatabase] 开始扫描歌曲目录: " + songs_dir)

	_songs.clear()
	_scanned = false

	var dir = DirAccess.open(songs_dir)
	if dir == null:
		push_warning("[SongDatabase] 无法打开歌曲目录: " + songs_dir)
		return _songs

	# 收集所有子目录
	var subdirs: Array[String] = []
	dir.list_dir_begin()
	var folder_name = dir.get_next()

	while folder_name != "":
		if dir.current_is_dir() and not folder_name.begins_with("."):
			subdirs.append(folder_name)
		folder_name = dir.get_next()

	dir.list_dir_end()

	# 扫描每个子目录
	var total = subdirs.size()
	for i in range(total):
		var subdir = subdirs[i]
		var folder_path = songs_dir + "/" + subdir
		_scan_song_folder(folder_path)

		# 发送进度信号
		scan_progress.emit(i + 1, total, subdir)

	# 按标题排序
	_sort_songs()

	_scanned = true
	scan_completed.emit(_songs)

	print("[SongDatabase] 扫描完成，共找到 %d 首歌曲" % _songs.size())
	return _songs


## 扫描单个歌曲文件夹
func _scan_song_folder(folder_path: String) -> void:
	var dir = DirAccess.open(folder_path)
	if dir == null:
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if file_name.ends_with(".tja"):
			var tja_path = folder_path + "/" + file_name
			_load_song_info(tja_path)
		file_name = dir.get_next()

	dir.list_dir_end()


## 加载歌曲信息
func _load_song_info(tja_path: String) -> void:
	var parser = TJAParser.new()
	var result = parser.parse_file(tja_path)

	if not result.success:
		push_warning("[SongDatabase] 解析TJA文件失败: " + tja_path + " - " + result.error)
		return

	var song = result.song

	# 构建歌曲数据
	var song_data: Dictionary = {
		"title": song.title,
		"title_en": song.title_en if song.title_en != "" else song.title,
		"subtitle": song.subtitle,
		"bpm": song.bpm,
		"wave": song.wave,
		"offset": song.offset,
		"demo_start": song.demo_start if song.demo_start > 0 else 0.0,
		"genre": song.genre,
		"maker": song.maker,
		"file_path": tja_path,
		"base_dir": tja_path.get_base_dir(),
		"courses": {},
		"preview_audio": "",
		"sort_order": _songs.size()
	}

	# 添加难度信息
	for course_type in song.courses:
		var course = song.courses[course_type]
		song_data.courses[course_type] = {
			"level": course.level,
			"score_init": course.score_init,
			"score_diff": course.score_diff,
			"total_notes": course.get_total_notes(),
			"balloon_counts": course.balloon_counts
		}

	# 查找预览音频
	if song.wave != "":
		song_data.preview_audio = song.wave

	_songs.append(song_data)


## 歌曲排序
func _sort_songs() -> void:
	# 按标题排序（忽略大小写）
	_songs.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a.title.to_lower() < b.title.to_lower()
	)


## 检查歌曲是否有指定难度
func has_course(song: Dictionary, course_type: int) -> bool:
	return song.courses.has(course_type)


## 获取歌曲的难度等级
func get_course_level(song: Dictionary, course_type: int) -> int:
	if song.courses.has(course_type):
		return song.courses[course_type].level
	return 0


## 获取歌曲的可用难度列表
func get_available_courses(song: Dictionary) -> Array[int]:
	var courses: Array[int] = []
	for course_type in song.courses.keys():
		courses.append(course_type)
	return courses


## 是否已扫描
func is_scanned() -> bool:
	return _scanned


## 清空缓存
func clear_cache() -> void:
	_songs.clear()
	_scanned = false