# Task-P0-001: TaikoLine Web 版本打包

**创建时间**：2026-03-19
**更新时间**：2026-03-21
**优先级**：P0
**状态**：已完成
**任务锁**：✅ 已完成 - Coder - 2026-03-21
**项目**：TaikoLine
**预计执行时间**：约30分钟

## 任务描述

将 TaikoLine 项目打包为 Web 版本，生成可在浏览器中运行的 HTML5 游戏。

## 任务背景

### 问题分析
- **问题描述**：用户需要将 TaikoLine 项目打包为 Web 版本，但当前项目只有 Android 导出预设，没有 Web 导出配置
- **影响范围**：项目导出配置、导出模板、构建输出
- **根本原因**：项目创建时未配置 Web 导出预设

### 当前状态分析
- **相关文件**：
  - `/home/linecat-huawei/agent-workspace/projects/TaikoLine/project.godot` - 项目配置文件
  - `/home/linecat-huawei/agent-workspace/projects/TaikoLine/export_presets.cfg` - 导出预设配置（当前只有 Android）
- **当前配置**：
  - Godot 版本：4.4.stable.official.4c311cbee
  - 渲染器：Forward Plus
  - 已有导出预设：Android (arm64-v8a)
  - 导出模板目录：`~/.local/share/godot/export_templates/`（当前为空）
- **依赖关系**：
  - 需要下载 Web 导出模板
  - 需要添加 Web 导出预设配置

### 修改原因
用户需要将游戏发布到 Web 平台，需要配置 Web 导出并执行打包。

## 详细执行计划

### 任务1：添加 Web 导出预设配置

**任务ID**：task-web-1
**操作类型**：文件编辑
**目标文件**：/home/linecat-huawei/agent-workspace/projects/TaikoLine/export_presets.cfg
**预计执行时间**：约30秒

#### 任务背景
当前 export_presets.cfg 只有 Android 导出预设，需要添加 Web 导出预设配置。

#### 操作命令（必填）
```
操作：使用 edit 工具
文件路径：/home/linecat-huawei/agent-workspace/projects/TaikoLine/export_presets.cfg
```

#### 操作内容（详细步骤）
1. 使用 read_file 工具读取当前 export_presets.cfg 内容
2. 使用 edit 工具在文件末尾添加 Web 导出预设配置
3. 使用 read_file 工具验证修改成功

#### 需要添加的配置内容
```ini
[preset.1]

name="Web"
platform="Web"
runnable=true
dedicated_server=false
custom_features=""
export_filter="all_resources"
include_filter=""
exclude_filter=""
export_path="export/web/index.html"
encryption_include_filters=""
encryption_exclude_filters=""
encrypt_pck=false
encrypt_directory=false

[preset.1.options]

custom_template/debug=""
custom_template/release=""
variant/extensions_capability=false
variant/thread_support=false
vram_texture_compression/for_desktop=true
vram_texture_compression/for_mobile=false
html/export_icon=true
html/custom_html_shell=""
html/head_include=""
html/canvas_resize_policy=2
html/focus_canvas_on_start=true
html/experimental_virtual_keyboard=false
progressive_web_app/enabled=false
progressive_web_app/ensure_cross_origin_isolation_headers=true
progressive_web_app/offline_page=""
progressive_web_app/display=1
progressive_web_app/orientation=0
progressive_web_app/icon_144x144=""
progressive_web_app/icon_180x180=""
progressive_web_app/icon_512x512=""
progressive_web_app/background_color=Color(0, 0, 0, 1)
```

#### 预期结果
export_presets.cfg 文件包含 Web 导出预设配置（preset.1）

#### 验证命令（必填）
```
验证命令：grep -n "platform=\"Web\"" /home/linecat-huawei/agent-workspace/projects/TaikoLine/export_presets.cfg
预期输出：platform="Web"
```

#### 回滚方案（必填）
```
如果操作失败，执行以下回滚：
使用 edit 工具删除添加的 [preset.1] 和 [preset.1.options] 部分
```

#### 注意事项
- 确保 preset 编号正确（当前已有 preset.0，新预设应为 preset.1）
- Web 导出路径设置为 export/web/index.html

#### 依赖关系
- 前置任务：无
- 后置任务：task-web-2（下载导出模板）

---

### 任务2：创建导出目录

**任务ID**：task-web-2
**操作类型**：命令执行
**目标文件**：不适用
**预计执行时间**：约5秒

#### 任务背景
需要创建 Web 导出的输出目录。

