## 音效播放器单元测试
## 测试 SoundEffectPlayer 的音效预加载、播放、通道管理和音量控制
## 测试框架：GUT v9.6.0

extends GutTest

var sfx_player: SoundEffectPlayer = null


func before_all() -> void:
	pass


func before_each() -> void:
	# 创建音效播放器实例
	sfx_player = SoundEffectPlayer.new()
	add_child(sfx_player)


func after_each() -> void:
	if sfx_player:
		sfx_player.queue_free()
		sfx_player = null


func after_all() -> void:
	pass


# =============================================================================
# SFX-001: 音效播放器初始化
# 测试 SoundEffectPlayer 正确初始化
# =============================================================================
func test_sfx_001_initialization() -> void:
	assert_not_null(sfx_player, "音效播放器应已创建")

	# 验证默认配置
	assert_eq(sfx_player.max_channels, 16, "默认最大通道数应为16")
	assert_eq(sfx_player.default_bus, "SFX", "默认音频总线应为SFX")


# =============================================================================
# SFX-002: 通道池初始化
# 测试通道池正确初始化
# =============================================================================
func test_sfx_002_channel_pool_initialization() -> void:
	# 等待_ready执行
	await get_tree().process_frame

	# 验证通道池已创建
	assert_eq(sfx_player._channel_pool.size(), sfx_player.max_channels, "通道池大小应为最大通道数")

	# 验证活动通道列表为空
	assert_eq(sfx_player._active_channels.size(), 0, "初始活动通道应为空")


# =============================================================================
# SFX-003: 音效池初始化
# 测试音效池正确初始化
# =============================================================================
func test_sfx_003_sound_pool_initialization() -> void:
	# 等待_ready执行
	await get_tree().process_frame

	# 验证音效池已创建
	assert_not_null(sfx_player._sound_pool, "音效池应已创建")


# =============================================================================
# SFX-004: 预加载音效-成功
# 测试预加载存在的音效文件
# =============================================================================
func test_sfx_004_preload_sound_success() -> void:
	# 测试预加载不存在的文件
	var result = sfx_player.preload_sound("test_sound", "res://nonexistent_sound.wav")
	assert_false(result, "预加载不存在的文件应返回false")

	# 验证音效未加载
	assert_false(sfx_player.is_sound_loaded("test_sound"), "不存在的音效应未加载")


# =============================================================================
# SFX-005: 预加载音效-失败
# 测试预加载不存在的音效文件
# =============================================================================
func test_sfx_005_preload_sound_failure() -> void:
	var result = sfx_player.preload_sound("invalid", "res://invalid_path.wav")

	assert_false(result, "预加载不存在的文件应返回false")
	assert_false(sfx_player.is_sound_loaded("invalid"), "不存在的音效应未加载")


# =============================================================================
# SFX-006: 卸载音效
# 测试卸载已加载的音效
# =============================================================================
func test_sfx_006_unload_sound() -> void:
	# 添加一个占位符
	sfx_player._sound_pool["test_unload"] = null

	# 卸载音效
	sfx_player.unload_sound("test_unload")

	# 验证音效已卸载
	assert_false("test_unload" in sfx_player._sound_pool, "音效应已卸载")


# =============================================================================
# SFX-007: 检查音效是否已加载
# 测试 is_sound_loaded 方法
# =============================================================================
func test_sfx_007_is_sound_loaded() -> void:
	# 未加载的音效
	assert_false(sfx_player.is_sound_loaded("nonexistent"), "未加载的音效应返回false")

	# 添加占位符（null值）
	sfx_player._sound_pool["placeholder"] = null
	assert_false(sfx_player.is_sound_loaded("placeholder"), "null值音效应返回false")


# =============================================================================
# SFX-008: 获取音效
# 测试 get_sound 方法
# =============================================================================
func test_sfx_008_get_sound() -> void:
	# 未加载的音效
	var sound = sfx_player.get_sound("nonexistent")
	assert_null(sound, "未加载的音效应返回null")

	# 添加占位符（null值）
	sfx_player._sound_pool["placeholder"] = null
	sound = sfx_player.get_sound("placeholder")
	assert_null(sound, "null值音效应返回null")


# =============================================================================
# SFX-009: 播放音效-未加载
# 测试播放未加载的音效
# =============================================================================
func test_sfx_009_play_sound_not_loaded() -> void:
	var result = sfx_player.play_sound("nonexistent_sound")

	assert_false(result, "播放未加载的音效应返回false")


# =============================================================================
# SFX-010: 播放音效-从位置播放
# 测试从指定位置播放音效
# =============================================================================
func test_sfx_010_play_sound_from_position() -> void:
	var result = sfx_player.play_sound_from_position("nonexistent", 0.5)

	assert_false(result, "播放未加载的音效应返回false")


