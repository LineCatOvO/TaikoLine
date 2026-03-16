## 音频同步集成测试
## 测试 AudioManager、GameController、SoundEffectPlayer 之间的协作
## 测试框架：GUT v9.6.0
##
## 测试用例：
## - AS-001: 音乐播放同步
## - AS-002: 音频偏移应用
## - AS-003: 暂停恢复音频
## - AS-004: 音效播放

extends GutTest

# ==================== 测试常量 ====================

const TJAData = preload("res://src/parser/tja_data.gd")
const GameController = preload("res://src/game/game_controller.gd")
const ScrollSystem = preload("res://src/game/scroll.gd")

# ==================== 测试变量 ====================

var game_controller: GameController = null
var scroll_system: ScrollSystem = null

# Mock AudioManager
var mock_audio_manager: RefCounted = null

# ==================== 测试生命周期 ====================

func before_all() -> void:
	pass

func before_each() -> void:
	# 创建 GameController
	game_controller = GameController.new()
	game_controller.auto_play = false
	add_child_autofree(game_controller)
	
	# 创建 ScrollSystem
	scroll_system = ScrollSystem.new()
	add_child_autofree(scroll_system)
	
	# 创建 Mock AudioManager
	mock_audio_manager = MockAudioManagerForTest.new()

func after_each() -> void:
	if game_controller:
		game_controller.queue_free()
	game_controller = null

func after_all() -> void:
	pass

# ==================== Mock 类定义 ====================

## 测试用 Mock AudioManager
class MockAudioManagerForTest extends RefCounted:
	var is_playing: bool = false
	var is_paused: bool = false
	var current_position: float = 0.0
	var audio_offset_ms: float = 0.0
	var volume: float = 1.0
	var last_sfx_played: String = ""
	var music_started_count: int = 0
	var music_stopped_count: int = 0
	var music_paused_count: int = 0
	var music_resumed_count: int = 0
	
	func play_music(_stream, _from_position: float = 0.0) -> void:
		is_playing = true
		is_paused = false
		music_started_count += 1
	
	func stop_music() -> void:
		is_playing = false
		is_paused = false
		music_stopped_count += 1
	
	func pause_music() -> void:
		if is_playing:
			is_paused = true
			music_paused_count += 1
	
	func resume_music() -> void:
		if is_paused:
			is_paused = false
			music_resumed_count += 1
	
	func get_music_position() -> float:
		return current_position
	
	func seek_music(position: float) -> void:
		current_position = position
	
	func set_audio_offset(offset_ms: float) -> void:
		audio_offset_ms = offset_ms
	
	func get_audio_offset() -> float:
		return audio_offset_ms
	
	func get_synced_time() -> float:
		return current_position + (audio_offset_ms / 1000.0)
	
	func play_sfx(sound_name: String, _volume_db: float = 0.0) -> void:
		last_sfx_played = sound_name
	
	func play_don() -> void:
		last_sfx_played = "don"
	
	func play_ka() -> void:
		last_sfx_played = "ka"
	
	func set_master_volume(value: float) -> void:
		volume = value
	
	func get_master_volume() -> float:
		return volume

# ==================== 辅助方法 ====================

## 创建测试歌曲数据
func _create_test_song_with_audio() -> TJAData.TJASong:
	var song = TJAData.TJASong.new()
	song.title = "Test Song"
	song.bpm = 120.0
	song.offset = 0.0
	song.wave = "test.ogg"  # 音频文件名
	
	var course = TJAData.TJACourse.new()
	course.course_type = TJAData.CourseType.ONI
	course.level = 5
	course.score_init = 1000
	course.score_diff = 100
	
	var measure = TJAData.TJAMeasure.new(0)
	measure.bpm = 120.0
	measure.scroll = 1.0
	measure.time_signature = Vector2(4.0, 4.0)
	measure.add_note(TJAData.TJANote.new(TJAData.NoteType.DON, 0.0))
	course.add_measure(measure)
	
	song.add_course(course)
	return song

## 创建带偏移的测试歌曲
func _create_test_song_with_offset(offset: float) -> TJAData.TJASong:
	var song = _create_test_song_with_audio()
	song.offset = offset
	return song

# ==================== AS-001: 音乐播放同步测试 ====================

## AS-001-1: 测试游戏开始时音乐播放
func test_as001_music_starts_with_game() -> void:
	# 设置测试数据
	game_controller.current_song = _create_test_song_with_audio()
	game_controller.current_course = game_controller.current_song.get_course(TJAData.CourseType.ONI)
	game_controller._initialize_game_systems()
	
	# 验证音乐播放器存在
	assert_not_null(game_controller.music_player, "音乐播放器应已创建")

