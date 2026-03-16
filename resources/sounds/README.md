# 音效资源说明

> **注意**：音效资源需要用户自行提供。以下为占位符说明，请将您的音效文件放入此目录。

## 所需音效文件

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

## 如何添加音效

1. 准备您的音效文件（OGG格式，44100Hz）
2. 按照上表中的文件名命名
3. 将文件放入 `resources/sounds/` 目录
4. 重新加载项目即可使用

## 音效来源建议

### 免费音效库
- [Freesound.org](https://freesound.org) - 需注册，CC协议
- [Zapsplat](https://www.zapsplat.com) - 需注册，部分免费
- [Mixkit](https://mixkit.co/free-sound-effects/) - 无需注册

### 自制音效
- 使用数字音频工作站（DAW）制作
- 使用合成器生成
- 使用 Audacity 等软件编辑

### 注意事项
- 确认音效的版权许可
- 商业使用需注意授权范围
- 建议使用CC0或自有音效