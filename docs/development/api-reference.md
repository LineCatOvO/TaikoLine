# API参考文档

本文档详细说明 TaikoLine 项目的主要类和方法、Autoload 单例说明和信号说明。

## 主要类

### 1. GameController

游戏控制器，整合所有游戏系统。

**文件位置**: `src/game/game_controller.gd`

#### 信号

| 信号 | 参数 | 说明 |
|------|------|------|
| game_started | - | 游戏开始 |
| game_ended | result: Dictionary | 游戏结束 |
| game_paused | - | 游戏暂停 |
| game_resumed | - | 游戏恢复 |
| time_updated | current_time: float | 时间更新 |
| branch_changed | new_branch: int | 分支切换 |
| gogo_started | - | Go-Go Time开始 |
| gogo_ended | - | Go-Go Time结束 |

#### 属性

| 属性 | 类型 | 说明 |
|------|------|------|
| auto_play | bool | 自动演奏模式 |
| practice_mode | bool | 练习模式 |
| current_state | PlayState | 当前游戏状态 |
| current_song | TJASong | 当前歌曲数据 |
| current_course | TJACourse | 当前难度数据 |
| game_time | float | 当前游戏时间 |

#### 方法

```gdscript
## 加载歌曲
## @param file_path: TJA文件路径
## @param course_type: 难度类型
## @return: 是否加载成功
func load_song(file_path: String, course_type: TJAData.CourseType = TJAData.CourseType.ONI) -> bool

## 开始游戏
func start_game() -> void

## 暂停游戏
func pause_game() -> void

## 恢复游戏
func resume_game() -> void

## 结束游戏
func end_game() -> void

## 重试游戏
func retry_game() -> void

## 处理输入
## @param input_type: 输入类型 ("don" 或 "ka")
func handle_input(input_type: String) -> void

## 获取当前状态
func get_state() -> PlayState

## 获取当前时间
func get_current_time() -> float

## 获取当前分数
func get_current_score() -> int

## 获取当前连击
func get_current_combo() -> int

## 获取最大连击
func get_max_combo() -> int

## 获取判定统计
func get_judge_counts() -> Dictionary

## 获取魂槽百分比
func get_soul_percentage() -> float

## 检查是否在清除状态
func is_clear_status() -> bool

## 设置滚动速度
func set_scroll_speed(speed: float) -> void

## 设置判定偏移
func set_judge_offset(offset_ms: float) -> void
```

---

### 2. JudgeSystem

判定系统，实现判定逻辑、连击管理、分数计算和魂槽系统。

**文件位置**: `src/game/judge.gd`

#### 信号

| 信号 | 参数 | 说明 |
|------|------|------|
| score_updated | score: int | 分数更新 |
| combo_updated | combo: int | 连击更新 |
| judge_result | judge_type: String, note_type: int | 判定结果 |
| soul_gauge_updated | gauge: float | 魂槽更新 |
| full_combo_achieved | - | 达成全连 |
| dondoko_full_combo_achieved | - | 达成全良 |

#### 属性

| 属性 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| perfect_window | float | 33.0 | 良判定窗口（毫秒） |
| good_window | float | 100.0 | 可判定窗口（毫秒） |
| base_score | int | 1000 | 基础分数 |
| score_diff | int | 100 | 分数差值 |
| max_soul_gauge | float | 10000.0 | 魂槽最大值 |
| soul_gain_perfect | float | 100.0 | 良判定魂槽增加 |
| soul_gain_good | float | 50.0 | 可判定魂槽增加 |
| soul_loss_miss | float | -200.0 | 不可判定魂槽减少 |
| soul_threshold_clear | float | 8000.0 | 通关阈值 |

#### 方法

