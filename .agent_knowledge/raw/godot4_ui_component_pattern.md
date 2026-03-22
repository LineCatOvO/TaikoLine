# Godot 4 UI 组件开发模式
**来源**：TaikoLine 项目菜单组件开发 **时间**：2026-03-23 **代理**：Coder

## 内容

### 1. GDScript 文件头部注释规范
```gdscript
## 组件名称
## 功能：功能描述
## 作者：团队名称
## 日期：YYYY-MM-DD
```

### 2. 变量声明最佳实践
- 使用 `@onready` 延迟加载子节点引用
- 使用 `@export` 导出可编辑变量
- 私有变量使用 `_` 前缀
- 所有变量添加类型注解

### 3. 动画实现模式
**呼吸动画**（使用正弦波）：
```gdscript
func _update_breathe_animation(delta: float) -> void:
    var time = Time.get_ticks_msec() / 1000.0
    var target_scale = _base_scale + sin(time * breathe_speed) * breathe_amplitude
    _current_scale = lerp(_current_scale, target_scale, 10.0 * delta)
    scale = Vector2(_current_scale, _current_scale)
```

**悬停动画**（状态驱动）：
```gdscript
func _update_hover_animation(delta: float) -> void:
    var target_scale = hover_scale if _is_hovered else 1.0
    _current_scale.x = lerp(_current_scale.x, target_scale, animation_speed * delta)
    _current_scale.y = lerp(_current_scale.y, target_scale, animation_speed * delta)
    scale = _base_scale * _current_scale
```

### 4. 组件通信模式
- 信号连接在 tscn 文件中定义
- 回调函数预留扩展（使用 pass）
- 公共方法使用清晰的命名

### 5. 版本信息读取
```gdscript
func _update_version() -> void:
    var version = ProjectSettings.get_setting("application/config/version", "v1.0.0")
    version_label.text = "版本：" + version
```

## 注意事项
1. tscn 文件使用 format=3（Godot 4 格式）
2. 使用 uid:// 前缀定义唯一标识符
3. Control 节点使用 layout_mode = 1（锚点模式）
4. 信号连接在场景文件末尾定义

## 标签
#godot4 #ui 组件 #gdscript #动画 #最佳实践
