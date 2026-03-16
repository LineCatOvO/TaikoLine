class_name Metronome
extends Node
## 节拍器组件
## 在播放时发出节拍信号，用于辅助对齐

## 信号
signal beat_occurred(is_downbeat: bool)

## 是否启用节拍器
var enabled: bool = false:
	set(value):
		enabled = value
		if not enabled:
			_beat_timer = 0.0
			current_beat = 0

## 音量（分贝）
var volume_db: float = -6.0

## 当前BPM
var bpm: float = 120.0:
	set(value):
		bpm = max(1.0, value)
		_update_beat_interval()

## 拍号 (分子/分母)
var time_signature: Vector2i = Vector2i(4, 4):
	set(value):
		time_signature = value
		_update_beat_interval()

## 当前拍数（在当前小节内）
var current_beat: int = 0

## 是否正在播放
var is_playing: bool = false

## 拍计时器
var _beat_timer: float = 0.0

## 拍间隔（秒）
var _beat_interval: float = 0.5

## 强拍音频播放器
var _downbeat_player: AudioStreamPlayer = null

## 弱拍音频播放器
var _upbeat_player: AudioStreamPlayer = null

## 强拍音频流（使用内置的简单音效）
var _downbeat_stream: AudioStream = null

## 弱拍音频流
var _upbeat_stream: AudioStream = null


func _ready() -> void:
	_update_beat_interval()
	_setup_audio_players()


func _process(delta: float) -> void:
	if not enabled or not is_playing:
		return
	
	_beat_timer += delta
	
	if _beat_timer >= _beat_interval:
		_beat_timer -= _beat_interval
		_on_beat()


## 设置音频播放器
func _setup_audio_players() -> void:
	# 创建强拍播放器
	_downbeat_player = AudioStreamPlayer.new()
	_downbeat_player.bus = "Master"
	_downbeat_player.volume_db = volume_db
	add_child(_downbeat_player)
	
	# 创建弱拍播放器
	_upbeat_player = AudioStreamPlayer.new()
	_upbeat_player.bus = "Master"
	_upbeat_player.volume_db = volume_db - 3.0  # 弱拍音量稍低
	add_child(_upbeat_player)
	
	# 创建简单的节拍音效（使用AudioStreamGenerator）
	_create_beat_sounds()


## 创建节拍音效
func _create_beat_sounds() -> void:
	# 使用简单的合成音效
	# 强拍：较高音调
	_downbeat_stream = _create_click_sound(880.0, 0.05)  # A5
	if _downbeat_stream:
		_downbeat_player.stream = _downbeat_stream
	
	# 弱拍：较低音调
	_upbeat_stream = _create_click_sound(440.0, 0.03)  # A4
	if _upbeat_stream:
		_upbeat_player.stream = _upbeat_stream


## 创建点击音效
func _create_click_sound(frequency: float, duration: float) -> AudioStreamGenerator:
	var generator = AudioStreamGenerator.new()
	generator.mix_rate = 22050
	generator.buffer_length = duration
	return generator


## 更新拍间隔
func _update_beat_interval() -> void:
	# 四分音符的时长 = 60 / BPM
	# 如果拍号分母是4，则一拍就是四分音符
	# 如果拍号分母是8，则一拍就是八分音符
	var beat_duration = 60.0 / bpm
	
	# 根据拍号分母调整
	match time_signature.y:
		2:  # 2分音符为一拍
			beat_duration *= 2.0
		4:  # 4分音符为一拍
			pass
		8:  # 8分音符为一拍
			beat_duration *= 0.5
		16: # 16分音符为一拍
			beat_duration *= 0.25
		_:  # 默认按4分音符处理
			pass
	
	_beat_interval = beat_duration


## 拍事件处理
func _on_beat() -> void:
	# 判断是否为强拍（每小节的第一拍）
	var is_downbeat = (current_beat % time_signature.x) == 0
	
	# 播放节拍音效
	_play_beat_sound(is_downbeat)
	
	# 发出信号
	beat_occurred.emit(is_downbeat)
	
	# 更新当前拍数
	current_beat += 1


## 播放节拍音效
func _play_beat_sound(is_downbeat: bool) -> void:
	if is_downbeat:
		if _downbeat_player and _downbeat_player.stream:
			_downbeat_player.play()
	else:
		if _upbeat_player and _upbeat_player.stream:
			_upbeat_player.play()


## 设置BPM
func set_bpm(new_bpm: float) -> void:
	bpm = new_bpm


## 设置拍号
func set_time_signature(numerator: int, denominator: int) -> void:
	time_signature = Vector2i(max(1, numerator), max(1, denominator))


## 开始播放
func start() -> void:
	is_playing = true
	_beat_timer = 0.0
	current_beat = 0


## 停止播放
func stop() -> void:
	is_playing = false
	_beat_timer = 0.0
	current_beat = 0


## 暂停播放
func pause() -> void:
	is_playing = false


## 恢复播放
func resume() -> void:
	is_playing = true


## 重置节拍器
func reset() -> void:
	_beat_timer = 0.0
	current_beat = 0
	is_playing = false


## 设置音量
func set_volume(db: float) -> void:
	volume_db = db
	if _downbeat_player:
		_downbeat_player.volume_db = volume_db
	if _upbeat_player:
		_upbeat_player.volume_db = volume_db - 3.0


## 获取当前拍在小节内的位置（0到time_signature.x-1）
func get_beat_in_measure() -> int:
	return current_beat % time_signature.x


## 获取当前小节数
func get_current_measure() -> int:
	return current_beat / time_signature.x


## 从指定时间同步节拍器
## time: 当前播放时间（秒）
func sync_to_time(time: float) -> void:
	if _beat_interval <= 0:
		return
	
	# 计算当前应该在第几拍
	var total_beats = int(time / _beat_interval)
	current_beat = total_beats
	
	# 计算在当前拍内的偏移
	_beat_timer = time - (total_beats * _beat_interval)