```gdscript
## 重置判定系统
func reset() -> void

## 设置Go-Go Time状态
func set_gogo_time(enabled: bool) -> void

## 设置总音符数
func set_total_notes(count: int) -> void

## 设置分数参数
func set_score_params(init: int, diff: int) -> void

## 判定音符
## @param time_diff_ms: 时间差（毫秒）
## @param note_type: 音符类型
## @return: 判定结果 ("良"/"可"/"不可")
func judge_note(time_diff_ms: float, note_type: int = 0) -> String

## 检查游戏结束状态
## @return: 结果字典
func check_game_end() -> Dictionary

## 获取判定精度
func get_accuracy() -> float

## 获取评级
func get_rank() -> String

## 获取魂槽百分比
func get_soul_percentage() -> float

## 检查是否在清除状态
func is_clear_status() -> bool

## 获取连击数
func get_combo() -> int

## 获取最大连击
func get_max_combo() -> int

## 获取分数
func get_score() -> int

## 获取判定统计
func get_judge_counts() -> Dictionary

## 计算理论最高分
func calculate_max_score() -> int
```

---

### 3. ScrollSystem

滚动系统，实现音符滚动、BPM变化处理、SCROLL命令处理和时间到位置转换。

**文件位置**: `src/game/scroll.gd`

#### 信号

| 信号 | 参数 | 说明 |
|------|------|------|
| scroll_speed_changed | new_speed: float | 滚动速度变化 |
| bpm_changed | new_bpm: float | BPM变化 |

#### 属性

| 属性 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| base_scroll_speed | float | 1.0 | 基础滚动速度 |
| judge_line_x | float | 400.0 | 判定线X坐标 |
| pixels_per_beat | float | 100.0 | 每拍像素数 |

#### 方法

```gdscript
## 重置滚动系统
func reset() -> void

## 设置偏移
func set_offset(offset: float) -> void

## 设置基础滚动速度
func set_base_scroll_speed(speed: float) -> void

## 加载谱面数据
func load_chart_data(course: TJACourse) -> void

## 更新当前时间
func update_time(time: float) -> void

## 时间转换为位置
## @param time_diff: 时间差（秒）
## @return: X坐标位置
func time_to_position(time_diff: float) -> float

## 位置转换为时间
## @param position: X坐标位置
## @return: 时间差（秒）
func position_to_time(position: float) -> float

## 获取生成提前时间
func get_spawn_ahead_time() -> float

## 获取当前BPM
func get_current_bpm() -> float

## 获取当前滚动速度
func get_current_scroll() -> float

## 获取有效滚动速度
func get_effective_scroll_speed() -> float
```

---

### 4. TJAParser

TJA文件解析器。

**文件位置**: `src/parser/tja_parser.gd`

#### 方法

```gdscript
## 解析TJA文件
## @param file_path: TJA文件路径
## @return: TJAParseResult 解析结果
func parse_file(file_path: String) -> TJAData.TJAParseResult

## 解析TJA内容
## @param content: TJA文件内容
## @param file_path: 文件路径（可选）
## @return: TJAParseResult 解析结果
func parse_content(content: String, file_path: String = "") -> TJAData.TJAParseResult

## 获取解析错误信息
func get_error() -> String

## 获取错误行号
func get_error_line() -> int
```

---

### 5. GameNote

音符类，实现音符的视觉表现和状态管理。

**文件位置**: `src/game/note.gd`

#### 信号

| 信号 | 参数 | 说明 |
|------|------|------|
| note_judged | note: GameNote, judge_result: String | 音符判定 |
| note_missed | note: GameNote | 音符错过 |

#### 属性

| 属性 | 类型 | 说明 |
|------|------|------|
| note_type | NoteType | 音符类型 |
| note_state | NoteState | 音符状态 |
| hit_time | float | 应该被打击的时间 |
| position_ratio | float | 在小节中的位置比例 |
| balloon_hits | int | 气球打击次数 |
| renda_count | int | 连打次数 |

#### 方法

```gdscript
## 是否为大音符
func is_big() -> bool

## 是否为连打类型
func is_renda() -> bool

## 是否为可打击音符
func is_hittable() -> bool

## 是否需要红音符输入
func needs_don_input() -> bool

## 是否需要蓝音符输入
func needs_ka_input() -> bool

## 更新音符位置
func update_position(current_time: float, scroll_system: ScrollSystem) -> void

## 尝试判定
## @param input_type: 输入类型
## @param current_time: 当前时间
## @return: 判定结果
func try_judge(input_type: String, current_time: float) -> String

## 重置音符状态
func reset() -> void

## 设置音符数据
func setup(data: TJAData.TJANote, p_hit_time: float) -> void
```

