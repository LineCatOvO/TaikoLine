# Task-P1-001: UI 设计复刻 - 主菜单界面

**创建时间**：2026-03-23 **优先级**：P1 **状态**：待处理
**项目**：TaikoLine **预计时间**：4 小时

## 任务描述
复刻太鼓达人虹版主菜单界面，包括动态背景、Logo、菜单按钮和底部信息。

## 任务背景
- **问题描述**：当前主菜单界面过于简单，仅有基础按钮和标签，缺乏太鼓达人虹版的视觉风格
- **影响范围**：`res://scenes/main.tscn`、`res://scenes/main.gd`
- **相关文件**：`res://project.godot`、`res://resources/skins/`

## 详细执行计划

### 任务 1：创建 UI 资源目录结构
**ID**：task-P1-001-1 **操作**：创建目录 **文件**：`res://resources/ui/` **时间**：10 分钟

#### 操作内容
1. 创建目录 `res://resources/ui/` - 存放 UI 相关资源
2. 创建目录 `res://resources/ui/textures/` - 存放纹理资源
3. 创建目录 `res://resources/ui/fonts/` - 存放字体资源
4. 创建目录 `res://resources/ui/themes/` - 存放主题资源
5. 创建目录 `res://resources/ui/backgrounds/` - 存放背景资源

#### 预期结果
目录结构创建完成，无报错

#### 验证命令
```bash
dir C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\resources\ui
```
预期：显示 5 个子目录

#### 回滚方案
删除创建的目录即可

#### 文档同步
| 路径 | 内容 | 时机 | 优先级 |
|------|------|------|--------|
| `.agent_knowledge/raw/ui-structure.md` | UI 目录结构规范 | 完成后 | P2 |

---

### 任务 2：创建主菜单主题资源
**ID**：task-P1-001-2 **操作**：创建文件 **文件**：`res://resources/ui/themes/main_menu_theme.tres` **时间**：30 分钟

#### 操作内容
1. 在 Godot 编辑器中创建 Theme 资源
2. 定义按钮样式（正常、悬停、按下、禁用状态）
3. 定义标签样式（字体、颜色、阴影）
4. 定义容器样式（背景、边距）
5. 保存为 `main_menu_theme.tres`

#### 主题配置详情
```gdscript
# 按钮样式配置
Button:
  normal_color: Color(0.2, 0.4, 0.8, 0.9)      # 蓝紫色
  hover_color: Color(0.3, 0.5, 0.9, 1.0)       # 悬停高亮
  pressed_color: Color(0.15, 0.35, 0.7, 0.95)  # 按下状态
  disabled_color: Color(0.3, 0.3, 0.3, 0.5)    # 禁用状态
  corner_radius: 15                             # 圆角半径
  font_size: 24                                 # 字体大小
  font_color: Color(1, 1, 1, 1)                 # 白色文字
  
# 标签样式配置
Label:
  font_size: 32                                 # 标题字体大小
  font_color: Color(1, 1, 1, 1)                 # 白色文字
  shadow_color: Color(0, 0, 0, 0.5)             # 阴影颜色
  shadow_offset: Vector2(2, 2)                  # 阴影偏移
```

#### 预期结果
主题资源文件创建成功，可在 Godot 编辑器中预览

#### 验证命令
检查文件是否存在：
```bash
test -f C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\resources\ui\themes\main_menu_theme.tres
```

#### 回滚方案
删除主题文件即可

#### 文档同步
| 路径 | 内容 | 时机 | 优先级 |
|------|------|------|--------|
| `.agent_knowledge/raw/theme-system.md` | Godot Theme 系统使用指南 | 完成后 | P2 |

---

### 任务 3：创建动态背景场景
**ID**：task-P1-001-3 **操作**：创建文件 **文件**：`res://scenes/components/main_background.tscn` **时间**：45 分钟

#### 操作内容
1. 创建 Control 节点作为根节点
2. 添加 ColorRect 作为背景底色（蓝紫色渐变）
3. 添加多个 ColorRect 作为漂浮音符装饰
4. 添加光晕效果（使用 TextureRect + 渐变纹理）
5. 创建脚本实现漂浮动画

#### 背景场景结构
```
MainBackground (Control)
├── BackgroundGradient (ColorRect)
├── GlowOverlay (TextureRect)
├── FloatingNotes (Node2D)
│   ├── Note1 (Sprite2D)
│   ├── Note2 (Sprite2D)
│   └── Note3 (Sprite2D)
└── BackgroundScript (GDScript)
```

