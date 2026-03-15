# 音符类型

本文档详细说明 TaikoLine 支持的所有音符类型，包括 TJA 代码、操作方式、得分特点和图形表示。

## 音符类型总览

TaikoLine 支持以下音符类型：

| 音符名称 | TJA代码 | 英文名称 | 说明 |
|---------|---------|----------|------|
| 空白 | 0 | None | 无音符，表示空白位置 |
| 小红音符 | 1 | Don | 普通红色音符 |
| 小蓝音符 | 2 | Ka | 普通蓝色音符 |
| 大红音符 | 3 | Big Don | 大型红色音符 |
| 大蓝音符 | 4 | Big Ka | 大型蓝色音符 |
| 普通连打 | 5 | Drumroll | 普通连打音符 |
| 大连打 | 6 | Big Drumroll | 大型连打音符 |
| 气球 | 7 | Balloon | 气球音符 |
| 结束标记 | 8 | End | 连打/气球结束标记 |
| 久寿玉 | 9 | Kusudama | 久寿玉音符 |
| 双人大红 | A | Don Double | 双人合作大红音符 |
| 双人大蓝 | B | Ka Double | 双人合作大蓝音符 |
| 炸弹 | C | Bomb | 炸弹音符 |
| ADLIB | F | ADLIB | 隐藏音符 |
| 交换 | G | Swap | 交换音符 |

## 详细说明

### 1. 小红音符 (Don)

**TJA代码**: `1`

**操作方式**: 击打鼓面（按键 F 或 J）

**得分特点**:
- 基础得分
- 受连击加成影响
- Go-Go Time 时得分 × 1.2

**图形表示**:
```
  ┌─────┐
  │  ●  │  红色圆形
  └─────┘
```

**代码示例**:
```gdscript
# TJA谱面中的表示
1000000000001000  # 两个小红音符
```

---

### 2. 小蓝音符 (Ka)

**TJA代码**: `2`

**操作方式**: 击打鼓边（按键 D 或 K）

**得分特点**:
- 基础得分
- 受连击加成影响
- Go-Go Time 时得分 × 1.2

**图形表示**:
```
  ┌─────┐
  │  ○  │  蓝色圆形
  └─────┘
```

**代码示例**:
```gdscript
# TJA谱面中的表示
2000000000002000  # 两个小蓝音符
```

---

### 3. 大红音符 (Big Don)

**TJA代码**: `3`

**操作方式**: 双手同时击打鼓面（同时按 F+J）

**得分特点**:
- 基础得分 × 2
- 受连击加成影响
- Go-Go Time 时得分 × 1.2

**图形表示**:
```
  ┌───────┐
  │   ●   │  大红色圆形
  └───────┘
```

**代码示例**:
```gdscript
# TJA谱面中的表示
3000000000003000  # 两个大红音符
```

---

### 4. 大蓝音符 (Big Ka)

**TJA代码**: `4`

**操作方式**: 双手同时击打鼓边（同时按 D+K）

**得分特点**:
- 基础得分 × 2
- 受连击加成影响
- Go-Go Time 时得分 × 1.2

**图形表示**:
```
  ┌───────┐
  │   ○   │  大蓝色圆形
  └───────┘
```

**代码示例**:
```gdscript
# TJA谱面中的表示
4000000000004000  # 两个大蓝音符
```

---

### 5. 普通连打 (Drumroll)

**TJA代码**: `5`（开始）+ `8`（结束）

**操作方式**: 连续击打鼓面或鼓边

**得分特点**:
- 每击打一次得 100 分
- 不受连击加成影响
- Go-Go Time 时每击得 120 分

**图形表示**:
```
  ┌─────────────────┐
  │ ●●●●●●●●●●●●●●● │  黄色长条
  └─────────────────┘
```

**代码示例**:
```gdscript
# TJA谱面中的表示
5000000000000008  # 一个普通连打
```

---

### 6. 大连打 (Big Drumroll)

**TJA代码**: `6`（开始）+ `8`（结束）

**操作方式**: 连续击打鼓面或鼓边

**得分特点**:
- 每击打一次得 200 分
- 不受连击加成影响
- Go-Go Time 时每击得 240 分

**图形表示**:
```
  ┌───────────────────┐
  │  ●●●●●●●●●●●●●●●  │  大黄色长条
  └───────────────────┘
```

**代码示例**:
```gdscript
# TJA谱面中的表示
6000000000000008  # 一个大连打
```

---

### 7. 气球 (Balloon)

**TJA代码**: `7`（开始）+ `8`（结束）

**操作方式**: 快速连续击打鼓面

**得分特点**:
- 每击打一次得 300 分
- 完成全部击打额外得 5000 分
- 击打次数由 `BALLOON` 命令指定

