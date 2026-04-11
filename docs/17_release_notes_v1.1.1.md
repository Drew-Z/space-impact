# Release Notes v1.1.1

## 版本定位

`v1.1.1` 是在 `v1.1.0` 基础上继续完成结构收口、Boss 扩展、武器成长重做、菜单交互修复与音频打磨后的正式发布版本。

这一版的重点不是再横向扩系统，而是把项目从“完整可玩”进一步推进到“更接近成品展示状态”。当前版本已经形成从主菜单到五个常规关卡、再到最终 Boss 战的完整短局街机闭环。

## 相比 v1.1.0 的关键提升

- 关卡结构扩展为 5 个常规 Sector 加 1 个最终 Boss 阶段
- Boss 阵容扩展并拉开差异，整体战斗时长和压迫感明显提高
- 武器成长重做为 13 级曲线，高阶形态支持持续直线主炮
- 玩家改为单命 `HULL 3`，并加入“先掉武器等级、后掉船体”的受伤规则
- Boss 战新增更规整的支援小怪波次，兼顾压力和补给机会
- 主菜单补齐 `开始游戏 / 阶段继续 / 设置 / 退出` 完整结构
- 修复设置界面键盘导航穿透主菜单的问题，并补齐中英文切换
- 每关加入差异化背景风格，整体画面更有阶段感
- 背景音乐区分主菜单与战斗场景，射击、Boss 警报、激光主炮等音效完成一轮重做与柔化
- Windows 导出版再次完成实际运行验证

## 本版亮点

- 完整的主菜单 -> 战斗 -> 结算 -> 返回菜单闭环
- 5 个常规关卡与 1 个最终 Boss 阶段
- 多类基础敌人、差异化 Boss 与更明确的阶段压迫
- 13 级武器成长与高阶持续主炮
- 伤害会先打掉武器等级，再进入船体损伤
- 中英文界面切换
- 更完整的 HUD、Boss 警报、结算与通关收尾提示
- 主菜单和战斗场景使用不同背景音乐
- Windows 独立构建已手动导出并验证通过

## 推荐 GitHub Release 标题

`Space War v1.1.1 - Full Arcade Loop Polish`

## 推荐 GitHub Release 简介

Space War v1.1.1 is a substantial polish release that pushes the project closer to a complete showcase-ready remake of the original Nokia 3310 Space Impact.

This update expands the game into a five-sector run with a dedicated final boss phase, reworks the weapon progression into a 13-level curve with a persistent beam weapon at higher tiers, improves boss variety and battle duration, and refines the menu, language, and audio experience for standalone Windows play.

## 建议附上的要点列表

- Expanded campaign flow with five sectors plus a final boss phase
- Reworked 13-level weapon progression with persistent beam fire at higher tiers
- Tougher and more distinct bosses with clearer phase pressure
- Single-life HULL system with weapon-level loss on damage
- Improved stage resume flow, settings navigation, and language switching
- Softer and more distinct music and combat audio mix
- Verified Windows standalone export
- Apache-2.0 licensed repository

## 建议上传到 Release 的素材

- `build/windows/v1.1.1/SpaceWar.exe`
- `build/windows/v1.1.1/SpaceWar.pck`
- `docs/media/menu.png`
- `docs/media/gameplay.png`
- `docs/media/result.png`

## 配套文档

- `README.md`
- `docs/09_release_checklist.md`
- `docs/10_postmortem.md`
- `docs/14_distribution_guide.md`
- `docs/16_final_summary.md`
