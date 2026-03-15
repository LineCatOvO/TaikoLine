# TaikoLine 项目文档

欢迎来到 TaikoLine 项目文档中心。本文档提供了太鼓达人风格节奏游戏模拟器的完整技术说明。

## 文档导航

### 游戏机制

| 文档 | 说明 |
|------|------|
| [音符类型](./game-mechanics/notes.md) | 所有音符类型的详细说明，包括TJA代码、操作方式和得分特点 |
| [判定系统](./game-mechanics/judgment.md) | 判定等级、判定时间窗口和判定与分数的关系 |
| [分数系统](./game-mechanics/scoring.md) | 分数计算公式、连击加成机制和Go-Go Time加成 |
| [魂槽系统](./game-mechanics/soul-gauge.md) | 魂槽机制说明、增长/减少规则和通关条件 |
| [分支谱面](./game-mechanics/branching.md) | 分支类型、分支判定逻辑和背景颜色标识 |

### TJA格式

| 文档 | 说明 |
|------|------|
| [TJA格式规范](./tja-format/specification.md) | TJA文件的完整格式规范，包括元数据命令和谱面命令 |
| [TJA示例](./tja-format/examples.md) | 完整的TJA文件示例和各种命令的使用示例 |

### 开发指南

| 文档 | 说明 |
|------|------|
| [项目架构](./development/architecture.md) | 项目结构说明、模块划分和数据流说明 |
| [API参考](./development/api-reference.md) | 主要类和方法说明、Autoload单例说明和信号说明 |

## 快速开始

### 环境要求

- Godot 4.4 或更高版本

### 运行项目

1. 使用 Godot 编辑器打开项目
2. 打开 `scenes/main.tscn` 作为主场景
3. 按 F5 或点击运行按钮启动游戏

### 操作方式

| 按键 | 功能 |
|------|------|
| F | 红音符（左） |
| J | 红音符（右） |
| D | 蓝音符（左） |
| K | 蓝音符（右） |
| Enter | 确认 |
| Escape | 取消/返回 |

## 项目概述

TaikoLine 是一个开源的太鼓达人风格节奏游戏模拟器，使用 Godot 4.4 和 GDScript 开发。项目支持 TJA 格式谱面文件的解析和游玩，具有完整的游戏系统架构。

### 核心特性

- **完整的TJA解析** - 支持所有TJA格式命令
- **精确判定系统** - 三级判定（良、可、不可）
- **分支谱面支持** - 支持普通/玄人/达人分支
- **模块化设计** - 清晰的代码架构

## 许可证

MIT License