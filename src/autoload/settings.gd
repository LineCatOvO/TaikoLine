extends Node

## 设置管理
## 管理游戏设置

## 音量设置
var master_volume: float = 1.0
var music_volume: float = 1.0
var sfx_volume: float = 1.0

## 游戏设置
var scroll_speed: float = 1.0
var judge_offset: float = 0.0  ## 判定偏移（毫秒）
var show_debug: bool = false

## 皮肤设置
var current_skin: String = "default"

## 保存设置
func save_settings() -> void:
	var config = ConfigFile.new()
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("game", "scroll_speed", scroll_speed)
	config.set_value("game", "judge_offset", judge_offset)
	config.set_value("game", "show_debug", show_debug)
	config.set_value("game", "current_skin", current_skin)
	config.save("user://settings.cfg")

## 加载设置
func load_settings() -> void:
	var config = ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		master_volume = config.get_value("audio", "master_volume", 1.0)
		music_volume = config.get_value("audio", "music_volume", 1.0)
		sfx_volume = config.get_value("audio", "sfx_volume", 1.0)
		scroll_speed = config.get_value("game", "scroll_speed", 1.0)
		judge_offset = config.get_value("game", "judge_offset", 0.0)
		show_debug = config.get_value("game", "show_debug", false)
		current_skin = config.get_value("game", "current_skin", "default")

func _ready() -> void:
	load_settings()