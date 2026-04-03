## 设置项组件控制器
## 功能：管理单个设置项的显示和交互
## 参考 Taiko no Tatsujin 设置界面风格
## 作者：TaikoLine Team
## 日期：2026-04-03

extends Control

## ==================== 信号 ====================

## 值改变信号
signal value_changed(new_value: float)

## ==================== 导出变量 ====================

## 设置项类型
enum ItemType {
	SLIDER,      ## 滑块类型
	CHECKBOX,    ## 复选框类型
	OPTION,      ## 选项按钮类型
	BUTTON,      ## 普通按钮类型
	LABEL        ## 纯标签类型
}

## 设置项类型
@export var item_type: ItemType = ItemType.SLIDER

## 设置项标题
@export var title: String = "Setting"

## 设置项描述
@export_multiline var description: String = ""

## 滑块最小值
@export var slider_min: float = 0.0

## 滑块最大值
@export var slider_max: float = 100.0

## 滑块步进值
@export var slider_step: float = 1.0

## 滑块默认值
@export var slider_default: float = 100.0

## 选项列表（用于 OPTION 类型）
@export var options: Array[String] = []

## 当前选中的选项索引
@export var selected_option: int = 0

## 按钮文字（用于 BUTTON 类型）
@export var button_text: String = "Button"

## ==================== 节点引用 ====================

## 标题标签
@onready var title_label: Label = $VBoxContainer/TitleLabel

## 描述标签
@onready var description_label: Label = $VBoxContainer/DescriptionLabel

## 内容容器
@onready var content_container: HBoxContainer = $VBoxContainer/ContentContainer

## 滑块节点
@onready var slider: HSlider = $VBoxContainer/ContentContainer/Slider

## 滑块值标签
@onready var slider_value_label: Label = $VBoxContainer/ContentContainer/SliderValueLabel

## 复选框节点
@onready var checkbox: CheckBox = $VBoxContainer/ContentContainer/CheckBox

## 选项按钮节点
@onready var option_button: OptionButton = $VBoxContainer/ContentContainer/OptionButton

## 普通按钮节点
@onready var action_button: Button = $VBoxContainer/ContentContainer/ActionButton

## 分隔线
@onready var separator: HSeparator = $Separator

## ==================== 动画参数 ====================

## 入场动画时长
const ENTER_ANIMATION_DURATION := 0.3

## 悬停动画时长
const HOVER_ANIMATION_DURATION := 0.15

## ==================== 状态变量 ====================

## 当前值
var current_value: float = 0.0

## 是否已初始化
var _is_initialized: bool = false

## ==================== 初始化 ====================

func _ready() -> void:
	# 设置初始状态
	_setup_item()

	# 连接信号
	_connect_signals()

	# 标记已初始化
	_is_initialized = true


## 设置设置项
func _setup_item() -> void:
	# 设置标题
	if title_label:
		title_label.text = title

	# 设置描述
	if description_label:
		description_label.text = description
		description_label.visible = not description.is_empty()

	# 根据类型设置内容
	_setup_content_by_type()


## 根据类型设置内容
func _setup_content_by_type() -> void:
	# 隐藏所有内容节点
	_hide_all_content_nodes()

	# 根据类型显示对应节点
	match item_type:
		ItemType.SLIDER:
			_setup_slider()
		ItemType.CHECKBOX:
			_setup_checkbox()
		ItemType.OPTION:
			_setup_option_button()
		ItemType.BUTTON:
			_setup_action_button()
		ItemType.LABEL:
			# 纯标签类型不需要额外内容
			pass


## 隐藏所有内容节点
func _hide_all_content_nodes() -> void:
	if slider:
		slider.visible = false
	if slider_value_label:
		slider_value_label.visible = false
	if checkbox:
		checkbox.visible = false
	if option_button:
		option_button.visible = false
	if action_button:
		action_button.visible = false


## 设置滑块
func _setup_slider() -> void:
	if not slider or not slider_value_label:
		return

	slider.visible = true
	slider_value_label.visible = true

	# 设置滑块参数
	slider.min_value = slider_min
	slider.max_value = slider_max
	slider.step = slider_step
	slider.value = slider_default

	# 设置当前值
	current_value = slider_default

	# 更新值显示
	_update_slider_value_display()


## 设置复选框
func _setup_checkbox() -> void:
	if not checkbox:
		return

	checkbox.visible = true

	# 设置初始状态
	checkbox.button_pressed = bool(current_value)