#### 背景脚本示例
```gdscript
extends Control
## 主菜单动态背景脚本

@onready var floating_notes: Node2D = $FloatingNotes

# 音符漂浮速度
var _float_speed: float = 20.0
# 音符漂浮幅度
var _float_amplitude: float = 10.0

func _ready() -> void:
    # 初始化音符位置
    _initialize_notes()

func _process(delta: float) -> void:
    # 更新漂浮动画
    _update_floating_animation(delta)

func _initialize_notes() -> void:
    # 随机分布音符位置
    for note in floating_notes.get_children():
        note.position = Vector2(
            randf_range(0, 1280),
            randf_range(0, 720)
        )

func _update_floating_animation(delta: float) -> void:
    var time = Time.get_ticks_msec() / 1000.0
    for note in floating_notes.get_children():
        # 正弦波漂浮效果
        note.position.y += sin(time + note.position.x) * _float_amplitude * delta
        note.position.x += cos(time + note.position.y) * _float_amplitude * delta
```

#### 预期结果
背景场景创建完成，运行时有动态漂浮效果

#### 验证命令
在 Godot 中打开场景预览，无报错

#### 回滚方案
删除背景场景文件即可

#### 文档同步
| 路径 | 内容 | 时机 | 优先级 |
|------|------|------|--------|
| `.agent_knowledge/raw/animation-system.md` | Godot 动画系统使用指南 | 完成后 | P2 |

---

### 任务 4：创建 Logo 场景组件
**ID**：task-P1-001-4 **操作**：创建文件 **文件**：`res://scenes/components/menu_logo.tscn` **时间**：30 分钟

#### 操作内容
1. 创建 Control 节点作为根节点
2. 添加 Label 节点显示"太鼓达人虹"
3. 添加 RichTextLabel 用于特效文字
4. 创建脚本实现呼吸动画效果
5. 添加发光效果（使用 Outline 或 Shader）

#### Logo 场景结构
```
MenuLogo (Control)
├── LogoBackground (ColorRect)
├── LogoText (Label)
│   └── LogoGlow (Label)  # 发光层
└── LogoScript (GDScript)
```

#### Logo 脚本示例
```gdscript
extends Control
## 菜单 Logo 脚本，实现呼吸动画效果

@onready var logo_text: Label = $LogoText
@onready var logo_glow: Label = $LogoGlow

# 呼吸动画参数
var _breath_speed: float = 2.0
var _breath_min_scale: float = 0.95
var _breath_max_scale: float = 1.05

func _ready() -> void:
    # 初始化发光效果
    _setup_glow_effect()

func _process(delta: float) -> void:
    # 更新呼吸动画
    _update_breath_animation(delta)

func _setup_glow_effect() -> void:
    # 设置发光层样式
    logo_glow.modulate.a = 0.5
    logo_glow.position = Vector2(2, 2)

func _update_breath_animation(delta: float) -> void:
    var time = Time.get_ticks_msec() / 1000.0
    var scale_factor = _breath_min_scale + (_breath_max_scale - _breath_min_scale) * (sin(time * _breath_speed) + 1) / 2
    logo_text.scale = Vector2(scale_factor, scale_factor)
    logo_glow.scale = Vector2(scale_factor, scale_factor)
```

#### 预期结果
Logo 组件创建完成，有呼吸动画效果

#### 验证命令
在 Godot 中打开场景预览，无报错

#### 回滚方案
删除 Logo 场景文件即可

#### 文档同步
| 路径 | 内容 | 时机 | 优先级 |
|------|------|------|--------|
| `.agent_knowledge/raw/text-effects.md` | Godot 文字特效实现指南 | 完成后 | P2 |

---

### 任务 5：创建菜单按钮组件
**ID**：task-P1-001-5 **操作**：创建文件 **文件**：`res://scenes/components/menu_button.tscn` **时间**：45 分钟

#### 操作内容
1. 创建 Button 节点作为根节点
2. 添加 Icon 节点显示音符图标
3. 添加 Label 节点显示按钮文字
4. 创建脚本实现悬停放大和选中高亮动画
5. 添加音效（悬停音、确认音）

#### 按钮场景结构
```
MenuButton (Button)
├── ButtonBackground (ColorRect)
├── ButtonIcon (TextureRect)
├── ButtonLabel (Label)
├── HoverEffect (ColorRect)
└── ButtonScript (GDScript)
```

