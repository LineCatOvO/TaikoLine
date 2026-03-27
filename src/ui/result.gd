class_name ResultUI
extends Control
## 结果界面
## 显示游戏结束后的结果统计
##
## 设计参考：太鼓达人虹版（Taiko no Tatsujin Nijiiro）
## - 评级显示：大号 SS/S/A/B/C/D/F，带动画
## - 统计信息：得分、准确率、良/可/不可、最大连击
## - 魂槽状态：清除/未清除指示
## - 按钮：再玩一次、返回选歌

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

## 颜色配置
const COLOR_GOLD := Color(1.0, 0.85, 0.0)
const COLOR_SILVER := Color(0.85, 0.85, 0.85)
const COLOR_BRONZE := Color(0.85, 0.55, 0.25)
const COLOR_FAILED := Color(0.5, 0.5, 0.5)
const COLOR_PERFECT := Color(1.0, 0.8, 0.0)
const COLOR_GOOD := Color(0.5, 0.8, 1.0)
const COLOR_MISS := Color(1.0, 0.3, 0.3)
const COLOR_ACCURACY := Color(0.5, 1.0, 0.5)

## UI节点引用 - 顶部栏
@onready var _title_label: Label = $TopBar/VBoxContainer/TitleLabel
@onready var _song_title_label: Label = $TopBar/VBoxContainer/SongTitleLabel

## UI节点引用 - 左侧面板
@onready var _rank_label: Label = $MainContainer/LeftPanel/VBoxContainer/RankContainer/RankLabel
@onready var _rank_desc_label: Label = $MainContainer/LeftPanel/VBoxContainer/RankDescLabel
@onready var _score_label: Label = $MainContainer/LeftPanel/VBoxContainer/ScoreContainer/ScoreLabel

## UI节点引用 - 右侧面板
@onready var _perfect_label: Label = $MainContainer/RightPanel/VBoxContainer/PerfectRow/PerfectLabel
@onready var _good_label: Label = $MainContainer/RightPanel/VBoxContainer/GoodRow/GoodLabel
@onready var _miss_label: Label = $MainContainer/RightPanel/VBoxContainer/MissRow/MissLabel
@onready var _max_combo_label: Label = $MainContainer/RightPanel/VBoxContainer/ComboRow/MaxComboLabel
@onready var _accuracy_label: Label = $MainContainer/RightPanel/VBoxContainer/AccuracyRow/AccuracyLabel

## UI节点引用 - 底部栏
@onready var _retry_button: Button = $BottomBar/HBoxContainer/RetryButton
@onready var _back_button: Button = $BottomBar/HBoxContainer/BackButton

## 结果数据
var _result_data: Dictionary = {}

## 动画 Tween
var _animation_tween: Tween
var _score_tween: Tween
var _rank_tween: Tween

## 动画配置
const ANIMATION_DURATION := 0.5
const SCORE_ANIMATION_DURATION := 1.0
const RANK_SCALE_DURATION := 0.3


func _ready() -> void:
	_setup_ui_style()
	_connect_signals()
	_load_result_data()
	_start_animation_sequence()


## 设置UI样式
func _setup_ui_style() -> void:
	# 顶部标题样式
	_title_label.add_theme_font_size_override("font_size", 36)
	_title_label.add_theme_color_override("font_color", COLOR_GOLD)

	# 歌曲标题样式
	_song_title_label.add_theme_font_size_override("font_size", 20)
	_song_title_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))

	# 评级标签样式
	_rank_label.add_theme_font_size_override("font_size", 120)
	_rank_label.add_theme_color_override("font_color", COLOR_GOLD)

	# 评级说明样式
	_rank_desc_label.add_theme_font_size_override("font_size", 24)
	_rank_desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))

	# 分数样式
	_score_label.add_theme_font_size_override("font_size", 32)
	_score_label.add_theme_color_override("font_color", COLOR_GOLD)

	# 判定统计样式
	var perfect_name: Label = $MainContainer/RightPanel/VBoxContainer/PerfectRow/PerfectName
	perfect_name.add_theme_font_size_override("font_size", 20)
	perfect_name.add_theme_color_override("font_color", COLOR_PERFECT)
	_perfect_label.add_theme_font_size_override("font_size", 20)
	_perfect_label.add_theme_color_override("font_color", COLOR_PERFECT)

	var good_name: Label = $MainContainer/RightPanel/VBoxContainer/GoodRow/GoodName
	good_name.add_theme_font_size_override("font_size", 20)
	good_name.add_theme_color_override("font_color", COLOR_GOOD)
	_good_label.add_theme_font_size_override("font_size", 20)
	_good_label.add_theme_color_override("font_color", COLOR_GOOD)

	var miss_name: Label = $MainContainer/RightPanel/VBoxContainer/MissRow/MissName
	miss_name.add_theme_font_size_override("font_size", 20)
	miss_name.add_theme_color_override("font_color", COLOR_MISS)
	_miss_label.add_theme_font_size_override("font_size", 20)
	_miss_label.add_theme_color_override("font_color", COLOR_MISS)

	# 最大连击样式
	var combo_name: Label = $MainContainer/RightPanel/VBoxContainer/ComboRow/ComboName
	combo_name.add_theme_font_size_override("font_size", 20)
	combo_name.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	_max_combo_label.add_theme_font_size_override("font_size", 20)
	_max_combo_label.add_theme_color_override("font_color", COLOR_GOLD)

	# 精度样式
	var accuracy_name: Label = $MainContainer/RightPanel/VBoxContainer/AccuracyRow/AccuracyName
	accuracy_name.add_theme_font_size_override("font_size", 20)
	accuracy_name.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	_accuracy_label.add_theme_font_size_override("font_size", 20)
	_accuracy_label.add_theme_color_override("font_color", COLOR_ACCURACY)

	# 统计标题样式
	var stats_title: Label = $MainContainer/RightPanel/VBoxContainer/StatsTitle
	stats_title.add_theme_font_size_override("font_size", 22)
	stats_title.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))

	# 按钮样式
	_retry_button.add_theme_font_size_override("font_size", 18)
	_back_button.add_theme_font_size_override("font_size", 18)

	# 初始隐藏所有内容（用于动画）
	_set_content_visible(false)


