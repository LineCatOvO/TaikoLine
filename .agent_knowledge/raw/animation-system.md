# Godot 动画系统使用指南

**来源**：Task-P1-001 UI 设计复刻 - 主菜单界面
**时间**：2026-03-27
**代理**：Coder

## 内容

### 呼吸动画实现

使用正弦波实现平滑的缩放变化：

```gdscript
## 呼吸动画速度（每秒周期数）
@export var breathe_speed: float = 2.0

## 呼吸幅度（缩放变化范围）
@export var breathe_amplitude: float = 0.05

func _process(delta: float) -> void:
    var time = Time.get_ticks_msec() / 1000.0
    # 计算目标缩放值：基础缩放 + 正弦波变化
    var scale_factor = sin(time * breathe_speed) * breathe_amplitude
    var target_scale = _base_scale + scale_factor
    # 使用 lerp 实现平滑过渡
    _current_scale = lerp(_current_scale, target_scale, 10.0 * delta)
    scale = Vector2(_current_scale, _current_scale)
```

### 悬停缩放动画

使用 lerp 实现平滑的悬停放大效果：

```gdscript
@export var hover_scale: float = 1.1
@export var animation_speed: float = 10.0

var _is_hovered: bool = false
var _current_scale: Vector2 = Vector2(1, 1)

func _process(delta: float) -> void:
    var target_scale = hover_scale if _is_hovered else 1.0
    _current_scale.x = lerp(_current_scale.x, target_scale, animation_speed * delta)
    _current_scale.y = lerp(_current_scale.y, target_scale, animation_speed * delta)
    scale = _base_scale * _current_scale
```

### 场景过渡动画

使用 Tween 实现淡入淡出效果：

```gdscript
const TRANSITION_DURATION: float = 0.3

func _change_scene(scene_path: String) -> void:
    var tween = create_tween()
    tween.set_ease(Tween.EASE_IN)
    tween.set_trans(Tween.TRANS_QUAD)
    tween.tween_property(self, "modulate:a", 0.0, TRANSITION_DURATION)
    await tween.finished
    get_tree().change_scene_to_file(scene_path)
```

### 漂浮动画

使用正弦波和余弦波组合实现漂浮效果：

```gdscript
func _update_floating_animation(delta: float, time: float) -> void:
    for i in range(floating_notes.get_child_count()):
        var note = floating_notes.get_child(i)
        var offset = i * 2.0  # 每个音符有不同的相位偏移
        # 正弦波漂浮效果（上下）
        note.position.y += sin(time + offset) * float_amplitude * delta * 0.5
        # 余弦波漂浮效果（左右，速度较慢）
        note.position.x += cos(time * 0.5 + offset) * float_amplitude * delta * 0.3
```

### 注意事项

1. 使用 `Time.get_ticks_msec() / 1000.0` 获取平滑的时间值
2. 使用 `lerp()` 实现平滑过渡，避免突兀的变化
3. 为每个动画对象设置不同的相位偏移，避免同步
4. 在 `_process()` 中更新动画，确保帧率独立

## 标签

`Godot` `Animation` `Tween` `lerp` `动画系统`