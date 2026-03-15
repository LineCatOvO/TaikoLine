extends Node

## 游戏状态管理
## 管理当前游戏的全局状态

## 当前选中的歌曲
var current_song: Dictionary = {}
## 当前难度
var current_course: String = "Oni"
## 当前分数
var current_score: int = 0
## 当前连击
var current_combo: int = 0
## 最大连击
var max_combo: int = 0
## 判定统计
var judge_counts: Dictionary = {
	"良": 0,
	"可": 0,
	"不可": 0
}

## 重置游戏状态
func reset_game_state() -> void:
	current_score = 0
	current_combo = 0
	max_combo = 0
	judge_counts = {"良": 0, "可": 0, "不可": 0}

## 添加判定
func add_judge(judge_type: String) -> void:
	if judge_type in judge_counts:
		judge_counts[judge_type] += 1
	if judge_type != "不可":
		current_combo += 1
		if current_combo > max_combo:
			max_combo = current_combo
	else:
		current_combo = 0