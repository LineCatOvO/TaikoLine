# 分数系统

本文档详细说明 TaikoLine 的分数系统，包括分数计算公式、连击加成机制、Go-Go Time 加成以及连打/气球得分。

## 分数计算公式

### 基础公式

```
单音符得分 = INIT + max(0, DIFF × floor((min(COMBO, 100) - 1) / 10))
```

其中：
- `INIT` = 基础分数（由 `SCOREINIT` 定义）
- `DIFF` = 分数差值（由 `SCOREDIFF` 定义）
- `COMBO` = 当前连击数

### 参数说明

| 参数 | TJA命令 | 说明 |
|------|---------|------|
| INIT | SCOREINIT | 基础分数值 |
| DIFF | SCOREDIFF | 连击加成增量 |

### 代码实现

```gdscript
## 分数配置
@export var base_score: int = 1000   ## 基础分数 (SCOREINIT)
@export var score_diff: int = 100    ## 分数差值 (SCOREDIFF)

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
```

## 连击加成机制

### 加成规则

| 连击范围 | 加成计算 | 示例（DIFF=100） |
|---------|---------|-----------------|
| 1-10 | 0% | 1000 分 |
| 11-20 | 1%-10% | 1010-1100 分 |
| 21-30 | 11%-20% | 1110-1200 分 |
| ... | ... | ... |
| 91-100 | 81%-90% | 1810-1900 分 |
| 100+ | 100%（最大） | 2000 分 |

### 连击加成曲线

```
加成系数
    │
1.0 ┤                                    ────────────
    │                              ──────
0.8 ┤                        ──────
    │                  ──────
0.6 ┤            ──────
    │      ──────
0.4 ┤──────
    │
0.2 ┤
    │
0.0 ┼────────────────────────────────────────────────
    0    10   20   30   40   50   60   70   80   90  100+
                              连击数
```

### 连击中断

当出现「不可」判定时，连击数重置为 0：

```gdscript
## 不可判定处理
func _on_miss_judge() -> void:
    # 重置连击
    current_combo = 0

    # 更新魂槽
    _update_soul_gauge(soul_loss_miss)

    # 更新清除状态
    is_full_combo = false
    is_dondoko_full_combo = false
```

## Go-Go Time 加成

### 加成规则

在 Go-Go Time 期间，所有得分乘以 1.2 倍。

```gdscript
## Go-Go Time配置
const GOGO_SCORE_MULTIPLIER: float = 1.2  ## Go-Go Time分数倍率

## Go-Go Time状态
var is_gogo_time: bool = false
```

### Go-Go Time 得分计算

```gdscript
## 良判定处理（含Go-Go Time）
func _on_perfect_judge() -> void:
    var combo_bonus = _calculate_combo_bonus()
    var base_score_value = int(base_score * (1.0 + combo_bonus))

    # 应用Go-Go Time加成
    if is_gogo_time:
        base_score_value = int(base_score_value * GOGO_SCORE_MULTIPLIER)

    current_score += base_score_value
```

### Go-Go Time 得分示例

| 连击数 | 普通得分 | Go-Go Time 得分 |
|-------|---------|----------------|
| 1 | 1000 | 1200 |
| 10 | 1000 | 1200 |
| 20 | 1100 | 1320 |
| 50 | 1400 | 1680 |
| 100 | 2000 | 2400 |

### Go-Go Time 触发

```gdscript
## 检查Go-Go Time状态
func _check_gogo_time() -> void:
    var was_gogo = is_gogo_time
    is_gogo_time = false

    # 检查当前时间是否在任何Go-Go Time区间内
    for section in _gogo_sections:
        if game_time >= section.start and game_time < section.end:
            is_gogo_time = true
            break

    # 更新判定系统的Go-Go Time状态
    if judge_system:
        judge_system.set_gogo_time(is_gogo_time)

    # 发送Go-Go Time信号
    if is_gogo_time and not was_gogo:
        gogo_started.emit()
    elif not is_gogo_time and was_gogo:
        gogo_ended.emit()
```

## 连打/气球得分

### 连打得分

| 连打类型 | TJA代码 | 每击得分 | Go-Go Time |
|---------|---------|---------|-----------|
| 普通连打 | 5 | 100 | 120 |
| 大连打 | 6 | 200 | 240 |

### 气球得分

| 项目 | 得分 |
|------|------|
| 每击得分 | 300 |
| 完成奖励 | 5000 |
| Go-Go Time 每击 | 360 |

### 久寿玉得分

与气球相同：
- 每击得分：300
- 完成奖励：5000

### 连打计数

```gdscript
## 记录连打
func record_renda() -> void:
    current_renda_count += 1
    if current_renda_count > max_renda_count:
        max_renda_count = current_renda_count

## 获取最大连打次数
func get_max_renda_count() -> int:
    return max_renda_count
```

## 理论最高分计算

### 计算公式

```gdscript
## 计算理论最高分
func calculate_max_score() -> int:
    var max_score = 0
    for i in range(total_notes):
        var combo_bonus = 0.0
        if i >= COMBO_BONUS_THRESHOLD:
            combo_bonus = minf((i - COMBO_BONUS_THRESHOLD) * 0.01, COMBO_BONUS_MAX)
        max_score += int(base_score * (1.0 + combo_bonus))
    return max_score
```

### 理论最高分示例

假设：
- 总音符数：100
- SCOREINIT：1000
- SCOREDIFF：100

计算：
```
音符 1-10:  1000 × 10 = 10,000
音符 11-20: 1010-1100 × 10 = 10,550
音符 21-30: 1110-1200 × 10 = 11,550
音符 31-40: 1210-1300 × 10 = 12,550
音符 41-50: 1310-1400 × 10 = 13,550
音符 51-60: 1410-1500 × 10 = 14,550
音符 61-70: 1510-1600 × 10 = 15,550
音符 71-80: 1610-1700 × 10 = 16,550
音符 81-90: 1710-1800 × 10 = 17,550
音符 91-100: 1900-2000 × 10 = 19,500

理论最高分 ≈ 142,400
```

## 分数显示

### 分数更新信号

```gdscript
## 信号
signal score_updated(score: int)

## 分数更新回调
func _on_score_updated(score: int) -> void:
    # 更新全局状态
    GameState.current_score = score
```

### 获取当前分数

```gdscript
## 获取分数
func get_score() -> int:
    return current_score
```

## 相关文件

- 判定系统实现: `src/game/judge.gd`
- 游戏控制器: `src/game/game_controller.gd`
- 分数显示组件: `src/ui/components/score_display.gd`