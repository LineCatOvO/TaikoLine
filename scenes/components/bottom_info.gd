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

## 更新版本号显示
## 从项目设置中读取版本号，如果没有则使用默认值 v1.0.0
func _update_version() -> void:
	var version = ProjectSettings.get_setting("application/config/version", "v1.0.0")
	version_label.text = "版本：" + version

## 设置操作提示文字
## 参数 text: 要显示的提示文字
func set_hint(text: String) -> void:
	hint_label.text = text
