# 技术设计

## 引擎与范围

- 引擎版本：Godot 4.6.1
- 当前阶段：阶段 0，仅初始化项目与文档，不进入大规模玩法开发。

## 目录约定

- `docs/`：项目文档
- `scenes/`：Godot 场景
- `scenes/entities/`：玩家、敌人、Boss、拾取物
- `scenes/game/`：主关卡、战斗流程、关卡控制
- `scenes/ui/`：HUD、菜单、暂停、结算
- `scripts/`：GDScript 脚本
- `scripts/entities/`：实体逻辑
- `scripts/game/`：关卡、波次、游戏状态
- `scripts/ui/`：UI 控制
- `scripts/autoload/`：全局状态、分数、配置
- `assets/`：美术、音频、字体
- `tests/`：测试脚本或 smoke test

## 预期场景结构

阶段 1 开始后优先创建：

- `scenes/ui/main_menu.tscn`
- `scenes/game/game_root.tscn`
- `scenes/entities/player_ship.tscn`
- `scenes/entities/enemy_basic_*.tscn`
- `scenes/entities/boss_stage_1.tscn`
- `scenes/ui/result_screen.tscn`

## 预期脚本职责

- 玩家控制：输入、移动、射击、受伤。
- 敌人逻辑：移动轨迹、攻击、死亡。
- 子弹逻辑：移动、碰撞、伤害。
- 关卡流程：卷轴、波次、Boss 进入。
- UI 逻辑：菜单、HUD、结算。
- 全局状态：分数、生命、阶段结果。

## 配置策略

- 阶段 0 只建立最小 `project.godot`，避免过早固定主场景、autoload、输入映射。
- 阶段 1 开始前再补 `run/main_scene` 和输入映射。
- 只有在确有需要时才新增 autoload，并且必须记录用途。

当前阶段 1 实际采用：

- `run/main_scene` 指向 `scenes/ui/main_menu.tscn`
- 新增 `GameSession` autoload
- 用途：统一配置调色板、视口常量、运行时输入映射，以及在战斗与结算页之间传递本局结果

## 数据策略

- 阶段 1 允许先把敌人和关卡参数写在脚本或资源里。
- 阶段 2 再视复杂度决定是否抽到 `Resource` 配置或数据表。

当前阶段 1 的关卡波次先写在 `scripts/game/game_root.gd` 的固定时间表内，属于刻意的最小实现。

阶段 2 继续沿用这一思路，但扩展为：

- 多 Sector 数据仍暂存在 `scripts/game/game_root.gd`
- 每个 Sector 由 `schedule + boss config` 构成
- 等阶段 2 复杂度稳定后，再决定是否在后续阶段抽离为 `Resource`

阶段 3 补充：

- `GameSession` 负责加载与保存最高分、总局数。
- `HUD` 负责战斗 HUD、中心提示、底部提示、Boss 条与暂停面板。
- 战斗反馈使用轻量 `feedback_burst`，不引入复杂粒子系统。

## 风险与约束

- 最大风险是“像太空射击游戏，但不像原版 Space Impact”。
- 第二风险是阶段 1 范围失控，导致最小可玩版本迟迟不能闭环。
- 技术设计必须服务于“小步快跑、先闭环再扩展”。
