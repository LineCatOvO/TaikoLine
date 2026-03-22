# Godot UI 资源创建规范
**来源**：Task-P1-001 步骤 1-3 执行经验 **时间**：2026-03-23 **代理**：Coder

## 内容

### 1. UI 资源目录结构
```
res://resources/ui/
├── textures/     # UI 纹理资源
├── fonts/        # UI 字体资源
├── themes/       # UI 主题资源 (.tres)
└── backgrounds/  # UI 背景资源

res://resources/sounds/ui/  # UI 音效资源
```

### 2. Theme 资源文件格式 (.tres)
- 文件头：`[gd_resource type="Theme" load_steps=2 format=3 uid="uid://<名称>"]`
- 子资源：`[sub_resource type="Font" id="<ID>"]`
- 样式框：`[stylebox:"<属性>"/"<类型>"] = SubResource("<ID>")`
- 字体大小：`[font_sizes:"font_size"/"<类型>"] = <大小>`
- 颜色属性：`[color:"<属性>"/"<类型>"] = Color(r, g, b, a)`

### 3. 场景文件格式 (.tscn)
- 文件头：`[gd_scene format=3 uid="uid://<名称>"]`
- 节点定义：`[node name="<名称>" type="<类型>" parent="<父节点>"]`
- 属性设置：直接写在节点下方
- 信号连接：`[connection signal="<信号>" from="<源>" to="<目标>" method="<方法>"]`

### 4. GDScript 脚本规范
- 继承：`extends <类型>`
- 导出变量：`@export var <变量>: <类型> = <默认值>`
- 就绪变量：`@onready var <变量>: <类型> = $<路径>`
- 私有变量：以下划线开头 `_`
- 函数注释：使用 `##` 添加函数说明

### 5. 漂浮动画实现
```gdscript
# 时间偏移（随机化起始位置）
var _time_offset: float = randf() * 10.0

# 使用三角函数实现平滑动画
position.y += sin(time + offset) * amplitude * delta * 系数
position.x += cos(time * 系数 + offset) * amplitude * delta * 系数
```

## 注意事项
1. Godot 资源文件必须包含唯一的 uid
2. 场景文件中的节点路径使用 `$` 前缀
3. 颜色值使用归一化的 RGBA (0.0-1.0)
4. 动画计算需要考虑 delta 时间保证帧率独立

## 相关命令
```bash
# 创建目录结构
mkdir resources\ui\textures
mkdir resources\ui\fonts
mkdir resources\ui\themes
mkdir resources\ui\backgrounds
mkdir resources\sounds\ui
```

## 标签
#godot #ui #resources #theme #scene #gdscript #animation