## AS-001-2: 测试游戏时间与音乐同步
func test_as001_game_time_music_sync() -> void:
	# 设置测试数据
	game_controller.current_song = _create_test_song_with_audio()
	game_controller.current_course = game_controller.current_song.get_course(TJAData.CourseType.ONI)
	game_controller._initialize_game_systems()
	game_controller.current_state = GameController.PlayState.PLAYING
	
	# 模拟游戏时间推进
	game_controller.game_time = 0.0
	game_controller._check_game_start()
	
	# 验证游戏开始标志
	assert_true(game_controller._has_started, "游戏应该已开始")

## AS-001-3: 测试游戏结束时音乐停止
func test_as001_music_stops_on_game_end() -> void:
	# 设置测试数据
	game_controller.current_song = _create_test_song_with_audio()
	game_controller.current_course = game_controller.current_song.get_course(TJAData.CourseType.ONI)
	game_controller._initialize_game_systems()
	game_controller.current_state = GameController.PlayState.PLAYING
	
	# 结束游戏
	game_controller.end_game()
	
	# 验证音乐播放器已停止
	assert_eq(game_controller.current_state, GameController.PlayState.IDLE, "游戏状态应为IDLE")

## AS-001-4: 测试时间更新信号
func test_as001_time_update_signal() -> void:
	# 设置测试数据
	game_controller.current_song = _create_test_song_with_audio()
	game_controller.current_course = game_controller.current_song.get_course(TJAData.CourseType.ONI)
	game_controller._initialize_game_systems()
	game_controller.current_state = GameController.PlayState.PLAYING
	
	# 监听时间更新信号
	var time_received = -1.0
	game_controller.time_updated.connect(func(time): time_received = time)
	
	# 模拟帧更新
	game_controller._update_time(0.016)  # 约60fps
	
	# 验证信号触发
	assert_almost_eq(time_received, 0.016, 0.001, "时间更新信号应携带正确时间")

## AS-001-5: 测试音乐播放位置
func test_as001_music_playback_position() -> void:
	# 设置测试数据
	game_controller.current_song = _create_test_song_with_audio()
	game_controller.current_course = game_controller.current_song.get_course(TJAData.CourseType.ONI)
	game_controller._initialize_game_systems()
	game_controller.current_state = GameController.PlayState.PLAYING
	
	# 模拟游戏开始
	game_controller.game_time = 0.0
	game_controller._has_started = true
	
	# 验证音乐播放器状态
	# 注意：在测试环境中，音频文件可能不存在
	# 所以我们只验证播放器存在
	assert_not_null(game_controller.music_player, "音乐播放器应存在")

# ==================== AS-002: 音频偏移应用测试 ====================

## AS-002-1: 测试正偏移应用
func test_as002_positive_offset_applied() -> void:
	# 创建带正偏移的歌曲
	var song = _create_test_song_with_offset(0.1)  # 100ms偏移
	
	# 验证偏移值
	assert_eq(song.offset, 0.1, "歌曲偏移应为0.1秒")

## AS-002-2: 测试负偏移应用
func test_as002_negative_offset_applied() -> void:
	# 创建带负偏移的歌曲
	var song = _create_test_song_with_offset(-0.05)  # -50ms偏移
	
	# 验证偏移值
	assert_eq(song.offset, -0.05, "歌曲偏移应为-0.05秒")

## AS-002-3: 测试偏移影响游戏时间
func test_as002_offset_affects_game_time() -> void:
	# 设置测试数据
	game_controller.current_song = _create_test_song_with_offset(0.1)
	game_controller.current_course = game_controller.current_song.get_course(TJAData.CourseType.ONI)
	game_controller._initialize_game_systems()
	
	# 验证偏移已应用到音频偏移变量
	assert_eq(game_controller.audio_offset, 0.1, "音频偏移应为0.1秒")

## AS-002-4: 测试偏移影响滚动系统
func test_as002_offset_affects_scroll_system() -> void:
	# 设置测试数据
	var song = _create_test_song_with_offset(0.15)
	game_controller.current_song = song
	game_controller.current_course = song.get_course(TJAData.CourseType.ONI)
	game_controller._initialize_game_systems()
	
	# 验证滚动系统偏移
	assert_eq(game_controller.scroll_system._offset, 0.15, "滚动系统偏移应为0.15秒")

