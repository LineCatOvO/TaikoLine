## 主菜单控制器
## 功能：管理主菜单的显示、按钮响应、场景切换
## 作者：TaikoLine Team
## 日期：2026-04-03

extends Control

## ==================== 场景路径常量 ====================

## 歌曲选择场景路径
const SONG_SELECT_SCENE := "res://scenes/song_select.tscn"

## 设置场景路径
const SETTINGS_SCENE := "res://scenes/settings.tscn"

## ==================== 节点引用 ====================

## 菜单容器
@onready var menu_container: VBoxContainer = $MenuContainer

## 开始按钮
@onready var start_button: Button = $MenuContainer/StartButton

## 设置按钮
@onready var options_button: Button = $MenuContainer/OptionsButton

## 退出按钮
@onready var exit_button: Button = $MenuContainer/ExitButton

## Logo 节点
@onready var logo: Control = $Logo

## 背景节点
@onready var background: Control = $Background

## 底部信息节点
@onready var bottom_info: Control = $BottomInfo

## ==================== 动画相关 ====================

## 动画管理器引用（Autoload）
var animation_manager: Node = null

## 入场动画延迟
const ENTER_ANIMATION_DELAY := 0.1

## ==================== 初始化 ====================

func _ready() -> void:
	# 获取动画管理器引用
	animation_manager = get_node_or_null("/root/AnimationManager")
	if animation_manager == null:
		push_warning("[MainMenu] AnimationManager not found")

	# 注意：按钮信号已在场景文件中连接，无需重复连接

	# 设置初始焦点
	start_button.grab_focus()

	# 执行入场动画
	_play_enter_animation()

	# 播放背景音乐（如果有）
	_play_background_music()


## ==================== 按钮响应 ====================

## 开始按钮点击响应
func _on_start_button_pressed() -> void:
	# 播放确认音效
	if AudioManager:
		AudioManager.play_ui_confirm()

	# 执行按钮动画
	_play_button_animation(start_button)

	# 切换到歌曲选择场景
	_transition_to_scene(SONG_SELECT_SCENE)


## 设置按钮点击响应
func _on_options_button_pressed() -> void:
	# 播放确认音效
	if AudioManager:
		AudioManager.play_ui_confirm()

	# 执行按钮动画
	_play_button_animation(options_button)

	# 切换到设置场景
	_transition_to_scene(SETTINGS_SCENE)


## 退出按钮点击响应
func _on_exit_button_pressed() -> void:
	# 播放确认音效
	if AudioManager:
		AudioManager.play_ui_confirm()

	# 执行按钮动画
	_play_button_animation(exit_button)

	# 退出游戏
	_exit_game()


## ==================== 场景切换 ====================

## 切换到指定场景
## @param scene_path: 场景路径
func _transition_to_scene(scene_path: String) -> void:
	# 检查场景是否存在
	if not ResourceLoader.exists(scene_path):
		push_error("[MainMenu] Scene not found: %s" % scene_path)
		return

	# 执行淡出动画
	if animation_manager:
		var tween = animation_manager.create_preset_animation(self, animation_manager.PresetType.FADE_OUT, 0.3)
		if tween:
			tween.finished.connect(_change_scene.bind(scene_path))
	else:
		# 直接切换场景
		_change_scene(scene_path)


## 切换场景
## @param scene_path: 场景路径
func _change_scene(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)


## 退出游戏
func _exit_game() -> void:
	# 执行淡出动画
	if animation_manager:
		var tween = animation_manager.create_preset_animation(self, animation_manager.PresetType.FADE_OUT, 0.3)
		if tween:
			tween.finished.connect(_quit_game)
	else:
		_quit_game()


## 退出游戏
func _quit_game() -> void:
	get_tree().quit()


## ==================== 动画效果 ====================

## 播放入场动画
func _play_enter_animation() -> void:
	# Logo 入场动画
	if animation_manager and logo:
		animation_manager.create_preset_animation(logo, animation_manager.PresetType.FADE_IN, 0.5)

	# 菜单按钮入场动画（延迟依次出现）
	if animation_manager and menu_container:
		var buttons = menu_container.get_children()
		for i in range(buttons.size()):
			var button = buttons[i]
			button.modulate.a = 0.0

			# 延迟创建动画
			await get_tree().create_timer(i * ENTER_ANIMATION_DELAY).timeout
			animation_manager.create_preset_animation(button, animation_manager.PresetType.SLIDE_IN_RIGHT, 0.3)


## 播放按钮点击动画
## @param button: 按钮节点
func _play_button_animation(button: Button) -> void:
	if animation_manager:
		animation_manager.create_preset_animation(button, animation_manager.PresetType.PULSE, 0.2)


## ==================== 背景音乐 ====================

## 播放背景音乐
func _play_background_music() -> void:
	# 如果有 AudioManager，可以播放背景音乐
	# 这里暂时不播放，等待后续添加背景音乐资源
	pass


## ==================== 输入处理 ====================

## 处理键盘输入
func _input(event: InputEvent) -> void:
	# 处理取消键（ESC）
	if event.is_action_pressed("ui_cancel"):
		# 如果当前焦点在退出按钮，直接退出
		if exit_button.has_focus():
			_on_exit_button_pressed()
		else:
			# 否则将焦点移到退出按钮
			exit_button.grab_focus()
			if AudioManager:
				AudioManager.play_ui_navigate()