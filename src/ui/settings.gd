## 设置界面
## 管理游戏设置，包括音频、游戏、显示、系统等选项
## 参考 Taiko no Tatsujin 设置界面设计风格
## 作者：TaikoLine Team
## 日期：2026-04-03

extends Control

## 信号
signal back_requested
signal settings_saved

## ==================== 常量定义 ====================

## 分辨率选项
const RESOLUTIONS = [
	{"name": "1280x720 (HD)", "width": 1280, "height": 720},
	{"name": "1600x900 (HD+)", "width": 1600, "height": 900},
	{"name": "1920x1080 (FHD)", "width": 1920, "height": 1080},
	{"name": "2560x1440 (QHD)", "width": 2560, "height": 1440},
	{"name": "3840x2160 (4K)", "width": 3840, "height": 2160},
]

## 音频缓冲区选项（样本数）
const BUFFER_SIZES = [
	{"name": "256 (Low Latency)", "value": 256},
	{"name": "512 (Default)", "value": 512},
	{"name": "1024 (Balanced)", "value": 1024},
	{"name": "2048 (High Stability)", "value": 2048},
]

## 标签页名称
const TAB_NAMES = ["Audio", "Game", "Display", "System"]

## 场景过渡动画时长
const TRANSITION_DURATION: float = 0.3

## 入场动画延迟间隔
const ENTER_ANIMATION_DELAY: float = 0.05

## ==================== UI 节点引用 ====================

## 背景
@onready var _background: Control = $Background

## 标签页按钮
@onready var _audio_tab: Button = $MainContainer/ContentContainer/TabContainer/AudioTab
@onready var _game_tab: Button = $MainContainer/ContentContainer/TabContainer/GameTab
@onready var _display_tab: Button = $MainContainer/ContentContainer/TabContainer/DisplayTab
@onready var _system_tab: Button = $MainContainer/ContentContainer/TabContainer/SystemTab

## 设置面板
@onready var _audio_settings: VBoxContainer = $MainContainer/ContentContainer/SettingsPanel/SettingsScrollContainer/SettingsContent/AudioSettings
@onready var _game_settings: VBoxContainer = $MainContainer/ContentContainer/SettingsPanel/SettingsScrollContainer/SettingsContent/GameSettings
@onready var _display_settings: VBoxContainer = $MainContainer/ContentContainer/SettingsPanel/SettingsScrollContainer/SettingsContent/DisplaySettings
@onready var _system_settings: VBoxContainer = $MainContainer/ContentContainer/SettingsPanel/SettingsScrollContainer/SettingsContent/SystemSettings

## 音频设置项
@onready var _master_volume_item: Control = $MainContainer/ContentContainer/SettingsPanel/SettingsScrollContainer/SettingsContent/AudioSettings/MasterVolumeItem
@onready var _music_volume_item: Control = $MainContainer/ContentContainer/SettingsPanel/SettingsScrollContainer/SettingsContent/AudioSettings/MusicVolumeItem
@onready var _sfx_volume_item: Control = $MainContainer/ContentContainer/SettingsPanel/SettingsScrollContainer/SettingsContent/AudioSettings/SFXVolumeItem

## 游戏设置项
@onready var _scroll_speed_item: Control = $MainContainer/ContentContainer/SettingsPanel/SettingsScrollContainer/SettingsContent/GameSettings/ScrollSpeedItem
@onready var _judge_offset_item: Control = $MainContainer/ContentContainer/SettingsPanel/SettingsScrollContainer/SettingsContent/GameSettings/JudgeOffsetItem

## 显示设置项
@onready var _fullscreen_item: Control = $MainContainer/ContentContainer/SettingsPanel/SettingsScrollContainer/SettingsContent/DisplaySettings/FullscreenItem
@onready var _resolution_item: Control = $MainContainer/ContentContainer/SettingsPanel/SettingsScrollContainer/SettingsContent/DisplaySettings/ResolutionItem

