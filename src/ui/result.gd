class_name ResultUI
extends Control
## 结果界面
## 显示游戏结束后的结果统计

## 信号
signal retry_requested
signal back_to_song_select_requested

## 评级类型
enum RankType {
	GOLD,    ## 金冠（全良）
	SILVER,  ## 银冠（全连）
	BRONZE,  ## 铜冠（清除）
	FAILED   ## 失败
}

## UI节点引用
var _title_label: Label
var _song_title_label: Label
var _score_label: Label
var _rank_icon: TextureRect
var _rank_label: Label
var _perfect_label: Label
var _good_label: Label
var _miss_label: Label
var _max_combo_label: Label
var _accuracy_label: Label
var _retry_button: Button
var _back_button: Button

## 结果数据
var _result_data: Dictionary = {}


func _ready() -> void:
	_setup_ui()
	_load_result_data()
	_display_result()


## 设置UI布局
func _setup_ui() -> void:
	# 设置全屏
	anchors_preset = Control.PRESET_FULL_RECT
	offset_right = 0
	offset_bottom = 0
	
	# 创建主容器
	var main_vbox = VBoxContainer.new()
	add_child(main_vbox)
	main_vbox.anchors_preset = Control.PRESET_FULL_RECT
	main_vbox.offset_right = 0
	main_vbox.offset_bottom = 0
	
	# 顶部标题
	_setup_header(main_vbox)
	
	# 中间内容区域
	var content_hbox = HBoxContainer.new()
	content_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(content_hbox)
	
	# 左侧评级区域
	_setup_rank_area(content_hbox)
	
	# 右侧统计区域
	_setup_stats_area(content_hbox)
	
	# 底部按钮栏
	_setup_footer(main_vbox)


## 设置顶部标题
func _setup_header(parent: Control) -> void:
	var header = PanelContainer.new()
	header.custom_minimum_size = Vector2(0, 80)
	parent.add_child(header)
	
	var vbox = VBoxContainer.new()
	header.add_child(vbox)
	
	# 标题
	_title_label = Label.new()
	_title_label.text = "RESULT"
	_title_label.add_theme_font_size_override("font_size", 32)
	_title_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_title_label)
	
	# 歌曲标题
	_song_title_label = Label.new()
	_song_title_label.text = "---"
	_song_title_label.add_theme_font_size_override("font_size", 18)
	_song_title_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	_song_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_song_title_label)


## 设置评级区域
func _setup_rank_area(parent: Control) -> void:
	var rank_panel = PanelContainer.new()
	rank_panel.custom_minimum_size = Vector2(300, 0)
	rank_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(rank_panel)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	rank_panel.add_child(vbox)
	
	# 评级图标（使用Label代替）
	_rank_label = Label.new()
	_rank_label.text = "S"
	_rank_label.add_theme_font_size_override("font_size", 120)
	_rank_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
	_rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_rank_label)
	
	# 评级说明
	var rank_desc = Label.new()
	rank_desc.text = "RANK"
	rank_desc.add_theme_font_size_override("font_size", 24)
	rank_desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	rank_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(rank_desc)
	
	# 分数
	_score_label = Label.new()
	_score_label.text = "SCORE: 0"
	_score_label.add_theme_font_size_override("font_size", 28)
	_score_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_score_label)


