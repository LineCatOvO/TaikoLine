## 设置管理单元测试
## 测试 Settings 的默认值、保存、加载和持久化
## 测试框架：GUT v9.6.0

extends GutTest

var settings: Node = null
var test_config_path: String = "user://test_settings.cfg"


func before_all() -> void:
	# 删除可能存在的配置文件，确保测试默认值时不受影响
	_delete_settings_config()


func before_each() -> void:
	# 清理测试配置文件
	_delete_test_config()
	_delete_settings_config()
	# 创建设置实例（模拟autoload）
	settings = load("res://src/autoload/settings.gd").new()
	add_child(settings)


func after_each() -> void:
	if settings:
		settings.queue_free()
		settings = null
	# 清理测试配置文件
	_delete_test_config()


func after_all() -> void:
	pass


## 删除测试配置文件
func _delete_test_config() -> void:
	var dir = DirAccess.open("user://")
	if dir and dir.file_exists("test_settings.cfg"):
		dir.remove("test_settings.cfg")


## 删除设置配置文件
func _delete_settings_config() -> void:
	var dir = DirAccess.open("user://")
	if dir and dir.file_exists("settings.cfg"):
		dir.remove("settings.cfg")


# =============================================================================
# SET-001: 默认值验证
# 测试所有设置的默认值
# =============================================================================
func test_set_001_default_values() -> void:
	# 验证音量设置默认值
	assert_eq(settings.master_volume, 1.0, "主音量默认值应为1.0")
	assert_eq(settings.music_volume, 1.0, "音乐音量默认值应为1.0")
	assert_eq(settings.sfx_volume, 1.0, "音效音量默认值应为1.0")
	assert_eq(settings.audio_offset, 0.0, "音频偏移默认值应为0.0")
	assert_eq(settings.buffer_size, 0, "缓冲区大小默认值应为0")

	# 验证游戏设置默认值
	assert_eq(settings.scroll_speed, 1.0, "滚动速度默认值应为1.0")
	assert_eq(settings.judge_offset, 0.0, "判定偏移默认值应为0.0")
	assert_eq(settings.show_debug, false, "调试显示默认值应为false")

	# 验证显示设置默认值
	assert_eq(settings.fullscreen, false, "全屏默认值应为false")
	assert_eq(settings.resolution_width, 1280, "分辨率宽度默认值应为1280")
	assert_eq(settings.resolution_height, 720, "分辨率高度默认值应为720")

	# 验证皮肤设置默认值
	assert_eq(settings.current_skin, "default", "皮肤默认值应为default")


# =============================================================================
# SET-002: 设置保存
# 测试设置保存到配置文件
# =============================================================================
func test_set_002_save_settings() -> void:
	# 修改设置
	settings.master_volume = 0.8
	settings.music_volume = 0.6
	settings.sfx_volume = 0.7
	settings.audio_offset = 50.0
	settings.buffer_size = 1
	settings.scroll_speed = 2.0
	settings.judge_offset = 50.0
	settings.show_debug = true
	settings.fullscreen = true
	settings.resolution_width = 1920
	settings.resolution_height = 1080
	settings.current_skin = "custom_skin"

	# 保存设置
	settings.save_settings()

	# 验证配置文件已创建
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	assert_eq(err, OK, "配置文件应成功加载")

	# 验证保存的值
	assert_eq(config.get_value("audio", "master_volume", 0.0), 0.8, "主音量应保存为0.8")
	assert_eq(config.get_value("audio", "music_volume", 0.0), 0.6, "音乐音量应保存为0.6")
	assert_eq(config.get_value("audio", "sfx_volume", 0.0), 0.7, "音效音量应保存为0.7")
	assert_eq(config.get_value("audio", "audio_offset", 0.0), 50.0, "音频偏移应保存为50.0")
	assert_eq(config.get_value("audio", "buffer_size", 0), 1, "缓冲区大小应保存为1")
	assert_eq(config.get_value("game", "scroll_speed", 0.0), 2.0, "滚动速度应保存为2.0")
	assert_eq(config.get_value("game", "judge_offset", 0.0), 50.0, "判定偏移应保存为50.0")
	assert_eq(config.get_value("game", "show_debug", false), true, "调试显示应保存为true")
	assert_eq(config.get_value("display", "fullscreen", false), true, "全屏应保存为true")
	assert_eq(config.get_value("display", "resolution_width", 0), 1920, "分辨率宽度应保存为1920")
	assert_eq(config.get_value("display", "resolution_height", 0), 1080, "分辨率高度应保存为1080")
	assert_eq(config.get_value("game", "current_skin", ""), "custom_skin", "皮肤应保存为custom_skin")


