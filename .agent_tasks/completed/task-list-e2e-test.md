# Task-List: TaikoLine 端到端测试运行

**创建时间**：2026-03-19
**更新时间**：2026-03-19 18:15
**优先级**：P1
**状态**：已完成
**任务锁**：✅ 已完成 - Coder - 2026-03-19 18:15
**项目**：TaikoLine
**预计执行时间**：约60分钟

## 任务描述
为 TaikoLine 项目运行端到端测试（实际为 GUT 单元测试和集成测试）。

## 任务背景

### 问题分析
- **问题描述**：用户要求运行端到端测试，但项目目前使用 GUT 框架进行单元测试和集成测试，没有专门的 E2E 测试配置
- **影响范围**：测试无法运行，因为：
  1. Godot 4.4 引擎未安装在系统中
  2. GUT 插件存在编译错误（GutErrorTracker 类无法解析）
- **根本原因**：
  1. 环境是 PRoot/Termux ARM64 容器，Godot 需要手动安装
  2. GUT 插件版本可能与 Godot 4.4 存在兼容性问题

### 当前状态分析
- **相关文件**：
  - `/home/linecat-huawei/agent-workspace/projects/TaikoLine/.gutconfig.json` - GUT 配置文件
  - `/home/linecat-huawei/agent-workspace/projects/TaikoLine/addons/gut/` - GUT 插件目录
  - `/home/linecat-huawei/agent-workspace/projects/TaikoLine/test/` - 测试目录
  - `/home/linecat-huawei/agent-workspace/projects/TaikoLine/project.godot` - 项目配置

- **当前配置**：
  - GUT 版本：9.6.0
  - Godot 版本要求：4.4+
  - 测试目录：`res://test/unit/`, `res://test/integration/`

- **依赖关系**：
  - 需要先安装 Godot 4.4 引擎
  - 需要修复 GUT 插件编译问题
  - 然后才能运行测试

### 修改原因
用户需要验证项目代码的正确性，运行测试是必要的开发流程。

## 项目结构分析

### 测试目录结构
```
test/
├── unit/                    # 单元测试
│   ├── parser/             # 解析器测试
│   │   └── test_tja_parser.gd
│   ├── game/               # 游戏逻辑测试
│   │   ├── test_scroll.gd
│   │   ├── test_note.gd
│   │   └── test_judge.gd
│   └── autoload/           # 自动加载测试
│       ├── test_settings.gd
│       └── test_game_state.gd
├── integration/             # 集成测试
│   ├── game_flow/          # 游戏流程测试
│   │   ├── test_game_flow.gd
│   │   ├── test_parse_to_play.gd
│   │   └── test_judge_integration.gd
│   └── audio_sync/         # 音频同步测试
│       └── test_audio_sync.gd
├── fixtures/                # 测试数据
├── mock/                    # Mock 对象
│   ├── mock_skin_manager.gd
│   └── mock_audio_manager.gd
└── gut_config.gd           # GUT 配置脚本
```

### 现有测试文件清单
| 文件路径 | 测试类型 | 说明 |
|----------|----------|------|
| test/unit/parser/test_tja_parser.gd | 单元测试 | TJA 解析器测试 |
| test/unit/game/test_scroll.gd | 单元测试 | 滚动系统测试 |
| test/unit/game/test_note.gd | 单元测试 | 音符系统测试 |
| test/unit/game/test_judge.gd | 单元测试 | 判定系统测试 |
| test/unit/autoload/test_settings.gd | 单元测试 | 设置管理测试 |
| test/unit/autoload/test_game_state.gd | 单元测试 | 游戏状态测试 |
| test/integration/game_flow/test_game_flow.gd | 集成测试 | 游戏流程测试 |
| test/integration/game_flow/test_parse_to_play.gd | 集成测试 | 解析到游玩测试 |
| test/integration/game_flow/test_judge_integration.gd | 集成测试 | 判定集成测试 |
| test/integration/audio_sync/test_audio_sync.gd | 集成测试 | 音频同步测试 |

## 详细执行计划

### 任务1：下载并安装 Godot 4.4 引擎