## 设置统计区域
func _setup_stats_area(parent: Control) -> void:
	var stats_panel = PanelContainer.new()
	stats_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(stats_panel)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	stats_panel.add_child(vbox)
	
	# 判定统计标题
	var stats_title = Label.new()
	stats_title.text = "JUDGE STATS"
	stats_title.add_theme_font_size_override("font_size", 20)
	stats_title.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(stats_title)
	
	# 分隔线
	var separator1 = HSeparator.new()
	vbox.add_child(separator1)
	
	# 良
	var perfect_hbox = HBoxContainer.new()
	perfect_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(perfect_hbox)
	
	var perfect_name = Label.new()
	perfect_name.text = "良 (PERFECT): "
	perfect_name.add_theme_font_size_override("font_size", 20)
	perfect_name.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
	perfect_hbox.add_child(perfect_name)
	
	_perfect_label = Label.new()
	_perfect_label.text = "0"
	_perfect_label.add_theme_font_size_override("font_size", 20)
	_perfect_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
	perfect_hbox.add_child(_perfect_label)
	
	# 可
	var good_hbox = HBoxContainer.new()
	good_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(good_hbox)
	
	var good_name = Label.new()
	good_name.text = "可 (GOOD): "
	good_name.add_theme_font_size_override("font_size", 20)
	good_name.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
	good_hbox.add_child(good_name)
	
	_good_label = Label.new()
	_good_label.text = "0"
	_good_label.add_theme_font_size_override("font_size", 20)
	_good_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
	good_hbox.add_child(_good_label)
	
	# 不可
	var miss_hbox = HBoxContainer.new()
	miss_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(miss_hbox)
	
	var miss_name = Label.new()
	miss_name.text = "不可 (MISS): "
	miss_name.add_theme_font_size_override("font_size", 20)
	miss_name.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	miss_hbox.add_child(miss_name)
	
	_miss_label = Label.new()
	_miss_label.text = "0"
	_miss_label.add_theme_font_size_override("font_size", 20)
	_miss_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	miss_hbox.add_child(_miss_label)
	
	# 分隔线
	var separator2 = HSeparator.new()
	vbox.add_child(separator2)
	
	# 最大连击
	var combo_hbox = HBoxContainer.new()
	combo_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(combo_hbox)
	
	var combo_name = Label.new()
	combo_name.text = "MAX COMBO: "
	combo_name.add_theme_font_size_override("font_size", 20)
	combo_name.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	combo_hbox.add_child(combo_name)
	
	_max_combo_label = Label.new()
	_max_combo_label.text = "0"
	_max_combo_label.add_theme_font_size_override("font_size", 20)
	_max_combo_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
	combo_hbox.add_child(_max_combo_label)
	
	# 精度
	var accuracy_hbox = HBoxContainer.new()
	accuracy_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(accuracy_hbox)
	
	var accuracy_name = Label.new()
	accuracy_name.text = "ACCURACY: "
	accuracy_name.add_theme_font_size_override("font_size", 20)
	accuracy_name.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	accuracy_hbox.add_child(accuracy_name)
	
	_accuracy_label = Label.new()
	_accuracy_label.text = "0.00%"
	_accuracy_label.add_theme_font_size_override("font_size", 20)
	_accuracy_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
	accuracy_hbox.add_child(_accuracy_label)


## 设置底部按钮栏
func _setup_footer(parent: Control) -> void:
	var footer = HBoxContainer.new()
	footer.custom_minimum_size = Vector2(0, 80)
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	parent.add_child(footer)
	
	# 重试按钮
	_retry_button = Button.new()
	_retry_button.text = "Retry"
	_retry_button.custom_minimum_size = Vector2(150, 50)
	_retry_button.pressed.connect(_on_retry_pressed)
	footer.add_child(_retry_button)
	
	# 间隔
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(30, 0)
	footer.add_child(spacer)
	
	# 返回按钮
	_back_button = Button.new()
	_back_button.text = "Back to Song Select"
	_back_button.custom_minimum_size = Vector2(200, 50)
	_back_button.pressed.connect(_on_back_pressed)
	footer.add_child(_back_button)


## 加载结果数据
func _load_result_data() -> void:
	# 从全局状态获取结果数据
	_result_data = {
		"score": GameState.current_score,
		"max_combo": GameState.max_combo,
		"perfect_count": GameState.judge_counts.get("良", 0),
		"good_count": GameState.judge_counts.get("可", 0),
		"miss_count": GameState.judge_counts.get("不可", 0),
		"song_title": GameState.current_song.get("title", "Unknown"),
		"cleared": true,  # 简化处理
		"full_combo": GameState.judge_counts.get("不可", 0) == 0,
		"dondoko_full_combo": GameState.judge_counts.get("可", 0) == 0 and GameState.judge_counts.get("不可", 0) == 0
	}