# =============================================================================
# SET-003: 设置加载
# 测试从配置文件加载设置
# =============================================================================
func test_set_003_load_settings() -> void:
	# 创建测试配置文件
	var config = ConfigFile.new()
	config.set_value("audio", "master_volume", 0.5)
	config.set_value("audio", "music_volume", 0.3)
	config.set_value("audio", "sfx_volume", 0.4)
	config.set_value("audio", "audio_offset", 100.0)
	config.set_value("audio", "buffer_size", 2)
	config.set_value("game", "scroll_speed", 1.5)
	config.set_value("game", "judge_offset", -20.0)
	config.set_value("game", "show_debug", true)
	config.set_value("display", "fullscreen", true)
	config.set_value("display", "resolution_width", 1600)
	config.set_value("display", "resolution_height", 900)
	config.set_value("game", "current_skin", "loaded_skin")
	config.save("user://settings.cfg")

	# 加载设置
	settings.load_settings()

	# 验证加载的值
	assert_eq(settings.master_volume, 0.5, "主音量应加载为0.5")
	assert_eq(settings.music_volume, 0.3, "音乐音量应加载为0.3")
	assert_eq(settings.sfx_volume, 0.4, "音效音量应加载为0.4")
	assert_eq(settings.audio_offset, 100.0, "音频偏移应加载为100.0")
	assert_eq(settings.buffer_size, 2, "缓冲区大小应加载为2")
	assert_eq(settings.scroll_speed, 1.5, "滚动速度应加载为1.5")
	assert_eq(settings.judge_offset, -20.0, "判定偏移应加载为-20.0")
	assert_eq(settings.show_debug, true, "调试显示应加载为true")
	assert_eq(settings.fullscreen, true, "全屏应加载为true")
	assert_eq(settings.resolution_width, 1600, "分辨率宽度应加载为1600")
	assert_eq(settings.resolution_height, 900, "分辨率高度应加载为900")
	assert_eq(settings.current_skin, "loaded_skin", "皮肤应加载为loaded_skin")


# =============================================================================
# SET-004: 设置持久化
# 测试设置在保存和加载后的持久化
# =============================================================================
func test_set_004_settings_persistence() -> void:
	# 修改设置
	settings.master_volume = 0.75
	settings.music_volume = 0.5
	settings.sfx_volume = 0.25
	settings.audio_offset = 200.0
	settings.buffer_size = 1
	settings.scroll_speed = 3.0
	settings.judge_offset = 100.0
	settings.show_debug = true
	settings.fullscreen = true
	settings.resolution_width = 2560
	settings.resolution_height = 1440
	settings.current_skin = "persistent_skin"

	# 保存设置
	settings.save_settings()

	# 创建新的设置实例并加载
	var new_settings = load("res://src/autoload/settings.gd").new()
	add_child(new_settings)
	new_settings.load_settings()

	# 验证持久化的值
	assert_eq(new_settings.master_volume, 0.75, "主音量应持久化为0.75")
	assert_eq(new_settings.music_volume, 0.5, "音乐音量应持久化为0.5")
	assert_eq(new_settings.sfx_volume, 0.25, "音效音量应持久化为0.25")
	assert_eq(new_settings.audio_offset, 200.0, "音频偏移应持久化为200.0")
	assert_eq(new_settings.buffer_size, 1, "缓冲区大小应持久化为1")
	assert_eq(new_settings.scroll_speed, 3.0, "滚动速度应持久化为3.0")
	assert_eq(new_settings.judge_offset, 100.0, "判定偏移应持久化为100.0")
	assert_eq(new_settings.show_debug, true, "调试显示应持久化为true")
	assert_eq(new_settings.fullscreen, true, "全屏应持久化为true")
	assert_eq(new_settings.resolution_width, 2560, "分辨率宽度应持久化为2560")
	assert_eq(new_settings.resolution_height, 1440, "分辨率高度应持久化为1440")
	assert_eq(new_settings.current_skin, "persistent_skin", "皮肤应持久化为persistent_skin")

	new_settings.queue_free()