**任务ID**：task-e2e-1
**操作类型**：命令执行
**目标文件**：不适用
**预计执行时间**：约10分钟

#### 任务背景
Godot 引擎未安装在系统中，需要下载 ARM64 版本的 Godot 4.4 才能运行测试。

#### 操作命令（必填）
```
操作：使用 RunCommand 工具
命令：wget -O /home/linecat-huawei/godot4.4.zip https://github.com/godotengine/godot/releases/download/4.4-stable/Godot_v4.4-stable_linux.arm64.zip && unzip -o /home/linecat-huawei/godot4.4.zip -d /home/linecat-huawei/bin/ && chmod +x /home/linecat-huawei/bin/Godot_v4.4-stable_linux.arm64
工作目录：/home/linecat-huawei
```

#### 操作内容（详细步骤）
1. 下载 Godot 4.4 ARM64 版本
   - 输入：Godot 官方 GitHub releases URL
   - 操作：使用 wget 下载 zip 文件
   - 输出：/home/linecat-huawei/godot4.4.zip

2. 解压到用户 bin 目录
   - 输入：godot4.4.zip 文件
   - 操作：使用 unzip 解压到 /home/linecat-huawei/bin/
   - 输出：/home/linecat-huawei/bin/Godot_v4.4-stable_linux.arm64

3. 设置可执行权限
   - 输入：Godot 可执行文件
   - 操作：chmod +x
   - 输出：可执行的 Godot 引擎

#### 预期结果
Godot 4.4 引擎安装在 /home/linecat-huawei/bin/ 目录下，可以直接运行。

#### 验证命令（必填）
```
验证命令：/home/linecat-huawei/bin/Godot_v4.4-stable_linux.arm64 --version
预期输出：4.4.stable.official.4c311cbee
```

#### 回滚方案（必填）
```
如果操作失败，执行以下回滚：
步骤1：rm -f /home/linecat-huawei/godot4.4.zip
步骤2：rm -f /home/linecat-huawei/bin/Godot_v4.4-stable_linux.arm64
步骤3：尝试使用备用下载源或 AppImage 版本
```

#### 注意事项
- 确保网络连接正常，GitHub 下载可能较慢
- ARM64 架构必须下载对应的 ARM64 版本
- 如果官方下载失败，可以尝试使用镜像源

#### 依赖关系
- 前置任务：无
- 后置任务：task-e2e-2

---

### 任务2：验证 Godot 安装并检查项目兼容性

**任务ID**：task-e2e-2
**操作类型**：命令执行
**目标文件**：不适用
**预计执行时间**：约2分钟

#### 任务背景
确认 Godot 安装成功，并验证项目可以正常打开。

#### 操作命令（必填）
```
操作：使用 RunCommand 工具
命令：/home/linecat-huawei/bin/Godot_v4.4-stable_linux.arm64 --headless --quit-after 2 --path /home/linecat-huawei/agent-workspace/projects/TaikoLine
工作目录：/home/linecat-huawei/agent-workspace/projects/TaikoLine
```

#### 操作内容（详细步骤）
1. 验证 Godot 版本
   - 输入：Godot 可执行文件
   - 操作：运行 --version 命令
   - 输出：版本号 4.4.stable

2. 验证项目可以打开
   - 输入：项目路径
   - 操作：运行 Godot --headless 模式打开项目
   - 输出：项目加载日志

#### 预期结果
Godot 可以正常打开项目，没有致命错误。

#### 验证命令（必填）
```
验证命令：/home/linecat-huawei/bin/Godot_v4.4-stable_linux.arm64 --version
预期输出：4.4.stable.official.4c311cbee
```

#### 回滚方案（必填）
```
如果操作失败，执行以下回滚：
检查错误日志，可能需要：
1. 重新下载 Godot
2. 检查项目配置文件
3. 检查依赖项
```

#### 注意事项
- headless 模式下某些功能可能受限
- 注意观察错误日志

#### 依赖关系
- 前置任务：task-e2e-1
- 后置任务：task-e2e-3

---

### 任务3：诊断并修复 GUT 插件编译问题

