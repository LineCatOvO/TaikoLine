class_name JudgeSystem
extends Node
## 判定系统
## 实现判定逻辑、连击管理、分数计算和魂槽系统

## 信号
signal score_updated(score: int)
signal combo_updated(combo: int)
signal judge_result(judge_type: String, note_type: int)
signal soul_gauge_updated(gauge: float)
signal full_combo_achieved()
signal dondoko_full_combo_achieved()

## 判定类型
enum JudgeType {
	PERFECT,  ## 良
	GOOD,     ## 可
	MISS      ## 不可
}

## 判定窗口配置（毫秒）
@export var perfect_window: float = 33.0
@export var good_window: float = 100.0

## 分数配置
@export var base_score: int = 1000
@export var score_diff: int = 100

## 魂槽配置
@export var max_soul_gauge: float = 10000.0
@export var soul_gain_perfect: float = 100.0
@export var soul_gain_good: float = 50.0
@export var soul_loss_miss: float = -200.0
@export var soul_threshold_clear: float = 8000.0  ## 清除阈值

## 当前状态
var current_score: int = 0
var current_combo: int = 0
var max_combo: int = 0
var soul_gauge: float = 0.0

## 判定统计
var judge_counts: Dictionary = {
	JudgeType.PERFECT: 0,
	JudgeType.GOOD: 0,
	JudgeType.MISS: 0
}

## 总音符数
var total_notes: int = 0

## 是否已清除
var is_cleared: bool = false

## 是否全连
var is_full_combo: bool = false

## 是否魂全连（全良）
var is_dondoko_full_combo: bool = false

## 连击加成系数
const COMBO_BONUS_THRESHOLD: int = 10  ## 开始加成的连击数
const COMBO_BONUS_MAX: float = 1.0     ## 最大加成系数

## Go-Go Time配置
const GOGO_SCORE_MULTIPLIER: float = 1.2  ## Go-Go Time分数倍率

## Go-Go Time状态
var is_gogo_time: bool = false

## 最大连打次数（用于分支判定）
var max_renda_count: int = 0
var current_renda_count: int = 0


func _ready() -> void:
	reset()


## 重置判定系统
func reset() -> void:
	current_score = 0
	current_combo = 0
	max_combo = 0
	soul_gauge = 0.0
	judge_counts = {
		JudgeType.PERFECT: 0,
		JudgeType.GOOD: 0,
		JudgeType.MISS: 0
	}
	total_notes = 0
	is_cleared = false
	is_full_combo = false
	is_dondoko_full_combo = true  ## 初始假设全良
	is_gogo_time = false
	max_renda_count = 0
	current_renda_count = 0


## 设置Go-Go Time状态
func set_gogo_time(enabled: bool) -> void:
	is_gogo_time = enabled


## 获取最大连打次数
func get_max_renda_count() -> int:
	return max_renda_count


## 记录连打
func record_renda() -> void:
	current_renda_count += 1
	if current_renda_count > max_renda_count:
		max_renda_count = current_renda_count


## 重置连打计数
func reset_renda_count() -> void:
	current_renda_count = 0


## 设置总音符数
func set_total_notes(count: int) -> void:
	total_notes = count


## 设置分数参数
func set_score_params(init: int, diff: int) -> void:
	base_score = init
	score_diff = diff


## 判定音符
func judge_note(time_diff_ms: float, note_type: int = 0) -> String:
	var judge_type: JudgeType
	var judge_name: String
	
	# 计算判定类型
	var abs_diff = abs(time_diff_ms)
	
	if abs_diff <= perfect_window:
		judge_type = JudgeType.PERFECT
		judge_name = "良"
	elif abs_diff <= good_window:
		judge_type = JudgeType.GOOD
		judge_name = "可"
	else:
		judge_type = JudgeType.MISS
		judge_name = "不可"
	
	# 更新统计
	judge_counts[judge_type] += 1
	
	# 处理判定结果
	match judge_type:
		JudgeType.PERFECT:
			_on_perfect_judge()
		JudgeType.GOOD:
			_on_good_judge()
		JudgeType.MISS:
			_on_miss_judge()
	
	# 发送信号
	judge_result.emit(judge_name, note_type)
	
	return judge_name


## 良判定处理
func _on_perfect_judge() -> void:
	# 更新连击
	current_combo += 1
	if current_combo > max_combo:
		max_combo = current_combo

	# 计算分数
	var combo_bonus = _calculate_combo_bonus()
	var base_score_value = int(base_score * (1.0 + combo_bonus))
	
	# 应用Go-Go Time加成
	if is_gogo_time:
		base_score_value = int(base_score_value * GOGO_SCORE_MULTIPLIER)
	
	current_score += base_score_value

	# 更新魂槽
	var soul_gain = soul_gain_perfect
	if is_gogo_time:
		soul_gain *= GOGO_SCORE_MULTIPLIER
	_update_soul_gauge(soul_gain)

	# 发送更新信号
	score_updated.emit(current_score)
	combo_updated.emit(current_combo)


