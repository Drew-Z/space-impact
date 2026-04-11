# Release Checklist

## 当前版本目标

- 版本定位：`v1.1.x` 展示 / 发布候选版
- 核心范围：五个常规 Sector + 最终 Boss `FINAL CORE`
- 体验目标：短局高压、贴近 Nokia 3310 初代《Space Impact》气质、可完整打通一局

## 核心流程

- [x] 主菜单可正常显示并进入游戏
- [x] 主菜单提供 `开始游戏 / 阶段继续 / 设置 / 退出`
- [x] 设置内支持中英文切换
- [x] 战斗场景可正常进入
- [x] 五关 + 最终 Boss 流程可完整运行
- [x] 暂停菜单可继续 / 重开 / 返回主菜单
- [x] 失败后可进入结果页
- [x] 通关后可进入结果页
- [x] 结果页可重新开始或返回主菜单

## 战斗与平衡

- [x] 玩家移动边界已与 HUD 留白对齐
- [x] 玩家生命模型为 `HULL 3` 单命结构
- [x] 受伤优先掉武器等级，基础武器后才开始掉 `HULL`
- [x] 13 级主武器成长已接入
- [x] 9 级以上主武器为按住开火的常驻贯穿射线
- [x] 普通敌人、Boss、强化、掉落循环均已接入
- [x] Boss 战会生成低血量支援小怪用于补给循环
- [x] Boss 支援小怪当前已改为更规整的插入波次
- [x] 所有关底 Boss 与最终 Boss 已做多轮耐久上调
- [x] 护盾出现频率已下调，当前更偏向火力 / 过载补偿

## UI 与反馈

- [x] HUD 可显示分数、船体、武器、阶段进度与 Boss 状态
- [x] Boss 来临前有独立的 `DANGEROUS` 预警
- [x] 普通 Boss 与最终 Boss 都有阶段变化提示
- [x] 受击、拾取、击破、Boss 击毁、最终通关反馈已接入
- [x] 最终 Boss 击破后有额外收尾提示，不会直接硬切结果页
- [x] HUD 状态文本已本地化，不再中英混杂

## 音画与表现

- [x] 整体视觉保持单色 / 低彩复古方向
- [x] 各关已有不同背景主题
- [x] 程序化音效已接入
- [x] 菜单 / 战斗 / 暂停 / 胜利 / 失败基础音乐氛围已接入
- [ ] 需人工主观确认音量、音色与最终 Boss 战听感

## 文档

- [x] `docs/00_project_brief.md`
- [x] `docs/01_reference_breakdown.md`
- [x] `docs/02_core_game_loop.md`
- [x] `docs/03_gameplay_spec.md`
- [x] `docs/04_technical_design.md`
- [x] `docs/05_art_audio_style.md`
- [x] `docs/06_production_plan.md`
- [x] `docs/07_test_plan.md`
- [x] `docs/08_playtest_report.md`
- [x] `docs/09_release_checklist.md`
- [x] `docs/10_postmortem.md`
- [x] `docs/12_final_playtest_runbook.md`
- [x] `docs/13_release_notes_v1.0.1.md`
- [x] `docs/14_distribution_guide.md`
- [x] `docs/15_release_notes_v1.1.0.md`
- [x] `docs/16_final_summary.md`

## 自动验证

- [x] `res://scenes/ui/main_menu.tscn` 无头加载通过
- [x] `res://scenes/game/game_root.tscn` 无头加载通过
- [x] `res://scenes/ui/result_screen.tscn` 无头加载通过
- [x] 最近一轮修改后未出现新的 GDScript 解析错误
- [ ] 需人工确认导出后的 Windows 构建完整打一局

## 人工发布前必查

- [ ] 从主菜单完整打一局，确认五关与最终 Boss 时长合理
- [ ] 验证 `阶段继续` 入口是否符合预期
- [ ] 验证语言切换后菜单、HUD、结果页文本都正确
- [ ] 验证暂停 / 重开 / 返回主菜单全流程
- [ ] 验证最高分持久化
- [ ] 验证导出版 `SpaceWar.exe` 可脱离编辑器运行
- [ ] 记录最终一轮人工试玩结论

## 当前已知非阻塞项

- Headless 环境下仍会看到 `Failed to read the root certificate store`
- Headless 退出时仍会看到 `ObjectDB instances leaked at exit`
- 上述两项目前未表现为实际玩法故障，但仍建议在编辑器和导出版中做最终人工确认
