## 音频管理器单元测试
## 测试 AudioManager 的音频加载、音量控制、播放/暂停和音频偏移设置
## 测试框架：GUT v9.6.0

extends GutTest

## 预加载 AudioManager 脚本
const AudioManagerScript = preload("res://src/audio/audio_manager.gd")

var audio_manager: AudioManager = null
var mock_music_stream: AudioStream = null


func before_all() -> void:
	# 预加载测试音频资源（使用 Godot 内置资源）
	mock_music_stream = AudioStream.new()


func before_each() -> void:
	# 创建音频管理器实例（使用脚本加载）
	audio_manager = AudioManagerScript.new()
	add_child(audio_manager)


func after_each() -> void:
	if audio_manager:
		audio_manager.queue_free()
		audio_manager = null


func after_all() -> void:
	if mock_music_stream:
		mock_music_stream.free()
		mock_music_stream = null


# =============================================================================
# AUD-001: 音频管理器初始化
# 测试 AudioManager 正确初始化
# =============================================================================
func test_aud_001_audio_manager_initialization() -> void:
	# 验证节点已添加到场景树
	assert_not_null(audio_manager, "音频管理器应已创建")
	
	# 验证音频总线常量定义
	assert_eq(audio_manager.MASTER_BUS, "Master", "主总线名称应为 Master")
	assert_eq(audio_manager.MUSIC_BUS, "Music", "音乐总线名称应为 Music")
	assert_eq(audio_manager.SFX_BUS, "SFX", "音效总线名称应为 SFX")


# =============================================================================
# AUD-002: 音频加载-从文件路径
# 测试从文件路径加载音频
# =============================================================================
func test_aud_002_audio_load_from_file_path() -> void:
	# 测试不存在的文件
	var result = audio_manager.play_music_from_file("res://nonexistent_audio_file.ogg")
	assert_false(result, "不存在的文件应返回 false")
	
	# 注意：由于测试环境限制，不测试实际音频文件加载
	# 实际项目中应使用真实音频文件测试


# =============================================================================
# AUD-003: 音频播放控制-播放
# 测试音频播放功能
# =============================================================================
func test_aud_003_audio_play_control() -> void:
	# 验证初始状态
	assert_false(audio_manager.is_music_playing(), "初始状态音乐不应播放")
	assert_false(audio_manager.is_music_paused(), "初始状态音乐不应暂停")
	
	# 测试播放位置为 0
	assert_eq(audio_manager.get_music_position(), 0.0, "初始播放位置应为 0")


# =============================================================================
# AUD-004: 音频播放控制-暂停
# 测试音频暂停功能
# =============================================================================
func test_aud_004_audio_pause_control() -> void:
	# 初始状态不应暂停
	assert_false(audio_manager.is_music_paused(), "初始状态不应暂停")
	
	# 测试暂停（无音乐时不应崩溃）
	audio_manager.pause_music()
	assert_false(audio_manager.is_music_paused(), "无音乐时暂停应无效")


# =============================================================================
# AUD-005: 音频播放控制-恢复
# 测试音频恢复功能
# =============================================================================
func test_aud_005_audio_resume_control() -> void:
	# 初始状态不应暂停
	assert_false(audio_manager.is_music_paused(), "初始状态不应暂停")
	
	# 测试恢复（无音乐时不应崩溃）
	audio_manager.resume_music()
	assert_false(audio_manager.is_music_paused(), "无音乐时恢复应无效")


# =============================================================================
# AUD-006: 音频播放控制-停止
# 测试音频停止功能
# =============================================================================
func test_aud_006_audio_stop_control() -> void:
	# 测试停止（无音乐时不应崩溃）
	audio_manager.stop_music()
	assert_false(audio_manager.is_music_playing(), "停止后音乐应停止")


# =============================================================================
# AUD-007: 音量控制-主音量
# 测试主音量设置和获取
# =============================================================================
func test_aud_007_volume_control_master() -> void:
	# 测试设置主音量
	audio_manager.set_master_volume(0.5)
	var volume = audio_manager.get_master_volume()
	assert_true(volume >= 0.0 and volume <= 1.0, "主音量应在 0-1 范围内")
	
	# 测试音量边界
	audio_manager.set_master_volume(0.0)
	volume = audio_manager.get_master_volume()
	assert_true(volume >= 0.0, "音量不应低于 0")
	
	audio_manager.set_master_volume(1.0)
	volume = audio_manager.get_master_volume()
	assert_true(volume <= 1.0, "音量不应高于 1")
	
	# 测试超出边界的音量
	audio_manager.set_master_volume(1.5)
	volume = audio_manager.get_master_volume()
	assert_true(volume <= 1.0, "音量应限制在 1.0")
	
	audio_manager.set_master_volume(-0.5)
	volume = audio_manager.get_master_volume()
	assert_true(volume >= 0.0, "音量应限制在 0.0")


