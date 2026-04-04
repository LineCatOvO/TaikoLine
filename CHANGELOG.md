# Changelog

## [Unreleased]

### Added
- 测试谱面文件 (task-P1-add-test-charts)
  - tutorial.tja - 教程谱面，包含 Easy(1), Normal(3), Hard(5), Oni(7) 四个难度
  - rhythm_training.tja - 节奏训练谱面，包含 Easy(2), Normal(4), Hard(6), Oni(8) 四个难度
  - special_notes.tja - 特殊音符练习谱面，包含 Easy(2), Normal(4), Hard(6), Oni(8) 四个难度
  - speed_variation.tja - 速度变化练习谱面，包含 Easy(2), Normal(4), Hard(6), Oni(8) 四个难度
  - full_demo.tja - 完整演示谱面，包含 Easy(1), Normal(4), Hard(6), Oni(8), Edit(10) 五个难度
- 谱面验证脚本 (scripts/verify_charts.gd) - 用于验证谱面解析正确性
- 性能监控组件 (performance_monitor.gd) - FPS、内存、渲染性能监控
- FPS 显示组件 (fps_display.gd) - 实时 FPS 显示
- 性能面板组件 (performance_panel.gd) - 完整性能信息面板
- 音符可见性剔除功能 - 减少渲染开销
- 音符分批更新功能 - 优化每帧更新性能
- 音效播放优先级机制 - 关键音效优先播放
- 音效播放器池预创建 - 减少首次播放延迟
- 音频性能统计功能 - 播放计数、跳过计数统计

### Changed
- 优化音符管理器性能 - 可见性剔除、分批更新、性能统计
- 优化音频管理器性能 - 播放器池预创建、优先级播放、性能统计

## [0.1.0] - 2026-04-03

### Added
- 基础游戏框架
- 音符系统
- 音频系统
- 滚动系统
- 判定系统