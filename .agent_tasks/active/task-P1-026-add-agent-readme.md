# Task-P1-026: 添加 Agent Readme 文件

**创建时间**：2026-03-21
**更新时间**：2026-03-21
**优先级**：P1
**状态**：待处理
**任务锁**：🔓 待处理 - Planner - 2026-03-21
**项目**：TaikoLine
**预计执行时间**：约5分钟

## 任务描述

在 TaikoLine 项目根目录添加 AGENT_README.md 文件，写入 Godot 项目编译规则说明。

## 任务背景

### 问题分析
- **问题描述**：项目缺少 Agent 指导文档，Agent 在处理项目修改后不知道需要执行 Windows 编译
- **影响范围**：项目构建流程、Agent 行为规范
- **根本原因**：项目创建时未添加 Agent 指导文档

### 当前状态分析
- **相关文件**：
  - `C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\README.md` - 项目说明文档
  - `C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\export_presets.cfg` - 导出预设配置
  - `C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\export\windows\` - Windows 编译输出目录
- **当前配置**：
  - 项目类型：Godot 4.4 游戏项目
  - 已有导出预设：Android (arm64-v8a), Web, Windows Desktop
  - Windows 编译输出：export/windows/TaikoLine.exe
- **依赖关系**：
  - 需要参考工作目录的 AGENT_ENV.md 格式
  - 需要参考 code-fever-aio 项目的 AGENTS.md 格式

### 修改原因
用户要求添加 Agent 指导文档，明确 Godot 项目修改后需要编译 Windows 版本，保持编译成品最新。

## 详细执行计划

### 任务1：创建 AGENT_README.md 文件

**任务ID**：task-readme-1
**操作类型**：文件创建
**目标文件**：C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\AGENT_README.md
**预计执行时间**：约2分钟

#### 任务背景
创建 Agent 指导文档，明确项目修改后的编译规则。

#### 操作命令（必填）
```
操作：使用 write_file 工具
文件路径：C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\AGENT_README.md
文件内容：见下方完整内容
```

#### 操作内容（详细步骤）
1. 使用 write_file 工具创建 AGENT_README.md 文件
   - 输入：文件路径和完整内容
   - 操作：写入文件
   - 输出：创建成功的文件
2. 使用 read_file 工具验证文件内容正确

#### 文件完整内容
```markdown
# AGENT_README.md - Agent 项目指导文档

**最后更新**: 2026-03-21
**适用项目**: TaikoLine

---

## 项目类型

- **引擎**: Godot 4.4
- **语言**: GDScript
- **平台**: Windows Desktop, Web, Android

---

## Agent 行为规则

### 编译规则

> **重要**: Godot 项目修改后默认要编译 Windows 版，保持编译成品最新

当 Agent 对项目进行以下修改时，必须执行 Windows 编译：

| 修改类型 | 是否需要编译 |
|----------|--------------|
| GDScript 代码修改 | 是 |
| 场景文件修改 (.tscn) | 是 |
| 资源文件修改 | 是 |
| 项目配置修改 (project.godot) | 是 |
| 导出预设修改 (export_presets.cfg) | 是 |
| 文档修改 (.md) | 否 |
| 配置文件修改 (.cfg, .json) | 视情况而定 |

### 编译命令

```bash
# Windows x64 编译
C:\Users\Administrator\bin\Godot_v4.4-stable_win64.exe --headless --path "C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine" --export-release "Windows Desktop" "C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\export\windows\TaikoLine.exe"
```

### 编译输出

- **输出目录**: `export/windows/`
- **主文件**: `TaikoLine.exe`
- **资源包**: `TaikoLine.pck`（如果未嵌入）

---

## 项目结构

```
TaikoLine/
├── scenes/              # 游戏场景
├── src/                 # GDScript 源代码
│   ├── audio/           # 音频系统
│   ├── autoload/        # 自动加载单例
│   ├── game/            # 游戏核心
│   ├── parser/          # 谱面解析
│   └── ui/              # UI组件
├── songs/               # 谱面目录
├── resources/           # 资源文件
├── export/              # 导出输出
│   └── windows/         # Windows 编译输出
├── project.godot        # 项目配置
├── export_presets.cfg   # 导出预设
└── README.md            # 项目说明
```

---

## 开发规范

### 代码规范
- 使用 GDScript 静态类型
- 遵循 Godot 命名约定
- 函数名使用 snake_case
- 类名使用 PascalCase

