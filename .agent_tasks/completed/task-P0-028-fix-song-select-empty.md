# Task-P0-028: 修复选歌界面空白问题

**创建时间**：2026-03-21
**更新时间**：2026-03-22
**优先级**：P0
**状态**：已完成
**任务锁**：✅ 已完成 - Coder - 2026-03-22
**项目**：TaikoLine
**预计执行时间**：约30分钟

## 任务描述

修复选歌界面无法显示歌曲列表的问题，确保 TJA 谱面文件能够被正确扫描和解析。

## 任务背景

### 问题分析

- **问题描述**：选歌界面什么也没有显示，用户无法选择歌曲
- **影响范围**：整个游戏流程，用户无法开始游戏
- **根本原因**：`.tja` 文件没有被 Godot 4 的资源系统识别和导入

### 当前状态分析

- **相关文件**：
  - `C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\src\ui\song_select.gd` - 选歌界面逻辑
  - `C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\src\parser\tja_parser.gd` - TJA 解析器
  - `C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\songs\test\` - 测试歌曲目录
- **当前配置**：
  - `songs/test/` 目录包含 3 个 TJA 文件：`demo.tja`, `sample.tja`, `simple_test.tja`
  - `simple_test.wav` 音频文件已存在并已导入
  - TJA 文件未出现在 Godot 文件系统缓存中
- **依赖关系**：无

### 修改原因

在 Godot 4 中，非标准文件类型（如 `.tja`）默认不会被导入到资源系统。虽然 `DirAccess` 可以遍历目录，但 `FileAccess.file_exists()` 对于 `res://` 路径下的非导入文件可能返回 `false`，导致 TJA 解析器无法读取文件。

## 详细执行计划

### 任务1：修改 TJA 解析器使用绝对路径读取

**任务ID**：task-P0-028-1
**操作类型**：文件编辑
**目标文件**：`C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\src\parser\tja_parser.gd`
**预计执行时间**：约10分钟

#### 任务背景

当前 `TJAParser.parse_file()` 使用 `FileAccess.file_exists()` 检查文件是否存在，但对于 `res://` 路径下的非导入文件可能返回 `false`。需要修改为直接尝试打开文件，通过 `FileAccess.open()` 的返回值判断文件是否存在。

#### 操作命令（必填）
```
操作：使用 edit 工具
文件路径：C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\src\parser\tja_parser.gd
```

#### 操作内容（详细步骤）

1. 读取 `tja_parser.gd` 文件的 `parse_file` 函数（约第60-75行）
2. 修改文件存在检查逻辑：
   - 移除 `FileAccess.file_exists(file_path)` 检查
   - 直接使用 `FileAccess.open()` 尝试打开文件
   - 如果打开失败（返回 null），则返回错误

#### 修改前代码（第63-70行）：
```gdscript
func parse_file(file_path: String) -> TJAData.TJAParseResult:
	var result = TJAData.TJAParseResult.new()

	# 检查文件是否存在
	if not FileAccess.file_exists(file_path):
		result.success = false
		result.error = "文件不存在: " + file_path
		return result
```

#### 修改后代码：
```gdscript
func parse_file(file_path: String) -> TJAData.TJAParseResult:
	var result = TJAData.TJAParseResult.new()

	# 直接尝试打开文件（避免 res:// 路径下非导入文件的问题）
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		result.success = false
		result.error = "无法打开文件: " + file_path
		return result
	file.close()
```

#### 预期结果

TJA 解析器能够正确读取 `res://` 路径下的 `.tja` 文件，即使文件没有被 Godot 导入。

#### 验证命令（必填）
```
验证命令：运行 Godot 项目，进入选歌界面
预期输出：歌曲列表显示测试歌曲
```

#### 回滚方案（必填）
```
如果修改失败，恢复原始代码：
将代码改回使用 FileAccess.file_exists() 检查
```

#### 注意事项

- 修改后需要确保 `_read_file_with_encoding` 函数也能正确处理文件路径
- 测试时需要检查所有 TJA 文件是否能被正确解析

#### 依赖关系
- 前置任务：无
- 后置任务：task-P0-028-2

---

### 任务2：添加调试日志帮助排查问题

**任务ID**：task-P0-028-2
**操作类型**：文件编辑
**目标文件**：`C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\src\ui\song_select.gd`
**预计执行时间**：约5分钟

#### 任务背景

为了更好地排查问题，需要在歌曲扫描过程中添加调试日志，显示扫描到的目录和文件。

#### 操作命令（必填）
```
操作：使用 edit 工具
文件路径：C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\src\ui\song_select.gd
```

#### 操作内容（详细步骤）

