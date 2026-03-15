class_name SoundEffectPlayer
extends Node
## 音效播放器
## 实现多通道音效播放和音效池管理

## 信号
signal sound_played(sound_name: String)
signal sound_finished(sound_name: String)

## 配置
@export var max_channels: int = 16  ## 最大同时播放通道数
@export var default_bus: String = "SFX"  ## 默认音频总线

## 音效池
var _sound_pool: Dictionary = {}

## 活动通道
var _active_channels: Array[AudioStreamPlayer] = []

## 通道池（复用）
var _channel_pool: Array[AudioStreamPlayer] = []

## 音效类型定义
const SOUND_EFFECTS := {
	"don": "res://resources/sounds/don.ogg",
	"ka": "res://resources/sounds/ka.ogg",
	"balloon": "res://resources/sounds/balloon.ogg",
	"judge_perfect": "res://resources/sounds/judge_perfect.ogg",
	"judge_good": "res://resources/sounds/judge_good.ogg",
	"judge_miss": "res://resources/sounds/judge_miss.ogg",
	"combo_bonus": "res://resources/sounds/combo_bonus.ogg"
}


func _ready() -> void:
	_initialize_channel_pool()
	preload_default_sounds()


func _process(_delta: float) -> void:
	_cleanup_finished_channels()


## 初始化通道池
func _initialize_channel_pool() -> void:
	for i in range(max_channels):
		var player = AudioStreamPlayer.new()
		player.bus = default_bus
		_channel_pool.append(player)


## 预加载默认音效
func preload_default_sounds() -> void:
	for sound_name in SOUND_EFFECTS:
		var sound_path = SOUND_EFFECTS[sound_name]
		preload_sound(sound_name, sound_path)


## ==================== 音效预加载 ====================

## 预加载音效
## @param name: 音效名称
## @param path: 音效文件路径
## @return 是否成功
func preload_sound(name: String, path: String) -> bool:
	if not FileAccess.file_exists(path):
		push_warning("音效文件不存在: " + path)
		# 创建占位符，避免重复警告
		_sound_pool[name] = null
		return false
	
	var audio_stream = load(path)
	if audio_stream == null:
		push_error("无法加载音效文件: " + path)
		return false
	
	_sound_pool[name] = audio_stream
	return true


## 批量预加载音效
## @param sounds: 音效字典 {名称: 路径}
func preload_sounds(sounds: Dictionary) -> void:
	for name in sounds:
		preload_sound(name, sounds[name])


## 卸载音效
## @param name: 音效名称
func unload_sound(name: String) -> void:
	if name in _sound_pool:
		_sound_pool.erase(name)


## 检查音效是否已加载
## @param name: 音效名称
## @return 是否已加载
func is_sound_loaded(name: String) -> bool:
	return name in _sound_pool and _sound_pool[name] != null


## 获取已加载的音效
## @param name: 音效名称
## @return 音频流
func get_sound(name: String) -> AudioStream:
	if name in _sound_pool:
		return _sound_pool[name]
	return null


## ==================== 音效播放 ====================

## 播放音效
## @param sound_name: 音效名称
## @param volume_db: 音量偏移（分贝）
## @param pitch_scale: 音高缩放
## @return 是否成功播放
func play_sound(sound_name: String, volume_db: float = 0.0, pitch_scale: float = 1.0) -> bool:
	# 获取音效
	var stream = get_sound(sound_name)
	if stream == null:
		# 尝试从默认音效加载
		if sound_name in SOUND_EFFECTS:
			if preload_sound(sound_name, SOUND_EFFECTS[sound_name]):
				stream = get_sound(sound_name)
		
		if stream == null:
			push_warning("音效未加载: " + sound_name)
			return false
	
	# 获取可用通道
	var player = _get_available_channel()
	if player == null:
		push_warning("没有可用的音效通道")
		return false
	
	# 设置播放器
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.bus = default_bus
	
	# 播放
	player.play()
	
	# 添加到活动通道
	if not player in _active_channels:
		_active_channels.append(player)
	
	sound_played.emit(sound_name)
	
	return true


## 播放音效（带位置变化）
## @param sound_name: 音效名称
## @param from_position: 起始位置（秒）
## @param volume_db: 音量偏移（分贝）
## @return 是否成功播放
func play_sound_from_position(sound_name: String, from_position: float, volume_db: float = 0.0) -> bool:
	var stream = get_sound(sound_name)
	if stream == null:
		push_warning("音效未加载: " + sound_name)
		return false
	
	var player = _get_available_channel()
	if player == null:
		push_warning("没有可用的音效通道")
		return false
	
	player.stream = stream
	player.volume_db = volume_db
	player.bus = default_bus
	player.play(from_position)
	
	if not player in _active_channels:
		_active_channels.append(player)
	
	sound_played.emit(sound_name)
	return true