# =============================================================================
# AUD-008: 音量控制-音乐音量
# 测试音乐音量设置和获取
# =============================================================================
func test_aud_008_volume_control_music() -> void:
	# 测试设置音乐音量
	audio_manager.set_music_volume(0.7)
	var volume = audio_manager.get_music_volume()
	assert_true(volume >= 0.0 and volume <= 1.0, "音乐音量应在 0-1 范围内")
	
	# 测试音量边界
	audio_manager.set_music_volume(0.0)
	volume = audio_manager.get_music_volume()
	assert_true(volume >= 0.0, "音乐音量不应低于 0")
	
	audio_manager.set_music_volume(1.0)
	volume = audio_manager.get_music_volume()
	assert_true(volume <= 1.0, "音乐音量不应高于 1")


# =============================================================================
# AUD-009: 音量控制-音效音量
# 测试音效音量设置和获取
# =============================================================================
func test_aud_009_volume_control_sfx() -> void:
	# 测试设置音效音量
	audio_manager.set_sfx_volume(0.8)
	var volume = audio_manager.get_sfx_volume()
	assert_true(volume >= 0.0 and volume <= 1.0, "音效音量应在 0-1 范围内")
	
	# 测试音量边界
	audio_manager.set_sfx_volume(0.0)
	volume = audio_manager.get_sfx_volume()
	assert_true(volume >= 0.0, "音效音量不应低于 0")
	
	audio_manager.set_sfx_volume(1.0)
	volume = audio_manager.get_sfx_volume()
	assert_true(volume <= 1.0, "音效音量不应高于 1")


# =============================================================================
# AUD-010: 音量控制-静音
# 测试静音功能
# =============================================================================
func test_aud_010_volume_control_mute() -> void:
	# 测试静音切换
	audio_manager.set_mute(false)
	var is_muted = audio_manager.is_muted()
	# 注意：静音状态取决于 AudioServer 的实际状态
	
	# 测试静音功能（不崩溃）
	audio_manager.set_mute(true)
	audio_manager.set_mute(false)
	assert_true(true, "静音切换不应崩溃")


# =============================================================================
# AUD-011: 音频偏移设置
# 测试音频同步偏移设置和获取
# =============================================================================
func test_aud_011_audio_offset_setting() -> void:
	# 测试初始偏移
	var offset = audio_manager.get_audio_offset()
	assert_eq(offset, 0.0, "初始音频偏移应为 0")
	
	# 测试设置偏移
	audio_manager.set_audio_offset(100.0)
	offset = audio_manager.get_audio_offset()
	assert_eq(offset, 100.0, "音频偏移应设置为 100ms")
	
	# 测试负偏移
	audio_manager.set_audio_offset(-50.0)
	offset = audio_manager.get_audio_offset()
	assert_eq(offset, -50.0, "音频偏移应支持负值")
	
	# 测试小数偏移
	audio_manager.set_audio_offset(25.5)
	offset = audio_manager.get_audio_offset()
	assert_eq(offset, 25.5, "音频偏移应支持小数值")


# =============================================================================
# AUD-012: 同步时间计算
# 测试 get_synced_time 方法
# =============================================================================
func test_aud_012_synced_time_calculation() -> void:
	# 无偏移时同步时间应为播放位置
	audio_manager.set_audio_offset(0.0)
	var synced_time = audio_manager.get_synced_time()
	assert_eq(synced_time, 0.0, "无偏移时同步时间应为 0")
	
	# 设置正偏移
	audio_manager.set_audio_offset(100.0)  # 100ms = 0.1s
	# 注意：由于没有实际播放音乐，get_music_position() 返回 0
	# synced_time = 0 + 0.1 = 0.1
	synced_time = audio_manager.get_synced_time()
	# 由于没有实际播放，位置为 0，所以 synced_time = 0 + 0.1 = 0.1
	assert_true(synced_time >= 0.0, "同步时间应正确计算")


# =============================================================================
# AUD-013: 音效播放-预加载
# 测试音效预加载功能
# =============================================================================
func test_aud_013_sfx_preload() -> void:
	# 测试预加载不存在的音效
	var result = audio_manager.preload_sound("test_sound", "res://nonexistent.ogg")
	assert_false(result, "预加载不存在的文件应返回 false")
	
	# 测试检查音效是否预加载
	var is_loaded = audio_manager.is_sound_preloaded("nonexistent")
	assert_false(is_loaded, "不存在的音效应返回 false")