#### 按钮脚本示例
```gdscript
extends Button
## 菜单按钮脚本，实现悬停放大和选中高亮动画

@onready var button_background: ColorRect = $ButtonBackground
@onready var hover_effect: ColorRect = $HoverEffect
@onready var button_label: Label = $ButtonLabel

# 动画参数
var _hover_scale: float = 1.1
var _normal_scale: float = 1.0
var _animation_speed: float = 10.0

# 音效
@onready var hover_sound: AudioStreamPlayer = $HoverSound
@onready var confirm_sound: AudioStreamPlayer = $ConfirmSound

var _is_hovered: bool = false
var _current_scale: float = 1.0

func _ready() -> void:
    # 连接信号
    mouse_entered.connect(_on_mouse_entered)
    mouse_exited.connect(_on_mouse_exited)
    pressed.connect(_on_pressed)
    # 初始化状态
    hover_effect.modulate.a = 0.0

func _process(delta: float) -> void:
    # 平滑缩放动画
    _update_scale_animation(delta)

func _on_mouse_entered() -> void:
    _is_hovered = true
    hover_sound.play()
    # 显示悬停效果
    var tween = create_tween()
    tween.tween_property(hover_effect, "modulate:a", 0.3, 0.2)

func _on_mouse_exited() -> void:
    _is_hovered = false
    # 隐藏悬停效果
    var tween = create_tween()
    tween.tween_property(hover_effect, "modulate:a", 0.0, 0.2)

func _on_pressed() -> void:
    confirm_sound.play()

func _update_scale_animation(delta: float) -> void:
    var target_scale = _hover_scale if _is_hovered else _normal_scale
    _current_scale = lerp(_current_scale, target_scale, _animation_speed * delta)
    scale = Vector2(_current_scale, _current_scale)
```

#### 预期结果
按钮组件创建完成，有悬停和点击动画效果

#### 验证命令
在 Godot 中打开场景预览，测试悬停和点击效果

#### 回滚方案
删除按钮场景文件即可

#### 文档同步
| 路径 | 内容 | 时机 | 优先级 |
|------|------|------|--------|
| `.agent_knowledge/raw/button-system.md` | Godot 按钮系统高级用法 | 完成后 | P2 |

---

### 任务 6：重构主菜单场景
**ID**：task-P1-001-6 **操作**：修改文件 **文件**：`res://scenes/main.tscn` **时间**：60 分钟

#### 操作内容
1. 备份原场景文件
2. 重构场景结构，使用新创建的组件
3. 设置主题资源
4. 调整布局和锚点
5. 连接信号

#### 新场景结构
```
Main (Control)
├── MainBackground (PackedScene: main_background.tscn)
├── MenuLogo (PackedScene: menu_logo.tscn)
├── MenuContainer (VBoxContainer)
│   ├── StartButton (PackedScene: menu_button.tscn)
│   ├── OptionsButton (PackedScene: menu_button.tscn)
│   └── ExitButton (PackedScene: menu_button.tscn)
├── BottomInfo (HBoxContainer)
│   ├── VersionLabel (Label)
│   ├── CopyrightLabel (Label)
│   └── HintLabel (Label)
└── MainScript (GDScript)
```

#### 场景配置详情
```gdscript
# Main 节点配置
anchors_preset = 15  # 全屏
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
theme = load("res://resources/ui/themes/main_menu_theme.tres")

# MenuContainer 配置
layout_mode = 1  # 锚点模式
anchors_preset = 8  # 中心
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -150.0
offset_top = -100.0
offset_right = 150.0
offset_bottom = 100.0
grow_horizontal = 2
grow_vertical = 2
alignment = BoxContainer.ALIGNMENT_CENTER

# BottomInfo 配置
layout_mode = 1
anchors_preset = 12  # 底部
anchor_left = 0.0
anchor_top = 1.0
anchor_right = 1.0
anchor_bottom = 1.0
offset_top = -40.0
grow_horizontal = 2
grow_vertical = 0
alignment = BoxContainer.ALIGNMENT_CENTER
```

#### 预期结果
主菜单场景重构完成，所有组件正常工作

#### 验证命令
在 Godot 中运行场景，无报错

#### 回滚方案
使用备份的原场景文件恢复

#### 文档同步
| 路径 | 内容 | 时机 | 优先级 |
|------|------|------|--------|
| `.agent_knowledge/raw/scene-composition.md` | Godot 场景组合最佳实践 | 完成后 | P2 |

