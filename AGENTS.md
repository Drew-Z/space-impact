# AGENTS.md

请始终使用简体中文与用户沟通。
代码、命令、路径、报错信息可保留原文；解释、说明、总结必须使用中文。
除非用户明确要求，否则不要切换为英文回复。

## Project Context

- 这是一个使用 Godot 4.6.1 开发的项目。
- 项目目标是复刻 / 重制 Nokia 3310 上的《Space Impact》初代体验。
- 核心参考方向：
  - 横向自动卷轴射击
  - 短局街机节奏
  - 简洁敌人波次
  - 强化拾取
  - 关卡 Boss
  - 单色 / 低分彩屏风格气质
- 允许少量现代化可用性优化，但不要把项目做成完全不同的现代原创射击游戏。
- 开发必须遵循“先文档、后实现；先最小可玩、后扩展；每阶段先验证、再继续”的流程。

## Directory Convention

项目目录建议优先保持清晰分层：

- `docs/`
  - 项目文档、拆解文档、技术设计、测试计划、里程碑
- `scenes/`
  - Godot 场景
- `scenes/entities/`
  - 玩家、敌人、子弹、Boss、拾取物
- `scenes/game/`
  - 主关卡、战斗流程、关卡控制
- `scenes/ui/`
  - HUD、菜单、暂停、结算、设置
- `scripts/`
  - GDScript 脚本
- `scripts/entities/`
  - 实体逻辑
- `scripts/game/`
  - 游戏流程、关卡、生成器、状态管理
- `scripts/ui/`
  - UI 控制逻辑
- `scripts/autoload/`
  - 全局状态、配置、存档、分数等
- `assets/`
  - 图片、音效、字体、占位资源
- `assets/sprites/`
- `assets/audio/`
- `assets/fonts/`
- `tests/`
  - 如果后续需要测试脚本或 smoke test，可放这里

如果现有结构已经存在，优先沿用；不要轻易平行新开一套目录。

## Development Process

必须按阶段推进，不要跳步：

1. 阶段 0：预制作与文档
2. 阶段 1：最小可玩原型
3. 阶段 2：战斗与关卡扩展
4. 阶段 3：菜单、HUD、结算与外层流程
5. 阶段 4：打磨、平衡、音画、发布准备

每个阶段都要：

- 先检查上一阶段文档
- 明确本阶段目标
- 只做本阶段最小必要工作
- 完成后先验证
- 汇报结果，再进入下一阶段

除非用户明确要求，否则不要自动跨阶段扩展。

## Documentation Rules

开始编码前，优先准备并维护这些文档：

- `docs/00_project_brief.md`
- `docs/01_reference_breakdown.md`
- `docs/02_core_game_loop.md`
- `docs/03_gameplay_spec.md`
- `docs/04_technical_design.md`
- `docs/05_art_audio_style.md`
- `docs/06_production_plan.md`
- `docs/07_test_plan.md`

后期补充：

- `docs/08_playtest_report.md`
- `docs/09_release_checklist.md`
- `docs/10_postmortem.md`

文档更新要求：

- 设计改动时同步更新文档
- 如果实现偏离原计划，必须记录原因
- 要明确区分：
  - 忠实复刻内容
  - 工程现实下的简化
  - 为可玩性做的现代化微调

## Godot Workflow

- 先检查 `project.godot`、主场景、autoload、输入映射，再动手修改。
- 新场景和新脚本优先按职责归档，不要把所有逻辑塞进一个文件。
- 修改 `.tscn` 节点结构时，要同步检查：
  - 节点路径
  - 脚本绑定
  - 导出变量
  - 信号连接
- 如果要新增输入操作，先检查 `project.godot` 当前输入映射，再做最小必要补充。
- 如果只是小改玩法，不要随意大改主场景结构。
- 优先保证可玩闭环，不要过早沉迷特效和资源替换。

## Gameplay Design Constraints

项目设计必须围绕原版核心体验：

- 重点是“简洁、直接、短局、街机感”
- 重点是“横向卷轴射击”
- 重点是“波次 + Boss + 简单强化”
- 不要过早加入这些内容，除非用户明确要求：
  - 复杂技能树
  - Roguelike 大量 build
  - 复杂剧情系统
  - 大地图探索
  - 重度弹幕化
  - 联机
  - 商业化外层系统

如果新增系统可能偏离原作气质，先说明，再实现。

## Coding Workflow

- 优先做最小必要改动，避免无关重构。
- 不要擅自删除用户已有脚本、场景、资源或配置。
- 保持这些逻辑分离：
  - 玩家控制
  - 敌人行为
  - 子弹 / 碰撞
  - 波次 / 关卡流程
  - HUD / 菜单 / 结算
  - 全局状态 / 存档 / 分数
- 如果发现职责混乱，优先小步整理，不要一次性大重构。

## Verification Rules

每次修改完成后，尽量做可运行验证，而不是只看代码。

优先验证：

- 主菜单是否能进入游戏
- 游戏是否能正常开始
- 玩家是否能移动和射击
- 敌人是否正常生成
- 碰撞与受伤是否正常
- 强化是否可拾取
- Boss 是否可进入
- 玩家死亡 / 通关后结算是否正常
- 返回主菜单 / 重开是否正常

如果当前环境无法运行 Godot：

- 明确说明原因
- 给出可执行的本地验证步骤
- 不要假装已经验证通过

## project.godot / Autoload Safety

- 不要随意重写 `project.godot`
- 不要随意更换 `run/main_scene`
- 新增 autoload 时必须说明用途
- 新增输入映射时必须说明用途
- 修改窗口分辨率、拉伸模式、渲染设置前，先确认是否确有必要

## Shell Preference

- 默认优先使用 Git Bash。
- 如果 Git Bash 不方便，再使用 cmd。
- 除非明确必要，否则不要使用 PowerShell。
- 执行命令优先采用：
  - `bash -lc "<command>"`
  - `cmd /c <command>`

## Git Workflow

- 不要使用破坏性 Git 命令，例如：
  - `git reset --hard`
  - `git checkout -- <file>`
  - `git clean -fd`
- 除非用户明确要求，否则不要改写历史，不要强推。
- 提交前先确认改动范围。
- 提交信息尽量简洁清晰，说明改动目的。

## Output Preference

- 回复尽量简洁、直接、可执行。
- 先说结论，再补必要说明。
- 每阶段完成后优先汇报：
  - 已完成什么
  - 当前版本能怎么玩
  - 离目标还差什么
  - 做了哪些验证
  - 下一步建议做什么

## Safety

- 不要执行用户未明确同意的高风险操作。
- 涉及删除、覆盖、移动大量文件时，先确认目标路径和影响范围。
- 涉及 `project.godot`、autoload、输入映射、主场景、导出配置调整时，先说明将要做什么。