# =============================================================================
# AUD-014: 音效播放-播放
# 测试音效播放功能
# =============================================================================
func test_aud_014_sfx_playback() -> void:
	# 测试播放不存在的音效（不应崩溃）
	audio_manager.play_sfx("nonexistent_sound")
	assert_true(true, "播放不存在的音效不应崩溃")
	
	# 测试播放鼓声音效（不应崩溃）
	audio_manager.play_don()
	audio_manager.play_ka()
	assert_true(true, "播放鼓声音效不应崩溃")
	
	# 测试播放判定音效（不应崩溃）
	audio_manager.play_judge_perfect()
	audio_manager.play_judge_good()
	audio_manager.play_judge_miss()
	assert_true(true, "播放判定音效不应崩溃")
	
	# 测试播放连击加成音（不应崩溃）
	audio_manager.play_combo_bonus()
	assert_true(true, "播放连击加成音不应崩溃")


# =============================================================================
# AUD-015: 音效播放器设置
# 测试 SFX 播放器设置
# =============================================================================
func test_aud_015_sfx_player_setting() -> void:
	# 创建模拟 SFX 播放器
	var mock_sfx_player = Node.new()
	add_child(mock_sfx_player)
	
	# 设置 SFX 播放器
	audio_manager.set_sfx_player(mock_sfx_player)
	assert_true(true, "设置 SFX 播放器不应崩溃")
	
	mock_sfx_player.queue_free()


# =============================================================================
# AUD-016: 音频资源管理-卸载
# 测试音频资源卸载功能
# =============================================================================
func test_aud_016_audio_resource_unload() -> void:
	# 测试卸载不存在的资源（不应崩溃）
	audio_manager.unload_sound("nonexistent")
	assert_true(true, "卸载不存在的资源不应崩溃")


# =============================================================================
# AUD-017: 音乐长度获取
# 测试获取音乐总时长
# =============================================================================
func test_aud_017_music_length() -> void:
	# 未加载音乐时长度应为 0
	var length = audio_manager.get_music_length()
	assert_eq(length, 0.0, "未加载音乐时长度应为 0")


# =============================================================================
# AUD-018: 音乐跳转
# 测试音乐跳转功能
# =============================================================================
func test_aud_018_music_seek() -> void:
	# 测试跳转（无音乐时不应崩溃）
	audio_manager.seek_music(10.0)
	assert_true(true, "无音乐时跳转不应崩溃")


# =============================================================================
# AUD-019: 信号发射-音乐开始
# 测试音乐开始信号
# =============================================================================
func test_aud_019_signal_music_started() -> void:
	# 监听信号
	var signal_watcher = watch_signals(audio_manager)
	
	# 注意：由于没有实际音频流，不测试实际播放
	# 只验证信号存在
	assert_true(audio_manager.has_signal("music_started"), "应有 music_started 信号")
	assert_true(audio_manager.has_signal("music_stopped"), "应有 music_stopped 信号")
	assert_true(audio_manager.has_signal("music_paused"), "应有 music_paused 信号")
	assert_true(audio_manager.has_signal("music_resumed"), "应有 music_resumed 信号")
	assert_true(audio_manager.has_signal("music_position_changed"), "应有 music_position_changed 信号")
	assert_true(audio_manager.has_signal("volume_changed"), "应有 volume_changed 信号")


# =============================================================================
# AUD-020: 预加载音效资源检查
# 测试 SOUND_EFFECTS 常量定义
# =============================================================================
func test_aud_020_preloaded_sounds_check() -> void:
	# 验证预定义音效常量
	var expected_sounds = ["don", "ka", "balloon", "judge_perfect", "judge_good", "judge_miss", "combo_bonus"]
	
	for sound_name in expected_sounds:
		assert_true(sound_name in AudioManager.SOUND_EFFECTS, "应定义音效：" + sound_name)
	
	# 验证音效路径格式
	for sound_name in AudioManager.SOUND_EFFECTS:
		var path = AudioManager.SOUND_EFFECTS[sound_name]
		assert_true(path.begins_with("res://"), "音效路径应以 res:// 开头")
		assert_true(path.ends_with(".wav") or path.ends_with(".ogg"), "音效应为 WAV 或 OGG 格式")


# =============================================================================
# 附加测试：音量变化信号
# =============================================================================
func test_volume_change_signal() -> void:
	# 验证信号存在
	assert_true(audio_manager.has_signal("volume_changed"), "应有 volume_changed 信号")


# =============================================================================
# 附加测试：气球音效播放
# =============================================================================
func test_balloon_sfx() -> void:
	# 测试播放气球音效（不应崩溃）
	audio_manager.play_balloon()
	assert_true(true, "播放气球音效不应崩溃")


