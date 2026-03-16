class_name PreviewController
extends Node
## 预览控制器
## 管理谱面预览播放、暂停、停止、位置控制和速度调整
## 支持音频同步播放

const EditorData = preload("res://src/editor/editor_data.gd")

## 信号
signal playback_started()
signal playback_stopped()
signal playback_paused()
signal position_changed(time: float)
signal speed_changed(speed: float)
signal audio_loaded(path: String)
signal audio_unloaded()
signal audio_load_failed(error: String)

## 编辑器控制器引用
var editor_controller: EditorController = null

## 音频相关属性
var audio_stream: AudioStream = null
var audio_player: AudioStreamPlayer = null
var audio_offset: float = 0.0  ## 音频偏移（秒）
var is_audio_loaded: bool = false
var audio_file_path: String = ""

## 播放状态枚举
enum PlaybackState {
	STOPPED,   ## 停止
	PLAYING,   ## 播放中
	PAUSED     ## 暂停
}

## 当前播放状态
var current_state: PlaybackState = PlaybackState.STOPPED

## 当前播放位置（秒）
var current_position: float = 0.0

## 播放速度（倍率）
var playback_speed: float = 1.0:
	set(value):
		playback_speed = clamp(value, 0.25, 4.0)
		speed_changed.emit(playback_speed)

## 可用的播放速度选项
const SPEED_OPTIONS: Array[float] = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]

## 总时长（秒）
var total_duration: float = 0.0

## 是否循环播放
var loop_enabled: bool = false

## 循环起始位置（秒）
var loop_start: float = 0.0

## 循环结束位置（秒）
var loop_end: float = 0.0

## 上一次更新时间
var _last_update_time: float = 0.0


func _ready() -> void:
	set_process(false)
	_setup_audio_player()


## 设置音频播放器
func _setup_audio_player() -> void:
	audio_player = AudioStreamPlayer.new()
	audio_player.bus = "Master"
	audio_player.volume_db = 0.0
	add_child(audio_player)


func _process(delta: float) -> void:
	if current_state != PlaybackState.PLAYING:
		return
	
	if editor_controller == null:
		return
	
	# 更新播放位置
	var adjusted_delta = delta * playback_speed
	current_position += adjusted_delta
	
	# 检查循环
	if loop_enabled and current_position >= loop_end:
		current_position = loop_start
	
	# 检查是否播放结束
	if current_position >= total_duration:
		if loop_enabled:
			current_position = 0.0
		else:
			stop()
			return
	
	# 发出位置变更信号
	position_changed.emit(current_position)


## 设置编辑器控制器引用
func set_editor_controller(controller: EditorController) -> void:
	editor_controller = controller
	if editor_controller:
		editor_controller.data_changed.connect(_on_data_changed)
		_update_total_duration()


## 开始播放
func play() -> void:
	if editor_controller == null:
		return

	current_state = PlaybackState.PLAYING
	_last_update_time = Time.get_ticks_msec() / 1000.0
	set_process(true)
	
	# 同步播放音频
	if is_audio_loaded and audio_player:
		audio_player.play()
		audio_player.seek(current_position + audio_offset)
	
	playback_started.emit()


## 暂停播放
func pause() -> void:
	if current_state != PlaybackState.PLAYING:
		return

	current_state = PlaybackState.PAUSED
	set_process(false)
	
	# 暂停音频
	if is_audio_loaded and audio_player:
		audio_player.stream_paused = true
	
	playback_paused.emit()


## 停止播放
func stop() -> void:
	current_state = PlaybackState.STOPPED
	current_position = 0.0
	set_process(false)
	
	# 停止音频
	if is_audio_loaded and audio_player:
		audio_player.stop()
		audio_player.stream_paused = false
	
	playback_stopped.emit()
	position_changed.emit(0.0)


## 切换播放/暂停
func toggle_play_pause() -> void:
	match current_state:
		PlaybackState.STOPPED, PlaybackState.PAUSED:
			play()
		PlaybackState.PLAYING:
			pause()


