# 任务：实现音频高级选项功能

## 任务信息
- **优先级**: P1
- **类型**: feature
- **状态**: completed
- **创建时间**: 2026-04-03
- **完成时间**: 2026-04-03
- **操作范围**: 单子项目：TaikoLine

## 任务目标
实现 TaikoLine 项目音频高级选项功能，包括：
1. 缓冲区大小设置（256/512/1024/2048）
2. 音频偏移微调（-100ms ~ +100ms）
3. 音量分离控制（主音量、音乐音量、音效音量）
4. 音频设备选择（列出可用输出设备）

## 现状分析

### 已有功能
- 音量分离控制（主音量、音乐音量、音效音量） - 已实现
- 音频设备选择 - 已实现
- 音频偏移设置 - 已实现（范围 -500ms ~ +500ms）
- 缓冲区设置 - 已实现（只有 3 个抽象选项）

### 已完成改进
1. **缓冲区大小设置**：从抽象选项改为具体数值（256/512/1024/2048）
2. **音频偏移范围**：从 -500ms ~ +500ms 改为 -100ms ~ +100ms

## 执行计划

### 步骤 1：修改缓冲区设置
- 修改 `src/autoload/settings.gd` - 更新 buffer_size 存储为具体数值
- 修改 `src/audio/audio_manager.gd` - 更新缓冲区应用逻辑
- 修改 `src/ui/settings.gd` - 更新缓冲区选项和回调

### 步骤 2：修改音频偏移范围
- 修改 `scenes/settings.tscn` - 更新滑块范围
- 修改 `src/ui/settings.gd` - 更新显示逻辑

### 步骤 3：验证功能
- 运行 Godot 项目验证功能

## 进度记录
| 步骤 | 状态 | 时间 | 备注 |
|------|------|------|------|
| 分析现有代码 | 完成 | 2026-04-03 | 已分析 audio_manager.gd, settings.gd, settings.tscn |
| 修改缓冲区设置 | 完成 | 2026-04-03 | 已修改所有相关文件 |
| 修改音频偏移范围 | 完成 | 2026-04-03 | 已修改滑块范围 |
| 验证功能 | 完成 | 2026-04-03 | Godot 项目验证通过 |

## 事件记录
- 2026-04-03: 开始任务分析，发现大部分功能已实现，需要改进缓冲区和偏移范围
- 2026-04-03: 完成缓冲区设置改进，改为具体数值（256/512/1024/2048）
- 2026-04-03: 完成音频偏移范围改进，改为 -100ms ~ +100ms
- 2026-04-03: Godot 项目验证通过，无语法错误

## 修改文件列表
1. `/workspaces/agent-workspace/projects/TaikoLine/src/autoload/settings.gd`
   - 更新 buffer_size 变量注释和默认值
   - 更新 load_settings 和 reset_to_defaults 中的默认值

2. `/workspaces/agent-workspace/projects/TaikoLine/src/audio/audio_manager.gd`
   - 新增 BUFFER_SIZE_OPTIONS 常量
   - 重写 apply_buffer_settings 函数，使用具体数值
   - 新增 get_current_buffer_size 和 get_buffer_size_options 函数
   - 更新 check_audio_system 函数

3. `/workspaces/agent-workspace/projects/TaikoLine/src/ui/settings.gd`
   - 更新 BUFFER_SIZES 常量，改为具体数值
   - 新增 _select_current_buffer_size 函数
   - 更新 _on_buffer_size_selected 和 _apply_buffer_settings 函数
   - 更新 _reset_to_defaults 函数

4. `/workspaces/agent-workspace/projects/TaikoLine/scenes/settings.tscn`
   - 更新 AudioOffsetSlider 的 min_value 和 max_value