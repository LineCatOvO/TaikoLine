# Task-P0-002: TaikoLine Windows x64 版本编译

**创建时间**：2026-03-20
**更新时间**：2026-03-21
**优先级**：P0
**状态**：已完成
**任务锁**：✅ 已完成 - Coder - 2026-03-21 00:22
**项目**：TaikoLine
**预计执行时间**：约30-45分钟

## 任务描述

将 TaikoLine 项目编译为 Windows x64 版本，生成可在 Windows 系统上独立运行的桌面应用程序。

## 任务背景

### 问题分析
- **问题描述**：用户需要将 TaikoLine 项目编译为 Windows x64 版本，但当前项目只有 Android 和 Web 导出预设，没有 Windows Desktop 导出配置
- **影响范围**：项目导出配置、导出模板、构建输出
- **根本原因**：项目创建时未配置 Windows Desktop 导出预设

### 当前状态分析
- **相关文件**：
  - `C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\project.godot` - 项目配置文件
  - `C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\export_presets.cfg` - 导出预设配置（当前只有 Android 和 Web）
- **当前配置**：
  - Godot 版本要求：4.4 或更高版本
  - 渲染器：Forward Plus
  - 已有导出预设：Android (arm64-v8a), Web
  - Godot 安装状态：未安装在系统中
- **依赖关系**：
  - 需要下载并安装 Godot 4.4 Windows 版本
  - 需要下载 Windows Desktop 导出模板
  - 需要添加 Windows Desktop 导出预设配置

### 修改原因
用户需要将游戏发布到 Windows 平台，需要配置 Windows Desktop 导出并执行编译。

## 详细执行计划

### 任务1：下载 Godot 4.4 Windows 版本

**任务ID**：task-win-1
**操作类型**：命令执行
**目标文件**：不适用
**预计执行时间**：约5-10分钟（取决于网络速度）

#### 任务背景
系统未安装 Godot 引擎，需要下载 Windows x64 版本的 Godot 4.4 标准版。

#### 操作命令（必填）
```
操作：使用 run_shell_command 工具
命令：powershell -Command "Invoke-WebRequest -Uri 'https://github.com/godotengine/godot/releases/download/4.4-stable/Godot_v4.4-stable_win64.exe.zip' -OutFile 'C:\Users\Administrator\Downloads\Godot_v4.4-stable_win64.exe.zip'"
工作目录：C:\Users\Administrator\Downloads
```

#### 操作内容（详细步骤）
1. 使用 PowerShell 下载 Godot 4.4 Windows x64 版本
   - 输入：Godot 官方 GitHub releases URL
   - 操作：执行 Invoke-WebRequest 命令下载
   - 输出：C:\Users\Administrator\Downloads\Godot_v4.4-stable_win64.exe.zip
2. 解压下载的文件
   - 输入：Godot_v4.4-stable_win64.exe.zip
   - 操作：使用 PowerShell Expand-Archive 解压
   - 输出：C:\Users\Administrator\bin\Godot_v4.4-stable_win64.exe
3. 创建 bin 目录（如果不存在）
4. 验证 Godot 可执行文件存在

#### 预期结果
Godot 4.4 Windows x64 版本安装在 C:\Users\Administrator\bin\ 目录下。

#### 验证命令（必填）
```
验证命令：C:\Users\Administrator\bin\Godot_v4.4-stable_win64.exe --version
预期输出：4.4.stable 或类似版本号
```

#### 回滚方案（必填）
```
如果操作失败，执行以下回滚：
步骤1：del C:\Users\Administrator\Downloads\Godot_v4.4-stable_win64.exe.zip
步骤2：del C:\Users\Administrator\bin\Godot_v4.4-stable_win64.exe
```

#### 注意事项
- 需要网络连接访问 GitHub
- 下载可能需要较长时间
- 如果 GitHub 访问慢，可以使用镜像站点

#### 依赖关系
- 前置任务：无
- 后置任务：task-win-2（下载导出模板）

---

### 任务2：下载 Windows Desktop 导出模板

**任务ID**：task-win-2
**操作类型**：命令执行
**目标文件**：不适用
**预计执行时间**：约5-15分钟（取决于网络速度）

#### 任务背景
Godot 导出需要对应版本的导出模板。需要下载 Windows Desktop 导出模板。

