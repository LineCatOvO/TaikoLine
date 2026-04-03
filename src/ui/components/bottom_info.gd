## 主菜单底部信息控制器
## 功能：管理底部信息的显示，包括版本号、版权信息、操作提示
## 作者：TaikoLine Team
## 日期：2026-04-03

extends Control

## ==================== 节点引用 ====================

## 水平容器
@onready var hbox_container: HBoxContainer = $HBoxContainer

## 版本标签
@onready var version_label: Label = $HBoxContainer/VersionLabel

## 版权标签
@onready var copyright_label: Label = $HBoxContainer/CopyrightLabel

## 提示标签
@onready var hint_label: Label = $HBoxContainer/HintLabel

## ==================== 配置参数 ====================

## 项目版本号
const PROJECT_VERSION := "v1.0.0"

## 版权信息
const COPYRIGHT_TEXT := "© 2026 TaikoLine"

## 操作提示
const HINT_TEXT := "按 Enter 确认 | 按 ESC 退出"

## 入场动画时长（秒）
const ENTER_ANIMATION_DURATION := 0.5

## ==================== 动画管理器引用 ====================

var animation_manager: Node = null

## ==================== 初始化 ====================

func _ready() -> void:
	# 获取动画管理器引用
	animation_manager = get_node_or_null("/root/AnimationManager")

	# 设置初始状态
	_set_initial_state()

	# 更新显示内容
	_update_display_content()

	# 启动入场动画
	_play_enter_animation()


## ==================== 初始状态设置 ====================

## 设置初始状态
func _set_initial_state() -> void:
	# 初始透明度为 0（用于入场动画）
	modulate.a = 0.0


## ==================== 显示内容更新 ====================

## 更新显示内容
func _update_display_content() -> void:
	# 设置版本号
	if version_label:
		version_label.text = "版本：%s" % PROJECT_VERSION

	# 设置版权信息
	if copyright_label:
		copyright_label.text = COPYRIGHT_TEXT

	# 设置操作提示
	if hint_label:
		hint_label.text = HINT_TEXT


## ==================== 入场动画 ====================

## 播放入场动画
func _play_enter_animation() -> void:
	if animation_manager:
		# 使用从底部滑入动画
		animation_manager.create_preset_animation(self, animation_manager.PresetType.SLIDE_IN_BOTTOM, ENTER_ANIMATION_DURATION)
	else:
		# 直接设置透明度
		modulate.a = 1.0


## ==================== 外部接口 ====================

## 设置版本号
## @param version: 版本号字符串
func set_version(version: String) -> void:
	if version_label:
		version_label.text = "版本：%s" % version


## 设置版权信息
## @param copyright: 版权信息字符串
func set_copyright(copyright: String) -> void:
	if copyright_label:
		copyright_label.text = copyright


## 设置操作提示
## @param hint: 提示信息字符串
func set_hint(hint: String) -> void:
	if hint_label:
		hint_label.text = hint


## 设置所有信息
## @param version: 版本号
## @param copyright: 版权信息
## @param hint: 操作提示
func set_all_info(version: String, copyright: String, hint: String) -> void:
	set_version(version)
	set_copyright(copyright)
	set_hint(hint)


## ==================== 颜色设置 ====================

## 设置版本标签颜色
## @param color: 文字颜色
func set_version_color(color: Color) -> void:
	if version_label:
		version_label.add_theme_color_override("font_color", color)


## 设置版权标签颜色
## @param color: 文字颜色
func set_copyright_color(color: Color) -> void:
	if copyright_label:
		copyright_label.add_theme_color_override("font_color", color)


## 设置提示标签颜色
## @param color: 文字颜色
func set_hint_color(color: Color) -> void:
	if hint_label:
		hint_label.add_theme_color_override("font_color", color)


## 设置所有标签颜色
## @param color: 文字颜色
func set_all_color(color: Color) -> void:
	set_version_color(color)
	set_copyright_color(color)
	set_hint_color(color)


## ==================== 动画控制 ====================

## 暂停所有动画
func pause_animations() -> void:
	set_process(false)


## 恢复所有动画
func resume_animations() -> void:
	set_process(true)