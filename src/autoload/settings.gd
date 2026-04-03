## 设置管理
## 管理游戏设置，包括音频、游戏、显示等选项
## 作者：TaikoLine Team
## 日期：2026-03-27

extends Node

## ==================== 音频设置 ====================

## 主音量 (0.0 - 1.0)
var master_volume: float = 1.0

## 音乐音量 (0.0 - 1.0)
var music_volume: float = 1.0

## 音效音量 (0.0 - 1.0)
var sfx_volume: float = 1.0

## 音频偏移（毫秒），用于调整音频同步
var audio_offset: float = 0.0

## 音频缓冲区大小（样本数）
## 可选值：256, 512, 1024, 2048
var buffer_size: int = 512

## 音频输出设备名称
## 空字符串表示使用默认设备
var audio_output_device: String = ""

## 音频延迟测试结果（毫秒）
var audio_latency_result: float = 0.0

## ==================== 游戏设置 ====================

## 滚动速度 (1.0 - 10.0)
var scroll_speed: float = 1.0

## 判定偏移（毫秒）
var judge_offset: float = 0.0

## 是否显示调试信息
var show_debug: bool = false

## ==================== 显示设置 ====================

## 是否全屏
var fullscreen: bool = false

## 分辨率宽度
var resolution_width: int = 1280

## 分辨率高度
var resolution_height: int = 720

## ==================== 皮肤设置 ====================

## 当前皮肤名称
var current_skin: String = "default"

## ==================== 方法 ====================

## 保存设置到配置文件
func save_settings() -> void:
	var config = ConfigFile.new()

	# 音频设置
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("audio", "audio_offset", audio_offset)
	config.set_value("audio", "buffer_size", buffer_size)
	config.set_value("audio", "audio_output_device", audio_output_device)
	config.set_value("audio", "audio_latency_result", audio_latency_result)

	# 游戏设置
	config.set_value("game", "scroll_speed", scroll_speed)
	config.set_value("game", "judge_offset", judge_offset)
	config.set_value("game", "show_debug", show_debug)

	# 显示设置
	config.set_value("display", "fullscreen", fullscreen)
	config.set_value("display", "resolution_width", resolution_width)
	config.set_value("display", "resolution_height", resolution_height)

	# 皮肤设置
	config.set_value("game", "current_skin", current_skin)

	# 保存到文件
	var error = config.save("user://settings.cfg")
	if error != OK:
		push_warning("[Settings] Failed to save settings: %d" % error)


## 从配置文件加载设置
func load_settings() -> void:
	var config = ConfigFile.new()

	if config.load("user://settings.cfg") != OK:
		# 配置文件不存在，使用默认值
		return

	# 音频设置
	master_volume = config.get_value("audio", "master_volume", 1.0)
	music_volume = config.get_value("audio", "music_volume", 1.0)
	sfx_volume = config.get_value("audio", "sfx_volume", 1.0)
	audio_offset = config.get_value("audio", "audio_offset", 0.0)
	buffer_size = config.get_value("audio", "buffer_size", 512)
	audio_output_device = config.get_value("audio", "audio_output_device", "")
	audio_latency_result = config.get_value("audio", "audio_latency_result", 0.0)

	# 游戏设置
	scroll_speed = config.get_value("game", "scroll_speed", 1.0)
	judge_offset = config.get_value("game", "judge_offset", 0.0)
	show_debug = config.get_value("game", "show_debug", false)

	# 显示设置
	fullscreen = config.get_value("display", "fullscreen", false)
	resolution_width = config.get_value("display", "resolution_width", 1280)
	resolution_height = config.get_value("display", "resolution_height", 720)

	# 皮肤设置
	current_skin = config.get_value("game", "current_skin", "default")


## 重置所有设置为默认值
func reset_to_defaults() -> void:
	# 音频设置
	master_volume = 1.0
	music_volume = 1.0
	sfx_volume = 1.0
	audio_offset = 0.0
	buffer_size = 512  # 默认缓冲区大小（样本数）
	audio_output_device = ""
	audio_latency_result = 0.0

	# 游戏设置
	scroll_speed = 1.0
	judge_offset = 0.0
	show_debug = false

	# 显示设置
	fullscreen = false
	resolution_width = 1280
	resolution_height = 720

	# 皮肤设置
	current_skin = "default"


## 应用音频设置到音频总线
func apply_audio_settings() -> void:
	# 设置主音量总线
	var master_bus = AudioServer.get_bus_index("Master")
	if master_bus >= 0:
		AudioServer.set_bus_volume_db(master_bus, linear_to_db(master_volume))

	# 设置音乐音量总线
	var music_bus = AudioServer.get_bus_index("Music")
	if music_bus >= 0:
		AudioServer.set_bus_volume_db(music_bus, linear_to_db(music_volume))

	# 设置音效音量总线
	var sfx_bus = AudioServer.get_bus_index("SFX")
	if sfx_bus >= 0:
		AudioServer.set_bus_volume_db(sfx_bus, linear_to_db(sfx_volume))


## 应用显示设置
func apply_display_settings() -> void:
	# 设置全屏模式
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(Vector2i(resolution_width, resolution_height))


## 初始化
func _ready() -> void:
	load_settings()
	apply_audio_settings()
	apply_display_settings()