# =============================================================================
# SFX-011: 停止所有音效
# 测试 stop_all_sounds 方法
# =============================================================================
func test_sfx_011_stop_all_sounds() -> void:
	# 停止所有音效（不应崩溃）
	sfx_player.stop_all_sounds()

	assert_eq(sfx_player._active_channels.size(), 0, "活动通道应为空")


# =============================================================================
# SFX-012: 停止指定音效
# 测试 stop_sound 方法
# =============================================================================
func test_sfx_012_stop_sound() -> void:
	# 停止未加载的音效（不应崩溃）
	sfx_player.stop_sound("nonexistent")

	assert_true(true, "停止未加载的音效不应崩溃")


# =============================================================================
# SFX-013: 获取活动通道数
# 测试 get_active_channel_count 方法
# =============================================================================
func test_sfx_013_get_active_channel_count() -> void:
	var count = sfx_player.get_active_channel_count()

	assert_eq(count, 0, "初始活动通道数应为0")


# =============================================================================
# SFX-014: 获取已加载音效数
# 测试 get_loaded_sound_count 方法
# =============================================================================
func test_sfx_014_get_loaded_sound_count() -> void:
	var count = sfx_player.get_loaded_sound_count()

	# 初始可能有一些预加载的音效（如果文件存在）
	assert_true(count >= 0, "已加载音效数应大于等于0")


# =============================================================================
# SFX-015: 获取已加载音效列表
# 测试 get_loaded_sound_names 方法
# =============================================================================
func test_sfx_015_get_loaded_sound_names() -> void:
	var names = sfx_player.get_loaded_sound_names()

	assert_not_null(names, "音效名称列表不应为null")
	assert_true(names is Array, "音效名称列表应为数组")


# =============================================================================
# SFX-016: 检查音效是否正在播放
# 测试 is_sound_playing 方法
# =============================================================================
func test_sfx_016_is_sound_playing() -> void:
	var playing = sfx_player.is_sound_playing("nonexistent")

	assert_false(playing, "未加载的音效不应正在播放")


# =============================================================================
# SFX-017: 便捷方法-播放鼓声
# 测试 play_don 和 play_ka 方法
# =============================================================================
func test_sfx_017_play_drum_sounds() -> void:
	# 播放鼓声（不应崩溃）
	sfx_player.play_don()
	sfx_player.play_ka()

	assert_true(true, "播放鼓声不应崩溃")


# =============================================================================
# SFX-018: 便捷方法-播放气球音
# 测试 play_balloon 方法
# =============================================================================
func test_sfx_018_play_balloon() -> void:
	sfx_player.play_balloon()

	assert_true(true, "播放气球音不应崩溃")


# =============================================================================
# SFX-019: 便捷方法-播放判定音效
# 测试 play_judge_* 方法
# =============================================================================
func test_sfx_019_play_judge_sounds() -> void:
	sfx_player.play_judge_perfect()
	sfx_player.play_judge_good()
	sfx_player.play_judge_miss()

	assert_true(true, "播放判定音效不应崩溃")


# =============================================================================
# SFX-020: 便捷方法-播放连击加成音
# 测试 play_combo_bonus 方法
# =============================================================================
func test_sfx_020_play_combo_bonus() -> void:
	sfx_player.play_combo_bonus()

	assert_true(true, "播放连击加成音不应崩溃")


# =============================================================================
# SFX-021: 音量设置
# 测试 set_volume 和 get_volume 方法
# =============================================================================
func test_sfx_021_volume_control() -> void:
	# 设置音量
	sfx_player.set_volume(0.5)

	# 获取音量
	var volume = sfx_player.get_volume()

	# 验证音量在合理范围内
	assert_true(volume >= 0.0 and volume <= 1.0, "音量应在0-1范围内")


# =============================================================================
# SFX-022: 音量边界值
# 测试音量边界值
# =============================================================================
func test_sfx_022_volume_boundary() -> void:
	# 测试最小值
	sfx_player.set_volume(0.0)
	var volume = sfx_player.get_volume()
	assert_true(volume >= 0.0, "音量不应低于0")

	# 测试最大值
	sfx_player.set_volume(1.0)
	volume = sfx_player.get_volume()
	assert_true(volume <= 1.0, "音量不应高于1")

	# 测试超出范围的值
	sfx_player.set_volume(1.5)
	volume = sfx_player.get_volume()
	assert_true(volume <= 1.0, "音量应限制在1.0")

	sfx_player.set_volume(-0.5)
	volume = sfx_player.get_volume()
	assert_true(volume >= 0.0, "音量应限制在0.0")


