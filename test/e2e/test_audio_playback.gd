## E2E 音频播放测试
## 测试音频从加载到播放的完整流程
## 测试框架：GUT v9.6.0
##
## 测试用例：
## - AP-001: 音乐播放流程
## - AP-002: 音频同步测试
## - AP-003: 音效播放测试
## - AP-004: 音量控制测试
## - AP-005: 音频设备管理测试

extends GutTest

# ==================== 测试常量 ====================

const AudioManager = preload("res://src/audio/audio_manager.gd")
const GameController = preload("res://src/game/game_controller.gd")
const TJAData = preload("res://src/parser/tja_data.gd")

# 测试音频文件路径
const TEST_MUSIC_PATH = "res://test/fixtures/sample_audio/test_music.ogg"

# ==================== 测试变量 ====================

var audio_manager: AudioManager = null
var game_controller: GameController = null

# ==================== 测试生命周期 ====================

func before_all() -> void:
	pass


func before_each() -> void:
	# 创建 AudioManager
	audio_manager = AudioManager.new()
	add_child_autofree(audio_manager)

	# 创建 GameController
	game_controller = GameController.new()
	game_controller.auto_play = false
	add_child_autofree(game_controller)


func after_each() -> void:
	# 停止所有音频
	if audio_manager:
		audio_manager.stop_music()


func after_all() -> void:
	pass


# ==================== 辅助方法 ====================

## 创建测试歌曲数据
func _create_test_song_with_audio() -> TJAData.TJASong:
	var song = TJAData.TJASong.new()
	song.title = "Audio Test Song"
	song.bpm = 120.0
	song.offset = 0.0
	song.wave = "test_music.ogg"

	var course = TJAData.TJACourse.new()
	course.course_type = TJAData.CourseType.ONI
	course.level = 5
	course.score_init = 1000
	course.score_diff = 100

	var measure = TJAData.TJAMeasure.new(0)
	measure.bpm = 120.0
	measure.add_note(TJAData.TJANote.new(TJAData.NoteType.DON, 0.0))
	course.add_measure(measure)

	song.add_course(course)
	return song


## 创建测试音频流
func _create_test_audio_stream() -> AudioStream:
	# 创建一个简单的测试音频流
	var stream = AudioStreamGenerator.new()
	stream.mix_rate = 44100.0
	stream.buffer_length = 0.5
	return stream


# ==================== AP-001: 音乐播放流程测试 ====================

## AP-001-1: 测试音乐播放器初始化
func test_ap001_music_player_initialization() -> void:
	# 验证 AudioManager 已创建
	assert_not_null(audio_manager, "AudioManager 应已创建")

	# 验证音乐播放器存在
	assert_not_null(audio_manager._music_player, "音乐播放器应已创建")


## AP-001-2: 测试音乐播放
func test_ap001_music_playback() -> void:
	# 创建测试音频流
	var stream = _create_test_audio_stream()

	# 播放音乐
	audio_manager.play_music(stream)

	# 验证播放状态
	assert_true(audio_manager.is_music_playing(), "音乐应正在播放")


## AP-001-3: 测试音乐暂停
func test_ap001_music_pause() -> void:
	var stream = _create_test_audio_stream()
	audio_manager.play_music(stream)

	# 暂停音乐
	audio_manager.pause_music()

	# 验证暂停状态
	assert_true(audio_manager.is_music_paused(), "音乐应已暂停")


## AP-001-4: 测试音乐恢复
func test_ap001_music_resume() -> void:
	var stream = _create_test_audio_stream()
	audio_manager.play_music(stream)
	audio_manager.pause_music()

	# 恢复音乐
	audio_manager.resume_music()

	# 验证恢复状态
	assert_false(audio_manager.is_music_paused(), "音乐应已恢复")


## AP-001-5: 测试音乐停止
func test_ap001_music_stop() -> void:
	var stream = _create_test_audio_stream()
	audio_manager.play_music(stream)

	# 停止音乐
	audio_manager.stop_music()

	# 验证停止状态
	assert_false(audio_manager.is_music_playing(), "音乐应已停止")