### 提交规范
- 遵循 conventional commits 规范
- 提交前确保编译通过
- 提交后更新编译成品

---

## 注意事项

1. **编译优先**: 代码修改后优先编译 Windows 版本
2. **版本匹配**: 确保导出模板版本与 Godot 版本匹配
3. **测试验证**: 编译后验证游戏可正常运行
4. **文档同步**: 重要修改需同步更新 README.md

---

## 更新记录

| 日期 | 更新内容 | 版本 |
|------|----------|------|
| 2026-03-21 | 初始创建，添加编译规则说明 | v1.0.0 |
```

#### 预期结果
AGENT_README.md 文件创建成功，包含完整的 Agent 指导内容。

#### 验证命令（必填）
```
验证命令：type "C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\AGENT_README.md"
预期输出：文件内容包含 "Godot 项目修改后默认要编译 Windows 版"
验证方法：检查文件内容是否包含关键内容
```

#### 回滚方案（必填）
```
如果操作失败，执行以下回滚：
del "C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\AGENT_README.md"
```

#### 注意事项
- 确保文件编码为 UTF-8
- 确保文件内容格式正确
- 确保关键内容完整

#### 依赖关系
- 前置任务：无
- 后置任务：task-readme-2（验证文件内容）

---

### 任务2：验证文件内容

**任务ID**：task-readme-2
**操作类型**：命令执行
**目标文件**：不适用
**预计执行时间**：约30秒

#### 任务背景
验证 AGENT_README.md 文件创建成功且内容正确。

#### 操作命令（必填）
```
操作：使用 read_file 工具
文件路径：C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\AGENT_README.md
```

#### 操作内容（详细步骤）
1. 使用 read_file 工具读取文件内容
2. 验证文件包含关键内容：
   - "Godot 项目修改后默认要编译 Windows 版"
   - "编译规则" 章节
   - "编译命令" 章节
   - "项目结构" 章节

#### 预期结果
文件内容完整，包含所有必要章节。

#### 验证命令（必填）
```
验证命令：findstr /n "编译规则" "C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\AGENT_README.md"
预期输出：包含 "编译规则" 的行号
验证方法：检查关键章节是否存在
```

#### 回滚方案（必填）
```
如果验证失败，执行以下回滚：
重新执行 task-readme-1
```

#### 注意事项
- 检查文件编码是否正确
- 检查关键内容是否完整
- 检查格式是否正确

#### 依赖关系
- 前置任务：task-readme-1
- 后置任务：无

---

## 任务列表

**总任务数**：2
**预计执行时间**：约5分钟

### 任务依赖图
```
task-readme-1 (创建文件) ──► task-readme-2 (验证内容)
```

### 任务列表
| 序号 | 任务ID | 任务名称 | 操作类型 | 依赖 | 预计时间 |
|------|--------|----------|----------|------|----------|
| 1 | task-readme-1 | 创建 AGENT_README.md 文件 | 文件创建 | 无 | 约2分钟 |
| 2 | task-readme-2 | 验证文件内容 | 命令执行 | task-readme-1 | 约30秒 |

## 验收标准

### 必须满足
- [ ] AGENT_README.md 文件存在于项目根目录
- [ ] 文件内容包含 "Godot 项目修改后默认要编译 Windows 版，保持编译成品最新"
- [ ] 文件包含编译规则章节
- [ ] 文件包含编译命令章节
- [ ] 文件格式正确，可正常阅读

### 建议满足
- [ ] 文件内容完整，包含项目结构说明
- [ ] 文件内容包含开发规范
- [ ] 文件内容包含注意事项

## 风险评估

| 风险描述 | 影响级别 | 可能性 | 应对策略 |
|----------|----------|--------|----------|
| 文件创建失败 | 高 | 低 | 检查目录权限，重试创建 |
| 文件内容不完整 | 中 | 低 | 验证后重新写入 |
| 文件编码问题 | 低 | 低 | 确保使用 UTF-8 编码 |

## 相关资源

- **文档链接**：
  - 工作目录 AGENT_ENV.md：C:\Users\Administrator\Documents\agent-workspace\AGENT_ENV.md
  - code-fever-aio AGENTS.md：C:\Users\Administrator\Documents\agent-workspace\projects\code-fever-aio\AGENTS.md
- **代码路径**：
  - 项目根目录：C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine
- **配置文件**：
  - 项目配置：C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\project.godot
  - 导出预设：C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\export_presets.cfg

## 标签

agent-readme, godot, documentation, taikoline, build-rules