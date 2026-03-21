# Task-P2-002: 添加皮肤资源系统

**创建时间**：2026-03-15
**优先级**：P2
**状态**：✅已完成

## 任务描述
为TaikoLine项目实现皮肤系统，允许用户自定义游戏外观。

## 已完成内容
- [x] 设计皮肤资源格式（JSON格式）
- [x] 创建resources/skins/default/skin.json默认皮肤配置
- [x] 创建src/ui/skin_manager.gd皮肤管理器
- [x] 更新src/autoload/settings.gd添加皮肤设置
- [x] 注册SkinManager为Autoload单例
- [x] 修改note.gd使用SkinManager获取音符外观
- [x] 修改gameplay.gd使用SkinManager获取UI颜色
- [x] 添加皮肤切换信号监听

## 皮肤格式说明
```json
{
  "name": "皮肤名称",
  "notes": {
    "don": {"color": "#FF3333", "size": 40},
    "ka": {"color": "#3366FF", "size": 40}
  },
  "judge_line": {"color": "#FFD700", "height": 4},
  "background": {"color": "#1a1a2e"}
}
```

## 验收标准
- [x] 皮肤格式定义完成
- [x] 皮肤加载系统实现
- [x] 默认皮肤可用
- [x] 音符类已修改为使用皮肤资源
- [x] 皮肤切换功能正常（信号监听已实现）

## 后续改进（可选）
- [ ] 添加皮肤切换UI界面
- [ ] 支持自定义皮肤导入
- [ ] 皮肤预览功能