**任务ID**：task-e2e-3
**操作类型**：文件编辑
**目标文件**：/home/linecat-huawei/agent-workspace/projects/TaikoLine/addons/gut/
**预计执行时间**：约15分钟

#### 任务背景
根据日志显示，GUT 插件存在编译错误，GutErrorTracker 类无法解析。这可能是版本兼容性问题或文件损坏。

#### 操作命令（必填）
```
操作：使用 RunCommand 工具
命令：cd /home/linecat-huawei/agent-workspace/projects/TaikoLine && git status addons/gut/
工作目录：/home/linecat-huawei/agent-workspace/projects/TaikoLine
```

#### 操作内容（详细步骤）
1. 检查 GUT 插件状态
   - 输入：GUT 插件目录
   - 操作：检查 git 状态，确认文件完整性
   - 输出：文件状态列表

2. 尝试重新下载 GUT 插件（如果需要）
   - 输入：GUT 官方仓库
   - 操作：下载最新兼容版本
   - 输出：更新的 GUT 插件

3. 验证编译
   - 输入：修复后的 GUT 插件
   - 操作：运行 Godot 检查编译
   - 输出：编译结果

#### 预期结果
GUT 插件可以正常编译，没有错误。

#### 验证命令（必填）
```
验证命令：/home/linecat-huawei/bin/Godot_v4.4-stable_linux.arm64 --headless --script res://addons/gut/gut_cmdln.gd --path /home/linecat-huawei/agent-workspace/projects/TaikoLine -gprint_summary
预期输出：GUT 测试框架启动信息，无编译错误
```

#### 回滚方案（必填）
```
如果操作失败，执行以下回滚：
步骤1：git checkout -- addons/gut/ 恢复原始文件
步骤2：尝试使用 GUT 的其他版本
步骤3：考虑使用 Godot 编辑器手动修复
```

#### 注意事项
- GUT 9.6.0 应该兼容 Godot 4.4，但可能需要特定配置
- 检查 error_tracker.gd 文件的 class_name 声明是否正确
- 可能需要检查 Godot 的项目设置

#### 依赖关系
- 前置任务：task-e2e-2
- 后置任务：task-e2e-4

---

### 任务4：运行单元测试

**任务ID**：task-e2e-4
**操作类型**：命令执行
**目标文件**：不适用
**预计执行时间**：约5分钟

#### 任务背景
运行项目的单元测试，验证各个模块的功能正确性。

#### 操作命令（必填）
```
操作：使用 RunCommand 工具
命令：/home/linecat-huawei/bin/Godot_v4.4-stable_linux.arm64 --headless -s addons/gut/gut_cmdln.gd -gdir=res://test/unit/ -ginclude_subdirs -gprint_summary -gexit
工作目录：/home/linecat-huawei/agent-workspace/projects/TaikoLine
```

#### 操作内容（详细步骤）
1. 运行所有单元测试
   - 输入：测试目录 res://test/unit/
   - 操作：执行 GUT 命令行测试
   - 输出：测试结果

2. 收集测试报告
   - 输入：测试输出
   - 操作：解析测试结果
   - 输出：测试通过/失败统计

#### 预期结果
所有单元测试运行完成，输出测试结果摘要。

#### 验证命令（必填）
```
验证命令：检查测试输出中是否包含 "passed" 或 "failed" 统计
预期输出：测试摘要，显示通过和失败的测试数量
```

#### 回滚方案（必填）
```
如果操作失败，执行以下回滚：
步骤1：检查错误日志
步骤2：尝试运行单个测试文件
步骤3：检查测试依赖项
```

#### 注意事项
- headless 模式下某些测试可能需要跳过（如输入测试）
- 注意测试输出中的错误信息
- 可能需要设置 GUT 配置参数

#### 依赖关系
- 前置任务：task-e2e-3
- 后置任务：task-e2e-5

---

### 任务5：运行集成测试

**任务ID**：task-e2e-5
**操作类型**：命令执行
**目标文件**：不适用
**预计执行时间**：约5分钟

#### 任务背景
运行项目的集成测试，验证模块间的交互正确性。

