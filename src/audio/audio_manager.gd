extends Node
## 音频管理器
## 管理背景音乐播放、音效播放和音频同步
## 作为Autoload单例使用

## 信号
signal music_started
signal music_stopped
signal music_paused
signal music_resumed
signal music_position_changed(position: float)
signal volume_changed(bus: String, volume: float)

## 音频总线名称
const MASTER_BUS := "Master"
const MUSIC_BUS := "Music"
const SFX_BUS := "SFX"

## 背景音乐播放器
var _music_player: AudioStreamPlayer

## 音效播放器引用
var _sfx_player: Node

## 当前音乐状态
var _is_music_playing: bool = false
var _music_paused_position: float = 0.0

## 音频同步偏移（毫秒）
var _audio_offset_ms: float = 0.0

## 预加载的音效资源
var _preloaded_sounds: Dictionary = {}

## 音效类型定义
## 支持WAV和OGG格式，Godot会自动处理导入
const SOUND_EFFECTS := {
	"don": "res://resources/sounds/don.wav",
	"ka": "res://resources/sounds/ka.wav",
	"balloon": "res://resources/sounds/balloon.ogg",
	"judge_perfect": "res://resources/sounds/judge_perfect.ogg",
	"judge_good": "res://resources/sounds/judge_good.ogg",
	"judge_miss": "res://resources/sounds/judge_miss.ogg",
	"combo_bonus": "res://resources/sounds/combo_bonus.ogg"
}


func _ready() -> void:
	_setup_audio_buses()
	_create_music_player()
	_preload_sound_effects()


## 设置音频总线
func _setup_audio_buses() -> void:
	# 确保音频总线存在
	var master_bus_idx = AudioServer.get_bus_index(MASTER_BUS)
	if master_bus_idx == -1:
		# Master总线默认存在
		pass
	
	var music_bus_idx = AudioServer.get_bus_index(MUSIC_BUS)
	if music_bus_idx == -1:
		# 创建Music总线（如果不存在）
		# 注意：Godot 4.x中总线需要在项目设置中配置
		pass
	
	var sfx_bus_idx = AudioServer.get_bus_index(SFX_BUS)
	if sfx_bus_idx == -1:
		# 创建SFX总线（如果不存在）
		pass
	
	# 应用初始音量设置
	if Settings:
		set_master_volume(Settings.master_volume)
		set_music_volume(Settings.music_volume)
		set_sfx_volume(Settings.sfx_volume)


## 创建背景音乐播放器
func _create_music_player() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = MUSIC_BUS
	add_child(_music_player)
	
	# 连接信号
	_music_player.finished.connect(_on_music_finished)


## 预加载音效资源
func _preload_sound_effects() -> void:
	for sound_name in SOUND_EFFECTS:
		var sound_path = SOUND_EFFECTS[sound_name]
		if FileAccess.file_exists(sound_path):
			var audio_stream = load(sound_path)
			if audio_stream:
				_preloaded_sounds[sound_name] = audio_stream


## ==================== 背景音乐控制 ====================

## 播放背景音乐
## @param stream: 音频流
## @param from_position: 起始位置（秒）
func play_music(stream: AudioStream, from_position: float = 0.0) -> void:
	if _music_player == null:
		return
	
	# 停止当前播放
	stop_music()
	
	# 设置新音频流
	_music_player.stream = stream
	_music_player.play(from_position)
	
	_is_music_playing = true
	music_started.emit()


## 播放背景音乐（从文件路径）
## @param file_path: 音频文件路径
## @param from_position: 起始位置（秒）
func play_music_from_file(file_path: String, from_position: float = 0.0) -> bool:
	if not FileAccess.file_exists(file_path):
		push_warning("音频文件不存在: " + file_path)
		return false
	
	var stream = load(file_path)
	if stream == null:
		push_error("无法加载音频文件: " + file_path)
		return false
	
	play_music(stream, from_position)
	return true