# =============================================================================
# 附加测试：缺失配置文件时的默认值
# =============================================================================
func test_load_missing_config() -> void:
	# 确保配置文件不存在
	_delete_test_config()
	var dir = DirAccess.open("user://")
	if dir:
		if dir.file_exists("settings.cfg"):
			dir.remove("settings.cfg")

	# 重置设置到默认值
	settings.reset_to_defaults()

	# 加载不存在的配置文件
	settings.load_settings()

	# 应使用默认值
	assert_eq(settings.master_volume, 1.0, "缺失配置时应使用默认主音量")
	assert_eq(settings.music_volume, 1.0, "缺失配置时应使用默认音乐音量")
	assert_eq(settings.sfx_volume, 1.0, "缺失配置时应使用默认音效音量")
	assert_eq(settings.audio_offset, 0.0, "缺失配置时应使用默认音频偏移")
	assert_eq(settings.buffer_size, 0, "缺失配置时应使用默认缓冲区大小")
	assert_eq(settings.scroll_speed, 1.0, "缺失配置时应使用默认滚动速度")
	assert_eq(settings.judge_offset, 0.0, "缺失配置时应使用默认判定偏移")
	assert_eq(settings.show_debug, false, "缺失配置时应使用默认调试显示")
	assert_eq(settings.fullscreen, false, "缺失配置时应使用默认全屏")
	assert_eq(settings.resolution_width, 1280, "缺失配置时应使用默认分辨率宽度")
	assert_eq(settings.resolution_height, 720, "缺失配置时应使用默认分辨率高度")
	assert_eq(settings.current_skin, "default", "缺失配置时应使用默认皮肤")


# =============================================================================
# 附加测试：部分配置缺失时使用默认值
# =============================================================================
func test_load_partial_config() -> void:
	# 创建部分配置文件
	var config = ConfigFile.new()
	config.set_value("audio", "master_volume", 0.6)
	# 不设置其他值
	config.save("user://settings.cfg")

	# 加载设置
	settings.load_settings()

	# 验证部分值加载，其他使用默认值
	assert_eq(settings.master_volume, 0.6, "主音量应加载为0.6")
	assert_eq(settings.music_volume, 1.0, "音乐音量应使用默认值1.0")
	assert_eq(settings.sfx_volume, 1.0, "音效音量应使用默认值1.0")
	assert_eq(settings.audio_offset, 0.0, "音频偏移应使用默认值0.0")
	assert_eq(settings.buffer_size, 0, "缓冲区大小应使用默认值0")
	assert_eq(settings.scroll_speed, 1.0, "滚动速度应使用默认值1.0")
	assert_eq(settings.judge_offset, 0.0, "判定偏移应使用默认值0.0")
	assert_eq(settings.show_debug, false, "调试显示应使用默认值false")
	assert_eq(settings.fullscreen, false, "全屏应使用默认值false")
	assert_eq(settings.resolution_width, 1280, "分辨率宽度应使用默认值1280")
	assert_eq(settings.resolution_height, 720, "分辨率高度应使用默认值720")
	assert_eq(settings.current_skin, "default", "皮肤应使用默认值default")


# =============================================================================
# 附加测试：边界值测试
# =============================================================================
func test_boundary_values() -> void:
	# 测试音量边界值
	settings.master_volume = 0.0
	assert_eq(settings.master_volume, 0.0, "主音量可以为0")

	settings.master_volume = 1.0
	assert_eq(settings.master_volume, 1.0, "主音量可以为1")

	# 测试滚动速度边界值
	settings.scroll_speed = 0.1
	assert_eq(settings.scroll_speed, 0.1, "滚动速度可以为0.1")

	settings.scroll_speed = 10.0
	assert_eq(settings.scroll_speed, 10.0, "滚动速度可以为10")

	# 测试判定偏移边界值
	settings.judge_offset = -500.0
	assert_eq(settings.judge_offset, -500.0, "判定偏移可以为负值")

	settings.judge_offset = 500.0
	assert_eq(settings.judge_offset, 500.0, "判定偏移可以为正值")


# =============================================================================
# 附加测试：多次保存和加载
# =============================================================================
func test_multiple_save_load() -> void:
	# 第一次保存
	settings.scroll_speed = 1.0
	settings.save_settings()

	settings.load_settings()
	assert_eq(settings.scroll_speed, 1.0, "第一次加载滚动速度应为1.0")

	# 第二次保存
	settings.scroll_speed = 2.0
	settings.save_settings()

	settings.load_settings()
	assert_eq(settings.scroll_speed, 2.0, "第二次加载滚动速度应为2.0")

	# 第三次保存
	settings.scroll_speed = 3.0
	settings.save_settings()

	settings.load_settings()
	assert_eq(settings.scroll_speed, 3.0, "第三次加载滚动速度应为3.0")


