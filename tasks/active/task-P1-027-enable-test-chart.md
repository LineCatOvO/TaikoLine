# Task-P1-027: 使测试谱面在游戏中可用

**创建时间**：2026-03-21
**更新时间**：2026-03-21
**优先级**：P1
**状态**：待处理
**任务锁**：🔓 未锁定
**项目**：TaikoLine
**预计执行时间**：约30分钟

## 任务描述

使测试谱面 `songs/test/simple_test.tja` 在游戏中可用，确保玩家可以选择并游玩该谱面。

## 任务背景

### 问题分析
- **问题描述**：测试谱面 `simple_test.tja` 已创建，但需要验证是否能在游戏中正常使用
- **影响范围**：歌曲选择界面、游戏玩法、音频系统
- **根本原因**：测试谱面不包含WAVE字段（无音乐），需要确认游戏能否处理无音频情况

### 当前状态分析
- **相关文件**：
  - `C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\songs\test\simple_test.tja` - 测试谱面（已创建）
  - `C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\src\ui\song_select.gd` - 歌曲选择界面
  - `C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\src\game\game_controller.gd` - 游戏控制器
  - `C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\src\parser\tja_parser.gd` - TJA解析器
  - `C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\resources\sounds\README.md` - 音效说明
- **当前配置**：
  - 测试谱面已创建，格式正确
  - 项目中没有任何 `.ogg` 音频文件
  - 音效文件不存在（只有README.md）
- **依赖关系**：无

### 修改原因
用户需要测试谱面在游戏中可用，用于测试TJA解析器和游戏基本功能。

## 谱面加载机制分析

### 歌曲扫描流程
1. `song_select.gd` 的 `_scan_songs()` 扫描 `res://songs` 目录
2. 遍历子目录，查找 `.tja` 文件
3. `_load_song_info()` 解析 TJA 文件获取歌曲信息

### 游戏加载流程
1. `game_controller.gd` 的 `load_song()` 解析 TJA 文件
2. `_load_audio()` 加载音频文件
3. 如果 `wave.is_empty()` 返回 false（不阻止游戏继续）
4. 如果音频文件不存在，也返回 false（只打印警告）

### 无音频处理
- `game_controller.gd:154-158`：如果 `wave.is_empty()` 返回 false
- `song_select.gd:426-429`：预览功能在无音频时不播放
- 游戏时间通过 `game_time` 变量管理，不依赖音频

## 测试谱面缺少的资源分析

### 已有资源
- [x] TJA谱面文件 - `simple_test.tja` 已创建
- [x] TJA格式正确 - 符合规范
- [x] 游戏可处理无音频 - 代码已实现

### 缺少资源
- [ ] 音频文件 - 测试谱面不包含WAVE字段（设计如此）
- [ ] 打击音效 - `resources/sounds/` 目录为空

### 可选资源
- [ ] 静默音频 - 可创建用于时间同步
- [ ] 打击音效 - 可创建用于游戏体验

## 详细执行计划

### 任务1：验证测试谱面可被扫描

**任务ID**：task-P1-027-01
**操作类型**：命令执行
**目标文件**：不适用
**预计执行时间**：约5分钟

#### 任务背景
验证测试谱面能否被歌曲选择界面正确扫描和显示。

#### 操作命令（必填）
```
操作：使用 RunCommand 工具
命令：C:\Users\Administrator\bin\Godot_v4.4-stable_win64.exe --headless --path "C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine" --script res://test/test_song_scan.gd
工作目录：C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine
```

#### 操作内容（详细步骤）
1. 检查是否存在测试脚本 `test/test_song_scan.gd`
2. 如果不存在，创建简单的测试脚本验证谱面扫描
3. 运行测试脚本，验证谱面能否被正确解析

#### 预期结果
测试谱面 `simple_test.tja` 能被正确扫描和解析。

#### 验证命令（必填）
```
验证命令：检查测试输出，确认谱面信息正确显示
预期输出：谱面标题、BPM、难度等信息正确输出
```

#### 回滚方案（必填）
```
如果操作失败，执行以下回滚：
步骤1：检查TJA文件格式是否正确
步骤2：检查解析器代码是否有问题
```

