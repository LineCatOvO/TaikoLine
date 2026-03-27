# UI 音效目录

本目录存放 UI 相关的音效文件。

## 音效文件说明

| 文件名 | 用途 | 时长 | 音量 |
|--------|------|------|------|
| hover.wav | 鼠标悬停按钮 | 0.1s | -15dB |
| confirm.wav | 按钮确认 | 0.2s | -10dB |
| navigate.wav | 键盘导航 | 0.08s | -20dB |

## 生成音效

运行以下脚本生成简单的 UI 音效：

```gdscript
# 在 Godot 编辑器中运行
res://scripts/generate_ui_sounds.gd
```

或者使用命令行：

```bash
godot --headless --script res://scripts/generate_ui_sounds.gd
```

## 自定义音效

如需使用自定义音效，请替换对应的 .wav 文件，保持文件名不变。

## 音效格式要求

- 格式：WAV
- 采样率：44100 Hz
- 位深度：16-bit
- 声道：单声道（Mono）