# =============================================================================
# 附加测试：_ready 自动加载
# =============================================================================
func test_ready_auto_load() -> void:
	# 创建测试配置
	var config = ConfigFile.new()
	config.set_value("game", "scroll_speed", 4.0)
	config.save("user://settings.cfg")

	# 创建新实例（会触发_ready）
	var new_settings = load("res://src/autoload/settings.gd").new()
	add_child(new_settings)

	# 验证_ready中自动加载了设置
	assert_eq(new_settings.scroll_speed, 4.0, "_ready应自动加载设置")

	new_settings.queue_free()


# =============================================================================
# 附加测试：配置文件格式验证
# =============================================================================
func test_config_file_format() -> void:
	# 修改并保存设置
	settings.master_volume = 0.8
	settings.scroll_speed = 2.5
	settings.audio_offset = 100.0
	settings.buffer_size = 1
	settings.fullscreen = true
	settings.resolution_width = 1920
	settings.resolution_height = 1080
	settings.current_skin = "test_skin"
	settings.save_settings()

	# 直接读取配置文件验证格式
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	assert_eq(err, OK, "配置文件应可读取")

	# 验证section存在
	var sections = ["audio", "game", "display"]
	for section in sections:
		assert_true(config.has_section(section), "应包含section: " + section)

	# 验证key存在
	assert_true(config.has_section_key("audio", "master_volume"), "应包含master_volume键")
	assert_true(config.has_section_key("audio", "audio_offset"), "应包含audio_offset键")
	assert_true(config.has_section_key("audio", "buffer_size"), "应包含buffer_size键")
	assert_true(config.has_section_key("game", "scroll_speed"), "应包含scroll_speed键")
	assert_true(config.has_section_key("display", "fullscreen"), "应包含fullscreen键")
	assert_true(config.has_section_key("display", "resolution_width"), "应包含resolution_width键")
	assert_true(config.has_section_key("display", "resolution_height"), "应包含resolution_height键")
	assert_true(config.has_section_key("game", "current_skin"), "应包含current_skin键")


# =============================================================================
# 附加测试：浮点精度
# =============================================================================
func test_float_precision() -> void:
	# 测试浮点数精度
	settings.master_volume = 0.123456789
	settings.judge_offset = 12.3456789
	settings.save_settings()

	settings.load_settings()

	# 验证浮点数精度保持
	assert_almost_eq(settings.master_volume, 0.123456789, 0.0001, "主音量精度应保持")
	assert_almost_eq(settings.judge_offset, 12.3456789, 0.0001, "判定偏移精度应保持")


# =============================================================================
# 附加测试：特殊字符皮肤名
# =============================================================================
func test_special_skin_name() -> void:
	# 测试特殊字符皮肤名
	settings.current_skin = "skin_with_special-chars_123"
	settings.save_settings()

	settings.load_settings()
	assert_eq(settings.current_skin, "skin_with_special-chars_123", "特殊字符皮肤名应正确保存和加载")


# =============================================================================
# 附加测试：重置到默认值
# =============================================================================
func test_reset_to_defaults() -> void:
	# 修改所有设置
	settings.master_volume = 0.5
	settings.music_volume = 0.5
	settings.sfx_volume = 0.5
	settings.audio_offset = 100.0
	settings.buffer_size = 2
	settings.scroll_speed = 5.0
	settings.judge_offset = 100.0
	settings.show_debug = true
	settings.fullscreen = true
	settings.resolution_width = 1920
	settings.resolution_height = 1080
	settings.current_skin = "custom"

	# 调用重置方法
	settings.reset_to_defaults()

	# 验证重置
	assert_eq(settings.master_volume, 1.0, "主音量应重置为默认值")
	assert_eq(settings.music_volume, 1.0, "音乐音量应重置为默认值")
	assert_eq(settings.sfx_volume, 1.0, "音效音量应重置为默认值")
	assert_eq(settings.audio_offset, 0.0, "音频偏移应重置为默认值")
	assert_eq(settings.buffer_size, 0, "缓冲区大小应重置为默认值")
	assert_eq(settings.scroll_speed, 1.0, "滚动速度应重置为默认值")
	assert_eq(settings.judge_offset, 0.0, "判定偏移应重置为默认值")
	assert_eq(settings.show_debug, false, "调试显示应重置为默认值")
	assert_eq(settings.fullscreen, false, "全屏应重置为默认值")
	assert_eq(settings.resolution_width, 1280, "分辨率宽度应重置为默认值")
	assert_eq(settings.resolution_height, 720, "分辨率高度应重置为默认值")
	assert_eq(settings.current_skin, "default", "皮肤应重置为默认值")