#### 注意事项
- Godot 需要正确安装
- 测试脚本可能需要创建

#### 依赖关系
- 前置任务：无
- 后置任务：无

---

### 任务2：创建静默音频文件（可选）

**任务ID**：task-P1-027-02
**操作类型**：文件创建
**目标文件**：`C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\songs\test\silence.ogg`
**预计执行时间**：约10分钟

#### 任务背景
创建一个静默的OGG音频文件，用于测试谱面的时间同步。

#### 操作命令（必填）
```
操作：使用 Write 工具（二进制文件需要特殊处理）
说明：由于OGG是二进制格式，需要使用其他方法创建
```

#### 操作内容（详细步骤）
1. 方案A：使用FFmpeg创建静默音频
   ```
   ffmpeg -f lavfi -i anullsrc=r=44100:cl=stereo -t 30 -c:a libvorbis silence.ogg
   ```
2. 方案B：下载一个静默OGG文件
3. 方案C：修改测试谱面，添加WAVE字段指向现有音频

#### 预期结果
创建一个30秒的静默OGG文件，用于测试谱面。

#### 验证命令（必填）
```
验证命令：检查文件是否存在
预期输出：文件存在且大小合理
```

#### 回滚方案（必填）
```
如果操作失败，执行以下回滚：
步骤1：删除创建的文件
步骤2：使用其他方案
```

#### 注意事项
- 需要FFmpeg或其他音频工具
- 文件大小应尽量小

#### 依赖关系
- 前置任务：无
- 后置任务：任务3

---

### 任务3：更新测试谱面添加WAVE字段

**任务ID**：task-P1-027-03
**操作类型**：文件编辑
**目标文件**：`C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\songs\test\simple_test.tja`
**预计执行时间**：约2分钟

#### 任务背景
如果创建了静默音频，需要更新测试谱面添加WAVE字段。

#### 操作命令（必填）
```
操作：使用 SearchReplace 工具
文件路径：C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\songs\test\simple_test.tja
搜索内容（old_str）：
TITLE:简单测试谱面
TITLEEN:Simple Test Chart
SUBTITLE:~四分音符红蓝交替~
BPM:120
OFFSET:0.0
替换内容（new_str）：
TITLE:简单测试谱面
TITLEEN:Simple Test Chart
SUBTITLE:~四分音符红蓝交替~
BPM:120
WAVE:silence.ogg
OFFSET:0.0
```

#### 操作内容（详细步骤）
1. 读取当前测试谱面内容
2. 在BPM行后添加WAVE字段
3. 验证修改正确

#### 预期结果
测试谱面包含WAVE字段，指向静默音频文件。

#### 验证命令（必填）
```
验证命令：使用 read_file 工具读取文件，确认WAVE字段存在
预期输出：文件包含 "WAVE:silence.ogg" 行
```

#### 回滚方案（必填）
```
如果操作失败，执行以下回滚：
步骤1：恢复原始文件内容
```

#### 注意事项
- WAVE字段必须在BPM之后、OFFSET之前
- 文件名必须与实际音频文件名一致

#### 依赖关系
- 前置任务：任务2（如果创建静默音频）
- 后置任务：无

---

### 任务4：创建基本打击音效（可选）

**任务ID**：task-P1-027-04
**操作类型**：文件创建
**目标文件**：
- `C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\resources\sounds\don.ogg`
- `C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\resources\sounds\ka.ogg`
**预计执行时间**：约10分钟

#### 任务背景
创建基本的打击音效文件，提升游戏体验。

#### 操作命令（必填）
```
操作：使用外部工具创建音效
说明：可以使用合成器或下载免费音效
```

#### 操作内容（详细步骤）
1. 方案A：使用FFmpeg生成简单音效
   ```
   ffmpeg -f lavfi -i "sine=frequency=200:duration=0.1" -c:a libvorbis don.ogg
   ffmpeg -f lavfi -i "sine=frequency=400:duration=0.1" -c:a libvorbis ka.ogg
   ```
2. 方案B：下载免费音效
3. 方案C：暂时跳过，游戏可在无音效情况下运行

#### 预期结果
创建基本的打击音效文件。

