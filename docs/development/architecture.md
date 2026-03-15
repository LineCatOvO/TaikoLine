# 项目架构

本文档详细说明 TaikoLine 项目的架构设计，包括项目结构说明、模块划分和数据流说明。

## 项目结构

```
TaikoLine/
├── scenes/              # 游戏场景
│   ├── main.gd          # 主菜单场景脚本
│   ├── main.tscn        # 主菜单场景
│   ├── song_select.gd   # 选曲场景脚本
│   ├── song_select.tscn # 选曲场景
│   ├── gameplay.gd      # 游戏场景脚本
│   ├── gameplay.tscn    # 游戏场景
│   ├── result.gd        # 结果场景脚本
│   └── result.tscn      # 结果场景
├── src/
│   ├── audio/           # 音频系统
│   │   ├── audio_manager.gd      # 音频管理器
│   │   └── sound_effect_player.gd # 音效播放器
│   ├── autoload/        # 自动加载单例
│   │   ├── game_state.gd         # 游戏状态
│   │   └── settings.gd           # 设置管理
│   ├── game/            # 游戏核心
│   │   ├── game_controller.gd    # 游戏控制器
│   │   ├── judge.gd              # 判定系统
│   │   ├── note.gd               # 音符类
│   │   ├── note_manager.gd       # 音符管理器
│   │   └── scroll.gd             # 滚动系统
│   ├── parser/          # 谱面解析
│   │   ├── tja_data.gd           # 数据结构定义
│   │   ├── tja_parser.gd         # TJA解析器
│   │   └── vtt_parser.gd         # VTT歌词解析
│   └── ui/              # UI组件
│       ├── components/           # UI子组件
│       │   ├── combo_display.gd  # 连击显示
│       │   ├── judge_display.gd  # 判定显示
│       │   ├── lyrics_display.gd # 歌词显示
│       │   ├── score_display.gd  # 分数显示
│       │   ├── song_item.gd      # 歌曲项
│       │   └── soul_gauge.gd     # 魂槽显示
│       ├── gameplay.gd           # 游戏UI
│       ├── result.gd             # 结果UI
│       ├── skin_manager.gd       # 皮肤管理
│       └── song_select.gd        # 选曲UI
├── songs/               # 谱面目录
│   └── test/            # 测试谱面
│       ├── demo.tja
│       └── sample.tja
├── resources/           # 资源文件
│   ├── skins/           # 皮肤资源
│   │   └── default/
│   │       └── skin.json
│   └── sounds/          # 音效资源
│       └── README.md
├── tools/               # 工具脚本
│   └── generate_sounds.gd
├── tasks/               # 任务文档
│   ├── completed/
│   └── pending/
├── docs/                # 文档目录
│   ├── README.md
│   ├── game-mechanics/
│   ├── tja-format/
│   └── development/
├── icon.svg             # 项目图标
├── project.godot        # 项目配置
└── README.md            # 项目说明
```

## 模块划分

### 1. 场景模块 (scenes/)

负责游戏场景的组织和管理。

| 文件 | 职责 |
|------|------|
| main.gd/tscn | 主菜单场景 |
| song_select.gd/tscn | 选曲场景 |
| gameplay.gd/tscn | 游戏主场景 |
| result.gd/tscn | 结果展示场景 |

### 2. 音频模块 (src/audio/)

负责音频播放和音效管理。

```
┌─────────────────┐
│  AudioManager   │ ─── 背景音乐播放
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│SoundEffectPlayer│ ─── 音效播放
└─────────────────┘
```

| 类 | 职责 |
|------|------|
| AudioManager | 背景音乐播放、音频同步 |
| SoundEffectPlayer | 打击音效、判定音效 |

### 3. 自动加载模块 (src/autoload/)

全局单例，提供全局状态管理。

| 单例名 | 文件 | 职责 |
|--------|------|------|
| GameState | game_state.gd | 游戏状态管理 |
| Settings | settings.gd | 设置管理 |

### 4. 游戏核心模块 (src/game/)

游戏核心逻辑实现。

```
┌─────────────────────────────────────────────────┐
│              GameController                      │
│  ┌─────────────────────────────────────────┐   │
│  │              游戏流程控制                  │   │
│  │  - 加载歌曲                               │   │
│  │  - 开始/暂停/结束                         │   │
│  │  - 输入处理                               │   │
│  └─────────────────────────────────────────┘   │
└──────────────────────┬──────────────────────────┘
                       │
         ┌─────────────┼─────────────┐
         ▼             ▼             ▼
┌─────────────┐ ┌─────────────┐ ┌─────────────┐
│NoteManager  │ │ JudgeSystem │ │ScrollSystem │
│ 音符管理    │ │ 判定系统    │ │ 滚动系统    │
└─────────────┘ └─────────────┘ └─────────────┘
```

| 类 | 职责 |
|------|------|
| GameController | 游戏流程控制、系统协调 |
| NoteManager | 音符生成、回收、判定 |
| JudgeSystem | 判定计算、分数计算、魂槽管理 |
| ScrollSystem | BPM变化、滚动速度、时间-位置转换 |
| GameNote | 音符视觉表现、状态管理 |

### 5. 解析模块 (src/parser/)

谱面文件解析。

```
┌─────────────────┐
│   TJAParser     │ ─── TJA文件解析
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│    TJAData      │ ─── 数据结构定义
└─────────────────┘
```