## 停止所有音效
func stop_all_sounds() -> void:
	for player in _active_channels:
		if is_instance_valid(player):
			player.stop()
			_recycle_channel(player)
	
	_active_channels.clear()


## 停止指定音效
## @param sound_name: 音效名称
func stop_sound(sound_name: String) -> void:
	var stream = get_sound(sound_name)
	if stream == null:
		return
	
	for player in _active_channels:
		if is_instance_valid(player) and player.stream == stream:
			player.stop()
			_recycle_channel(player)
			_active_channels.erase(player)
			sound_finished.emit(sound_name)
			break


## ==================== 通道管理 ====================

## 获取可用通道
## @return 音频播放器
func _get_available_channel() -> AudioStreamPlayer:
	# 优先从池中获取
	if _channel_pool.size() > 0:
		return _channel_pool.pop_back()
	
	# 检查是否有已完成的通道可复用
	for player in _active_channels:
		if is_instance_valid(player) and not player.playing:
			_active_channels.erase(player)
			return player
	
	# 如果未达到最大通道数，创建新通道
	if _active_channels.size() < max_channels:
		var player = AudioStreamPlayer.new()
		player.bus = default_bus
		return player
	
	return null


## 回收通道
## @param player: 音频播放器
func _recycle_channel(player: AudioStreamPlayer) -> void:
	if player == null or not is_instance_valid(player):
		return
	
	player.stream = null
	player.volume_db = 0.0
	player.pitch_scale = 1.0
	
	# 如果池未满，放回池中
	if _channel_pool.size() < max_channels:
		_channel_pool.append(player)
	else:
		player.queue_free()


## 清理已完成的通道
func _cleanup_finished_channels() -> void:
	var finished_players: Array[AudioStreamPlayer] = []
	
	for player in _active_channels:
		if not is_instance_valid(player) or not player.playing:
			finished_players.append(player)
	
	for player in finished_players:
		_active_channels.erase(player)
		_recycle_channel(player)


## ==================== 便捷方法 ====================

## 播放鼓声（红音符）
func play_don() -> void:
	play_sound("don")


## 播放鼓声（蓝音符）
func play_ka() -> void:
	play_sound("ka")


## 播放气球打击音
func play_balloon() -> void:
	play_sound("balloon")


## 播放判定音效（良）
func play_judge_perfect() -> void:
	play_sound("judge_perfect")


## 播放判定音效（可）
func play_judge_good() -> void:
	play_sound("judge_good")


## 播放判定音效（不可）
func play_judge_miss() -> void:
	play_sound("judge_miss")


## 播放连击加成音
func play_combo_bonus() -> void:
	play_sound("combo_bonus")


## ==================== 音量控制 ====================

## 设置音效总线音量
## @param volume: 音量（0.0-1.0）
func set_volume(volume: float) -> void:
	var bus_idx = AudioServer.get_bus_index(default_bus)
	if bus_idx != -1:
		var volume_db = linear_to_db(clamp(volume, 0.0, 1.0))
		AudioServer.set_bus_volume_db(bus_idx, volume_db)


## 获取音效总线音量
## @return 音量（0.0-1.0）
func get_volume() -> float:
	var bus_idx = AudioServer.get_bus_index(default_bus)
	if bus_idx != -1:
		return db_to_linear(AudioServer.get_bus_volume_db(bus_idx))
	return 1.0


## ==================== 状态查询 ====================

## 获取活动通道数
## @return 活动通道数
func get_active_channel_count() -> int:
	return _active_channels.size()


## 获取已加载音效数
## @return 已加载音效数
func get_loaded_sound_count() -> int:
	var count = 0
	for name in _sound_pool:
		if _sound_pool[name] != null:
			count += 1
	return count


## 获取已加载音效列表
## @return 音效名称数组
func get_loaded_sound_names() -> Array:
	var names: Array = []
	for name in _sound_pool:
		if _sound_pool[name] != null:
			names.append(name)
	return names


## 检查音效是否正在播放
## @param sound_name: 音效名称
## @return 是否正在播放
func is_sound_playing(sound_name: String) -> bool:
	var stream = get_sound(sound_name)
	if stream == null:
		return false
	
	for player in _active_channels:
		if is_instance_valid(player) and player.stream == stream and player.playing:
			return true
	
	return false