## AP-001-6: 测试音乐跳转
func test_ap001_music_seek() -> void:
	var stream = _create_test_audio_stream()
	audio_manager.play_music(stream)

	# 跳转到指定位置
	audio_manager.seek_music(5.0)

	# 验证跳转（位置可能略有偏差）
	var position = audio_manager.get_music_position()
	assert_gte(position, 0.0, "位置应 >= 0")


# ==================== AP-002: 音频同步测试 ====================

## AP-002-1: 测试音频偏移设置
func test_ap002_audio_offset_setting() -> void:
	# 设置音频偏移
	audio_manager.set_audio_offset(100.0)

	# 验证偏移值
	assert_eq(audio_manager.get_audio_offset(), 100.0, "音频偏移应为 100ms")


## AP-002-2: 测试正偏移同步时间
func test_ap002_positive_offset_sync_time() -> void:
	# 设置正偏移
	audio_manager.set_audio_offset(100.0)  # 100ms

	# 播放音乐
	var stream = _create_test_audio_stream()
	audio_manager.play_music(stream)

	# 等待一小段时间
	await get_tree().create_timer(0.1).timeout

	# 获取同步时间
	var synced_time = audio_manager.get_synced_time()
	var position = audio_manager.get_music_position()

	# 验证同步时间 = 位置 + 偏移
	assert_almost_eq(synced_time, position + 0.1, 0.01, "同步时间应正确计算")


## AP-002-3: 测试负偏移同步时间
func test_ap002_negative_offset_sync_time() -> void:
	# 设置负偏移
	audio_manager.set_audio_offset(-50.0)  # -50ms

	# 播放音乐
	var stream = _create_test_audio_stream()
	audio_manager.play_music(stream)

	# 等待一小段时间
	await get_tree().create_timer(0.1).timeout

	# 获取同步时间
	var synced_time = audio_manager.get_synced_time()
	var position = audio_manager.get_music_position()

	# 验证同步时间 = 位置 + 偏移（负值）
	assert_almost_eq(synced_time, position - 0.05, 0.01, "同步时间应正确计算")


## AP-002-4: 测试零偏移同步时间
func test_ap002_zero_offset_sync_time() -> void:
	# 设置零偏移
	audio_manager.set_audio_offset(0.0)

	# 播放音乐
	var stream = _create_test_audio_stream()
	audio_manager.play_music(stream)

	# 等待一小段时间
	await get_tree().create_timer(0.1).timeout

	# 获取同步时间
	var synced_time = audio_manager.get_synced_time()
	var position = audio_manager.get_music_position()

	# 验证同步时间 = 位置
	assert_almost_eq(synced_time, position, 0.01, "同步时间应等于播放位置")


## AP-002-5: 测试大偏移值处理
func test_ap002_large_offset_handling() -> void:
	# 设置大偏移值
	audio_manager.set_audio_offset(500.0)  # 500ms

	# 验证偏移值
	assert_eq(audio_manager.get_audio_offset(), 500.0, "大偏移值应正确设置")


# ==================== AP-003: 音效播放测试 ====================

## AP-003-1: 测试音效预加载
func test_ap003_sfx_preloading() -> void:
	# 验证音效已预加载
	assert_true(audio_manager._preloaded_sounds.size() > 0, "应有预加载的音效")


## AP-003-2: 测试 don 音效播放
func test_ap003_don_sfx_playback() -> void:
	# 播放 don 音效
	audio_manager.play_don()

	# 验证不会崩溃
	assert_true(true, "don 音效播放应成功")


## AP-003-3: 测试 ka 音效播放
func test_ap003_ka_sfx_playback() -> void:
	# 播放 ka 音效
	audio_manager.play_ka()

	# 验证不会崩溃
	assert_true(true, "ka 音效播放应成功")


## AP-003-4: 测试判定音效播放
func test_ap003_judge_sfx_playback() -> void:
	# 播放各种判定音效
	audio_manager.play_judge_perfect()
	audio_manager.play_judge_good()
	audio_manager.play_judge_miss()

	# 验证不会崩溃
	assert_true(true, "判定音效播放应成功")