| 类 | 职责 |
|------|------|
| TJAParser | TJA文件解析、错误处理 |
| TJAData | 数据结构定义（音符、小节、课程等） |
| VTTParser | VTT歌词文件解析 |

### 6. UI模块 (src/ui/)

用户界面组件。

```
┌─────────────────────────────────────────────────┐
│                   UI层                          │
├─────────────────────────────────────────────────┤
│  ┌───────────┐  ┌───────────┐  ┌───────────┐  │
│  │ScoreDisplay│  │ComboDisplay│  │SoulGauge │  │
│  └───────────┘  └───────────┘  └───────────┘  │
│  ┌───────────┐  ┌───────────┐  ┌───────────┐  │
│  │JudgeDisplay│  │LyricsDisplay│ │SongItem  │  │
│  └───────────┘  └───────────┘  └───────────┘  │
└─────────────────────────────────────────────────┘
```

| 组件 | 职责 |
|------|------|
| ScoreDisplay | 分数显示 |
| ComboDisplay | 连击显示 |
| SoulGauge | 魂槽显示 |
| JudgeDisplay | 判定结果显示 |
| LyricsDisplay | 歌词显示 |
| SongItem | 歌曲列表项 |
| SkinManager | 皮肤管理 |

## 数据流说明

### 1. 游戏启动流程

```
用户启动游戏
       │
       ▼
┌─────────────────┐
│   Main Scene    │ ─── 显示主菜单
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ SongSelect Scene│ ─── 选择歌曲和难度
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Gameplay Scene  │ ─── 游戏主循环
└─────────────────┘
```

### 2. 谱面加载流程

```
GameController.load_song()
       │
       ▼
┌─────────────────┐
│   TJAParser     │ ─── 解析TJA文件
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│    TJAData      │ ─── 生成数据结构
└────────┬────────┘
         │
         ├──────────────────┐
         ▼                  ▼
┌─────────────────┐ ┌─────────────────┐
│  ScrollSystem   │ │   NoteManager   │
│ 加载BPM/滚动数据 │ │  加载音符数据   │
└─────────────────┘ └─────────────────┘
```

### 3. 游戏主循环

```
_process(delta)
       │
       ├──────────────────┐
       ▼                  ▼
┌─────────────────┐ ┌─────────────────┐
│  更新时间       │ │ 检查分支条件    │
└────────┬────────┘ └─────────────────┘
         │
         ▼
┌─────────────────┐
│  ScrollSystem   │ ─── 更新滚动状态
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  NoteManager    │ ─── 更新音符位置
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  检查游戏结束   │
└─────────────────┘
```

### 4. 输入处理流程

```
用户输入
       │
       ▼
┌─────────────────┐
│ GameController  │ ─── handle_input()
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  NoteManager    │ ─── 查找可判定音符
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   GameNote      │ ─── try_judge()
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  JudgeSystem    │ ─── 计算判定结果
└────────┬────────┘
         │
         ├──────────────────┬──────────────────┐
         ▼                  ▼                  ▼
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│   更新分数      │ │   更新连击      │ │   更新魂槽      │
└─────────────────┘ └─────────────────┘ └─────────────────┘
```

### 5. 信号流

```
┌─────────────────┐
│  JudgeSystem    │
└────────┬────────┘
         │
         │ score_updated
         ├──────────────────────► GameState.current_score
         │
         │ combo_updated
         ├──────────────────────► GameState.current_combo
         │
         │ judge_result
         ├──────────────────────► JudgeDisplay
         │
         │ soul_gauge_updated
         └──────────────────────► SoulGauge
```

## 类图

```
┌─────────────────────────────────────────────────────────────┐
│                        GameController                        │
├─────────────────────────────────────────────────────────────┤
│ - note_manager: NoteManager                                  │
│ - judge_system: JudgeSystem                                  │
│ - scroll_system: ScrollSystem                                │
│ - music_player: AudioStreamPlayer                            │
│ - current_song: TJASong                                      │
│ - current_course: TJACourse                                  │
├─────────────────────────────────────────────────────────────┤
│ + load_song(file_path, course_type) -> bool                  │
│ + start_game()                                               │
│ + pause_game()                                               │
│ + resume_game()                                              │
│ + end_game()                                                 │
│ + handle_input(input_type)                                   │
└─────────────────────────────────────────────────────────────┘
                              │
            ┌─────────────────┼─────────────────┐
            ▼                 ▼                 ▼
┌───────────────────┐ ┌───────────────────┐ ┌───────────────────┐
│   NoteManager     │ │   JudgeSystem     │ │   ScrollSystem    │
├───────────────────┤ ├───────────────────┤ ├───────────────────┤
│ - notes: Array    │ │ - current_score   │ │ - _bpm_changes    │
│ - scroll_system   │ │ - current_combo   │ │ - _scroll_changes │
│ - judge_system    │ │ - soul_gauge      │ │ - _current_bpm    │
├───────────────────┤ ├───────────────────┤ ├───────────────────┤
│ + load_chart()    │ │ + judge_note()    │ │ + time_to_position│
│ + update()        │ │ + get_accuracy()  │ │ + position_to_time│
│ + handle_input()  │ │ + get_rank()      │ │ + get_spawn_time  │
└───────────────────┘ └───────────────────┘ └───────────────────┘
```

## 相关文件

- API参考: `docs/development/api-reference.md`
- 判定系统: `src/game/judge.gd`
- 游戏控制器: `src/game/game_controller.gd`
- TJA解析器: `src/parser/tja_parser.gd`