# 魂槽系统

本文档详细说明 TaikoLine 的魂槽系统，包括魂槽机制说明、增长/减少规则和通关条件。

## 魂槽机制说明

### 什么是魂槽

魂槽（Soul Gauge）是太鼓达人系列的核心机制之一，表示玩家的演奏状态。魂槽的增减反映了玩家的演奏表现，达到一定阈值即为通关。

### 魂槽特性

| 特性 | 说明 |
|------|------|
| 最大值 | 10000 |
| 通关阈值 | 8000（80%） |
| 初始值 | 0 |
| 可见性 | 实时显示在游戏界面 |

### 魂槽配置

```gdscript
## 魂槽配置
@export var max_soul_gauge: float = 10000.0      ## 魂槽最大值
@export var soul_gain_perfect: float = 100.0     ## 良判定增加量
@export var soul_gain_good: float = 50.0         ## 可判定增加量
@export var soul_loss_miss: float = -200.0       ## 不可判定减少量
@export var soul_threshold_clear: float = 8000.0 ## 通关阈值
```

## 增长/减少规则

### 判定与魂槽变化

| 判定等级 | 魂槽变化 | Go-Go Time | 说明 |
|---------|---------|-----------|------|
| 良 | +100 | +120 | 完美判定，大幅增加 |
| 可 | +50 | +60 | 良好判定，小幅增加 |
| 不可 | -200 | -200 | 失误判定，大幅减少 |

### 魂槽变化代码

```gdscript
## 更新魂槽
func _update_soul_gauge(amount: float) -> void:
    soul_gauge = clampf(soul_gauge + amount, 0.0, max_soul_gauge)
    soul_gauge_updated.emit(soul_gauge)

    # 检查清除状态
    if soul_gauge >= soul_threshold_clear:
        is_cleared = true

## 良判定处理
func _on_perfect_judge() -> void:
    # ... 其他处理 ...

    # 更新魂槽
    var soul_gain = soul_gain_perfect
    if is_gogo_time:
        soul_gain *= GOGO_SCORE_MULTIPLIER
    _update_soul_gauge(soul_gain)

## 可判定处理
func _on_good_judge() -> void:
    # ... 其他处理 ...

    # 更新魂槽
    var soul_gain = soul_gain_good
    if is_gogo_time:
        soul_gain *= GOGO_SCORE_MULTIPLIER
    _update_soul_gauge(soul_gain)

## 不可判定处理
func _on_miss_judge() -> void:
    # ... 其他处理 ...

    # 更新魂槽
    _update_soul_gauge(soul_loss_miss)
```

### 魂槽变化示意图

```
魂槽值
10000 ┤                                        ┌──────
      │                                  ┌─────┘
 8000 ┤──────────────────────────────────┘      ← 通关线
      │                          ┌───────┘
 6000 ┤                    ┌─────┘
      │              ┌─────┘
 4000 ┤        ┌─────┘
      │  ┌─────┘
 2000 ┤──┘
      │
    0 ┼──────────────────────────────────────────
      0   10   20   30   40   50   60   70   80
                           音符数
```

## 通关条件

### 基本条件

魂槽达到 **8000**（80%）即为通关。

```gdscript
## 检查是否在清除状态
func is_clear_status() -> bool:
    return soul_gauge >= soul_threshold_clear
```

### 通关判定时机

通关状态在游戏过程中实时判定，一旦魂槽达到阈值即标记为通关：

```gdscript
## 更新魂槽
func _update_soul_gauge(amount: float) -> void:
    soul_gauge = clampf(soul_gauge + amount, 0.0, max_soul_gauge)
    soul_gauge_updated.emit(soul_gauge)

    # 检查清除状态
    if soul_gauge >= soul_threshold_clear:
        is_cleared = true
```

### 游戏结束判定

```gdscript
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
```

## 魂槽显示组件

### 组件配置

```gdscript
class_name SoulGauge
extends Control

## 配置
@export var max_soul: float = 10000.0
@export var clear_threshold: float = 8000.0  ## 清除阈值
@export var animation_duration: float = 0.3

## 颜色配置
@export var normal_color: Color = Color(0.3, 0.6, 1.0)  ## 蓝色
@export var clear_color: Color = Color(1.0, 0.8, 0.0)   ## 金色（清除状态）
@export var danger_color: Color = Color(1.0, 0.3, 0.3)  ## 红色（危险状态）
```

### 魂槽颜色变化

| 魂槽状态 | 颜色 | 说明 |
|---------|------|------|
| 低于30% | 红色 | 危险状态 |
| 30%-80% | 蓝色 | 正常状态 |
| 80%以上 | 金色 | 通关状态 |

### 更新魂槽显示

```gdscript
## 更新魂槽值
func update_soul(soul: float) -> void:
    var old_soul = _current_soul
    _current_soul = clamp(soul, 0.0, max_soul)

    # 计算百分比
    var percentage = (_current_soul / max_soul) * 100.0

    # 更新标签
    _label.text = "%.1f%%" % percentage

    # 更新填充条
    _update_fill(percentage)

    # 检查清除状态变化
    var was_clear = _is_clear
    _is_clear = _current_soul >= clear_threshold

    if _is_clear and not was_clear:
        _on_threshold_reached()
    elif not _is_clear and was_clear:
        _on_threshold_lost()

    # 更新颜色
    _update_color()
```

### 颜色更新逻辑

```gdscript
## 更新颜色
func _update_color() -> void:
    var target_color: Color

    if _is_clear:
        target_color = clear_color
    elif _current_soul < max_soul * 0.3:
        target_color = danger_color
    else:
        target_color = normal_color

    if _tween:
        _tween.kill()

    _tween = create_tween()
    _tween.tween_property(_fill, "color", target_color, 0.2)
```

### 达到阈值动画

```gdscript
## 达到阈值回调
func _on_threshold_reached() -> void:
    soul_threshold_reached.emit()

    # 播放闪烁动画
    if _tween:
        _tween.kill()

    _tween = create_tween()
    _tween.tween_property(_fill, "modulate", Color(1.5, 1.5, 1.5), 0.1)
    _tween.tween_property(_fill, "modulate", Color.WHITE, 0.1)
```

## 魂槽百分比计算

```gdscript
## 获取魂槽百分比
func get_soul_percentage() -> float:
    return (soul_gauge / max_soul_gauge) * 100.0
```

## 魂槽与游戏结果

### 结果数据结构

```gdscript
var result = {
    "cleared": is_cleared,           ## 是否通关
    "full_combo": false,             ## 是否全连
    "dondoko_full_combo": false,     ## 是否全良
    "score": current_score,          ## 最终分数
    "max_combo": max_combo,          ## 最大连击
    "perfect_count": ...,            ## 良判定数
    "good_count": ...,               ## 可判定数
    "miss_count": ...                ## 不可判定数
}
```

## 相关文件

- 判定系统实现: `src/game/judge.gd`
- 魂槽显示组件: `src/ui/components/soul_gauge.gd`
- 游戏控制器: `src/game/game_controller.gd`