## 暂停背景音乐
func pause_music() -> void:
	if _music_player == null or not _is_music_playing:
		return
	
	_music_paused_position = _music_player.get_playback_position()
	_music_player.stream_paused = true
	music_paused.emit()


## 恢复背景音乐
func resume_music() -> void:
	if _music_player == null or not _music_player.stream_paused:
		return
	
	_music_player.stream_paused = false
	music_resumed.emit()


## 停止背景音乐
func stop_music() -> void:
	if _music_player == null:
		return
	
	_music_player.stop()
	_is_music_playing = false
	_music_paused_position = 0.0
	music_stopped.emit()


## 跳转到指定位置
## @param position: 目标位置（秒）
func seek_music(position: float) -> void:
	if _music_player == null or not _is_music_playing:
		return
	
	_music_player.seek(position)
	music_position_changed.emit(position)


## 获取当前播放位置
## @return 当前位置（秒）
func get_music_position() -> float:
	if _music_player == null or not _is_music_playing:
		return 0.0
	
	return _music_player.get_playback_position()


## 获取音乐总时长
## @return 总时长（秒）
func get_music_length() -> float:
	if _music_player == null or _music_player.stream == null:
		return 0.0
	
	return _music_player.stream.get_length()


## 检查音乐是否正在播放
## @return 是否正在播放
func is_music_playing() -> bool:
	return _is_music_playing and _music_player != null and not _music_player.stream_paused


## 检查音乐是否暂停
## @return 是否暂停
func is_music_paused() -> bool:
	return _music_player != null and _music_player.stream_paused


## 设置音频同步偏移
## @param offset_ms: 偏移量（毫秒）
func set_audio_offset(offset_ms: float) -> void:
	_audio_offset_ms = offset_ms


## 获取音频同步偏移
## @return 偏移量（毫秒）
func get_audio_offset() -> float:
	return _audio_offset_ms


## 获取同步后的播放时间
## @return 同步后的时间（秒）
func get_synced_time() -> float:
	var position = get_music_position()
	# 应用音频偏移（毫秒转秒）
	return position + (_audio_offset_ms / 1000.0)


## ==================== 音效播放 ====================

## 设置音效播放器引用
## @param player: 音效播放器节点
func set_sfx_player(player: Node) -> void:
	_sfx_player = player


## 播放音效
## @param sound_name: 音效名称
## @param volume_db: 音量偏移（分贝）
func play_sfx(sound_name: String, volume_db: float = 0.0) -> void:
	if _sfx_player and _sfx_player.has_method("play_sound"):
		_sfx_player.play_sound(sound_name, volume_db)
	elif sound_name in _preloaded_sounds:
		# 直接播放预加载的音效
		_play_sfx_direct(sound_name, volume_db)


## 直接播放音效（备用方法）
func _play_sfx_direct(sound_name: String, volume_db: float = 0.0) -> void:
	if not sound_name in _preloaded_sounds:
		return
	
	var player = AudioStreamPlayer.new()
	player.stream = _preloaded_sounds[sound_name]
	player.volume_db = volume_db
	player.bus = SFX_BUS
	add_child(player)
	player.play()
	
	# 播放完成后自动删除
	player.finished.connect(player.queue_free)


## 播放鼓声（红音符）
func play_don() -> void:
	play_sfx("don")


## 播放鼓声（蓝音符）
func play_ka() -> void:
	play_sfx("ka")


## 播放气球打击音
func play_balloon() -> void:
	play_sfx("balloon")


## 播放判定音效（良）
func play_judge_perfect() -> void:
	play_sfx("judge_perfect")


## 播放判定音效（可）
func play_judge_good() -> void:
	play_sfx("judge_good")


## 播放判定音效（不可）
func play_judge_miss() -> void:
	play_sfx("judge_miss")


## 播放连击加成音
func play_combo_bonus() -> void:
	play_sfx("combo_bonus")


## ==================== 音量控制 ====================

