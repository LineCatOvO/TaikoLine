# Task-P2-025: 创建测试TJA谱面

**创建时间**：2026-03-21
**更新时间**：2026-03-21
**优先级**：P2
**状态**：待处理
**任务锁**：🔓 未锁定
**项目**：TaikoLine
**预计执行时间**：约10分钟

## 任务描述

创建一个简单的测试TJA谱面文件，用于测试TJA解析器和游戏基本功能。

## 任务背景

### 问题分析
- **问题描述**：需要一个简单的测试谱面来验证TJA解析器和游戏基本功能
- **影响范围**：TJA解析器测试、游戏核心功能测试
- **根本原因**：现有测试谱面较为复杂，需要一个简单的基准测试谱面

### 当前状态分析
- **相关文件**：
  - `C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\songs\test\sample.tja` - 现有测试谱面（复杂）
  - `C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\docs\tja-format\specification.md` - TJA格式规范
  - `C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\docs\tja-format\examples.md` - TJA示例文档
- **当前配置**：songs/test/目录已存在测试谱面
- **依赖关系**：无

### 修改原因
用户需要一个简单的测试谱面，用于验证基本功能：
- 不使用音乐（无WAVE字段）
- 120 BPM
- 30秒长度
- 四分音符铺设
- 红蓝交替

## 详细执行计划

### 任务1：创建测试TJA谱面文件

**任务ID**：task-P2-025-01
**操作类型**：文件创建
**目标文件**：`C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\songs\test\simple_test.tja`
**预计执行时间**：约5分钟

#### 任务背景
创建一个简单的测试谱面，用于验证TJA解析器和游戏基本功能。

#### 操作命令（必填）
```
操作：使用 Write 工具
文件路径：C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\songs\test\simple_test.tja
文件内容：
[见下方完整内容]
```

#### 操作内容（详细步骤）

**TJA谱面计算**：
- BPM: 120 = 2拍/秒
- 时长: 30秒 = 60拍
- 4/4拍，每小节4拍 = 15小节
- 四分音符 = 每拍一个音符（每小节4个音符）
- 红蓝交替 = 1（小红）和2（小蓝）交替

**四分音符格式**：
- 每小节16个位置（4拍×4分音符）
- 四分音符 = 每4个位置一个音符
- 格式：`1000100010001000,` = 4个四分音符

**红蓝交替模式**：
- 小节1: 1000100010001000, (红红红红)
- 小节2: 2000200020002000, (蓝蓝蓝蓝)
- 交替15小节

**完整TJA文件内容**：

```
TITLE:简单测试谱面
TITLEEN:Simple Test Chart
SUBTITLE:~四分音符红蓝交替~
BPM:120
OFFSET:0.0
MAKER:TaikoLine Test

COURSE:Easy
LEVEL:1
SCOREINIT:100
SCOREDIFF:10

#START
1000100010001000,
2000200020002000,
1000100010001000,
2000200020002000,
1000100010001000,
2000200020002000,
1000100010001000,
2000200020002000,
1000100010001000,
2000200020002000,
1000100010001000,
2000200020002000,
1000100010001000,
2000200020002000,
1000100010001000,
#END
```

#### 预期结果
在 `songs/test/` 目录下创建 `simple_test.tja` 文件，包含15小节四分音符红蓝交替的简单谱面。

#### 验证命令（必填）
```
验证命令：读取文件确认内容正确
验证方法：使用 read_file 工具读取文件，确认内容与预期一致
```

#### 回滚方案（必填）
```
如果操作失败，执行以下回滚：
步骤1：删除创建的文件
命令：rm "C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\songs\test\simple_test.tja"
```

#### 注意事项
- 文件编码使用UTF-8
- 不包含WAVE字段（不使用音乐）
- 确保每行以逗号结尾（除了命令行）
- 确保小节数正确（15小节）

#### 依赖关系
- 前置任务：无
- 后置任务：无

---

## 任务列表

**总任务数**：1
**预计执行时间**：约10分钟

### 任务依赖图
```
任务1（创建文件）
```

### 任务列表
| 序号 | 任务ID | 任务名称 | 操作类型 | 依赖 | 预计时间 |
|------|--------|----------|----------|------|----------|
| 1 | task-P2-025-01 | 创建测试TJA谱面文件 | 文件创建 | 无 | 约5分钟 |

## 验收标准

### 必须满足
- [ ] 文件 `songs/test/simple_test.tja` 已创建
- [ ] 文件内容符合TJA格式规范
- [ ] BPM设置为120
- [ ] 谱面长度为15小节（30秒）
- [ ] 音符为四分音符铺设
- [ ] 音符为红蓝交替（1和2交替）
- [ ] 不包含WAVE字段（无音乐）

### 建议满足
- [ ] 文件可以被TJA解析器正确解析
- [ ] 文件编码为UTF-8

## 风险评估

| 风险描述 | 影响级别 | 可能性 | 应对策略 |
|----------|----------|--------|----------|
| 文件路径不存在 | 低 | 低 | 确认songs/test目录存在 |
| TJA格式错误 | 低 | 低 | 参考规范文档和示例 |

## 相关资源

- **文档链接**：
  - `C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\docs\tja-format\specification.md`
  - `C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\docs\tja-format\examples.md`
- **代码路径**：
  - `C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\src\parser\tja_parser.gd`
  - `C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\src\parser\tja_data.gd`
- **配置文件**：无
- **参考谱面**：`C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\songs\test\sample.tja`

## 标签

TJA, 测试谱面, 四分音符, 红蓝交替, TaikoLine