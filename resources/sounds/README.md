# 音效资源说明

## 音效文件列表

| 文件名 | 描述 | 用途 |
|--------|------|------|
| don.ogg | 红音符打击音 | 玩家击打Don音符时播放 |
| ka.ogg | 蓝音符打击音 | 玩家击打Ka音符时播放 |
| balloon.ogg | 气球打击音 | 击打气球音符时播放 |
| judge_perfect.ogg | 良判定音 | 获得Perfect判定时播放 |
| judge_good.ogg | 可判定音 | 获得Good判定时播放 |
| judge_miss.ogg | 不可判定音 | 获得Miss判定时播放 |
| combo_bonus.ogg | 连击加成音 | 达到特定连击数时播放 |

## 音效格式要求

- **格式**: OGG Vorbis
- **采样率**: 44100Hz
- **声道**: 单声道或立体声
- **时长**: 建议0.1-0.3秒

## 生成音效

### 方法1：使用内置工具生成

1. 在Godot编辑器中打开项目
2. 打开 `tools/generate_sounds.gd` 文件
3. 按 `Ctrl+Shift+X` 或点击 `File -> Run` 运行脚本
4. 脚本会在 `resources/sounds/` 目录生成WAV文件
5. 在FileSystem面板中右键点击WAV文件 -> Import
6. 选择OGG格式并重新导入
7. 删除WAV文件（可选）

### 方法2：使用外部音效

1. 从免费音效库下载音效（如 Freesound.org）
2. 使用音频编辑软件（如 Audacity）编辑
3. 导出为OGG格式，44100Hz
4. 将文件放入 `resources/sounds/` 目录

### 方法3：自制音效

1. 使用数字音频工作站（DAW）制作
2. 或使用合成器生成
3. 导出为OGG格式

## 音效来源建议

### 免费音效库
- [Freesound.org](https://freesound.org) - 需注册，CC协议
- [Zapsplat](https://www.zapsplat.com) - 需注册，部分免费
- [Mixkit](https://mixkit.co/free-sound-effects/) - 无需注册

### 注意事项
- 确认音效的版权许可
- 商业使用需注意授权范围
- 建议使用CC0或自有音效