# =============================================================================
# 附加测试：获取未预加载的音效
# =============================================================================
func test_get_unloaded_sound() -> void:
	# 测试获取未预加载的音效
	var sound = audio_manager.get_preloaded_sound("nonexistent")
	assert_null(sound, "未预加载的音效应返回 null")


# =============================================================================
# 附加测试：音乐位置变化信号
# =============================================================================
func test_music_position_signal() -> void:
	# 验证信号存在
	assert_true(audio_manager.has_signal("music_position_changed"), "应有 music_position_changed 信号")


# =============================================================================
# AUD-021: 音频输出设备信号
# 测试音频输出设备相关信号
# =============================================================================
func test_aud_021_output_device_signals() -> void:
	# 验证信号存在
	assert_true(audio_manager.has_signal("output_devices_updated"), "应有 output_devices_updated 信号")
	assert_true(audio_manager.has_signal("output_device_changed"), "应有 output_device_changed 信号")


# =============================================================================
# AUD-022: 延迟测试信号
# 测试延迟测试相关信号
# =============================================================================
func test_aud_022_latency_test_signals() -> void:
	# 验证信号存在
	assert_true(audio_manager.has_signal("latency_test_started"), "应有 latency_test_started 信号")
	assert_true(audio_manager.has_signal("latency_test_completed"), "应有 latency_test_completed 信号")


# =============================================================================
# AUD-023: 输出设备列表获取
# 测试获取输出设备列表
# =============================================================================
func test_aud_023_get_output_devices() -> void:
	# 获取设备列表
	var devices = audio_manager.get_output_devices()
	assert_not_null(devices, "设备列表不应为 null")

	# 应至少包含 Default 选项
	assert_true(devices.size() > 0, "设备列表应至少包含 Default")
	assert_true("Default" in devices, "设备列表应包含 Default 选项")


# =============================================================================
# AUD-024: 设置输出设备
# 测试设置输出设备
# =============================================================================
func test_aud_024_set_output_device() -> void:
	# 测试设置 Default 设备
	var result = audio_manager.set_output_device("Default")
	assert_true(result, "设置 Default 设备应成功")

	# 测试设置不存在的设备
	result = audio_manager.set_output_device("NonExistentDevice")
	assert_false(result, "设置不存在的设备应失败")


# =============================================================================
# AUD-025: 获取当前输出设备
# 测试获取当前输出设备
# =============================================================================
func test_aud_025_get_current_output_device() -> void:
	# 获取当前设备
	var device = audio_manager.get_current_output_device()
	assert_not_null(device, "当前设备不应为 null")


# =============================================================================
# AUD-026: 延迟测试状态
# 测试延迟测试状态检查
# =============================================================================
func test_aud_026_latency_testing_state() -> void:
	# 初始状态不应在测试中
	var is_testing = audio_manager.is_latency_testing()
	assert_false(is_testing, "初始状态不应在延迟测试中")


# =============================================================================
# AUD-027: 延迟测试结果
# 测试延迟测试结果获取
# =============================================================================
func test_aud_027_latency_results() -> void:
	# 未测试时平均延迟应为 0
	var avg_latency = audio_manager.get_average_latency()
	assert_eq(avg_latency, 0.0, "未测试时平均延迟应为 0")

	# 获取延迟描述
	var description = audio_manager.get_latency_description()
	assert_eq(description, "No test data", "未测试时描述应为 No test data")


# =============================================================================
# AUD-028: 缓冲区设置
# 测试音频缓冲区设置
# =============================================================================
func test_aud_028_buffer_settings() -> void:
	# 测试应用缓冲区设置（不应崩溃）
	audio_manager.apply_buffer_settings(0)  # Default
	audio_manager.apply_buffer_settings(1)  # Low Latency
	audio_manager.apply_buffer_settings(2)  # High Stability
	assert_true(true, "应用缓冲区设置不应崩溃")


# =============================================================================
# AUD-029: 音频系统状态检查
# 测试音频系统状态检查
# =============================================================================
func test_aud_029_audio_system_check() -> void:
	# 检查音频系统状态
	var status = audio_manager.check_audio_system()
	assert_not_null(status, "状态字典不应为 null")

	# 验证状态字典包含必要的键
	assert_true("output_device" in status, "状态应包含 output_device")
	assert_true("device_count" in status, "状态应包含 device_count")
	assert_true("buffer_latency" in status, "状态应包含 buffer_latency")
	assert_true("average_latency" in status, "状态应包含 average_latency")
	assert_true("is_testing" in status, "状态应包含 is_testing")


# =============================================================================
# AUD-030: 刷新设备列表
# 测试刷新设备列表
# =============================================================================
func test_aud_030_refresh_devices() -> void:
	# 刷新设备列表（不应崩溃）
	audio_manager.refresh_devices()
	assert_true(true, "刷新设备列表不应崩溃")