**图形表示**:
```
  ┌─────────────────┐
  │    ◇◇◇◇◇◇◇◇    │  气球形状
  └─────────────────┘
```

**代码示例**:
```gdscript
# TJA头部定义气球击打次数
BALLOON:5,7,10

# TJA谱面中的表示
7000000800000000  # 一个气球音符
```

---

### 8. 结束标记 (End)

**TJA代码**: `8`

**说明**: 用于标记连打或气球的结束位置

**代码示例**:
```gdscript
5000000000000008  # 连打以8结束
7000000800000000  # 气球以8结束
```

---

### 9. 久寿玉 (Kusudama)

**TJA代码**: `9`（开始）+ `8`（结束）

**操作方式**: 快速连续击打鼓面

**得分特点**:
- 与气球相同的得分机制
- 每击打一次得 300 分
- 完成全部击打额外得 5000 分

**图形表示**:
```
  ┌─────────────────┐
  │    ☆☆☆☆☆☆☆☆    │  星形图案
  └─────────────────┘
```

**代码示例**:
```gdscript
# TJA谱面中的表示
9000000800000000  # 一个久寿玉音符
```

---

### 10. 双人大红音符 (Don Double)

**TJA代码**: `A` 或 `a`

**说明**: 双人合作模式专用音符

**操作方式**: 双人模式下，一方击打鼓面

---

### 11. 双人大蓝音符 (Ka Double)

**TJA代码**: `B` 或 `b`

**说明**: 双人合作模式专用音符

**操作方式**: 双人模式下，一方击打鼓边

---

### 12. 炸弹音符 (Bomb)

**TJA代码**: `C` 或 `c`

**说明**: 特殊音符，击打会导致失败

---

### 13. ADLIB隐藏音符 (ADLIB)

**TJA代码**: `F` 或 `f`

**说明**: 
- 隐藏音符，不在谱面上显示
- 击打可获得额外分数
- 不击打不会扣分

---

### 14. 交换音符 (Swap)

**TJA代码**: `G` 或 `g`

**说明**: 双人模式下交换位置的音符

---

## 音符类型枚举定义

```gdscript
## 音符类型枚举
enum NoteType {
    NONE = 0,       ## 空白
    DON = 1,        ## 小红音符
    KA = 2,         ## 小蓝音符
    DON_BIG = 3,    ## 大红音符
    KA_BIG = 4,     ## 大蓝音符
    RENDA = 5,      ## 普通连打
    RENDA_BIG = 6,  ## 大连打
    BALLOON = 7,    ## 气球音符
    END = 8,        ## 连打/气球结束标记
    KUSUDAMA = 9,   ## 久寿玉
    DON_DOUBLE = 10, ## 双人合作大红音符 (A)
    KA_DOUBLE = 11, ## 双人合作大蓝音符 (B)
    BOMB = 12,      ## 炸弹音符 (C)
    ADLIB = 13,     ## AD-LIB隐藏音符 (F)
    SWAP = 14       ## 交换音符 (G)
}
```

## 音符属性判断方法

```gdscript
## 是否为可打击音符
func is_hittable() -> bool:
    return note_type in [
        NoteType.DON, NoteType.KA, NoteType.DON_BIG, NoteType.KA_BIG,
        NoteType.RENDA, NoteType.RENDA_BIG, NoteType.BALLOON, NoteType.KUSUDAMA,
        NoteType.DON_DOUBLE, NoteType.KA_DOUBLE, NoteType.ADLIB
    ]

## 是否为连打类型
func is_renda() -> bool:
    return note_type in [NoteType.RENDA, NoteType.RENDA_BIG, NoteType.BALLOON, NoteType.KUSUDAMA]

## 是否为大音符
func is_big() -> bool:
    return note_type in [NoteType.DON_BIG, NoteType.KA_BIG, NoteType.RENDA_BIG, NoteType.DON_DOUBLE, NoteType.KA_DOUBLE]
```

## 音符与输入匹配

```gdscript
## 是否需要红音符输入
func needs_don_input() -> bool:
    return note_type in [
        NoteType.DON,
        NoteType.DON_BIG,
        NoteType.RENDA,
        NoteType.RENDA_BIG,
        NoteType.DON_DOUBLE
    ]

## 是否需要蓝音符输入
func needs_ka_input() -> bool:
    return note_type in [
        NoteType.KA,
        NoteType.KA_BIG,
        NoteType.KA_DOUBLE
    ]
```

## 相关文件

- 音符数据结构: `src/parser/tja_data.gd`
- 音符类实现: `src/game/note.gd`
- 音符管理器: `src/game/note_manager.gd`