## 系统设置项
@onready var _audio_advanced_item: Control = $MainContainer/ContentContainer/SettingsPanel/SettingsScrollContainer/SettingsContent/SystemSettings/AudioAdvancedItem
@onready var _buffer_item: Control = $MainContainer/ContentContainer/SettingsPanel/SettingsScrollContainer/SettingsContent/SystemSettings/BufferItem
@onready var _audio_offset_item: Control = $MainContainer/ContentContainer/SettingsPanel/SettingsScrollContainer/SettingsContent/SystemSettings/AudioOffsetItem
@onready var _output_device_item: Control = $MainContainer/ContentContainer/SettingsPanel/SettingsScrollContainer/SettingsContent/SystemSettings/OutputDeviceItem
@onready var _latency_test_item: Control = $MainContainer/ContentContainer/SettingsPanel/SettingsScrollContainer/SettingsContent/SystemSettings/LatencyTestItem

## 底部栏
@onready var _back_btn: Button = $BottomBar/BottomHBox/BackBtn
@onready var _reset_btn: Button = $BottomBar/BottomHBox/ResetBtn
@onready var _save_btn: Button = $BottomBar/BottomHBox/SaveBtn

## 音效节点
@onready var _navigate_sound: AudioStreamPlayer = $NavigateSound
@onready var _confirm_sound: AudioStreamPlayer = $ConfirmSound

## ==================== 状态变量 ====================

## 当前标签页索引
var _current_tab: int = 0

## 标签页按钮数组
var _tab_buttons: Array

## 设置面板数组
var _settings_panels: Array

## 设置是否已修改
var _settings_modified: bool = false

## 是否已初始化
var _is_initialized: bool = false

## ==================== 初始化 ====================

func _ready() -> void:
	# 初始化数组
	_tab_buttons = [_audio_tab, _game_tab, _display_tab, _system_tab]
	_settings_panels = [_audio_settings, _game_settings, _display_settings, _system_settings]

	# 设置按钮组
	_setup_tab_buttons()

	# 初始化选项
	_setup_options()

	# 加载设置
	_load_settings()

	# 设置音效
	_setup_sounds()

	# 连接音频管理器信号
	_connect_audio_manager_signals()

	# 设置初始标签页
	_select_tab(0)

	# 标记已初始化
	_is_initialized = true

	# 播放入场动画
	_play_enter_animation()


## 设置标签页按钮组
func _setup_tab_buttons() -> void:
	var group = ButtonGroup.new()
	for btn in _tab_buttons:
		btn.button_group = group


## 初始化选项
func _setup_options() -> void:
	# 设置分辨率选项
	if _resolution_item:
		var resolution_options: Array[String] = []
		for res in RESOLUTIONS:
			resolution_options.append(res.name)
		_resolution_item.set_options(resolution_options)

	# 设置缓冲区选项
	if _buffer_item:
		var buffer_options: Array[String] = []
		for buf in BUFFER_SIZES:
			buffer_options.append(buf.name)
		_buffer_item.set_options(buffer_options)

	# 设置输出设备选项
	_setup_output_device_options()


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


## ==================== 入场动画 ====================

## 播放入场动画
func _play_enter_animation() -> void:
	# 背景入场动画
	if _background and _background.has_method("play_enter_animation"):
		_background.play_enter_animation()

	# 标签页入场动画
	for i in range(_tab_buttons.size()):
		var btn = _tab_buttons[i]
		if btn:
			btn.modulate.a = 0.0
			var tween = create_tween()
			tween.set_ease(Tween.EASE_OUT)
			tween.set_trans(Tween.TRANS_QUART)
			await get_tree().create_timer(i * ENTER_ANIMATION_DELAY).timeout
			tween.tween_property(btn, "modulate:a", 1.0, TRANSITION_DURATION)

	# 设置项入场动画
	await get_tree().create_timer(0.2).timeout
	_play_settings_enter_animation(_current_tab)


## 播放设置项入场动画
func _play_settings_enter_animation(tab_index: int) -> void:
	var panel = _settings_panels[tab_index]
	if not panel:
		return

	# 获取所有设置项
	var items = _get_settings_items(tab_index)
	for i in range(items.size()):
		var item = items[i]
		if item and item.has_method("play_enter_animation"):
			item.play_enter_animation(i * ENTER_ANIMATION_DELAY)


## 获取设置项列表
func _get_settings_items(tab_index: int) -> Array:
	var items: Array = []

	match tab_index:
		0:  # Audio
			items = [_master_volume_item, _music_volume_item, _sfx_volume_item]
		1:  # Game
			items = [_scroll_speed_item, _judge_offset_item]
		2:  # Display
			items = [_fullscreen_item, _resolution_item]
		3:  # System
			items = [_audio_advanced_item, _buffer_item, _audio_offset_item, _output_device_item, _latency_test_item]

	return items