1. 在 `_scan_songs()` 函数中添加调试日志
2. 在 `_scan_song_folder()` 函数中添加调试日志
3. 在 `_load_song_info()` 函数中添加调试日志

#### 修改内容：

在 `_scan_songs()` 函数开头添加：
```gdscript
print("[SongSelect] 开始扫描歌曲目录: " + songs_dir)
```

在 `_scan_songs()` 函数的目录遍历中添加：
```gdscript
print("[SongSelect] 发现子目录: " + folder_name)
```

在 `_scan_song_folder()` 函数开头添加：
```gdscript
print("[SongSelect] 扫描文件夹: " + folder_path)
```

在 `_scan_song_folder()` 函数的文件遍历中添加：
```gdscript
print("[SongSelect] 发现 TJA 文件: " + file_name)
```

在 `_load_song_info()` 函数中添加：
```gdscript
print("[SongSelect] 加载歌曲信息: " + tja_path)
if result.success:
    print("[SongSelect] 解析成功: " + song.title)
else:
    print("[SongSelect] 解析失败: " + result.error)
```

#### 预期结果

在控制台输出歌曲扫描过程的详细日志，帮助定位问题。

#### 验证命令（必填）
```
验证命令：运行 Godot 项目，查看控制台输出
预期输出：显示歌曲扫描过程的详细日志
```

#### 回滚方案（必填）
```
如果不需要调试日志，可以移除添加的 print 语句
```

#### 注意事项

- 调试日志仅在开发阶段使用，正式发布前应移除或使用条件编译

#### 依赖关系
- 前置任务：task-P0-028-1
- 后置任务：task-P0-028-3

---

### 任务3：编译并测试

**任务ID**：task-P0-028-3
**操作类型**：命令执行
**目标文件**：不适用
**预计执行时间**：约15分钟

#### 任务背景

修改代码后需要编译项目并测试选歌界面是否正常工作。

#### 操作命令（必填）
```
操作：使用 run_shell_command 工具
命令：C:\Users\Administrator\bin\Godot_v4.4-stable_win64.exe --headless --path "C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine" --export-release "Windows Desktop" export/windows/TaikoLine.exe
工作目录：C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine
```

#### 操作内容（详细步骤）

1. 编译 Windows 版本
2. 运行编译后的程序
3. 进入选歌界面验证歌曲是否显示

#### 预期结果

编译成功，选歌界面显示测试歌曲。

#### 验证命令（必填）
```
验证命令：运行 export/windows/TaikoLine.exe
预期输出：选歌界面显示歌曲列表
```

#### 回滚方案（必填）
```
如果编译失败，检查错误信息并修复代码
```

#### 注意事项

- 确保编译环境正确配置
- 测试时注意查看控制台输出的调试日志

#### 依赖关系
- 前置任务：task-P0-028-2
- 后置任务：无

---

## 任务列表

**总任务数**：3
**预计执行时间**：约30分钟

### 任务依赖图
```
任务1 → 任务2 → 任务3
```

### 任务列表
| 序号 | 任务ID | 任务名称 | 操作类型 | 依赖 | 预计时间 |
|------|--------|----------|----------|------|----------|
| 1 | task-P0-028-1 | 修改 TJA 解析器使用绝对路径读取 | 文件编辑 | 无 | 约10分钟 |
| 2 | task-P0-028-2 | 添加调试日志帮助排查问题 | 文件编辑 | task-P0-028-1 | 约5分钟 |
| 3 | task-P0-028-3 | 编译并测试 | 命令执行 | task-P0-028-2 | 约15分钟 |

## 验收标准

### 必须满足
- [ ] 选歌界面能够显示歌曲列表
- [ ] 能够选择歌曲并查看歌曲信息
- [ ] 能够选择难度并开始游戏

### 建议满足
- [ ] 调试日志清晰显示扫描过程
- [ ] 代码整洁，无冗余日志

## 风险评估

| 风险描述 | 影响级别 | 可能性 | 应对策略 |
|----------|----------|--------|----------|
| 修改后仍无法读取文件 | 高 | 低 | 检查文件权限和路径 |
| 编译失败 | 中 | 低 | 检查代码语法错误 |
| 解析器解析失败 | 中 | 中 | 检查 TJA 文件格式 |

## 相关资源

- **文档链接**：无
- **代码路径**：
  - `C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\src\ui\song_select.gd`
  - `C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\src\parser\tja_parser.gd`
- **配置文件**：无

## 标签

bug-fix, song-select, tja-parser, godot4| 2026-03-22 | �ƶ��� completed | ������ɹ鵵 | 