## 设置主音量
## @param volume: 音量（0.0-1.0）
func set_master_volume(volume: float) -> void:
	var bus_idx = AudioServer.get_bus_index(MASTER_BUS)
	if bus_idx != -1:
		var volume_db = linear_to_db(clamp(volume, 0.0, 1.0))
		AudioServer.set_bus_volume_db(bus_idx, volume_db)
		volume_changed.emit(MASTER_BUS, volume)


## 设置音乐音量
## @param volume: 音量（0.0-1.0）
func set_music_volume(volume: float) -> void:
	var bus_idx = AudioServer.get_bus_index(MUSIC_BUS)
	if bus_idx != -1:
		var volume_db = linear_to_db(clamp(volume, 0.0, 1.0))
		AudioServer.set_bus_volume_db(bus_idx, volume_db)
		volume_changed.emit(MUSIC_BUS, volume)


## 设置音效音量
## @param volume: 音量（0.0-1.0）
func set_sfx_volume(volume: float) -> void:
	var bus_idx = AudioServer.get_bus_index(SFX_BUS)
	if bus_idx != -1:
		var volume_db = linear_to_db(clamp(volume, 0.0, 1.0))
		AudioServer.set_bus_volume_db(bus_idx, volume_db)
		volume_changed.emit(SFX_BUS, volume)


## 获取主音量
## @return 音量（0.0-1.0）
func get_master_volume() -> float:
	var bus_idx = AudioServer.get_bus_index(MASTER_BUS)
	if bus_idx != -1:
		return db_to_linear(AudioServer.get_bus_volume_db(bus_idx))
	return 1.0


## 获取音乐音量
## @return 音量（0.0-1.0）
func get_music_volume() -> float:
	var bus_idx = AudioServer.get_bus_index(MUSIC_BUS)
	if bus_idx != -1:
		return db_to_linear(AudioServer.get_bus_volume_db(bus_idx))
	return 1.0


## 获取音效音量
## @return 音量（0.0-1.0）
func get_sfx_volume() -> float:
	var bus_idx = AudioServer.get_bus_index(SFX_BUS)
	if bus_idx != -1:
		return db_to_linear(AudioServer.get_bus_volume_db(bus_idx))
	return 1.0


## 静音/取消静音
## @param mute: 是否静音
func set_mute(mute: bool) -> void:
	var bus_idx = AudioServer.get_bus_index(MASTER_BUS)
	if bus_idx != -1:
		AudioServer.set_bus_mute(bus_idx, mute)


## 检查是否静音
## @return 是否静音
func is_muted() -> bool:
	var bus_idx = AudioServer.get_bus_index(MASTER_BUS)
	if bus_idx != -1:
		return AudioServer.is_bus_mute(bus_idx)
	return false


## ==================== 音频资源管理 ====================

## 预加载音频资源
## @param name: 资源名称
## @param path: 资源路径
func preload_sound(name: String, path: String) -> bool:
	if not FileAccess.file_exists(path):
		push_warning("音频文件不存在: " + path)
		return false
	
	var audio_stream = load(path)
	if audio_stream == null:
		push_error("无法加载音频文件: " + path)
		return false
	
	_preloaded_sounds[name] = audio_stream
	return true


## 获取预加载的音频资源
## @param name: 资源名称
## @return 音频流
func get_preloaded_sound(name: String) -> AudioStream:
	if name in _preloaded_sounds:
		return _preloaded_sounds[name]
	return null


## 检查音效是否已预加载
## @param name: 资源名称
## @return 是否已预加载
func is_sound_preloaded(name: String) -> bool:
	return name in _preloaded_sounds


## 释放预加载的音频资源
## @param name: 资源名称
func unload_sound(name: String) -> void:
	if name in _preloaded_sounds:
		_preloaded_sounds.erase(name)


## ==================== 信号回调 ====================

## 音乐播放完成回调
func _on_music_finished() -> void:
	_is_music_playing = false
	music_stopped.emit()