## ==================== 标签页切换 ====================

## 选择标签页
func _select_tab(tab_index: int) -> void:
	if tab_index == _current_tab:
		return

	# 隐藏当前面板
	_settings_panels[_current_tab].visible = false

	# 更新标签页按钮状态
	for i in range(_tab_buttons.size()):
		var btn = _tab_buttons[i]
		if btn and btn.has_method("set_selected"):
			btn.set_selected(i == tab_index)

	# 显示新面板
	_current_tab = tab_index
	_settings_panels[_current_tab].visible = true

	# 播放入场动画
	_play_settings_enter_animation(tab_index)

	# 播放导航音效
	_play_navigate_sound()


## 标签页选中回调
func _on_tab_selected(tab_index: int) -> void:
	_select_tab(tab_index)


## ==================== 加载设置 ====================

## 加载设置
func _load_settings() -> void:
	# 音频设置
	if _master_volume_item:
		_master_volume_item.set_value(Settings.master_volume * 100)
	if _music_volume_item:
		_music_volume_item.set_value(Settings.music_volume * 100)
	if _sfx_volume_item:
		_sfx_volume_item.set_value(Settings.sfx_volume * 100)

	# 游戏设置
	if _scroll_speed_item:
		_scroll_speed_item.set_value(Settings.scroll_speed)
	if _judge_offset_item:
		_judge_offset_item.set_value(Settings.judge_offset)

	# 显示设置
	if _fullscreen_item:
		_fullscreen_item.set_value(float(Settings.fullscreen))
	if _resolution_item:
		_select_current_resolution()

	# 系统设置
	if _buffer_item:
		_select_current_buffer_size()
	if _audio_offset_item:
		_audio_offset_item.set_value(Settings.audio_offset)
	if _output_device_item:
		_select_current_output_device()


## 选择当前缓冲区大小
func _select_current_buffer_size() -> void:
	var current_size = Settings.buffer_size

	for i in range(BUFFER_SIZES.size()):
		if BUFFER_SIZES[i].value == current_size:
			if _buffer_item:
				_buffer_item.set_value(float(i))
			return

	# 默认选择 512
	for i in range(BUFFER_SIZES.size()):
		if BUFFER_SIZES[i].value == 512:
			if _buffer_item:
				_buffer_item.set_value(float(i))
			return


## 选择当前分辨率
func _select_current_resolution() -> void:
	var current_width = Settings.resolution_width
	var current_height = Settings.resolution_height

	for i in range(RESOLUTIONS.size()):
		if RESOLUTIONS[i].width == current_width and RESOLUTIONS[i].height == current_height:
			if _resolution_item:
				_resolution_item.set_value(float(i))
			return

	# 默认选择第一个
	if _resolution_item:
		_resolution_item.set_value(0.0)


## ==================== 设置项回调 ====================

## 主音量改变
func _on_master_volume_changed(value: float) -> void:
	Settings.master_volume = value / 100.0
	_apply_audio_settings()
	_settings_modified = true


## 音乐音量改变
func _on_music_volume_changed(value: float) -> void:
	Settings.music_volume = value / 100.0
	_apply_audio_settings()
	_settings_modified = true


## 音效音量改变
func _on_sfx_volume_changed(value: float) -> void:
	Settings.sfx_volume = value / 100.0
	_apply_audio_settings()
	_settings_modified = true


## 应用音频设置
func _apply_audio_settings() -> void:
	# 设置主音量总线
	var master_bus = AudioServer.get_bus_index("Master")
	if master_bus >= 0:
		AudioServer.set_bus_volume_db(master_bus, linear_to_db(Settings.master_volume))

	# 设置音乐音量总线
	var music_bus = AudioServer.get_bus_index("Music")
	if music_bus >= 0:
		AudioServer.set_bus_volume_db(music_bus, linear_to_db(Settings.music_volume))

	# 设置音效音量总线
	var sfx_bus = AudioServer.get_bus_index("SFX")
	if sfx_bus >= 0:
		AudioServer.set_bus_volume_db(sfx_bus, linear_to_db(Settings.sfx_volume))


## 滚动速度改变
func _on_scroll_speed_changed(value: float) -> void:
	Settings.scroll_speed = value
	_settings_modified = true