#### 操作命令（必填）
```
操作：使用 run_shell_command 工具
命令：powershell -Command "Invoke-WebRequest -Uri 'https://github.com/godotengine/godot/releases/download/4.4-stable/Godot_v4.4-stable_export_templates.tpz' -OutFile 'C:\Users\Administrator\Downloads\Godot_v4.4-stable_export_templates.tpz'"
工作目录：C:\Users\Administrator\Downloads
```

#### 操作内容（详细步骤）
1. 下载 Godot 4.4 导出模板包
   - 输入：Godot 官方 GitHub releases URL
   - 操作：执行 Invoke-WebRequest 命令下载
   - 输出：C:\Users\Administrator\Downloads\Godot_v4.4-stable_export_templates.tpz
2. 创建模板目录
   - 输入：模板目录路径
   - 操作：mkdir 命令创建目录
   - 输出：C:\Users\Administrator\AppData\Roaming\Godot\export_templates\4.4.stable\
3. 解压模板文件
   - 输入：Godot_v4.4-stable_export_templates.tpz
   - 操作：使用 PowerShell 解压（tpz 是 zip 格式）
   - 输出：模板文件到指定目录

#### 预期结果
C:\Users\Administrator\AppData\Roaming\Godot\export_templates\4.4.stable\ 目录包含 Windows 导出模板文件。

#### 验证命令（必填）
```
验证命令：dir C:\Users\Administrator\AppData\Roaming\Godot\export_templates\4.4.stable\ | findstr /i "windows"
预期输出：包含 windows_release 或 windows_debug 相关文件
```

#### 回滚方案（必填）
```
如果操作失败，执行以下回滚：
步骤1：del C:\Users\Administrator\Downloads\Godot_v4.4-stable_export_templates.tpz
步骤2：rmdir /s /q C:\Users\Administrator\AppData\Roaming\Godot\export_templates\4.4.stable
```

#### 注意事项
- 导出模板包约 1GB，下载需要较长时间
- tpz 文件实际上是 zip 格式，可以直接解压
- 模板版本必须与 Godot 版本完全匹配

#### 依赖关系
- 前置任务：无
- 后置任务：task-win-3（添加导出预设）

---

### 任务3：添加 Windows Desktop 导出预设配置

**任务ID**：task-win-3
**操作类型**：文件编辑
**目标文件**：C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\export_presets.cfg
**预计执行时间**：约30秒

#### 任务背景
当前 export_presets.cfg 只有 Android 和 Web 导出预设，需要添加 Windows Desktop 导出预设配置。

#### 操作命令（必填）
```
操作：使用 edit 工具
文件路径：C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\export_presets.cfg
```

#### 操作内容（详细步骤）
1. 使用 read_file 工具读取当前 export_presets.cfg 内容
2. 使用 edit 工具在文件末尾添加 Windows Desktop 导出预设配置
3. 使用 read_file 工具验证修改成功

#### 需要添加的配置内容
```ini
[preset.2]

name="Windows Desktop"
platform="Windows Desktop"
runnable=true
dedicated_server=false
custom_features=""
export_filter="all_resources"
include_filter=""
exclude_filter=""
export_path="export/windows/TaikoLine.exe"
encryption_include_filters=""
encryption_exclude_filters=""
encrypt_pck=false
encrypt_directory=false

[preset.2.options]

custom_template/debug=""
custom_template/release=""
debug/export_console_wrapper=1
binary_format/embed_pck=true
texture_format/bptc=true
texture_format/s3tc=true
texture_format/etc=false
texture_format/etc2=false
binary_format/architecture="x86_64"
codesign/enable=false
codesign/timestamp=true
codesign/timestamp_server_url=""
codesign/digest_algorithm=1
codesign/description=""
codesign/custom_options=PackedStringArray()
application/modify_resources=true
application/icon=""
application/console_wrapper_icon=""
application/icon_interpolation=4
application/file_version=""
application/product_version=""
application/company_name=""
application/product_name=""
application/file_description=""
application/copyright=""
application/trademarks=""
application/export_angle=0
ssh_remote_deploy/enabled=false
ssh_remote_deploy/host=""
ssh_remote_deploy/port="22"
ssh_remote_deploy/extra_args_ssh=""
ssh_remote_deploy/extra_args_scp=""
ssh_remote_deploy/run_script="!shell_escape_windows [\"#!/bin/sh\\n\", \"export DISPLAY=:0\\n\", \"unzip -o -q \\\"{temp_dir}/{archive_name}\\\" -d \\\"{temp_dir}\\\"\\n\", \"{temp_dir}/{exe_name} {cmd_args}\\\"]"
ssh_remote_deploy/cleanup_script="!shell_escape_windows [\"#!/bin/sh\\n\", \"rm -rf \\\"{temp_dir}\\\"\"]"
```

