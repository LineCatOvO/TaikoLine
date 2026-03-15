# TJA格式完整规范

本文档详细说明 TJA 文件格式的完整规范，包括文件结构、元数据命令、谱面命令和音符代码。

## 文件结构

### 基本结构

一个 TJA 文件由以下部分组成：

```
[头部元数据]
[COURSE定义]
[谱面数据]
[END标记]
```

### 示例结构

```
TITLE:歌曲标题
BPM:120
WAVE:audio.ogg
OFFSET:0.0

COURSE:Oni
LEVEL:8
BALLOON:10,15
SCOREINIT:1000
SCOREDIFF:100

#START
1000000000001000,
2000000000002000,
#BPMCHANGE:140
3000000000003000,
#GOGOSTART
4000000000004000,
#GOGOEND
#END
```

## 头部元数据命令

### 歌曲信息

| 命令 | 说明 | 示例 |
|------|------|------|
| TITLE | 歌曲标题（日文） | `TITLE:太鼓の達人` |
| TITLEEN | 歌曲标题（英文） | `TITLEEN:Taiko no Tatsujin` |
| SUBTITLE | 副标题 | `SUBTITLE:~アニメスペシャル~` |
| MAKER | 谱面作者 | `MAKER:TaikoLine` |
| GENRE | 歌曲类型 | `GENRE:バラエティ` |

### 音频信息

| 命令 | 说明 | 示例 |
|------|------|------|
| BPM | 初始BPM | `BPM:120` |
| WAVE | 音频文件名 | `WAVE:song.ogg` |
| OFFSET | 音频偏移（秒） | `OFFSET:-0.05` |
| DEMOSTART | 预览开始时间 | `DEMOSTART:30.0` |
| LYRICS | 歌词文件路径 | `LYRICS:lyrics.vtt` |

### 计分信息

| 命令 | 说明 | 示例 |
|------|------|------|
| SCOREMODE | 计分模式 | `SCOREMODE:0` |

## 难度定义命令

### COURSE 命令

定义难度类型：

| 值 | 说明 |
|------|------|
| Easy | 简单 |
| Normal | 普通 |
| Hard | 困难 |
| Oni | 鬼 |
| Edit | 编辑 |
| Tower | 塔 |
| Dan | 段位 |

**示例**:
```
COURSE:Oni
```

### LEVEL 命令

定义难度星级（1-10）：

```
LEVEL:8
```

### BALLOON 命令

定义气球/久寿玉的击打次数：

```
BALLOON:5,10,15,20
```

### SCOREINIT / SCOREDIFF 命令

定义计分参数：

```
SCOREINIT:1000
SCOREDIFF:100
```

### STYLE 命令

定义谱面样式：

| 值 | 说明 |
|------|------|
| Single | 单人 |
| Double | 双人 |

**示例**:
```
STYLE:Single
```

## 谱面命令

### 基本命令

| 命令 | 说明 | 示例 |
|------|------|------|
| #START | 谱面开始 | `#START` |
| #END | 谱面结束 | `#END` |

### BPM变化

| 命令 | 说明 | 示例 |
|------|------|------|
| #BPMCHANGE | BPM变化 | `#BPMCHANGE:140` |

### 滚动速度

| 命令 | 说明 | 示例 |
|------|------|------|
| #SCROLL | 滚动速度变化 | `#SCROLL:1.5` |

### 拍号变化

| 命令 | 说明 | 示例 |
|------|------|------|
| #MEASURE | 拍号变化 | `#MEASURE:3/4` |

### Go-Go Time

| 命令 | 说明 | 示例 |
|------|------|------|
| #GOGOSTART | Go-Go Time开始 | `#GOGOSTART` |
| #GOGOEND | Go-Go Time结束 | `#GOGOEND` |

### 小节线控制

| 命令 | 说明 | 示例 |
|------|------|------|
| #BARLINEOFF | 隐藏小节线 | `#BARLINEOFF` |
| #BARLINEON | 显示小节线 | `#BARLINEON` |

### 时间偏移

| 命令 | 说明 | 示例 |
|------|------|------|
| #DELAY | 时间偏移 | `#DELAY:0.5` |

### 分支谱面命令

| 命令 | 说明 | 示例 |
|------|------|------|
| #BRANCHSTART | 分支开始 | `#BRANCHSTART p,75,90` |
| #N | 普通分支 | `#N` |
| #E | 高级分支 | `#E` |
| #M | 大师分支 | `#M` |
| #BRANCHEND | 分支结束 | `#BRANCHEND` |
| #SECTION | 重置分支判定 | `#SECTION` |

### 歌词显示

| 命令 | 说明 | 示例 |
|------|------|------|
| #LYRIC | 歌词显示 | `#LYRIC:歌詞テキスト` |

## 音符代码

### 基本音符