---

### 6. SoulGauge

魂槽显示组件。

**文件位置**: `src/ui/components/soul_gauge.gd`

#### 信号

| 信号 | 说明 |
|------|------|
| soul_threshold_reached | 达到通关阈值 |

#### 属性

| 属性 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| max_soul | float | 10000.0 | 魂槽最大值 |
| clear_threshold | float | 8000.0 | 通关阈值 |
| animation_duration | float | 0.3 | 动画时长 |
| normal_color | Color | (0.3, 0.6, 1.0) | 正常颜色 |
| clear_color | Color | (1.0, 0.8, 0.0) | 通关颜色 |
| danger_color | Color | (1.0, 0.3, 0.3) | 危险颜色 |

#### 方法

```gdscript
## 更新魂槽值
func update_soul(soul: float) -> void

## 获取当前魂槽值
func get_soul() -> float

## 获取百分比
func get_percentage() -> float

## 检查是否清除状态
func is_clear() -> bool

## 重置
func reset() -> void
```

---

## Autoload 单例

### 1. GameState

游戏状态管理。

**文件位置**: `src/autoload/game_state.gd`

**单例名**: `GameState`

#### 属性

| 属性 | 类型 | 说明 |
|------|------|------|
| current_song | Dictionary | 当前选中的歌曲 |
| current_course | String | 当前难度 |
| current_score | int | 当前分数 |
| current_combo | int | 当前连击 |
| max_combo | int | 最大连击 |
| judge_counts | Dictionary | 判定统计 |

#### 方法

```gdscript
## 重置游戏状态
func reset_game_state() -> void

## 添加判定
func add_judge(judge_type: String) -> void
```

---

### 2. Settings

设置管理。

**文件位置**: `src/autoload/settings.gd`

**单例名**: `Settings`

#### 属性

| 属性 | 类型 | 说明 |
|------|------|------|
| scroll_speed | float | 滚动速度 |
| judge_offset | float | 判定偏移 |
| volume_master | float | 主音量 |
| volume_music | float | 音乐音量 |
| volume_sfx | float | 音效音量 |

---

## 数据结构

### TJAData

TJA数据结构定义。

**文件位置**: `src/parser/tja_data.gd`

#### 枚举

```gdscript
## 音符类型枚举
enum NoteType {
    NONE = 0, DON = 1, KA = 2, DON_BIG = 3, KA_BIG = 4,
    RENDA = 5, RENDA_BIG = 6, BALLOON = 7, END = 8,
    KUSUDAMA = 9, DON_DOUBLE = 10, KA_DOUBLE = 11,
    BOMB = 12, ADLIB = 13, SWAP = 14
}

## 难度类型枚举
enum CourseType {
    EASY = 0, NORMAL = 1, HARD = 2, ONI = 3,
    EDIT = 4, TOWER = 5, DAN = 6
}

## 分支类型枚举
enum BranchType {
    NORMAL = 0, EXPERT = 1, MASTER = 2
}

## 分支条件类型枚举
enum BranchConditionType {
    ACCURACY = 0, RENDA = 1, SCORE = 2
}
```

#### 类

| 类 | 说明 |
|------|------|
| TJANote | 音符数据 |
| TJACommand | 命令数据 |
| TJAMeasure | 小节数据 |
| TJACourse | 难度数据 |
| TJASong | 歌曲元数据 |
| TJAParseResult | 解析结果 |
| BranchCondition | 分支条件 |

#### 静态方法

```gdscript
## 将字符串转换为音符类型
static func char_to_note_type(char: String) -> NoteType

## 将字符串转换为难度类型
static func string_to_course_type(str: String) -> CourseType

## 将难度类型转换为字符串
static func course_type_to_string(type: CourseType) -> String
```

---

## 相关文件

- 项目架构: `docs/development/architecture.md`
- 判定系统实现: `src/game/judge.gd`
- 游戏控制器: `src/game/game_controller.gd`
- TJA解析器: `src/parser/tja_parser.gd`
- 数据结构: `src/parser/tja_data.gd`