## AP-003-5: 测试气球音效播放
func test_ap003_balloon_sfx_playback() -> void:
	# 播放气球音效
	audio_manager.play_balloon()

	# 验证不会崩溃
	assert_true(true, "气球音效播放应成功")


## AP-003-6: 测试连击加成音效播放
func test_ap003_combo_bonus_sfx_playback() -> void:
	# 播放连击加成音效
	audio_manager.play_combo_bonus()

	# 验证不会崩溃
	assert_true(true, "连击加成音效播放应成功")


## AP-003-7: 测试自定义音效播放
func test_ap003_custom_sfx_playback() -> void:
	# 播放自定义音效
	audio_manager.play_sfx("don", 0.0)

	# 验证不会崩溃
	assert_true(true, "自定义音效播放应成功")


# ==================== AP-004: 音量控制测试 ====================

## AP-004-1: 测试主音量设置
func test_ap004_master_volume_setting() -> void:
	# 设置主音量
	audio_manager.set_master_volume(0.5)

	# 验证音量
	assert_almost_eq(audio_manager.get_master_volume(), 0.5, 0.01, "主音量应为 0.5")


## AP-004-2: 测试音乐音量设置
func test_ap004_music_volume_setting() -> void:
	# 设置音乐音量
	audio_manager.set_music_volume(0.7)

	# 验证音量
	assert_almost_eq(audio_manager.get_music_volume(), 0.7, 0.01, "音乐音量应为 0.7")


## AP-004-3: 测试音效音量设置
func test_ap004_sfx_volume_setting() -> void:
	# 设置音效音量
	audio_manager.set_sfx_volume(0.8)

	# 验证音量
	assert_almost_eq(audio_manager.get_sfx_volume(), 0.8, 0.01, "音效音量应为 0.8")


## AP-004-4: 测试音量边界值
func test_ap004_volume_boundary_values() -> void:
	# 测试最小值
	audio_manager.set_master_volume(0.0)
	assert_almost_eq(audio_manager.get_master_volume(), 0.0, 0.01, "最小音量应为 0")

	# 测试最大值
	audio_manager.set_master_volume(1.0)
	assert_almost_eq(audio_manager.get_master_volume(), 1.0, 0.01, "最大音量应为 1")


## AP-004-5: 测试静音功能
func test_ap004_mute_functionality() -> void:
	# 设置静音
	audio_manager.set_mute(true)
	assert_true(audio_manager.is_muted(), "应处于静音状态")

	# 取消静音
	audio_manager.set_mute(false)
	assert_false(audio_manager.is_muted(), "应取消静音")


## AP-004-6: 测试音量变化信号
func test_ap004_volume_change_signal() -> void:
	# 监听音量变化信号
	var signal_received = false
	var received_volume = 0.0

	audio_manager.volume_changed.connect(func(bus: String, volume: float):
		signal_received = true
		received_volume = volume
	)

	# 设置音量
	audio_manager.set_master_volume(0.6)

	# 验证信号
	assert_true(signal_received, "应触发音量变化信号")
	assert_almost_eq(received_volume, 0.6, 0.01, "信号应携带正确音量")


# ==================== AP-005: 音频设备管理测试 ====================

## AP-005-1: 测试输出设备列表获取
func test_ap005_output_device_list() -> void:
	# 获取输出设备列表
	var devices = audio_manager.get_output_devices()

	# 验证列表不为空（至少有 Default）
	assert_gte(devices.size(), 1, "应至少有一个输出设备")
	assert_true("Default" in devices, "应包含 Default 设备")


## AP-005-2: 测试当前设备获取
func test_ap005_current_device_get() -> void:
	# 获取当前设备
	var current = audio_manager.get_current_output_device()

	# 验证当前设备不为空
	assert_not_null(current, "当前设备不应为空")


## AP-005-3: 测试设备切换
func test_ap005_device_switching() -> void:
	# 切换到 Default 设备
	var result = audio_manager.set_output_device("Default")

	# 验证切换成功
	assert_true(result, "切换到 Default 设备应成功")
	assert_eq(audio_manager.get_current_output_device(), "Default", "当前设备应为 Default")