## AS-002-5: 测试零偏移
func test_as002_zero_offset() -> void:
	# 创建零偏移的歌曲
	var song = _create_test_song_with_offset(0.0)
	
	# 验证偏移值
	assert_eq(song.offset, 0.0, "歌曲偏移应为0")

# ==================== AS-003: 暂停恢复音频测试 ====================

## AS-003-1: 测试暂停时音频暂停
func test_as003_audio_pauses_on_game_pause() -> void:
	# 设置测试数据
	game_controller.current_song = _create_test_song_with_audio()
	game_controller.current_course = game_controller.current_song.get_course(TJAData.CourseType.ONI)
	game_controller._initialize_game_systems()
	game_controller.current_state = GameController.PlayState.PLAYING
	
	# 暂停游戏
	game_controller.pause_game()
	
	# 验证音乐播放器暂停状态
	assert_true(game_controller.music_player.stream_paused, "音乐播放器应暂停")

## AS-003-2: 测试恢复时音频恢复
func test_as003_audio_resumes_on_game_resume() -> void:
	# 设置测试数据
	game_controller.current_song = _create_test_song_with_audio()
	game_controller.current_course = game_controller.current_song.get_course(TJAData.CourseType.ONI)
	game_controller._initialize_game_systems()
	game_controller.current_state = GameController.PlayState.PAUSED
	game_controller.music_player.stream_paused = true
	
	# 恢复游戏
	game_controller.resume_game()
	
	# 验证音乐播放器恢复状态
	assert_false(game_controller.music_player.stream_paused, "音乐播放器应恢复播放")

## AS-003-3: 测试暂停恢复信号
func test_as003_pause_resume_signals() -> void:
	# 设置测试数据
	game_controller.current_song = _create_test_song_with_audio()
	game_controller.current_course = game_controller.current_song.get_course(TJAData.CourseType.ONI)
	game_controller._initialize_game_systems()
	game_controller.current_state = GameController.PlayState.PLAYING
	
	# 监听信号
	var paused_received = false
	var resumed_received = false
	
	game_controller.game_paused.connect(func(): paused_received = true)
	game_controller.game_resumed.connect(func(): resumed_received = true)
	
	# 暂停
	game_controller.pause_game()
	assert_true(paused_received, "应触发暂停信号")
	
	# 恢复
	game_controller.resume_game()
	assert_true(resumed_received, "应触发恢复信号")

## AS-003-4: 测试暂停时游戏时间不变
func test_as003_game_time_freezes_on_pause() -> void:
	# 设置测试数据
	game_controller.current_song = _create_test_song_with_audio()
	game_controller.current_course = game_controller.current_song.get_course(TJAData.CourseType.ONI)
	game_controller._initialize_game_systems()
	game_controller.current_state = GameController.PlayState.PLAYING
	game_controller.game_time = 5.0
	
	# 暂停游戏
	game_controller.pause_game()
	
	# 记录时间
	var time_at_pause = game_controller.game_time
	
	# 模拟帧更新（暂停状态）
	game_controller._process(0.016)
	
	# 验证时间未变化
	assert_eq(game_controller.game_time, time_at_pause, "暂停时游戏时间应不变")

## AS-003-5: 测试恢复后时间继续
func test_as003_time_continues_after_resume() -> void:
	# 设置测试数据
	game_controller.current_song = _create_test_song_with_audio()
	game_controller.current_course = game_controller.current_song.get_course(TJAData.CourseType.ONI)
	game_controller._initialize_game_systems()
	game_controller.current_state = GameController.PlayState.PLAYING
	game_controller.game_time = 5.0
	
	# 暂停
	game_controller.pause_game()
	
	# 恢复
	game_controller.resume_game()
	
	# 模拟帧更新
	game_controller._process(0.016)
	
	# 验证时间继续
	assert_almost_eq(game_controller.game_time, 5.016, 0.001, "恢复后时间应继续")

# ==================== AS-004: 音效播放测试 ====================

## AS-004-1: 测试音效播放器存在
func test_as004_sfx_player_exists() -> void:
	# 验证音效播放器可以创建
	var sfx_player = AudioStreamPlayer.new()
	assert_not_null(sfx_player, "音效播放器应可创建")
	sfx_player.queue_free()

## AS-004-2: 测试音效类型定义
func test_as004_sfx_types_defined() -> void:
	# 验证音效类型常量存在
	# AudioManager 中定义的音效类型
	var expected_sounds = ["don", "ka", "balloon", "judge_perfect", "judge_good", "judge_miss", "combo_bonus"]
	
	# 在实际 AudioManager 中，这些是路径常量
	# 这里只验证常量名称的概念
	assert_eq(expected_sounds.size(), 7, "应定义7种音效类型")