## 连接信号
func _connect_signals() -> void:
	_retry_button.pressed.connect(_on_retry_pressed)
	_back_button.pressed.connect(_on_back_pressed)


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


## 设置内容可见性
func _set_content_visible(visible: bool) -> void:
	_rank_label.modulate.a = 1.0 if visible else 0.0
	_rank_desc_label.modulate.a = 1.0 if visible else 0.0
	_score_label.modulate.a = 1.0 if visible else 0.0
	_perfect_label.modulate.a = 1.0 if visible else 0.0
	_good_label.modulate.a = 1.0 if visible else 0.0
	_miss_label.modulate.a = 1.0 if visible else 0.0
	_max_combo_label.modulate.a = 1.0 if visible else 0.0
	_accuracy_label.modulate.a = 1.0 if visible else 0.0


## 开始动画序列
func _start_animation_sequence() -> void:
	# 更新歌曲标题
	_song_title_label.text = _result_data.get("song_title", "Unknown")

	# 初始化显示值
	_score_label.text = "0"
	_perfect_label.text = "0"
	_good_label.text = "0"
	_miss_label.text = "0"
	_max_combo_label.text = "0"
	_accuracy_label.text = "0.00%"

	# 创建动画序列
	_animation_tween = create_tween()
	_animation_tween.set_parallel(false)

	# 1. 标题淡入
	_animation_tween.tween_property(_title_label, "modulate:a", 1.0, 0.3)
	_animation_tween.tween_property(_song_title_label, "modulate:a", 1.0, 0.2)

	# 2. 评级显示动画
	_animation_tween.tween_callback(_animate_rank_appear)
	_animation_tween.tween_interval(RANK_SCALE_DURATION + 0.2)

	# 3. 分数滚动动画
	_animation_tween.tween_callback(_animate_score)

	# 4. 判定统计依次显示
	_animation_tween.tween_callback(_animate_stats)

	# 5. 按钮淡入
	_animation_tween.tween_interval(0.5)
	_animation_tween.tween_callback(_animate_buttons)