## 可判定处理
func _on_good_judge() -> void:
	# 更新连击
	current_combo += 1
	if current_combo > max_combo:
		max_combo = current_combo

	# 更新魂槽
	var soul_gain = soul_gain_good
	if is_gogo_time:
		soul_gain *= GOGO_SCORE_MULTIPLIER
	_update_soul_gauge(soul_gain)

	# 可判定不计入全良
	is_dondoko_full_combo = false

	# 发送更新信号
	score_updated.emit(current_score)
	combo_updated.emit(current_combo)


## 不可判定处理
func _on_miss_judge() -> void:
	# 重置连击
	current_combo = 0
	
	# 更新魂槽
	_update_soul_gauge(soul_loss_miss)
	
	# 更新清除状态
	is_full_combo = false
	is_dondoko_full_combo = false
	
	# 发送更新信号
	combo_updated.emit(current_combo)


## 计算连击加成
func _calculate_combo_bonus() -> float:
	if current_combo < COMBO_BONUS_THRESHOLD:
		return 0.0
	
	# 线性增长，最大为 COMBO_BONUS_MAX
	var bonus = (current_combo - COMBO_BONUS_THRESHOLD) * 0.01
	return minf(bonus, COMBO_BONUS_MAX)


## 更新魂槽
func _update_soul_gauge(amount: float) -> void:
	soul_gauge = clampf(soul_gauge + amount, 0.0, max_soul_gauge)
	soul_gauge_updated.emit(soul_gauge)
	
	# 检查清除状态
	if soul_gauge >= soul_threshold_clear:
		is_cleared = true


## 检查游戏结束状态
func check_game_end() -> Dictionary:
	var result = {
		"cleared": is_cleared,
		"full_combo": false,
		"dondoko_full_combo": false,
		"score": current_score,
		"max_combo": max_combo,
		"perfect_count": judge_counts[JudgeType.PERFECT],
		"good_count": judge_counts[JudgeType.GOOD],
		"miss_count": judge_counts[JudgeType.MISS]
	}
	
	# 检查全连
	if judge_counts[JudgeType.MISS] == 0 and total_notes > 0:
		is_full_combo = true
		result.full_combo = true
		full_combo_achieved.emit()
		
		# 检查全良
		if judge_counts[JudgeType.GOOD] == 0:
			is_dondoko_full_combo = true
			result.dondoko_full_combo = true
			dondoko_full_combo_achieved.emit()
	
	return result


## 获取判定精度
func get_accuracy() -> float:
	if total_notes == 0:
		return 0.0
	
	var perfect_weight = 1.0
	var good_weight = 0.5
	var miss_weight = 0.0
	
	var weighted_sum = (
		judge_counts[JudgeType.PERFECT] * perfect_weight +
		judge_counts[JudgeType.GOOD] * good_weight +
		judge_counts[JudgeType.MISS] * miss_weight
	)
	
	return weighted_sum / total_notes


## 获取评级
func get_rank() -> String:
	var accuracy = get_accuracy()
	
	if accuracy >= 1.0:
		return "SS"  ## 全良
	elif accuracy >= 0.95:
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


## 获取魂槽百分比
func get_soul_percentage() -> float:
	return (soul_gauge / max_soul_gauge) * 100.0


## 检查是否在清除状态
func is_clear_status() -> bool:
	return soul_gauge >= soul_threshold_clear


## 获取连击数
func get_combo() -> int:
	return current_combo


## 获取最大连击
func get_max_combo() -> int:
	return max_combo


## 获取分数
func get_score() -> int:
	return current_score


## 获取判定统计
func get_judge_counts() -> Dictionary:
	return {
		"良": judge_counts[JudgeType.PERFECT],
		"可": judge_counts[JudgeType.GOOD],
		"不可": judge_counts[JudgeType.MISS]
	}


## 计算理论最高分
func calculate_max_score() -> int:
	var max_score = 0
	for i in range(total_notes):
		var combo_bonus = 0.0
		if i >= COMBO_BONUS_THRESHOLD:
			combo_bonus = minf((i - COMBO_BONUS_THRESHOLD) * 0.01, COMBO_BONUS_MAX)
		max_score += int(base_score * (1.0 + combo_bonus))
	return max_score