## 判定偏移改变
func _on_judge_offset_changed(value: float) -> void:
	Settings.judge_offset = value
	_settings_modified = true


## 全屏切换
func _on_fullscreen_changed(value: float) -> void:
	var is_fullscreen = bool(value)
	Settings.fullscreen = is_fullscreen

	if is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

	_settings_modified = true
	_play_navigate_sound()


## 分辨率选择
func _on_resolution_changed(value: float) -> void:
	var index = int(value)
	if index < 0 or index >= RESOLUTIONS.size():
		return

	var res = RESOLUTIONS[index]
	Settings.resolution_width = res.width
	Settings.resolution_height = res.height

	# 如果不是全屏模式，设置窗口大小
	if not Settings.fullscreen:
		DisplayServer.window_set_size(Vector2i(res.width, res.height))

	_settings_modified = true


## 音频高级选项按钮
func _on_audio_advanced_pressed(_value: float) -> void:
	# 切换到系统设置标签页
	_select_tab(3)
	_tab_buttons[3].button_pressed = true
	_play_confirm_sound()


## 缓冲区大小选择
func _on_buffer_changed(value: float) -> void:
	var index = int(value)
	if index < 0 or index >= BUFFER_SIZES.size():
		return

	Settings.buffer_size = BUFFER_SIZES[index].value
	_apply_buffer_settings()
	_settings_modified = true


## 应用缓冲区设置
func _apply_buffer_settings() -> void:
	# 应用缓冲区大小设置
	if _has_audio_manager():
		AudioManager.apply_buffer_settings(Settings.buffer_size)
	else:
		# 直接设置输出延迟
		var sample_rate = 44100
		var latency_ms = float(Settings.buffer_size) / float(sample_rate) * 1000.0
		ProjectSettings.set_setting("audio/driver/output_latency", latency_ms)


## 音频偏移改变
func _on_audio_offset_changed(value: float) -> void:
	Settings.audio_offset = value
	_settings_modified = true


## ==================== 输出设备相关 ====================

## 初始化输出设备选项
func _setup_output_device_options() -> void:
	if not _output_device_item:
		return

	var device_options: Array[String] = []

	# 检查 AudioManager 是否存在
	if not _has_audio_manager():
		device_options.append("Default")
		_output_device_item.set_options(device_options)
		return

	# 获取设备列表
	var devices = AudioManager.get_output_devices()
	for device in devices:
		device_options.append(device)

	_output_device_item.set_options(device_options)


## 连接音频管理器信号
func _connect_audio_manager_signals() -> void:
	if not _has_audio_manager():
		return

	# 连接设备列表更新信号
	if not AudioManager.output_devices_updated.is_connected(_on_output_devices_updated):
		AudioManager.output_devices_updated.connect(_on_output_devices_updated)

	# 连接延迟测试信号
	if not AudioManager.latency_test_started.is_connected(_on_latency_test_started):
		AudioManager.latency_test_started.connect(_on_latency_test_started)

	if not AudioManager.latency_test_completed.is_connected(_on_latency_test_completed):
		AudioManager.latency_test_completed.connect(_on_latency_test_completed)


## 检查 AudioManager 是否存在
func _has_audio_manager() -> bool:
	return get_tree().root.has_node("AudioManager")


## 输出设备列表更新回调
func _on_output_devices_updated(devices: Array[String]) -> void:
	if not _output_device_item:
		return

	var device_options: Array[String] = []
	for device in devices:
		device_options.append(device)
	_output_device_item.set_options(device_options)

	# 重新选择当前设备
	_select_current_output_device()


## 选择当前输出设备
func _select_current_output_device() -> void:
	if not _output_device_item:
		return

	var current_device = Settings.audio_output_device
	if current_device.is_empty():
		current_device = "Default"

	# 查找设备索引
	var options = _output_device_item.options
	for i in range(options.size()):
		if options[i] == current_device:
			_output_device_item.set_value(float(i))
			return

	# 默认选择第一个
	_output_device_item.set_value(0.0)


## 输出设备选择回调
func _on_output_device_changed(value: float) -> void:
	var index = int(value)
	if not _output_device_item or index < 0 or index >= _output_device_item.options.size():
		return

	var device_name = _output_device_item.options[index]
	Settings.audio_output_device = device_name if device_name != "Default" else ""

	# 应用设备设置
	if _has_audio_manager():
		AudioManager.set_output_device(device_name)

	_settings_modified = true