#### 预期结果
export_presets.cfg 文件包含 Windows Desktop 导出预设配置（preset.2）。

#### 验证命令（必填）
```
验证命令：findstr /n "platform=\"Windows Desktop\"" C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\export_presets.cfg
预期输出：包含 platform="Windows Desktop" 的行
```

#### 回滚方案（必填）
```
如果操作失败，执行以下回滚：
使用 edit 工具删除添加的 [preset.2] 和 [preset.2.options] 部分
```

#### 注意事项
- 确保 preset 编号正确（当前已有 preset.0 Android, preset.1 Web，新预设应为 preset.2）
- Windows 导出路径设置为 export/windows/TaikoLine.exe
- 架构设置为 x86_64（64位）

#### 依赖关系
- 前置任务：无
- 后置任务：task-win-4（创建导出目录）

---

### 任务4：创建导出目录

**任务ID**：task-win-4
**操作类型**：命令执行
**目标文件**：不适用
**预计执行时间**：约5秒

#### 任务背景
需要创建 Windows 导出的输出目录。

#### 操作命令（必填）
```
操作：使用 run_shell_command 工具
命令：mkdir "C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\export\windows"
工作目录：C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine
```

#### 操作内容（详细步骤）
1. 执行 mkdir 命令创建导出目录
2. 验证目录创建成功

#### 预期结果
C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\export\windows 目录存在。

#### 验证命令（必填）
```
验证命令：dir "C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\export\"
预期输出：包含 windows 目录
```

#### 回滚方案（必填）
```
如果操作失败，执行以下回滚：
rmdir "C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\export\windows"
```

#### 注意事项
- 目录权限需要正确设置
- 确保父目录存在

#### 依赖关系
- 前置任务：无
- 后置任务：task-win-5（执行导出）

---

### 任务5：执行 Windows Desktop 导出

**任务ID**：task-win-5
**操作类型**：命令执行
**目标文件**：不适用
**预计执行时间**：约2-5分钟

#### 任务背景
使用 Godot 命令行工具执行 Windows Desktop 导出。

#### 操作命令（必填）
```
操作：使用 run_shell_command 工具
命令：C:\Users\Administrator\bin\Godot_v4.4-stable_win64.exe --headless --path "C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine" --export-release "Windows Desktop" "C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\export\windows\TaikoLine.exe"
工作目录：C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine
```

#### 操作内容（详细步骤）
1. 确认导出模板已安装
2. 执行 Godot 导出命令
3. 等待导出完成
4. 检查导出输出

#### 预期结果
C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\export\windows\ 目录包含：
- TaikoLine.exe（主可执行文件）
- TaikoLine.pck（游戏资源包，如果未嵌入）
- 其他依赖文件（如果有）

#### 验证命令（必填）
```
验证命令：dir "C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\export\windows\"
预期输出：包含 TaikoLine.exe 文件
```

#### 回滚方案（必填）
```
如果操作失败，执行以下回滚：
del /q "C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\export\windows\*"
```

#### 注意事项
- 确保导出模板版本与 Godot 版本匹配
- Windows 导出可能需要较长时间
- 如果遇到错误，检查日志输出
- 首次导出可能需要下载额外的依赖

#### 依赖关系
- 前置任务：task-win-1, task-win-2, task-win-3, task-win-4
- 后置任务：task-win-6（验证导出结果）

---

### 任务6：验证导出结果

**任务ID**：task-win-6
**操作类型**：命令执行
**目标文件**：不适用
**预计执行时间**：约30秒

#### 任务背景
验证 Windows 导出是否成功，检查生成的文件。

#### 操作命令（必填）
```
操作：使用 run_shell_command 工具
命令：dir "C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\export\windows\" && powershell -Command "(Get-Item 'C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\export\windows\TaikoLine.exe').Length / 1MB"
工作目录：C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine
```

