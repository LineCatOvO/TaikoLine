# 分支谱面

本文档详细说明 TaikoLine 的分支谱面系统，包括分支类型、分支判定逻辑和背景颜色标识。

## 分支类型

### 三种分支

| 分支类型 | 英文名称 | TJA命令 | 背景颜色 | 说明 |
|---------|----------|---------|---------|------|
| 普通分支 | Normal | #N | 灰色 | 基础难度谱面 |
| 高级分支 | Expert | #E | 蓝色 | 中等难度谱面 |
| 大师分支 | Master | #M | 紫色 | 最高难度谱面 |

### 分支枚举定义

```gdscript
## 分支类型枚举
enum BranchType {
    NORMAL = 0,  ## 普通分支
    EXPERT = 1,  ## 高级分支
    MASTER = 2   ## 大师分支
}
```

## 分支判定逻辑

### 判定条件类型

| 条件类型 | 代码 | 说明 |
|---------|------|------|
| 精度判定 | p | 根据判定精度决定分支 |
| 连打次数 | r | 根据连打次数决定分支 |

### 分支条件数据结构

```gdscript
## 分支条件类型枚举
enum BranchConditionType {
    ACCURACY = 0,    ## 准确率判定
    RENDA = 1,       ## 连打次数判定
    SCORE = 2        ## 分数判定
}

## 分支条件数据类
class BranchCondition:
    ## 条件类型
    var condition_type: BranchConditionType = BranchConditionType.ACCURACY
    ## 普通分支阈值（低于此值进入普通分支）
    var normal_threshold: float = 0.0
    ## 高级分支阈值（低于此值进入高级分支，高于则进入大师分支）
    var expert_threshold: float = 0.0
    ## 条件触发时间点
    var trigger_time: float = 0.0
    ## 是否已判定
    var is_judged: bool = false
    ## 判定结果
    var result_branch: BranchType = BranchType.NORMAL
```

### 分支判定公式

```gdscript
## 根据当前值判定分支
func evaluate(current_value: float) -> BranchType:
    if current_value >= expert_threshold:
        result_branch = BranchType.MASTER
    elif current_value >= normal_threshold:
        result_branch = BranchType.EXPERT
    else:
        result_branch = BranchType.NORMAL
    is_judged = true
    return result_branch
```

### 分支判定示意图

```
当前值
    │
    │         ┌─────────────────► 大师分支 (Master)
    │         │
    │    ┌────┴────┐
    │    │         │
    │    │    ┌────┴────────────► 高级分支 (Expert)
    │    │    │
    │    │    │
    │    └────┴─────────────────► 普通分支 (Normal)
    │
    └────┼────┼──────────────────
         │    │
      normal  expert
      阈值    阈值
```

## TJA分支命令

### #BRANCHSTART 命令

**语法**: `#BRANCHSTART 条件类型, 普通阈值, 高级阈值`

**示例**:
```
#BRANCHSTART p,75,90   # 精度判定：75%以下普通，75-90%高级，90%以上大师
#BRANCHSTART r,30,50   # 连打判定：30次以下普通，30-50次高级，50次以上大师
```

### 分支谱面定义

```
#BRANCHSTART p,75,90
#N
1000000000001000,
1000000000002000,
#E
1010101010101010,
2020202020202020,
#M
1110111011101110,
2220222022202220,
#BRANCHEND
```

### #SECTION 命令

重置分支判定条件：

```
#SECTION
#BRANCHSTART p,80,95
```

## 分支判定实现

### 初始化分支条件

```gdscript
## 初始化分支条件
func _initialize_branch_conditions() -> void:
    if not current_course.has_branch:
        return

    _pending_branch_conditions = current_course.branch_conditions.duplicate()
    _branch_condition_index = 0

    # 计算每个分支条件的触发时间
    var current_time = current_song.offset
    for measure in current_course.measures:
        for condition in _pending_branch_conditions:
            if condition.trigger_time == 0.0:
                # 根据小节索引计算触发时间
                condition.trigger_time = current_time
        current_time += measure.get_duration()
```

### 检查分支条件