## 设置播放位置（秒）
func set_position(time: float) -> void:
	current_position = clamp(time, 0.0, total_duration)
	
	# 同步音频位置
	_sync_audio_position()
	
	position_changed.emit(current_position)


## 设置播放位置（小节索引和小节内位置）
func set_position_by_measure(measure_index: int, position_in_measure: float = 0.0) -> void:
	if editor_controller == null:
		return
	
	var course = editor_controller.get_current_course()
	if course == null:
		return
	
	if measure_index < 0 or measure_index >= course.measures.size():
		return
	
	# 计算时间
	var time = 0.0
	for i in range(measure_index):
		time += course.measures[i].get_duration()
	
	time += course.measures[measure_index].get_duration() * clamp(position_in_measure, 0.0, 1.0)
	set_position(time)


## 设置播放速度
func set_speed(speed: float) -> void:
	playback_speed = speed


## 设置播放速度（通过索引）
func set_speed_by_index(index: int) -> void:
	if index >= 0 and index < SPEED_OPTIONS.size():
		playback_speed = SPEED_OPTIONS[index]


## 获取当前播放速度索引
func get_speed_index() -> int:
	for i in range(SPEED_OPTIONS.size()):
		if abs(playback_speed - SPEED_OPTIONS[i]) < 0.01:
			return i
	return 2  # 默认1.0x


## 获取速度选项名称列表
func get_speed_option_names() -> Array[String]:
	var names: Array[String] = []
	for speed in SPEED_OPTIONS:
		names.append("%.2gx" % speed)
	return names


## 跳转到指定小节
func jump_to_measure(measure_index: int) -> void:
	set_position_by_measure(measure_index, 0.0)


## 跳转到开头
func jump_to_start() -> void:
	set_position(0.0)


## 跳转到结尾
func jump_to_end() -> void:
	set_position(total_duration)


## 向前跳转（秒）
func skip_forward(seconds: float = 5.0) -> void:
	set_position(current_position + seconds)


## 向后跳转（秒）
func skip_backward(seconds: float = 5.0) -> void:
	set_position(current_position - seconds)


## 设置循环区域
func set_loop_region(start: float, end: float) -> void:
	loop_start = max(0.0, start)
	loop_end = min(total_duration, end)
	loop_enabled = true


## 清除循环区域
func clear_loop_region() -> void:
	loop_enabled = false
	loop_start = 0.0
	loop_end = total_duration


## 获取当前位置对应的小节索引
func get_current_measure_index() -> int:
	if editor_controller == null:
		return -1
	
	var course = editor_controller.get_current_course()
	if course == null:
		return -1
	
	var time = 0.0
	for i in range(course.measures.size()):
		var measure_duration = course.measures[i].get_duration()
		if current_position >= time and current_position < time + measure_duration:
			return i
		time += measure_duration
	
	return course.measures.size() - 1


## 获取当前位置在小节内的位置（0.0-1.0）
func get_current_position_in_measure() -> float:
	if editor_controller == null:
		return 0.0
	
	var course = editor_controller.get_current_course()
	if course == null:
		return 0.0
	
	var measure_index = get_current_measure_index()
	if measure_index < 0 or measure_index >= course.measures.size():
		return 0.0
	
	var time = 0.0
	for i in range(measure_index):
		time += course.measures[i].get_duration()
	
	var measure_duration = course.measures[measure_index].get_duration()
	if measure_duration <= 0:
		return 0.0
	
	return (current_position - time) / measure_duration


## 获取格式化的当前位置字符串
func get_formatted_position() -> String:
	var minutes = int(current_position) / 60
	var seconds = int(current_position) % 60
	var milliseconds = int((current_position - int(current_position)) * 100)
	return "%02d:%02d.%02d" % [minutes, seconds, milliseconds]


## 获取格式化的总时长字符串
func get_formatted_duration() -> String:
	var minutes = int(total_duration) / 60
	var seconds = int(total_duration) % 60
	var milliseconds = int((total_duration - int(total_duration)) * 100)
	return "%02d:%02d.%02d" % [minutes, seconds, milliseconds]