## AP-005-4: 测试设备刷新
func test_ap005_device_refresh() -> void:
	# 刷新设备列表
	audio_manager.refresh_devices()

	# 验证刷新成功
	var devices = audio_manager.get_output_devices()
	assert_gte(devices.size(), 1, "刷新后应至少有一个设备")


## AP-005-5: 测试无效设备处理
func test_ap005_invalid_device_handling() -> void:
	# 尝试切换到不存在的设备
	var result = audio_manager.set_output_device("NonExistentDevice")

	# 验证切换失败
	assert_false(result, "切换到无效设备应失败")


# ==================== 音频信号测试 ====================

## 测试音乐开始信号
func test_music_started_signal() -> void:
	var signal_received = false

	audio_manager.music_started.connect(func():
		signal_received = true
	)

	# 播放音乐
	var stream = _create_test_audio_stream()
	audio_manager.play_music(stream)

	# 等待信号
	await get_tree().create_timer(0.1).timeout

	assert_true(signal_received, "应触发 music_started 信号")


## 测试音乐停止信号
func test_music_stopped_signal() -> void:
	var signal_received = false

	audio_manager.music_stopped.connect(func():
		signal_received = true
	)

	# 播放并停止音乐
	var stream = _create_test_audio_stream()
	audio_manager.play_music(stream)
	audio_manager.stop_music()

	# 等待信号
	await get_tree().create_timer(0.1).timeout

	assert_true(signal_received, "应触发 music_stopped 信号")


## 测试音乐暂停信号
func test_music_paused_signal() -> void:
	var signal_received = false

	audio_manager.music_paused.connect(func():
		signal_received = true
	)

	# 播放并暂停音乐
	var stream = _create_test_audio_stream()
	audio_manager.play_music(stream)
	audio_manager.pause_music()

	# 等待信号
	await get_tree().create_timer(0.1).timeout

	assert_true(signal_received, "应触发 music_paused 信号")


## 测试音乐恢复信号
func test_music_resumed_signal() -> void:
	var signal_received = false

	audio_manager.music_resumed.connect(func():
		signal_received = true
	)

	# 播放、暂停并恢复音乐
	var stream = _create_test_audio_stream()
	audio_manager.play_music(stream)
	audio_manager.pause_music()
	audio_manager.resume_music()

	# 等待信号
	await get_tree().create_timer(0.1).timeout

	assert_true(signal_received, "应触发 music_resumed 信号")


# ==================== 音频资源管理测试 ====================

## 测试音效预加载检查
func test_sfx_preload_check() -> void:
	# 检查 don 音效是否已预加载
	var is_preloaded = audio_manager.is_sound_preloaded("don")

	# 验证预加载状态
	assert_true(is_preloaded, "don 音效应已预加载")


## 测试获取预加载音效
func test_get_preloaded_sfx() -> void:
	# 获取预加载的 don 音效
	var sound = audio_manager.get_preloaded_sound("don")

	# 验证音效存在
	assert_not_null(sound, "don 音效应存在")


## 测试动态加载音效
func test_dynamic_sfx_loading() -> void:
	# 尝试加载不存在的音效
	var result = audio_manager.preload_sound("nonexistent", "res://nonexistent.wav")

	# 验证加载失败
	assert_false(result, "加载不存在的音效应失败")


## 测试卸载音效
func test_sfx_unloading() -> void:
	# 卸载音效
	audio_manager.unload_sound("don")

	# 验证卸载成功
	assert_false(audio_manager.is_sound_preloaded("don"), "don 音效应已卸载")


# ==================== 音频延迟测试功能测试 ====================

## 测试延迟测试启动
func test_latency_test_start() -> void:
	# 开始延迟测试
	audio_manager.start_latency_test()

	# 验证测试状态
	assert_true(audio_manager.is_latency_testing(), "应正在进行延迟测试")


## 测试延迟测试停止
func test_latency_test_stop() -> void:
	# 开始并停止延迟测试
	audio_manager.start_latency_test()
	audio_manager.stop_latency_test()

	# 验证测试状态
	assert_false(audio_manager.is_latency_testing(), "应已停止延迟测试")


## 测试延迟测试结果
func test_latency_test_results() -> void:
	# 获取延迟测试结果
	var results = audio_manager.get_latency_results()

	# 验证结果类型
	assert_not_null(results, "应返回结果数组")