---

### 任务 7：实现主菜单脚本逻辑
**ID**：task-P1-001-7 **操作**：修改文件 **文件**：`res://scenes/main.gd` **时间**：30 分钟

#### 操作内容
1. 实现按钮信号连接
2. 实现键盘导航（上下键选择，Enter 确认）
3. 实现按钮焦点管理
4. 添加背景音乐
5. 添加场景过渡动画

#### 主菜单脚本示例
```gdscript
extends Control
## 主菜单场景脚本

signal menu_button_pressed(button_name: String)

# 按钮列表
@onready var buttons: Array[Button] = [
    $MenuContainer/StartButton,
    $MenuContainer/OptionsButton,
    $MenuContainer/ExitButton
]

# 当前选中的按钮索引
var _selected_index: int = 0
var _navigation_enabled: bool = true

# 音效
@onready var bgm_player: AudioStreamPlayer = $BackgroundMusic
@onready var navigate_sound: AudioStreamPlayer = $NavigateSound

func _ready() -> void:
    # 连接按钮信号
    _connect_button_signals()
    # 初始化选中状态
    _update_button_focus()
    # 播放背景音乐
    _start_background_music()

func _input(event: InputEvent) -> void:
    if not _navigation_enabled:
        return
    
    if event is InputEventKey and event.pressed:
        match event.keycode:
            KEY_UP:
                _navigate_up()
            KEY_DOWN:
                _navigate_down()
            KEY_ENTER, KEY_SPACE:
                _confirm_selection()

func _connect_button_signals() -> void:
    for i in range(buttons.size()):
        buttons[i].pressed.connect(_on_button_pressed.bind(i))

func _on_button_pressed(index: int) -> void:
    _selected_index = index
    match index:
        0:  # StartButton
            _start_game()
        1:  # OptionsButton
            _open_options()
        2:  # ExitButton
            _exit_game()

func _navigate_up() -> void:
    navigate_sound.play()
    _selected_index = (_selected_index - 1 + buttons.size()) % buttons.size()
    _update_button_focus()

func _navigate_down() -> void:
    navigate_sound.play()
    _selected_index = (_selected_index + 1) % buttons.size()
    _update_button_focus()

func _update_button_focus() -> void:
    for i in range(buttons.size()):
        buttons[i].grab_focus() if i == _selected_index else buttons[i].release_focus()

func _confirm_selection() -> void:
    buttons[_selected_index].emit_signal("pressed")

func _start_game() -> void:
    # 场景过渡动画
    var tween = create_tween()
    tween.tween_property(self, "modulate:a", 0.0, 0.3)
    tween.tween_callback(get_tree().change_scene_to_file.bind("res://scenes/song_select.tscn"))

func _open_options() -> void:
    # TODO: 实现选项界面
    pass

func _exit_game() -> void:
    get_tree().quit()

func _start_background_music() -> void:
    bgm_player.volume_db = -10.0
    bgm_player.play()
```

#### 预期结果
主菜单脚本功能完整，键盘导航和按钮点击正常工作

#### 验证命令
运行场景，测试键盘导航和按钮功能

#### 回滚方案
使用 Git 恢复原文件

#### 文档同步
| 路径 | 内容 | 时机 | 优先级 |
|------|------|------|--------|
| `.agent_knowledge/raw/input-navigation.md` | Godot 输入导航系统实现指南 | 完成后 | P2 |

---

### 任务 8：创建底部信息组件
**ID**：task-P1-001-8 **操作**：创建文件 **文件**：`res://scenes/components/bottom_info.tscn` **时间**：20 分钟

#### 操作内容
1. 创建 HBoxContainer 作为根节点
2. 添加三个 Label 节点（版本号、版权信息、操作提示）
3. 设置样式和布局
4. 实现版本号自动读取

#### 底部信息场景结构
```
BottomInfo (HBoxContainer)
├── VersionLabel (Label)
├── Spacer1 (Control)
├── CopyrightLabel (Label)
├── Spacer2 (Control)
└── HintLabel (Label)
```