#### 操作内容（详细步骤）
1. 列出导出目录中的所有文件
2. 检查文件大小
3. 验证关键文件存在

#### 预期结果
导出目录包含完整的 Windows 游戏文件，可以直接运行。

#### 验证命令（必填）
```
验证命令：if exist "C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\export\windows\TaikoLine.exe" (echo TaikoLine.exe exists) else (echo TaikoLine.exe missing)
预期输出：TaikoLine.exe exists
```

#### 回滚方案（必填）
```
如果验证失败，执行以下回滚：
重新执行 task-win-5
```

#### 注意事项
- 检查文件完整性
- 确认文件大小合理（通常 30-100MB）
- 可以尝试运行 TaikoLine.exe 验证功能

#### 依赖关系
- 前置任务：task-win-5
- 后置任务：无

---

## 任务列表

**总任务数**：6
**预计执行时间**：约20-45分钟

### 任务依赖图
```
task-win-1 (下载Godot) ─────┐
                            │
task-win-2 (下载模板) ──────┼──► task-win-5 (执行导出) ──► task-win-6 (验证结果)
                            │         ▲
task-win-3 (添加预设) ──────┤         │
                            │         │
task-win-4 (创建目录) ──────┘─────────┘
```

### 任务列表
| 序号 | 任务ID | 任务名称 | 操作类型 | 依赖 | 预计时间 |
|------|--------|----------|----------|------|----------|
| 1 | task-win-1 | 下载 Godot 4.4 Windows 版本 | 命令执行 | 无 | 约5-10分钟 |
| 2 | task-win-2 | 下载 Windows Desktop 导出模板 | 命令执行 | 无 | 约5-15分钟 |
| 3 | task-win-3 | 添加 Windows Desktop 导出预设配置 | 文件编辑 | 无 | 约30秒 |
| 4 | task-win-4 | 创建导出目录 | 命令执行 | 无 | 约5秒 |
| 5 | task-win-5 | 执行 Windows Desktop 导出 | 命令执行 | task-win-1,2,3,4 | 约2-5分钟 |
| 6 | task-win-6 | 验证导出结果 | 命令执行 | task-win-5 | 约30秒 |

## 验收标准

### 必须满足
- [ ] Godot 4.4 Windows 版本已下载并安装
- [ ] Windows Desktop 导出模板已下载并安装
- [ ] export_presets.cfg 包含 Windows Desktop 导出预设配置
- [ ] export/windows/ 目录包含完整的 Windows 游戏文件
- [ ] TaikoLine.exe 文件存在且大小合理
- [ ] 可以双击运行 TaikoLine.exe 启动游戏

### 建议满足
- [ ] 导出文件总大小合理（通常 30-100MB）
- [ ] 游戏可以正常启动并显示主菜单
- [ ] 游戏核心功能正常（选曲、游玩、结果）

## 风险评估

| 风险描述 | 影响级别 | 可能性 | 应对策略 |
|----------|----------|--------|----------|
| GitHub 下载速度慢或失败 | 高 | 中 | 使用镜像站点或代理下载 |
| 导出模板版本不匹配 | 高 | 低 | 确保下载与 Godot 版本完全匹配的模板 |
| 网络连接问题 | 中 | 中 | 使用代理或镜像站点下载 |
| 导出过程中内存不足 | 中 | 低 | 关闭其他应用程序 |
| Windows 导出不支持某些功能 | 低 | 低 | 检查项目是否使用了 Windows 不支持的功能 |
| 杀毒软件误报 | 低 | 中 | 将导出目录添加到杀毒软件白名单 |

## 相关资源

- **文档链接**：
  - Godot 官方文档：https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_windows.html
  - Godot Windows 导出模板：https://github.com/godotengine/godot/releases
  - Godot 下载页面：https://godotengine.org/download/windows/
- **代码路径**：
  - 项目根目录：C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine
- **配置文件**：
  - 项目配置：C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\project.godot
  - 导出预设：C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\export_presets.cfg
- **导出输出**：
  - Windows 导出目录：C:\Users\Administrator\Documents\agent-workspace\projects\TaikoLine\export\windows\

## 标签

godot, windows, x64, desktop-export, game-build, taikoline