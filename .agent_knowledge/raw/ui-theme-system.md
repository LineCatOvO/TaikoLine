# Godot Theme 系统使用指南

**来源**：Task-P1-001 UI 设计复刻 - 主菜单界面
**时间**：2026-03-27
**代理**：Coder

## 内容

### Theme 资源结构

Godot 4.4 的 Theme 资源可以统一定义 UI 控件的样式，包括颜色、字体、样式盒等。

### StyleBoxFlat 配置

```gdscript
# 创建 StyleBoxFlat 用于按钮样式
[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_normal"]
bg_color = Color(0.2, 0.15, 0.4, 0.9)  # 背景色
corner_radius_top_left = 15              # 圆角
corner_radius_top_right = 15
corner_radius_bottom_left = 15
corner_radius_bottom_right = 15
shadow_color = Color(0, 0, 0, 0.3)       # 阴影颜色
shadow_size = 4                           # 阴影大小
shadow_offset = Vector2(2, 2)            # 阴影偏移
```

### 按钮状态样式

| 状态 | StyleBox | 说明 |
|------|----------|------|
| normal | StyleBoxFlat_normal | 默认状态 |
| hover | StyleBoxFlat_hover | 鼠标悬停 |
| pressed | StyleBoxFlat_pressed | 按下状态 |
| disabled | StyleBoxFlat_disabled | 禁用状态 |
| focus | StyleBoxFlat_focus | 获得焦点 |

### 主题应用

```gdscript
# 在场景中应用主题
func _ready() -> void:
    theme = preload("res://resources/ui/themes/main_menu_theme.tres")
```

### 注意事项

1. Theme 资源使用 `.tres` 扩展名
2. StyleBoxFlat 可以定义圆角、边框、阴影等效果
3. 主题可以继承和覆盖
4. 使用 `theme_override_*` 可以在节点级别覆盖主题设置

## 标签

`Godot` `Theme` `UI` `StyleBox` `样式系统`