#### 底部信息脚本示例
```gdscript
extends HBoxContainer
## 底部信息组件脚本

@onready var version_label: Label = $VersionLabel
@onready var copyright_label: Label = $CopyrightLabel
@onready var hint_label: Label = $HintLabel

func _ready() -> void:
    # 自动读取版本号
    _load_version_info()
    # 设置版权信息
    _setup_copyright_info()
    # 设置操作提示
    _setup_input_hint()

func _load_version_info() -> void:
    var version = ProjectSettings.get_setting("application/config/version", "1.0.0")
    version_label.text = "Ver. %s" % version

func _setup_copyright_info() -> void:
    copyright_label.text = "© 2026 TaikoLine Team"

func _setup_input_hint() -> void:
    hint_label.text = "按 Enter 确认 | ↑↓ 选择 | Esc 返回"
```

#### 预期结果
底部信息组件创建完成，显示正确的版本号和提示信息

#### 验证命令
运行场景，检查底部信息显示

#### 回滚方案
删除组件文件即可

#### 文档同步
| 路径 | 内容 | 时机 | 优先级 |
|------|------|------|--------|
| `.agent_knowledge/raw/version-system.md` | Godot 版本管理系统 | 完成后 | P3 |

---

### 任务 9：创建音效资源
**ID**：task-P1-001-9 **操作**：创建文件 **文件**：`res://resources/sounds/ui/` **时间**：30 分钟

#### 操作内容
1. 创建目录 `res://resources/sounds/ui/`
2. 创建或导入以下音效文件：
   - `hover.wav` - 悬停音效
   - `confirm.wav` - 确认音效
   - `navigate.wav` - 导航音效
   - `bgm_menu.ogg` - 菜单背景音乐
3. 使用 `scripts/create_sound_effects.py` 生成简单音效

#### 音效配置
| 音效名称 | 用途 | 时长 | 音量 |
|----------|------|------|------|
| hover.wav | 鼠标悬停按钮 | 0.1s | -15dB |
| confirm.wav | 按钮确认 | 0.2s | -10dB |
| navigate.wav | 键盘导航 | 0.1s | -20dB |
| bgm_menu.ogg | 背景音乐 | 循环 | -10dB |

#### 预期结果
音效资源创建完成，可在场景中播放

#### 验证命令
```bash
dir C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\resources\sounds\ui
```

#### 回滚方案
删除音效目录即可

#### 文档同步
| 路径 | 内容 | 时机 | 优先级 |
|------|------|------|--------|
| `.agent_knowledge/raw/audio-system.md` | Godot 音频系统使用指南 | 完成后 | P2 |

---

### 任务 10：添加响应式布局支持
**ID**：task-P1-001-10 **操作**：修改文件 **文件**：`res://scenes/main.tscn` **时间**：30 分钟

#### 操作内容
1. 设置容器的锚点和生长模式
2. 添加 Container 节点的边距和间距
3. 测试不同分辨率下的显示效果
4. 确保在 1280x720 基准分辨率下完美显示

#### 响应式配置
```gdscript
# 主容器响应式配置
MenuContainer:
  anchors_preset = 8  # 中心锚点
  anchor_left = 0.5
  anchor_top = 0.5
  anchor_right = 0.5
  anchor_bottom = 0.5
  offset_left = -150.0  # 半宽
  offset_right = 150.0
  grow_horizontal = 2  # 居中生长
  
# 底部信息响应式配置
BottomInfo:
  anchors_preset = 12  # 底部拉伸
  anchor_left = 0.0
  anchor_top = 1.0
  anchor_right = 1.0
  anchor_bottom = 1.0
  offset_top = -40.0  # 高度 40px
  grow_horizontal = 2  # 水平拉伸
```

#### 预期结果
在不同分辨率下界面正常显示，无错位

#### 验证命令
在 Godot 中切换不同分辨率预览

#### 回滚方案
使用 Git 恢复原文件

#### 文档同步
| 路径 | 内容 | 时机 | 优先级 |
|------|------|------|--------|
| `.agent_knowledge/raw/responsive-ui.md` | Godot 响应式 UI 设计指南 | 完成后 | P2 |

---

## 验收标准

### 视觉验收
- [ ] 背景有蓝紫色渐变效果
- [ ] 背景有漂浮的音符装饰元素
- [ ] 背景有光晕效果
- [ ] Logo 位于屏幕上方中央
- [ ] Logo 有呼吸动画效果
- [ ] 菜单按钮位于屏幕中央偏下
- [ ] 按钮有圆角矩形样式
- [ ] 按钮有光晕效果
- [ ] 按钮悬停时有放大效果
- [ ] 按钮选中时有高亮效果
- [ ] 底部显示版本号
- [ ] 底部显示版权信息
- [ ] 底部显示操作提示

