# 判定系统

本文档详细说明 TaikoLine 的判定系统，包括判定等级、判定时间窗口、难度对判定的影响以及判定与分数的关系。

## 判定等级

TaikoLine 采用三级判定系统：

| 判定等级 | 日文名称 | 英文名称 | 说明 |
|---------|---------|----------|------|
| 良 | 良 | Perfect | 完美判定，获得最高分数 |
| 可 | 可 | Good | 良好判定，获得部分分数 |
| 不可 | 不可 | Miss | 失误判定，不得分且中断连击 |

## 判定时间窗口

### 默认判定窗口

| 判定等级 | 时间窗口 | 说明 |
|---------|---------|------|
| 良 | ±33ms | 在音符前后 33 毫秒内击打 |
| 可 | ±100ms | 在音符前后 100 毫秒内击打 |
| 不可 | >100ms | 超出 100 毫秒范围 |

### 判定窗口示意图

```
                    音符位置
                        │
    ◄───── 不可 ─────► │ ◄───── 不可 ─────►
    ◄── 可 ──►         │         ◄── 可 ──►
    ◄良►               │               ◄良►
    
    -100ms    -33ms    0ms    +33ms    +100ms
       │        │       │       │        │
       └────────┴───────┴───────┴────────┘
          可判定区    良判定区    可判定区
```

### 判定窗口配置

```gdscript
## 判定窗口配置（毫秒）
@export var perfect_window: float = 33.0   ## 良判定窗口
@export var good_window: float = 100.0     ## 可判定窗口
```

## 判定流程

### 1. 判定计算

```gdscript
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

    return judge_name
```

### 2. 判定结果处理

```gdscript
## 良判定处理
func _on_perfect_judge() -> void:
    # 更新连击
    current_combo += 1
    if current_combo > max_combo:
        max_combo = current_combo

    # 计算分数（含连击加成）
    var combo_bonus = _calculate_combo_bonus()
    var base_score_value = int(base_score * (1.0 + combo_bonus))

    # 应用Go-Go Time加成
    if is_gogo_time:
        base_score_value = int(base_score_value * GOGO_SCORE_MULTIPLIER)

    current_score += base_score_value

    # 更新魂槽
    _update_soul_gauge(soul_gain_perfect)

## 可判定处理
func _on_good_judge() -> void:
    # 更新连击
    current_combo += 1
    if current_combo > max_combo:
        max_combo = current_combo

    # 更新魂槽
    _update_soul_gauge(soul_gain_good)

    # 可判定不计入全良
    is_dondoko_full_combo = false

## 不可判定处理
func _on_miss_judge() -> void:
    # 重置连击
    current_combo = 0

    # 更新魂槽（减少）
    _update_soul_gauge(soul_loss_miss)

    # 更新清除状态
    is_full_combo = false
    is_dondoko_full_combo = false
```

## 判定与分数的关系

### 分数计算

| 判定等级 | 基础分数 | 连击加成 | Go-Go加成 |
|---------|---------|---------|----------|
| 良 | 基础值 × (1 + 连击加成) | 支持 | × 1.2 |
| 可 | 0 | - | - |
| 不可 | 0 | - | - |

### 连击加成机制

```gdscript
## 连击加成系数
const COMBO_BONUS_THRESHOLD: int = 10  ## 开始加成的连击数
const COMBO_BONUS_MAX: float = 1.0     ## 最大加成系数

## 计算连击加成
func _calculate_combo_bonus() -> float:
    if current_combo < COMBO_BONUS_THRESHOLD:
        return 0.0

    # 线性增长，最大为 COMBO_BONUS_MAX
    var bonus = (current_combo - COMBO_BONUS_THRESHOLD) * 0.01
    return minf(bonus, COMBO_BONUS_MAX)
```

### 连击加成表

| 连击数 | 加成系数 | 说明 |
|-------|---------|------|
| 1-10 | 0% | 无加成 |
| 11 | 1% | 开始加成 |
| 20 | 10% | - |
| 50 | 40% | - |
| 100+ | 100% | 最大加成 |

## 判定与魂槽的关系

### 魂槽变化

| 判定等级 | 魂槽变化 | Go-Go Time |
|---------|---------|-----------|
| 良 | +100 | +120 |
| 可 | +50 | +60 |
| 不可 | -200 | -200 |

### 魂槽配置

```gdscript
## 魂槽配置
@export var max_soul_gauge: float = 10000.0
@export var soul_gain_perfect: float = 100.0
@export var soul_gain_good: float = 50.0
@export var soul_loss_miss: float = -200.0
@export var soul_threshold_clear: float = 8000.0  ## 清除阈值
```

## 判定精度计算

### 精度公式

```
精度 = (良数 × 1.0 + 可数 × 0.5 + 不可数 × 0.0) / 总音符数
```

### 代码实现

```gdscript
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
```

## 评级系统

### 评级标准

| 评级 | 精度要求 | 说明 |
|------|---------|------|
| SS | 100% | 全良 |
| S | ≥95% | 优秀 |
| A | ≥90% | 良好 |
| B | ≥80% | 一般 |
| C | ≥70% | 及格 |
| D | ≥60% | 较差 |
| F | <60% | 失败 |

### 代码实现

```gdscript
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
```

## 特殊判定状态

### 全连 (Full Combo)

```gdscript
## 检查全连
if judge_counts[JudgeType.MISS] == 0 and total_notes > 0:
    is_full_combo = true
```

### 全良 (Dondoko Full Combo)

```gdscript
## 检查全良
if judge_counts[JudgeType.MISS] == 0 and judge_counts[JudgeType.GOOD] == 0:
    is_dondoko_full_combo = true
```

## 判定统计

### 获取判定统计

```gdscript
## 获取判定统计
func get_judge_counts() -> Dictionary:
    return {
        "良": judge_counts[JudgeType.PERFECT],
        "可": judge_counts[JudgeType.GOOD],
        "不可": judge_counts[JudgeType.MISS]
    }
```

## 相关文件

- 判定系统实现: `src/game/judge.gd`
- 音符类: `src/game/note.gd`
- 游戏控制器: `src/game/game_controller.gd`