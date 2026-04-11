# Release Notes v1.0.1

## 版本定位

`v1.0.1` 是基于人工试玩反馈完成的正式发布推荐版本。

它不是一次系统扩张，而是在现有完整可玩版本基础上，针对首次人工试玩暴露出的关键问题做了一轮收口修正，使项目更适合公开展示、录制演示和作为稳定归档版本保留。

## 相比 v1.0.0 的关键提升

- 修正了主菜单和结算页的布局偏移问题
- 玩家活动范围扩展到更合理的全屏安全区，同时避开 HUD 顶栏和底栏
- 武器升级由更偏脚本预设的节奏调整为“击毁累计保底 + 随机补偿掉落”
- 敌我子弹区分进一步强化，战斗中的可读性更高
- 修正暂停时敌机、Boss、子弹和背景仍继续运动的问题
- 增强 Boss 预警表现、暂停菜单焦点稳定性和基础音效混音舒适度

## 本版亮点

- 完整主菜单 -> 战斗 -> 结算闭环
- 双 Sector 关卡结构
- 4 类基础敌人
- 3 类局内强化
- 2 个差异化 Boss
- 暂停流程、最高分记录、结算回路
- 单色 / 低彩 LCD 风格界面与战斗表现
- 程序化音效与极简复古氛围
- 从预制作到最终收口的完整文档链路

## 推荐 GitHub Release 标题

`Space War v1.0.1 - Final Playtest Polish`

## 推荐 GitHub Release 简介

Space War v1.0.1 is the recommended formal release build of this Godot 4.6.1 remake project inspired by the original Nokia 3310 Space Impact.

This update focuses on final playtest-driven polish rather than feature expansion: UI alignment fixes, wider but cleaner player movement bounds, improved upgrade drop pacing, clearer player/enemy bullet readability, a real gameplay pause state, stronger boss warning feedback, and more comfortable core audio mixing.

The result is a more stable and presentation-ready version while preserving the original project's short-session arcade feel and restrained retro style.

## 建议附上的要点列表

- Full arcade loop from menu to result screen
- Two-sector stage structure with two bosses
- In-run weapon, repair, and overdrive pickups
- Score persistence and restart / return flow
- Playtest-informed polish pass for readability and pacing
- Apache-2.0 licensed repository

## 建议上传到 Release 的素材

- `docs/media/menu.png`
- `docs/media/gameplay.png`
- `docs/media/result.png`

如果你后续录制了 GIF 或短视频，也建议一并挂到 Release 页面。

## 发布前最后确认

- 当前推荐用新标签 `v1.0.1`，不要直接复用现有 `v1.0.0`
- 原因是 `v1.0.0` 不包含后续的试玩修正、截图更新、许可证补充和最终收口优化
- 当前 `main` 分支最新提交已经是更适合作为正式展示版的状态