#### 操作命令（必填）
```
操作：使用 run_shell_command 工具
命令：mkdir -p /home/linecat-huawei/agent-workspace/projects/TaikoLine/export/web
工作目录：/home/linecat-huawei/agent-workspace/projects/TaikoLine
```

#### 操作内容（详细步骤）
1. 执行 mkdir 命令创建导出目录
2. 验证目录创建成功

#### 预期结果
/home/linecat-huawei/agent-workspace/projects/TaikoLine/export/web 目录存在

#### 验证命令（必填）
```
验证命令：ls -la /home/linecat-huawei/agent-workspace/projects/TaikoLine/export/
预期输出：包含 web 目录
```

#### 回滚方案（必填）
```
如果操作失败，执行以下回滚：
rm -rf /home/linecat-huawei/agent-workspace/projects/TaikoLine/export/web
```

#### 注意事项
- 目录权限需要正确设置
- 确保父目录存在

#### 依赖关系
- 前置任务：无
- 后置任务：task-web-3（下载导出模板）

---

### 任务3：下载 Web 导出模板

**任务ID**：task-web-3
**操作类型**：命令执行
**目标文件**：不适用
**预计执行时间**：约5-10分钟（取决于网络速度）

#### 任务背景
Godot 导出需要对应版本的导出模板。当前导出模板目录为空，需要下载 Web 导出模板。

#### 操作命令（必填）
```
操作：使用 run_shell_command 工具
命令：~/bin/Godot_v4.4-stable_linux.arm64 --headless --quit-after 2 2>&1 || echo "Template download initiated"
工作目录：/home/linecat-huawei/agent-workspace/projects/TaikoLine
```

**备选方案**：如果自动下载失败，需要手动下载模板：
```
# 下载 Godot 4.4 Web 导出模板
wget https://github.com/godotengine/godot/releases/download/4.4-stable/Godot_v4.4-stable_export_templates.tpz -O /tmp/godot_templates.tpz

# 解压到模板目录
mkdir -p ~/.local/share/godot/export_templates/4.4.stable
unzip /tmp/godot_templates.tpz -d ~/.local/share/godot/export_templates/4.4.stable/
```

#### 操作内容（详细步骤）
1. 尝试通过 Godot 编辑器自动下载模板
2. 如果自动下载失败，使用手动下载方式
3. 验证模板文件存在

#### 预期结果
~/.local/share/godot/export_templates/4.4.stable/ 目录包含 Web 导出模板文件

#### 验证命令（必填）
```
验证命令：ls ~/.local/share/godot/export_templates/4.4.stable/ 2>/dev/null | grep -i web || echo "Templates not found"
预期输出：包含 web_release 或 web_debug 相关文件
```

#### 回滚方案（必填）
```
如果操作失败，执行以下回滚：
rm -rf ~/.local/share/godot/export_templates/4.4.stable/
```

#### 注意事项
- 需要网络连接
- 下载可能需要较长时间
- ARM64 平台可能需要特殊处理

#### 依赖关系
- 前置任务：无
- 后置任务：task-web-4（执行导出）

---

### 任务4：执行 Web 导出

**任务ID**：task-web-4
**操作类型**：命令执行
**目标文件**：不适用
**预计执行时间**：约2-5分钟

#### 任务背景
使用 Godot 命令行工具执行 Web 导出。

#### 操作命令（必填）
```
操作：使用 run_shell_command 工具
命令：~/bin/Godot_v4.4-stable_linux.arm64 --headless --path /home/linecat-huawei/agent-workspace/projects/TaikoLine --export-release "Web" /home/linecat-huawei/agent-workspace/projects/TaikoLine/export/web/index.html
工作目录：/home/linecat-huawei/agent-workspace/projects/TaikoLine
```

#### 操作内容（详细步骤）
1. 确认导出模板已安装
2. 执行 Godot 导出命令
3. 等待导出完成
4. 检查导出输出

#### 预期结果
/home/linecat-huawei/agent-workspace/projects/TaikoLine/export/web/ 目录包含：
- index.html
- index.js
- index.wasm
- index.pck
- 其他资源文件

#### 验证命令（必填）
```
验证命令：ls -la /home/linecat-huawei/agent-workspace/projects/TaikoLine/export/web/
预期输出：包含 index.html, index.js, index.wasm 等文件
```

#### 回滚方案（必填）
```
如果操作失败，执行以下回滚：
rm -rf /home/linecat-huawei/agent-workspace/projects/TaikoLine/export/web/*
```

#### 注意事项
- 确保导出模板版本与 Godot 版本匹配
- Web 导出可能需要较长时间
- 如果遇到错误，检查日志输出