#### 验证命令（必填）
```
验证命令：检查文件是否存在
预期输出：文件存在且大小合理
```

#### 回滚方案（必填）
```
如果操作失败，执行以下回滚：
步骤1：删除创建的文件
```

#### 注意事项
- 音效格式必须是OGG
- 采样率建议44100Hz
- 时长建议0.1-0.3秒

#### 依赖关系
- 前置任务：无
- 后置任务：无

---

### 任务5：验证游戏可运行测试谱面

**任务ID**：task-P1-027-05
**操作类型**：命令执行
**目标文件**：不适用
**预计执行时间**：约5分钟

#### 任务背景
验证游戏能否正常运行测试谱面。

#### 操作命令（必填）
```
操作：使用 RunCommand 工具
命令：C:\Users\Administrator\bin\Godot_v4.4-stable_win64.exe --path "C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine"
工作目录：C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine
```

#### 操作内容（详细步骤）
1. 启动游戏
2. 进入歌曲选择界面
3. 选择测试谱面 "简单测试谱面"
4. 开始游戏，验证能否正常游玩

#### 预期结果
游戏能够正常加载和运行测试谱面。

#### 验证命令（必填）
```
验证命令：手动验证游戏运行正常
预期输出：谱面可被选择，游戏可正常进行
```

#### 回滚方案（必填）
```
如果操作失败，执行以下回滚：
步骤1：检查错误日志
步骤2：修复问题
```

#### 注意事项
- 需要图形界面环境
- 可能需要手动操作

#### 依赖关系
- 前置任务：任务1-4
- 后置任务：无

---

## 任务列表

**总任务数**：5
**预计执行时间**：约30分钟

### 任务依赖图
```
任务1（验证扫描）
    ↓
任务2（创建静默音频）→ 任务3（更新谱面）
    ↓                       ↓
任务4（创建音效）←──────────┘
    ↓
任务5（验证游戏）
```

### 任务列表
| 序号 | 任务ID | 任务名称 | 操作类型 | 依赖 | 预计时间 |
|------|--------|----------|----------|------|----------|
| 1 | task-P1-027-01 | 验证测试谱面可被扫描 | 命令执行 | 无 | 约5分钟 |
| 2 | task-P1-027-02 | 创建静默音频文件 | 文件创建 | 无 | 约10分钟 |
| 3 | task-P1-027-03 | 更新测试谱面添加WAVE字段 | 文件编辑 | 任务2 | 约2分钟 |
| 4 | task-P1-027-04 | 创建基本打击音效 | 文件创建 | 无 | 约10分钟 |
| 5 | task-P1-027-05 | 验证游戏可运行测试谱面 | 命令执行 | 任务1-4 | 约5分钟 |

## 验收标准

### 必须满足
- [ ] 测试谱面 `simple_test.tja` 能被歌曲选择界面扫描到
- [ ] 测试谱面能被TJA解析器正确解析
- [ ] 游戏能够加载测试谱面并开始游戏
- [ ] 音符判定正常工作

### 建议满足
- [ ] 测试谱面有音频文件（静默音频）
- [ ] 打击音效正常工作
- [ ] 预览功能可用

## 风险评估

| 风险描述 | 影响级别 | 可能性 | 应对策略 |
|----------|----------|--------|----------|
| 无音频导致游戏异常 | 中 | 低 | 游戏代码已处理无音频情况 |
| 无音效影响体验 | 低 | 高 | 可选任务，不影响核心功能 |
| FFmpeg不可用 | 中 | 中 | 使用其他方案或跳过 |

## 相关资源

- **文档链接**：
  - `C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\docs\tja-format\specification.md`
  - `C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\docs\tja-format\examples.md`
- **代码路径**：
  - `C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\src\parser\tja_parser.gd`
  - `C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\src\parser\tja_data.gd`
  - `C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\src\ui\song_select.gd`
  - `C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\src\game\game_controller.gd`
- **配置文件**：无
- **参考谱面**：
  - `C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\songs\test\sample.tja`
  - `C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\songs\test\demo.tja`

## 标签

TJA, 测试谱面, TaikoLine, 音频, 音效