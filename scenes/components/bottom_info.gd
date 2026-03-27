## 底部信息组件
## 功能：显示版本信息、版权信息和操作提示
## 作者：TaikoLine Team
## 日期：2026-03-23

extends Control

## 版本标签控件
@onready var version_label: Label = $HBoxContainer/VersionLabel

## 版权标签控件
@onready var copyright_label: Label = $HBoxContainer/CopyrightLabel

## 提示标签控件
@onready var hint_label: Label = $HBoxContainer/HintLabel

## 初始化时更新版本信息
func _ready() -> void:
	_update_version()
	_setup_copyright()

## 更新版本号显示
## 从项目设置中读取版本号，如果没有则使用默认值 v1.0.0
func _update_version() -> void:
	var version = ProjectSettings.get_setting("application/config/version", "v1.0.0")
	if version_label:
		version_label.text = "版本：%s" % version

## 设置版权信息
func _setup_copyright() -> void:
	if copyright_label:
		copyright_label.text = "© 2026 TaikoLine"

## 设置操作提示文字
## 参数 text: 要显示的提示文字
func set_hint(text: String) -> void:
	if hint_label:
		hint_label.text = text

## 获取当前版本号
## 返回: 版本号字符串
func get_version() -> String:
	return ProjectSettings.get_setting("application/config/version", "v1.0.0")