## 是否正在播放
func is_playing() -> bool:
	return current_state == PlaybackState.PLAYING


## 是否已暂停
func is_paused() -> bool:
	return current_state == PlaybackState.PAUSED


## 是否已停止
func is_stopped() -> bool:
	return current_state == PlaybackState.STOPPED


## 数据变更回调
func _on_data_changed() -> void:
	_update_total_duration()


## 更新总时长
func _update_total_duration() -> void:
	if editor_controller == null:
		total_duration = 0.0
		return

	var course = editor_controller.get_current_course()
	if course == null:
		total_duration = 0.0
		return

	total_duration = course.get_total_duration()
	loop_end = total_duration


## ========== 音频相关方法 ==========

## 加载音频文件
## 支持格式：OGG, MP3, WAV
func load_audio(path: String) -> bool:
	# 检查文件是否存在
	if not FileAccess.file_exists(path):
		audio_load_failed.emit("文件不存在: " + path)
		return false
	
	# 检查文件扩展名
	var ext = path.get_extension().to_lower()
	if ext not in ["ogg", "mp3", "wav"]:
		audio_load_failed.emit("不支持的音频格式: " + ext)
		return false
	
	# 卸载现有音频
	if is_audio_loaded:
		unload_audio()
	
	# 加载音频流
	match ext:
		"ogg":
			audio_stream = AudioStreamOggVorbis.load_from_file(path)
		"mp3":
			audio_stream = AudioStreamMP3.load_from_file(path)
		"wav":
			audio_stream = AudioStreamWAV.load_from_file(path)
		_:
			audio_load_failed.emit("无法加载音频格式: " + ext)
			return false
	
	if audio_stream == null:
		audio_load_failed.emit("音频加载失败: " + path)
		return false
	
	# 设置音频播放器
	audio_player.stream = audio_stream
	audio_file_path = path
	is_audio_loaded = true
	
	# 更新总时长（如果音频时长大于当前时长）
	var audio_duration = get_audio_duration()
	if audio_duration > total_duration:
		total_duration = audio_duration
		loop_end = total_duration
	
	audio_loaded.emit(path)
	return true


## 卸载音频
func unload_audio() -> void:
	if audio_player:
		audio_player.stop()
		audio_player.stream = null
	
	audio_stream = null
	audio_file_path = ""
	is_audio_loaded = false
	audio_offset = 0.0
	
	audio_unloaded.emit()


## 获取音频时长（秒）
func get_audio_duration() -> float:
	if audio_stream == null:
		return 0.0
	return audio_stream.get_length()


## 同步音频位置
func _sync_audio_position() -> void:
	if not is_audio_loaded or audio_player == null:
		return
	
	if current_state == PlaybackState.PLAYING:
		audio_player.seek(current_position + audio_offset)
	elif current_state == PlaybackState.PAUSED:
		# 暂停状态下也需要更新位置
		audio_player.seek(current_position + audio_offset)


## 设置音频偏移（秒）
func set_audio_offset(offset: float) -> void:
	audio_offset = offset
	# 如果正在播放，重新同步
	if current_state == PlaybackState.PLAYING:
		_sync_audio_position()


## 设置音频音量（分贝）
func set_audio_volume(volume_db: float) -> void:
	if audio_player:
		audio_player.volume_db = volume_db


## 获取音频音量（分贝）
func get_audio_volume() -> float:
	if audio_player:
		return audio_player.volume_db
	return 0.0


## 静音音频
func set_audio_muted(muted: bool) -> void:
	if audio_player:
		audio_player.volume_db = -80.0 if muted else 0.0


## 是否音频已静音
func is_audio_muted() -> bool:
	if audio_player:
		return audio_player.volume_db <= -80.0
	return false


## 获取音频文件名
func get_audio_filename() -> String:
	if audio_file_path.is_empty():
		return ""
	return audio_file_path.get_file()