## ==================== 延迟测试相关 ====================

## 延迟测试按钮回调
func _on_latency_test_pressed(_value: float) -> void:
	if not _has_audio_manager():
		if _latency_test_item:
			_latency_test_item.set_description("AudioManager not available")
		return

	if AudioManager.is_latency_testing():
		# 停止测试
		AudioManager.stop_latency_test()
		if _latency_test_item:
			_latency_test_item.set_button_text("Start Test")
			_latency_test_item.set_description("Test cancelled")
		return

	# 开始测试
	AudioManager.start_latency_test()
	if _latency_test_item:
		_latency_test_item.set_button_text("Stop Test")
		_latency_test_item.set_description("Testing...")


## 延迟测试开始回调
func _on_latency_test_started() -> void:
	if _latency_test_item:
		_latency_test_item.set_description("Testing...")


## 延迟测试完成回调
func _on_latency_test_completed(latency_ms: float) -> void:
	if _latency_test_item:
		_latency_test_item.set_button_text("Start Test")
		_latency_test_item.set_description("Result: %.1f ms" % latency_ms)

	# 保存测试结果
	Settings.audio_latency_result = latency_ms
	_settings_modified = true

	# 显示详细结果
	if _has_audio_manager():
		var description = AudioManager.get_latency_description()
		print("[Audio Latency Test] %s" % description)


## ==================== 底部按钮 ====================

## 返回按钮
func _on_back_pressed() -> void:
	if _settings_modified:
		# 自动保存设置
		_save_settings()

	_play_confirm_sound()
	_change_scene("res://scenes/main.tscn")


## 重置按钮
func _on_reset_pressed() -> void:
	_reset_to_defaults()
	_play_confirm_sound()


## 保存按钮
func _on_save_pressed() -> void:
	_save_settings()
	_play_confirm_sound()


## 保存设置
func _save_settings() -> void:
	Settings.save_settings()
	_settings_modified = false
	settings_saved.emit()


## 重置为默认值
func _reset_to_defaults() -> void:
	# 音频设置
	Settings.master_volume = 1.0
	Settings.music_volume = 1.0
	Settings.sfx_volume = 1.0

	# 游戏设置
	Settings.scroll_speed = 1.0
	Settings.judge_offset = 0.0

	# 显示设置
	Settings.fullscreen = false
	Settings.resolution_width = 1280
	Settings.resolution_height = 720

	# 系统设置
	Settings.buffer_size = 512
	Settings.audio_offset = 0.0
	Settings.audio_output_device = ""
	Settings.audio_latency_result = 0.0

	# 重新加载 UI
	_load_settings()
	_apply_audio_settings()
	_apply_buffer_settings()

	# 应用窗口设置
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1280, 720))

	_settings_modified = true


## ==================== 场景切换 ====================

## 切换场景（带过渡动画）
func _change_scene(scene_path: String) -> void:
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "modulate:a", 0.0, TRANSITION_DURATION)

	await tween.finished
	get_tree().change_scene_to_file(scene_path)


## ==================== 音效播放 ====================

## 播放导航音效
func _play_navigate_sound() -> void:
	if _navigate_sound and _navigate_sound.stream:
		_navigate_sound.play()
	elif AudioManager:
		AudioManager.play_ui_navigate()


## 播放确认音效
func _play_confirm_sound() -> void:
	if _confirm_sound and _confirm_sound.stream:
		_confirm_sound.play()
	elif AudioManager:
		AudioManager.play_ui_confirm()


## ==================== 输入处理 ====================

## 输入处理（键盘导航）
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE:
				_on_back_pressed()
				get_viewport().set_input_as_handled()
			KEY_LEFT:
				_navigate_tab(-1)
				get_viewport().set_input_as_handled()
			KEY_RIGHT:
				_navigate_tab(1)
				get_viewport().set_input_as_handled()


## 导航标签页
func _navigate_tab(direction: int) -> void:
	var new_tab = _current_tab + direction
	if new_tab < 0:
		new_tab = _tab_buttons.size() - 1
	elif new_tab >= _tab_buttons.size():
		new_tab = 0

	_tab_buttons[new_tab].button_pressed = true
	_select_tab(new_tab)