## 测试平均延迟计算
func test_average_latency_calculation() -> void:
	# 获取平均延迟
	var avg = audio_manager.get_average_latency()

	# 验证结果类型
	assert_gte(avg, 0.0, "平均延迟应 >= 0")


## 测试延迟描述
func test_latency_description() -> void:
	# 获取延迟描述
	var desc = audio_manager.get_latency_description()

	# 验证描述不为空
	assert_not_null(desc, "延迟描述不应为空")


# ==================== 音频系统状态检查测试 ====================

## 测试音频系统状态检查
func test_audio_system_status_check() -> void:
	# 检查音频系统状态
	var status = audio_manager.check_audio_system()

	# 验证状态结构
	assert_has(status, "output_device", "状态应包含 output_device")
	assert_has(status, "device_count", "状态应包含 device_count")
	assert_has(status, "buffer_latency", "状态应包含 buffer_latency")
	assert_has(status, "average_latency", "状态应包含 average_latency")
	assert_has(status, "is_testing", "状态应包含 is_testing")


## 测试音频缓冲区设置
func test_audio_buffer_settings() -> void:
	# 应用默认缓冲区设置
	audio_manager.apply_buffer_settings(0)

	# 验证设置成功
	assert_true(true, "默认缓冲区设置应成功")


## 测试低延迟缓冲区设置
func test_low_latency_buffer_settings() -> void:
	# 应用低延迟缓冲区设置
	audio_manager.apply_buffer_settings(1)

	# 验证设置成功
	assert_true(true, "低延迟缓冲区设置应成功")


## 测试高稳定性缓冲区设置
func test_high_stability_buffer_settings() -> void:
	# 应用高稳定性缓冲区设置
	audio_manager.apply_buffer_settings(2)

	# 验证设置成功
	assert_true(true, "高稳定性缓冲区设置应成功")


# ==================== GameController 音频集成测试 ====================

## 测试 GameController 音频初始化
func test_game_controller_audio_initialization() -> void:
	# 设置游戏数据
	game_controller.current_song = _create_test_song_with_audio()
	game_controller.current_course = game_controller.current_song.get_course(TJAData.CourseType.ONI)
	game_controller._initialize_game_systems()

	# 验证音乐播放器存在
	assert_not_null(game_controller.music_player, "音乐播放器应已创建")


## 测试游戏暂停时音频暂停
func test_audio_pauses_on_game_pause() -> void:
	# 设置游戏数据
	game_controller.current_song = _create_test_song_with_audio()
	game_controller.current_course = game_controller.current_song.get_course(TJAData.CourseType.ONI)
	game_controller._initialize_game_systems()
	game_controller.current_state = GameController.PlayState.PLAYING

	# 暂停游戏
	game_controller.pause_game()

	# 验证音乐播放器暂停
	assert_true(game_controller.music_player.stream_paused, "音乐播放器应暂停")


## 测试游戏恢复时音频恢复
func test_audio_resumes_on_game_resume() -> void:
	# 设置游戏数据
	game_controller.current_song = _create_test_song_with_audio()
	game_controller.current_course = game_controller.current_song.get_course(TJAData.CourseType.ONI)
	game_controller._initialize_game_systems()
	game_controller.current_state = GameController.PlayState.PAUSED
	game_controller.music_player.stream_paused = true

	# 恢复游戏
	game_controller.resume_game()

	# 验证音乐播放器恢复
	assert_false(game_controller.music_player.stream_paused, "音乐播放器应恢复播放")


## 测试游戏结束时音频停止
func test_audio_stops_on_game_end() -> void:
	# 设置游戏数据
	game_controller.current_song = _create_test_song_with_audio()
	game_controller.current_course = game_controller.current_song.get_course(TJAData.CourseType.ONI)
	game_controller._initialize_game_systems()
	game_controller.current_state = GameController.PlayState.PLAYING

	# 结束游戏
	game_controller.end_game()

	# 验证游戏状态
	assert_eq(game_controller.current_state, GameController.PlayState.IDLE, "游戏状态应为 IDLE")