#### 操作命令（必填）
```
操作：使用 RunCommand 工具
命令：/home/linecat-huawei/bin/Godot_v4.4-stable_linux.arm64 --headless -s addons/gut/gut_cmdln.gd -gdir=res://test/integration/ -ginclude_subdirs -gprint_summary -gexit
工作目录：/home/linecat-huawei/agent-workspace/projects/TaikoLine
```

#### 操作内容（详细步骤）
1. 运行所有集成测试
   - 输入：测试目录 res://test/integration/
   - 操作：执行 GUT 命令行测试
   - 输出：测试结果

2. 收集测试报告
   - 输入：测试输出
   - 操作：解析测试结果
   - 输出：测试通过/失败统计

#### 预期结果
所有集成测试运行完成，输出测试结果摘要。

#### 验证命令（必填）
```
验证命令：检查测试输出中是否包含 "passed" 或 "failed" 统计
预期输出：测试摘要，显示通过和失败的测试数量
```

#### 回滚方案（必填）
```
如果操作失败，执行以下回滚：
步骤1：检查错误日志
步骤2：尝试运行单个测试文件
步骤3：检查测试依赖项
```

#### 注意事项
- 集成测试可能需要更多资源
- 音频相关测试在 headless 模式下可能受限
- 注意测试输出中的错误信息

#### 依赖关系
- 前置任务：task-e2e-4
- 后置任务：task-e2e-6

---

### 任务6：生成测试报告

**任务ID**：task-e2e-6
**操作类型**：文件创建
**目标文件**：/home/linecat-huawei/agent-workspace/projects/TaikoLine/test/results/test-report.md
**预计执行时间**：约3分钟

#### 任务背景
汇总所有测试结果，生成可读的测试报告。

#### 操作命令（必填）
```
操作：使用 Write 工具
文件路径：/home/linecat-huawei/agent-workspace/projects/TaikoLine/test/results/test-report.md
文件内容：
# TaikoLine 测试报告

**生成时间**：2026-03-19
**测试框架**：GUT 9.6.0
**Godot 版本**：4.4.stable

## 测试摘要

### 单元测试
| 测试文件 | 测试数 | 通过 | 失败 | 状态 |
|----------|--------|------|------|------|
| test_tja_parser.gd | - | - | - | 待运行 |
| test_scroll.gd | - | - | - | 待运行 |
| test_note.gd | - | - | - | 待运行 |
| test_judge.gd | - | - | - | 待运行 |
| test_settings.gd | - | - | - | 待运行 |
| test_game_state.gd | - | - | - | 待运行 |

### 集成测试
| 测试文件 | 测试数 | 通过 | 失败 | 状态 |
|----------|--------|------|------|------|
| test_game_flow.gd | - | - | - | 待运行 |
| test_parse_to_play.gd | - | - | - | 待运行 |
| test_judge_integration.gd | - | - | - | 待运行 |
| test_audio_sync.gd | - | - | - | 待运行 |

## 详细结果

[测试运行后填充]

## 问题列表

[测试运行后填充]

## 建议

[测试运行后填充]
```

#### 操作内容（详细步骤）
1. 创建测试结果目录
   - 输入：目录路径
   - 操作：mkdir -p test/results
   - 输出：目录创建成功

2. 生成测试报告
   - 输入：测试结果数据
   - 操作：写入报告文件
   - 输出：test-report.md 文件

#### 预期结果
测试报告文件创建成功，包含完整的测试结果。

#### 验证命令（必填）
```
验证命令：ls -la /home/linecat-huawei/agent-workspace/projects/TaikoLine/test/results/test-report.md
预期输出：文件存在且有内容
```

#### 回滚方案（必填）
```
如果操作失败，执行以下回滚：
步骤1：rm -f test/results/test-report.md
步骤2：重新创建报告
```

#### 注意事项
- 确保目录存在
- 报告格式要清晰易读

#### 依赖关系
- 前置任务：task-e2e-5
- 后置任务：无

---

## 任务列表

**总任务数**：6
**预计执行时间**：约40分钟