```gdscript
## 检查分支条件
func _check_branch_conditions() -> void:
    if _pending_branch_conditions.is_empty():
        return

    # 检查是否有需要判定的分支条件
    for i in range(_pending_branch_conditions.size()):
        var condition = _pending_branch_conditions[i]
        if condition.is_judged:
            continue

        # 检查是否到达触发时间
        if game_time >= condition.trigger_time:
            _evaluate_branch_condition(condition)
```

### 评估分支条件

```gdscript
## 评估分支条件
func _evaluate_branch_condition(condition: TJAData.BranchCondition) -> void:
    var current_value: float = 0.0

    # 根据条件类型获取当前值
    match condition.condition_type:
        TJAData.BranchConditionType.ACCURACY:
            current_value = judge_system.get_accuracy() * 100.0
        TJAData.BranchConditionType.RENDA:
            current_value = float(judge_system.get_max_renda_count())
        TJAData.BranchConditionType.SCORE:
            current_value = float(judge_system.get_score())

    # 评估分支
    var new_branch = condition.evaluate(current_value)

    # 如果分支发生变化
    if new_branch != current_branch:
        current_branch = new_branch
        current_course.current_branch = new_branch

        # 通知音符管理器切换分支
        if note_manager:
            note_manager.switch_branch(new_branch)

        # 发送分支切换信号
        branch_changed.emit(new_branch)
```

## 分支切换信号

```gdscript
## 信号
signal branch_changed(new_branch: int)  ## 分支切换信号
```

## 分支谱面数据存储

### 课程类中的分支数据

```gdscript
class TJACourse:
    # ... 其他属性 ...

    ## 分支谱面数据
    var branches: Dictionary = {
        BranchType.NORMAL: [],   ## 普通分支小节
        BranchType.EXPERT: [],   ## 高级分支小节
        BranchType.MASTER: []    ## 大师分支小节
    }
    ## 是否有分支
    var has_branch: bool = false
    ## 分支条件列表
    var branch_conditions: Array[BranchCondition] = []
    ## 当前分支
    var current_branch: BranchType = BranchType.NORMAL

    ## 获取指定分支的小节数据
    func get_branch_measures(branch: BranchType) -> Array:
        return branches.get(branch, [])

    ## 设置分支小节数据
    func set_branch_measures(branch: BranchType, branch_measures: Array) -> void:
        branches[branch] = branch_measures
```

## 背景颜色标识

### 颜色定义

| 分支 | 颜色 | RGB值 |
|------|------|-------|
| 普通 | 灰色 | (128, 128, 128) |
| 高级 | 蓝色 | (100, 150, 255) |
| 大师 | 紫色 | (200, 100, 255) |

### 视觉效果

```
┌─────────────────────────────────────┐
│                                     │
│   普通分支 (灰色背景)                │
│   ┌─────────────────────────────┐   │
│   │  ●   ●   ○   ●   ●   ○    │   │
│   └─────────────────────────────┘   │
│                                     │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│                                     │
│   高级分支 (蓝色背景)                │
│   ┌─────────────────────────────┐   │
│   │  ●●  ●●  ○○  ●●  ●●  ○○  │   │
│   └─────────────────────────────┘   │
│                                     │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│                                     │
│   大师分支 (紫色背景)                │
│   ┌─────────────────────────────┐   │
│   │  ●●● ●●● ○○○ ●●● ●●● ○○○ │   │
│   └─────────────────────────────┘   │
│                                     │
└─────────────────────────────────────┘
```

## 分支谱面示例

### 完整TJA示例

```
TITLE:分支测试歌曲
BPM:120
WAVE:test.ogg
OFFSET:0.0

COURSE:Oni
LEVEL:8
BALLOON:10

#START
1000000000001000,
1000000000002000,
1000000000001000,
1000000000002000,
#BRANCHSTART p,70,85
#N
1000000000001000,
1000000000002000,
#E
1010101010101010,
2020202020202020,
#M
1110111011101110,
2220222022202220,
#BRANCHEND
1000000000001000,
#END
```

## 相关文件

- 分支数据结构: `src/parser/tja_data.gd`
- TJA解析器: `src/parser/tja_parser.gd`
- 游戏控制器: `src/game/game_controller.gd`