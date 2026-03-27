extends Node
## 游戏场景脚本
## 负责场景级别的初始化和协调
##
## 功能：
## - 初始化游戏界面
## - 处理场景切换
## - 管理游戏生命周期

## 游戏界面引用
var _gameplay_ui: Control


func _ready() -> void:
	# 获取游戏界面节点
	_gameplay_ui = get_parent()
	
	# 连接游戏结束信号
	if _gameplay_ui and _gameplay_ui.has_signal("game_finished"):
		_gameplay_ui.game_finished.connect(_on_game_finished)
	
	print("游戏场景初始化完成")


## 游戏结束回调
func _on_game_finished(result: Dictionary) -> void:
	print("游戏结束，分数: %d" % result.score)