| 代码 | 音符名称 | 说明 |
|------|---------|------|
| 0 | 空白 | 无音符 |
| 1 | 小红音符 | Don |
| 2 | 小蓝音符 | Ka |
| 3 | 大红音符 | Big Don |
| 4 | 大蓝音符 | Big Ka |

### 连打音符

| 代码 | 音符名称 | 说明 |
|------|---------|------|
| 5 | 普通连打 | Drumroll |
| 6 | 大连打 | Big Drumroll |
| 7 | 气球 | Balloon |
| 8 | 结束标记 | 连打/气球结束 |
| 9 | 久寿玉 | Kusudama |

### 特殊音符

| 代码 | 音符名称 | 说明 |
|------|---------|------|
| A/a | 双人大红 | Don Double |
| B/b | 双人大蓝 | Ka Double |
| C/c | 炸弹 | Bomb |
| F/f | ADLIB | 隐藏音符 |
| G/g | 交换 | Swap |

## 谱面数据格式

### 小节格式

每个小节由一行数字组成，以逗号结尾：

```
1000000000001000,
```

### 小节分隔

逗号 `,` 用于分隔小节：

```
1000000000001000,
2000000000002000,
```

### 音符位置

数字的位置表示音符在小节中的相对时间位置：

```
1000000000001000,  # 两个音符，分别在开头和结尾
```

## 命令解析实现

### 命令类型枚举

```gdscript
## 命令数据类
class TJACommand:
    ## 命令类型枚举
    enum CommandType {
        MEASURE,      ## #MEASURE 拍号变化
        BPMCHANGE,    ## #BPMCHANGE BPM变化
        DELAY,        ## #DELAY 时间偏移
        SCROLL,       ## #SCROLL 滚动速度
        GOGOSTART,    ## #GOGOSTART Go-Go Time开始
        GOGOEND,      ## #GOGOEND Go-Go Time结束
        BARLINEOFF,   ## #BARLINEOFF 隐藏小节线
        BARLINEON,    ## #BARLINEON 显示小节线
        BRANCHSTART,  ## #BRANCHSTART 分支开始
        BRANCHEND,    ## #BRANCHEND 分支结束
        SECTION,      ## #SECTION 重置分支判定
        LYRIC,        ## #LYRIC 歌词显示
        N,            ## #N 普通分支
        E,            ## #E 高级分支
        M,            ## #M 大师分支
        START,        ## #START 谱面开始
        END           ## #END 谱面结束
    }
```

### 命令解析

```gdscript
## 解析命令
func _parse_command(line: String) -> bool:
    # 移除#号
    var cmd = line.substr(1).to_upper()

    # 解析命令和参数
    var space_pos = cmd.find(" ")
    var cmd_name: String
    var cmd_params: String

    if space_pos != -1:
        cmd_name = cmd.left(space_pos)
        cmd_params = cmd.substr(space_pos + 1).strip_edges()
    else:
        cmd_name = cmd
        cmd_params = ""

    # 处理命令
    match cmd_name:
        "START":
            _state = ParseState.NOTES
            _measure_index = 0
        "END":
            if _current_course != null:
                _song.add_course(_current_course)
                _current_course = null
            _state = ParseState.HEADER
        "MEASURE":
            var parts = cmd_params.split("/")
            if parts.size() == 2:
                _current_measure = Vector2(
                    _parse_float(parts[0], 4.0),
                    _parse_float(parts[1], 4.0)
                )
        "BPMCHANGE":
            _current_bpm = _parse_float(cmd_params, _current_bpm)
        "SCROLL":
            _current_scroll = _parse_float(cmd_params, 1.0)
        "GOGOSTART":
            _is_gogo = true
        "GOGOEND":
            _is_gogo = false
        # ... 其他命令处理 ...

    return true
```

## 文件编码

TJA 文件支持以下编码：

| 编码 | 说明 |
|------|------|
| UTF-8 | 推荐编码 |
| UTF-16 | 部分支持 |
| Shift-JIS | 日文编码 |
| ASCII | 基本支持 |

### 编码检测实现

```gdscript
## 读取文件（自动检测编码）
func _read_file_with_encoding(file_path: String) -> String:
    var file = FileAccess.open(file_path, FileAccess.READ)
    if file == null:
        return ""

    var content = file.get_buffer(file.get_length())
    file.close()

    # 尝试UTF-8解码
    var text = content.get_string_from_utf8()
    if not text.is_empty():
        return text

    # 尝试UTF-16解码
    text = content.get_string_from_utf16()
    if not text.is_empty():
        return text

    # 回退到ASCII
    return content.get_string_from_ascii()
```

## 相关文件

- 数据结构定义: `src/parser/tja_data.gd`
- TJA解析器: `src/parser/tja_parser.gd`
- TJA示例: `docs/tja-format/examples.md`