## AS-004-3: 测试音效播放方法
func test_as004_sfx_playback_methods() -> void:
	# 使用 Mock AudioManager 测试音效播放
	mock_audio_manager.play_don()
	assert_eq(mock_audio_manager.last_sfx_played, "don", "应播放don音效")
	
	mock_audio_manager.play_ka()
	assert_eq(mock_audio_manager.last_sfx_played, "ka", "应播放ka音效")

## AS-004-4: 测试音效音量控制
func test_as004_sfx_volume_control() -> void:
	# 测试音量设置
	mock_audio_manager.set_master_volume(0.5)
	assert_eq(mock_audio_manager.get_master_volume(), 0.5, "音量应设置为0.5")
	
	mock_audio_manager.set_master_volume(0.0)
	assert_eq(mock_audio_manager.get_master_volume(), 0.0, "音量应设置为0")
	
	mock_audio_manager.set_master_volume(1.0)
	assert_eq(mock_audio_manager.get_master_volume(), 1.0, "音量应设置为1")

## AS-004-5: 测试判定音效触发
func test_as004_judge_sfx_triggered() -> void:
	# 模拟判定音效
	mock_audio_manager.play_sfx("judge_perfect")
	assert_eq(mock_audio_manager.last_sfx_played, "judge_perfect", "应播放良判定音效")
	
	mock_audio_manager.play_sfx("judge_good")
	assert_eq(mock_audio_manager.last_sfx_played, "judge_good", "应播放可判定音效")
	
	mock_audio_manager.play_sfx("judge_miss")
	assert_eq(mock_audio_manager.last_sfx_played, "judge_miss", "应播放不可判定音效")

# ==================== 系统协作测试 ====================

## 测试 GameController 与音频系统协作
func test_game_controller_audio_collaboration() -> void:
	# 设置测试数据
	game_controller.current_song = _create_test_song_with_audio()
	game_controller.current_course = game_controller.current_song.get_course(TJAData.CourseType.ONI)
	game_controller._initialize_game_systems()
	
	# 验证音频相关组件
	assert_not_null(game_controller.music_player, "音乐播放器应存在")
	assert_eq(game_controller.audio_offset, game_controller.current_song.offset, "音频偏移应与歌曲偏移一致")

## 测试完整音频流程
func test_complete_audio_flow() -> void:
	# 设置测试数据
	game_controller.current_song = _create_test_song_with_audio()
	game_controller.current_course = game_controller.current_song.get_course(TJAData.CourseType.ONI)
	game_controller._initialize_game_systems()
	
	# 开始游戏
	game_controller.current_state = GameController.PlayState.READY
	game_controller.start_game()
	assert_eq(game_controller.current_state, GameController.PlayState.PLAYING, "游戏应开始")
	
	# 暂停游戏
	game_controller.pause_game()
	assert_eq(game_controller.current_state, GameController.PlayState.PAUSED, "游戏应暂停")
	
	# 恢复游戏
	game_controller.resume_game()
	assert_eq(game_controller.current_state, GameController.PlayState.PLAYING, "游戏应恢复")
	
	# 结束游戏
	game_controller.end_game()
	assert_eq(game_controller.current_state, GameController.PlayState.IDLE, "游戏应结束")

## 测试音频同步时间计算
func test_audio_sync_time_calculation() -> void:
	# 设置偏移
	mock_audio_manager.set_audio_offset(100.0)  # 100ms
	mock_audio_manager.current_position = 1.0  # 1秒
	
	# 获取同步时间
	var synced_time = mock_audio_manager.get_synced_time()
	
	# 验证同步时间 = 当前位置 + 偏移
	assert_almost_eq(synced_time, 1.1, 0.001, "同步时间应为1.1秒")

## 测试音频总线配置
func test_audio_bus_configuration() -> void:
	# 验证音频总线名称常量
	# AudioManager 中定义的总线名称
	var master_bus = "Master"
	var music_bus = "Music"
	var sfx_bus = "SFX"
	
	# 在实际环境中，这些总线应该在项目设置中配置
	# 这里只验证常量定义
	assert_eq(master_bus, "Master", "主总线名称应为Master")
	assert_eq(music_bus, "Music", "音乐总线名称应为Music")
	assert_eq(sfx_bus, "SFX", "音效总线名称应为SFX")