#### 依赖关系
- 前置任务：task-web-1, task-web-2, task-web-3
- 后置任务：task-web-5（验证导出结果）

---

### 任务5：验证导出结果

**任务ID**：task-web-5
**操作类型**：命令执行
**目标文件**：不适用
**预计执行时间**：约30秒

#### 任务背景
验证 Web 导出是否成功，检查生成的文件。

#### 操作命令（必填）
```
操作：使用 run_shell_command 工具
命令：ls -la /home/linecat-huawei/agent-workspace/projects/TaikoLine/export/web/ && du -sh /home/linecat-huawei/agent-workspace/projects/TaikoLine/export/web/
工作目录：/home/linecat-huawei/agent-workspace/projects/TaikoLine
```

#### 操作内容（详细步骤）
1. 列出导出目录中的所有文件
2. 检查文件大小
3. 验证关键文件存在

#### 预期结果
导出目录包含完整的 Web 游戏文件，可以部署到 Web 服务器。

#### 验证命令（必填）
```
验证命令：test -f /home/linecat-huawei/agent-workspace/projects/TaikoLine/export/web/index.html && echo "index.html exists" || echo "index.html missing"
预期输出：index.html exists
```

#### 回滚方案（必填）
```
如果验证失败，执行以下回滚：
重新执行 task-web-4
```

#### 注意事项
- 检查文件完整性
- 确认文件大小合理

#### 依赖关系
- 前置任务：task-web-4
- 后置任务：无

---

## 任务列表

**总任务数**：5
**预计执行时间**：约15-30分钟

### 任务依赖图
```
task-web-1 (添加预设) ──┐
                        │
task-web-2 (创建目录) ──┼──► task-web-4 (执行导出) ──► task-web-5 (验证结果)
                        │
task-web-3 (下载模板) ──┘
```

### 任务列表
| 序号 | 任务ID | 任务名称 | 操作类型 | 依赖 | 预计时间 |
|------|--------|----------|----------|------|----------|
| 1 | task-web-1 | 添加 Web 导出预设配置 | 文件编辑 | 无 | 约30秒 |
| 2 | task-web-2 | 创建导出目录 | 命令执行 | 无 | 约5秒 |
| 3 | task-web-3 | 下载 Web 导出模板 | 命令执行 | 无 | 约5-10分钟 |
| 4 | task-web-4 | 执行 Web 导出 | 命令执行 | task-web-1,2,3 | 约2-5分钟 |
| 5 | task-web-5 | 验证导出结果 | 命令执行 | task-web-4 | 约30秒 |

## 验收标准

### 必须满足
- [ ] export_presets.cfg 包含 Web 导出预设配置
- [ ] Web 导出模板已下载并安装
- [ ] export/web/ 目录包含完整的 Web 游戏文件
- [ ] index.html 文件存在且可访问
- [ ] index.wasm 文件存在（WebAssembly 运行时）
- [ ] index.pck 文件存在（游戏资源包）

### 建议满足
- [ ] 导出文件总大小合理（通常 10-50MB）
- [ ] 可以在本地 Web 服务器上运行测试

## 风险评估

| 风险描述 | 影响级别 | 可能性 | 应对策略 |
|----------|----------|--------|----------|
| 导出模板下载失败 | 高 | 中 | 使用手动下载方式，从 GitHub 直接下载 |
| ARM64 平台兼容性问题 | 高 | 低 | 确认 Godot ARM64 版本支持 Web 导出 |
| 网络连接问题 | 中 | 中 | 使用代理或镜像站点下载模板 |
| 导出过程中内存不足 | 中 | 低 | 关闭其他应用程序，增加交换空间 |
| Web 导出不支持某些功能 | 低 | 中 | 检查项目是否使用了 Web 不支持的功能 |

## 相关资源

- **文档链接**：
  - Godot 官方文档：https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html
  - Godot Web 导出模板：https://github.com/godotengine/godot/releases
- **代码路径**：
  - 项目根目录：/home/linecat-huawei/agent-workspace/projects/TaikoLine
- **配置文件**：
  - 项目配置：/home/linecat-huawei/agent-workspace/projects/TaikoLine/project.godot
  - 导出预设：/home/linecat-huawei/agent-workspace/projects/TaikoLine/export_presets.cfg
- **导出输出**：
  - Web 导出目录：/home/linecat-huawei/agent-workspace/projects/TaikoLine/export/web/

## 标签

godot, web-export, html5, game-build, taikoline