## 显示结果
func _display_result() -> void:
	# 更新歌曲标题
	_song_title_label.text = _result_data.get("song_title", "Unknown")
	
	# 更新分数
	_score_label.text = "SCORE: %d" % _result_data.get("score", 0)
	
	# 更新判定统计
	_perfect_label.text = str(_result_data.get("perfect_count", 0))
	_good_label.text = str(_result_data.get("good_count", 0))
	_miss_label.text = str(_result_data.get("miss_count", 0))
	
	# 更新最大连击
	_max_combo_label.text = str(_result_data.get("max_combo", 0))
	
	# 计算并更新精度
	var total_notes = _result_data.get("perfect_count", 0) + _result_data.get("good_count", 0) + _result_data.get("miss_count", 0)
	var accuracy = 0.0
	if total_notes > 0:
		accuracy = (_result_data.get("perfect_count", 0) * 1.0 + _result_data.get("good_count", 0) * 0.5) / total_notes * 100.0
	_accuracy_label.text = "%.2f%%" % accuracy
	
	# 更新评级
	_update_rank_display()


## 更新评级显示
func _update_rank_display() -> void:
	var rank_type = _calculate_rank()
	
	match rank_type:
		RankType.GOLD:
			_rank_label.text = "SS"
			_rank_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
			_title_label.text = "DONDAKO FULL COMBO!"
		RankType.SILVER:
			_rank_label.text = "FC"
			_rank_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
			_title_label.text = "FULL COMBO!"
		RankType.BRONZE:
			_rank_label.text = _calculate_letter_rank()
			_rank_label.add_theme_color_override("font_color", Color(0.8, 0.5, 0.2))
			_title_label.text = "CLEARED!"
		RankType.FAILED:
			_rank_label.text = "F"
			_rank_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			_title_label.text = "FAILED..."


## 计算评级类型
func _calculate_rank() -> RankType:
	if _result_data.get("dondoko_full_combo", false):
		return RankType.GOLD
	elif _result_data.get("full_combo", false):
		return RankType.SILVER
	elif _result_data.get("cleared", false):
		return RankType.BRONZE
	else:
		return RankType.FAILED


## 计算字母评级
func _calculate_letter_rank() -> String:
	var total_notes = _result_data.get("perfect_count", 0) + _result_data.get("good_count", 0) + _result_data.get("miss_count", 0)
	if total_notes == 0:
		return "F"
	
	var accuracy = (_result_data.get("perfect_count", 0) * 1.0 + _result_data.get("good_count", 0) * 0.5) / total_notes
	
	if accuracy >= 0.95:
		return "S"
	elif accuracy >= 0.90:
		return "A"
	elif accuracy >= 0.80:
		return "B"
	elif accuracy >= 0.70:
		return "C"
	elif accuracy >= 0.60:
		return "D"
	else:
		return "F"


## 重试按钮按下
func _on_retry_pressed() -> void:
	retry_requested.emit()
	
	# 重置游戏状态
	GameState.reset_game_state()
	
	# 返回游戏场景
	get_tree().change_scene_to_file("res://scenes/gameplay.tscn")


## 返回按钮按下
func _on_back_pressed() -> void:
	back_to_song_select_requested.emit()
	
	# 重置游戏状态
	GameState.reset_game_state()
	
	# 返回选曲场景
	get_tree().change_scene_to_file("res://scenes/song_select.tscn")


## 设置结果数据（外部调用）
func set_result_data(data: Dictionary) -> void:
	_result_data = data
	_display_result()


## 获取结果数据
func get_result_data() -> Dictionary:
	return _result_data