### 任务依赖图
```
task-e2e-1 (安装 Godot)
    ↓
task-e2e-2 (验证安装)
    ↓
task-e2e-3 (修复 GUT)
    ↓
task-e2e-4 (运行单元测试)
    ↓
task-e2e-5 (运行集成测试)
    ↓
task-e2e-6 (生成报告)
```

### 任务列表
| 序号 | 任务ID | 任务名称 | 操作类型 | 依赖 | 预计时间 |
|------|--------|----------|----------|------|----------|
| 1 | task-e2e-1 | 下载并安装 Godot 4.4 引擎 | 命令执行 | 无 | 约10分钟 |
| 2 | task-e2e-2 | 验证 Godot 安装并检查项目兼容性 | 命令执行 | task-e2e-1 | 约2分钟 |
| 3 | task-e2e-3 | 诊断并修复 GUT 插件编译问题 | 文件编辑 | task-e2e-2 | 约15分钟 |
| 4 | task-e2e-4 | 运行单元测试 | 命令执行 | task-e2e-3 | 约5分钟 |
| 5 | task-e2e-5 | 运行集成测试 | 命令执行 | task-e2e-4 | 约5分钟 |
| 6 | task-e2e-6 | 生成测试报告 | 文件创建 | task-e2e-5 | 约3分钟 |

## 验收标准

### 必须满足
- [ ] Godot 4.4 引擎成功安装并可运行
- [ ] GUT 插件编译无错误
- [ ] 所有单元测试运行完成
- [ ] 所有集成测试运行完成
- [ ] 测试报告生成成功

### 建议满足
- [ ] 所有测试通过
- [ ] 测试覆盖率报告生成
- [ ] JUnit XML 格式报告生成

## 风险评估

| 风险描述 | 影响级别 | 可能性 | 应对策略 |
|----------|----------|--------|----------|
| Godot ARM64 版本下载失败 | 高 | 中 | 使用镜像源或备用下载方式 |
| GUT 插件版本不兼容 | 高 | 中 | 尝试使用 GUT 的其他版本 |
| headless 模式下测试受限 | 中 | 高 | 跳过需要图形界面的测试 |
| 音频测试在 headless 模式失败 | 中 | 高 | 使用 mock 替代真实音频 |
| 网络问题导致下载超时 | 中 | 低 | 使用断点续传或本地缓存 |

## 相关资源

- **文档链接**：
  - GUT 文档：https://gut.readthedocs.io/
  - Godot 文档：https://docs.godotengine.org/
  - Godot 下载：https://godotengine.org/download/linux/

- **代码路径**：
  - 项目根目录：`/home/linecat-huawei/agent-workspace/projects/TaikoLine`
  - 测试目录：`/home/linecat-huawei/agent-workspace/projects/TaikoLine/test`
  - GUT 插件：`/home/linecat-huawei/agent-workspace/projects/TaikoLine/addons/gut`

- **配置文件**：
  - GUT 配置：`/home/linecat-huawei/agent-workspace/projects/TaikoLine/.gutconfig.json`
  - 项目配置：`/home/linecat-huawei/agent-workspace/projects/TaikoLine/project.godot`

## 标签
testing, godot, gut, e2e, unit-test, integration-test, arm64

---

## 附录：GUT 命令行参数参考

### 常用参数
| 参数 | 说明 |
|------|------|
| `-s` | 指定脚本路径 |
| `-gdir` | 指定测试目录 |
| `-ginclude_subdirs` | 包含子目录 |
| `-gselect` | 选择特定测试文件 |
| `-gprint_summary` | 打印测试摘要 |
| `-gexit` | 测试完成后退出 |
| `-glog_level` | 日志级别 (0-3) |
| `-gjunit_xml_file` | JUnit XML 输出路径 |

### 示例命令
```bash
# 运行所有测试
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://test/unit/,res://test/integration/ -ginclude_subdirs -gprint_summary -gexit

# 运行特定测试
godot --headless -s addons/gut/gut_cmdln.gd -gselect=test_tja_parser.gd -gprint_summary -gexit

# 生成 JUnit XML 报告
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://test/ -ginclude_subdirs -gjunit_xml_file=res://test/results/junit.xml -gexit
```