extends Node
## 结果场景脚本
## 负责场景级别的初始化和资源管理

## 场景引用
@onready var _result_ui: ResultUI = $Result


func _ready() -> void:
	# 场景初始化完成
	# ResultUI 会自动加载和显示结果数据
	pass


## 获取结果UI组件
func get_result_ui() -> ResultUI:
	return _result_ui