## 评级显示动画
func _animate_rank_appear() -> void:
	var rank_type = _calculate_rank()
	var rank_text = _get_rank_text(rank_type)
	var rank_color = _get_rank_color(rank_type)

	# 设置评级文本和颜色
	_rank_label.text = rank_text
	_rank_label.add_theme_color_override("font_color", rank_color)

	# 更新标题
	_update_title_for_rank(rank_type)

	# 缩放动画
	_rank_label.scale = Vector2(2.0, 2.0)
	_rank_label.modulate.a = 0.0

	if _rank_tween:
		_rank_tween.kill()

	_rank_tween = create_tween()
	_rank_tween.set_parallel(true)
	_rank_tween.tween_property(_rank_label, "scale", Vector2.ONE, RANK_SCALE_DURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	_rank_tween.tween_property(_rank_label, "modulate:a", 1.0, RANK_SCALE_DURATION * 0.5)
	_rank_tween.tween_property(_rank_desc_label, "modulate:a", 1.0, RANK_SCALE_DURATION * 0.5)


## 分数滚动动画
func _animate_score() -> void:
	var target_score = _result_data.get("score", 0)

	if _score_tween:
		_score_tween.kill()

	_score_tween = create_tween()
	_score_tween.tween_method(_set_display_score, 0, target_score, SCORE_ANIMATION_DURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	# 同时淡入
	_score_tween.set_parallel(true)
	_score_tween.tween_property(_score_label, "modulate:a", 1.0, 0.3)


## 设置显示分数（用于动画）
func _set_display_score(score: int) -> void:
	_score_label.text = _format_score(score)


## 格式化分数显示
func _format_score(score: int) -> String:
	var score_str = str(score)
	var formatted = ""
	var count = 0

	for i in range(score_str.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			formatted = "," + formatted
		formatted = score_str[i] + formatted
		count += 1

	return formatted


## 判定统计动画
func _animate_stats() -> void:
	var perfect = _result_data.get("perfect_count", 0)
	var good = _result_data.get("good_count", 0)
	var miss = _result_data.get("miss_count", 0)
	var max_combo = _result_data.get("max_combo", 0)
	var accuracy = _calculate_accuracy()

	# 创建统计动画
	var stats_tween = create_tween()
	stats_tween.set_parallel(false)

	# 依次显示各项统计
	_animate_stat_item(_perfect_label, str(perfect), stats_tween)
	_animate_stat_item(_good_label, str(good), stats_tween)
	_animate_stat_item(_miss_label, str(miss), stats_tween)
	stats_tween.tween_interval(0.1)
	_animate_stat_item(_max_combo_label, str(max_combo), stats_tween)
	_animate_stat_item(_accuracy_label, "%.2f%%" % accuracy, stats_tween)


## 单项统计动画
func _animate_stat_item(label: Label, text: String, tween: Tween) -> void:
	label.text = text
	label.modulate.a = 0.0
	label.scale = Vector2(1.5, 1.5)

	tween.set_parallel(true)
	tween.tween_property(label, "modulate:a", 1.0, 0.2)
	tween.tween_property(label, "scale", Vector2.ONE, 0.2)
	tween.set_parallel(false)
	tween.tween_interval(0.1)


## 按钮动画
func _animate_buttons() -> void:
	var buttons_tween = create_tween()

	_retry_button.modulate.a = 0.0
	_back_button.modulate.a = 0.0

	buttons_tween.set_parallel(true)
	buttons_tween.tween_property(_retry_button, "modulate:a", 1.0, 0.3)
	buttons_tween.tween_property(_back_button, "modulate:a", 1.0, 0.3)


## 计算精度
func _calculate_accuracy() -> float:
	var total_notes = _result_data.get("perfect_count", 0) + _result_data.get("good_count", 0) + _result_data.get("miss_count", 0)
	if total_notes == 0:
		return 0.0
	return (_result_data.get("perfect_count", 0) * 1.0 + _result_data.get("good_count", 0) * 0.5) / total_notes * 100.0


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


## 获取评级文本
func _get_rank_text(rank_type: RankType) -> String:
	match rank_type:
		RankType.GOLD:
			return "SS"
		RankType.SILVER:
			return "FC"
		RankType.BRONZE:
			return _calculate_letter_rank()
		RankType.FAILED:
			return "F"
		_:
			return "?"


## 获取评级颜色
func _get_rank_color(rank_type: RankType) -> Color:
	match rank_type:
		RankType.GOLD:
			return COLOR_GOLD
		RankType.SILVER:
			return COLOR_SILVER
		RankType.BRONZE:
			return COLOR_BRONZE
		RankType.FAILED:
			return COLOR_FAILED
		_:
			return Color.WHITE


## 更新标题显示
func _update_title_for_rank(rank_type: RankType) -> void:
	match rank_type:
		RankType.GOLD:
			_title_label.text = "DONDAKO FULL COMBO!"
			_title_label.add_theme_color_override("font_color", COLOR_GOLD)
		RankType.SILVER:
			_title_label.text = "FULL COMBO!"
			_title_label.add_theme_color_override("font_color", COLOR_SILVER)
		RankType.BRONZE:
			_title_label.text = "CLEARED!"
			_title_label.add_theme_color_override("font_color", COLOR_BRONZE)
		RankType.FAILED:
			_title_label.text = "FAILED..."
			_title_label.add_theme_color_override("font_color", COLOR_FAILED)


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

	# 场景过渡动画
	_transition_to_scene("res://scenes/gameplay.tscn")


## 返回按钮按下
func _on_back_pressed() -> void:
	back_to_song_select_requested.emit()

	# 重置游戏状态
	GameState.reset_game_state()

	# 场景过渡动画
	_transition_to_scene("res://scenes/song_select.tscn")


## 场景过渡动画
func _transition_to_scene(scene_path: String) -> void:
	var transition_tween = create_tween()
	transition_tween.set_ease(Tween.EASE_IN)
	transition_tween.set_trans(Tween.TRANS_QUAD)
	transition_tween.tween_property(self, "modulate:a", 0.0, 0.3)

	await transition_tween.finished
	get_tree().change_scene_to_file(scene_path)


## 设置结果数据（外部调用）
func set_result_data(data: Dictionary) -> void:
	_result_data = data
	# 重新播放动画
	_start_animation_sequence()


## 获取结果数据
func get_result_data() -> Dictionary:
	return _result_data


## 获取评级类型
func get_rank_type() -> RankType:
	return _calculate_rank()