### 功能验收
- [ ] "游戏开始"按钮可点击，跳转到选歌界面
- [ ] "选项"按钮可点击（预留功能）
- [ ] "退出"按钮可点击，退出游戏
- [ ] 键盘↑↓键可切换选中按钮
- [ ] Enter/Space 键可确认选择
- [ ] 悬停音效正常播放
- [ ] 确认音效正常播放
- [ ] 背景音乐正常播放

### 技术验收
- [ ] 使用 Godot 4.4 Control 节点
- [ ] 使用 Theme 资源统一定义样式
- [ ] 使用 Tween 实现动画
- [ ] 响应式设计支持 1280x720
- [ ] 无控制台报错
- [ ] 代码有详细注释
- [ ] Git 提交记录完整

### 性能验收
- [ ] 场景加载时间 < 2 秒
- [ ] 动画帧率稳定 60FPS
- [ ] 内存占用 < 100MB

## 风险评估

| 风险 | 级别 | 策略 |
|------|------|------|
| 音效资源缺失 | 低 | 使用程序生成或临时占位符 |
| 动画效果不流畅 | 低 | 使用 Tween 系统，优化 _process 逻辑 |
| 响应式布局问题 | 中 | 多分辨率测试，使用锚点系统 |
| 主题资源兼容性问题 | 低 | 参考 Godot 4.4 官方文档 |

## 标签
`UI` `Godot` `太鼓达人` `主菜单` `P1` `前端`

## 依赖关系
- 依赖 P0 任务（测试套件）已完成 ✅
- 不依赖其他 P1 任务

## 相关文件清单

### 新建文件
| 文件路径 | 说明 |
|----------|------|
| `res://resources/ui/textures/.gitkeep` | UI 纹理目录占位符 |
| `res://resources/ui/fonts/.gitkeep` | UI 字体目录占位符 |
| `res://resources/ui/themes/main_menu_theme.tres` | 主菜单主题资源 |
| `res://resources/ui/backgrounds/.gitkeep` | UI 背景目录占位符 |
| `res://scenes/components/main_background.tscn` | 动态背景场景 |
| `res://scenes/components/main_background.gd` | 动态背景脚本 |
| `res://scenes/components/menu_logo.tscn` | Logo 场景组件 |
| `res://scenes/components/menu_logo.gd` | Logo 脚本 |
| `res://scenes/components/menu_button.tscn` | 菜单按钮场景 |
| `res://scenes/components/menu_button.gd` | 菜单按钮脚本 |
| `res://scenes/components/bottom_info.tscn` | 底部信息场景 |
| `res://scenes/components/bottom_info.gd` | 底部信息脚本 |
| `res://resources/sounds/ui/hover.wav` | 悬停音效 |
| `res://resources/sounds/ui/confirm.wav` | 确认音效 |
| `res://resources/sounds/ui/navigate.wav` | 导航音效 |
| `res://resources/sounds/ui/bgm_menu.ogg` | 菜单背景音乐 |

### 修改文件
| 文件路径 | 说明 |
|----------|------|
| `res://scenes/main.tscn` | 重构主菜单场景 |
| `res://scenes/main.gd` | 实现主菜单逻辑 |
| `res://project.godot` | 添加版本号配置 |

## 预计时间
总计：约 4 小时

| 任务 | 预计时间 |
|------|----------|
| 任务 1：创建 UI 资源目录 | 10 分钟 |
| 任务 2：创建主题资源 | 30 分钟 |
| 任务 3：创建动态背景 | 45 分钟 |
| 任务 4：创建 Logo 组件 | 30 分钟 |
| 任务 5：创建菜单按钮 | 45 分钟 |
| 任务 6：重构主菜单场景 | 60 分钟 |
| 任务 7：实现主菜单脚本 | 30 分钟 |
| 任务 8：创建底部信息 | 20 分钟 |
| 任务 9：创建音效资源 | 30 分钟 |
| 任务 10：响应式布局 | 30 分钟 |
| **总计** | **330 分钟（5.5 小时）** |

## 备注
- 所有新建的 PackedScene 应添加到 `res://scenes/components/` 目录
- 所有脚本应添加详细注释，说明功能、参数、返回值
- 所有资源文件应使用小写字母和下划线命名
- 音效文件可使用开源音效或程序生成
- 主题资源应在 Godot 编辑器中可视化创建