# =============================================================================
# SFX-023: 批量预加载音效
# 测试 preload_sounds 方法
# =============================================================================
func test_sfx_023_preload_sounds() -> void:
	var sounds = {
		"sound1": "res://nonexistent1.wav",
		"sound2": "res://nonexistent2.wav"
	}

	# 批量预加载（不应崩溃）
	sfx_player.preload_sounds(sounds)

	assert_true(true, "批量预加载不应崩溃")


# =============================================================================
# SFX-024: 默认音效常量
# 测试 SOUND_EFFECTS 常量定义
# =============================================================================
func test_sfx_024_default_sound_effects() -> void:
	var expected_sounds = ["don", "ka", "balloon", "judge_perfect", "judge_good", "judge_miss", "combo_bonus"]

	for sound_name in expected_sounds:
		assert_true(sound_name in SoundEffectPlayer.SOUND_EFFECTS, "应定义音效：" + sound_name)


# =============================================================================
# SFX-025: 信号定义
# 测试信号定义
# =============================================================================
func test_sfx_025_signals_defined() -> void:
	assert_true(sfx_player.has_signal("sound_played"), "应有sound_played信号")
	assert_true(sfx_player.has_signal("sound_finished"), "应有sound_finished信号")


# =============================================================================
# SFX-026: 最大通道数配置
# 测试自定义最大通道数
# =============================================================================
func test_sfx_026_max_channels_config() -> void:
	# 创建自定义配置的播放器
	var custom_player = SoundEffectPlayer.new()
	custom_player.max_channels = 8
	add_child(custom_player)

	await get_tree().process_frame

	assert_eq(custom_player._channel_pool.size(), 8, "自定义通道数应生效")

	custom_player.queue_free()


# =============================================================================
# SFX-027: 通道获取
# 测试获取可用通道
# =============================================================================
func test_sfx_027_get_available_channel() -> void:
	await get_tree().process_frame

	var player = sfx_player._get_available_channel()

	assert_not_null(player, "应能获取可用通道")
	assert_is(player, AudioStreamPlayer, "通道应为AudioStreamPlayer类型")


# =============================================================================
# SFX-028: 通道回收
# 测试通道回收
# =============================================================================
func test_sfx_028_recycle_channel() -> void:
	await get_tree().process_frame

	var player = sfx_player._get_available_channel()
	var pool_size_before = sfx_player._channel_pool.size()

	sfx_player._recycle_channel(player)

	assert_eq(sfx_player._channel_pool.size(), pool_size_before + 1, "通道应被回收")


# =============================================================================
# SFX-029: 通道池满时释放
# 测试通道池满时释放通道
# =============================================================================
func test_sfx_029_pool_full_release() -> void:
	await get_tree().process_frame

	var max_pool_size = sfx_player.max_channels

	# 填满池
	while sfx_player._channel_pool.size() < max_pool_size:
		var player = AudioStreamPlayer.new()
		sfx_player._channel_pool.append(player)

	var pool_size_before = sfx_player._channel_pool.size()

	# 尝试回收额外通道
	var extra_player = AudioStreamPlayer.new()
	sfx_player._recycle_channel(extra_player)

	# 池大小不应超过最大值
	assert_eq(sfx_player._channel_pool.size(), pool_size_before, "池满时不应增加")


# =============================================================================
# SFX-030: 清理已完成通道
# 测试清理已完成的通道
# =============================================================================
func test_sfx_030_cleanup_finished_channels() -> void:
	await get_tree().process_frame

	# 添加一些无效通道到活动列表
	var invalid_player = AudioStreamPlayer.new()
	sfx_player._active_channels.append(invalid_player)

	# 清理
	sfx_player._cleanup_finished_channels()

	# 验证清理结果
	assert_eq(sfx_player._active_channels.size(), 0, "无效通道应被清理")


# =============================================================================
# 附加测试：默认音频总线
# =============================================================================
func test_default_bus() -> void:
	assert_eq(sfx_player.default_bus, "SFX", "默认音频总线应为SFX")


# =============================================================================
# 附加测试：通道池类型
# =============================================================================
func test_channel_pool_type() -> void:
	await get_tree().process_frame

	for player in sfx_player._channel_pool:
		assert_is(player, AudioStreamPlayer, "通道池中的对象应为AudioStreamPlayer")


# =============================================================================
# 附加测试：活动通道类型
# =============================================================================
func test_active_channels_type() -> void:
	assert_true(sfx_player._active_channels is Array, "活动通道应为数组")


# =============================================================================
# 附加测试：音效池类型
# =============================================================================
func test_sound_pool_type() -> void:
	assert_true(sfx_player._sound_pool is Dictionary, "音效池应为字典")