## 设置选项按钮
func _setup_option_button() -> void:
	if not option_button:
		return

	option_button.visible = true

	# 清空并添加选项
	option_button.clear()
	for option in options:
		option_button.add_item(option)

	# 设置当前选中
	if selected_option >= 0 and selected_option < options.size():
		option_button.select(selected_option)


## 设置普通按钮
func _setup_action_button() -> void:
	if not action_button:
		return

	action_button.visible = true
	action_button.text = button_text


## 连接信号
func _connect_signals() -> void:
	# 滑块信号
	if slider:
		slider.value_changed.connect(_on_slider_value_changed)

	# 复选框信号
	if checkbox:
		checkbox.toggled.connect(_on_checkbox_toggled)

	# 选项按钮信号
	if option_button:
		option_button.item_selected.connect(_on_option_selected)

	# 普通按钮信号
	if action_button:
		action_button.pressed.connect(_on_action_button_pressed)


## ==================== 值更新 ====================

## 更新滑块值显示
func _update_slider_value_display() -> void:
	if not slider_value_label:
		return

	# 根据滑块类型显示不同格式
	if slider_step >= 1.0:
		# 整数显示
		slider_value_label.text = "%d" % int(current_value)
	elif slider_max <= 10.0:
		# 小数显示（速度等）
		slider_value_label.text = "%.1fx" % current_value
	else:
		# 百分比显示
		slider_value_label.text = "%d%%" % int(current_value)


## ==================== 信号处理 ====================

## 滑块值改变
func _on_slider_value_changed(value: float) -> void:
	current_value = value
	_update_slider_value_display()
	value_changed.emit(value)


## 复选框切换
func _on_checkbox_toggled(is_checked: bool) -> void:
	current_value = float(is_checked)
	value_changed.emit(current_value)


## 选项选择
func _on_option_selected(index: int) -> void:
	selected_option = index
	current_value = float(index)
	value_changed.emit(current_value)


## 普通按钮点击
func _on_action_button_pressed() -> void:
	# 发送值改变信号（值为 1.0 表示按钮被点击）
	value_changed.emit(1.0)


## ==================== 公共方法 ====================

## 设置当前值
## @param value: 新值
func set_value(value: float) -> void:
	current_value = value

	if not _is_initialized:
		return

	match item_type:
		ItemType.SLIDER:
			if slider:
				slider.value = value
			_update_slider_value_display()
		ItemType.CHECKBOX:
			if checkbox:
				checkbox.button_pressed = bool(value)
		ItemType.OPTION:
			if option_button and int(value) >= 0 and int(value) < options.size():
				option_button.select(int(value))
				selected_option = int(value)


## 获取当前值
func get_value() -> float:
	return current_value


## 设置标题
## @param new_title: 新标题
func set_title(new_title: String) -> void:
	title = new_title
	if title_label:
		title_label.text = new_title


## 设置描述
## @param new_description: 新描述
func set_description(new_description: String) -> void:
	description = new_description
	if description_label:
		description_label.text = new_description
		description_label.visible = not new_description.is_empty()


## 设置选项列表
## @param new_options: 新选项列表
func set_options(new_options: Array[String]) -> void:
	options = new_options

	if not _is_initialized or item_type != ItemType.OPTION:
		return

	if option_button:
		option_button.clear()
		for option in options:
			option_button.add_item(option)

		# 重置选中
		if selected_option >= 0 and selected_option < options.size():
			option_button.select(selected_option)


## ==================== 动画效果 ====================

## 入场动画
func play_enter_animation(delay: float = 0.0) -> void:
	# 设置初始状态
	modulate.a = 0.0
	position.x -= 50

	# 等待延迟
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout

	# 创建入场动画
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUART)

	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, ENTER_ANIMATION_DURATION)
	tween.tween_property(self, "position:x", position.x + 50, ENTER_ANIMATION_DURATION)


## 悬停动画
func play_hover_animation() -> void:
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "modulate:v", 1.1, HOVER_ANIMATION_DURATION)
	tween.tween_property(self, "modulate:v", 1.0, HOVER_ANIMATION_DURATION)


## ==================== 外部接口 ====================

## 重置为默认值
func reset_to_default() -> void:
	match item_type:
		ItemType.SLIDER:
			set_value(slider_default)
		ItemType.CHECKBOX:
			set_value(0.0)
		ItemType.OPTION:
			set_value(0.0)


## 显示分隔线
func show_separator(show: bool) -> void:
	if separator:
		separator.visible = show