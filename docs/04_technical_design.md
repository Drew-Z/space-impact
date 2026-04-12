# 技术设计

## 引擎与当前实现

- 引擎版本：Godot 4.6.1
- 当前状态：已完成主菜单、战斗、暂停、结算、分数持久化与五关 + 最终 Boss 的街机闭环
- 当前目标：在不破坏已完成闭环的前提下，继续做小步扩展与稳定性优化

## 目录约定

- `docs/`：项目文档
- `scenes/`：Godot 场景
- `scenes/entities/`：玩家、敌人、Boss、拾取物
- `scenes/game/`：主关卡、战斗流程、反馈节点
- `scenes/ui/`：HUD、菜单、暂停、结算
- `scripts/`：GDScript 脚本
- `scripts/entities/`：实体逻辑
- `scripts/game/`：关卡、波次、游戏状态
- `scripts/ui/`：UI 控制
- `scripts/autoload/`：全局状态、分数、配置
- `assets/`：美术、音频、字体
- `tests/`：测试脚本或 smoke test

## 当前场景结构

- `scenes/ui/main_menu.tscn`：主菜单入口、最高分摘要、最近一局摘要
- `scenes/game/game_root.tscn`：五关与最终 Boss 战斗主场景
- `scenes/entities/player_ship.tscn`：玩家飞船
- `scenes/entities/enemy_ship.tscn`：多类型普通敌人
- `scenes/entities/boss_stage_1.tscn`：复用单场景、多 profile 的 Boss 实体
- `scenes/entities/bullet.tscn`：敌我通用弹体
- `scenes/entities/powerup_pickup.tscn`：局内拾取
- `scenes/ui/result_screen.tscn`：通关 / 失败结算页

## 脚本职责

- 玩家控制：`scripts/entities/player_ship.gd`
  负责移动、受伤、护盾、武器升级、掉级与发射请求
- 敌人逻辑：`scripts/entities/enemy_ship.gd`
  负责移动模式、攻击模式、受击与销毁
- Boss 逻辑：`scripts/entities/boss_stage_1.gd`
  通过 profile 区分 `striker / carrier / fortress / reaper / bastion / overlord`
- 子弹逻辑：`scripts/entities/bullet.gd`
  负责敌我子弹移动、碰撞、消费与差异化绘制
- 关卡流程：`scripts/game/game_root.gd`
  负责五关时间表、最终 Boss、支援敌机生成、暂停与结算跳转
- UI 逻辑：`scripts/ui/*.gd`
  负责菜单、HUD、暂停、结算与焦点流转
- 全局状态：`scripts/autoload/game_session.gd`
  负责配色常量、边界、输入、记录和本局结果
- 配置目录：`scripts/game/stage_catalog.gd`
  集中维护敌人基础参数、Boss 支援覆盖规则与 Boss 文案映射，减少 `game_root.gd` 中的配置堆积
- 节奏目录：`scripts/game/stage_schedule.gd`
  集中维护五个 Sector 与最终阶段的时间表数据，避免战斗主流程继续膨胀
- 平衡目录：`scripts/game/run_balance.gd`
  集中维护掉落节奏、Boss 警报次数与运行时拾取生成边界等规则

## 配置策略

- `run/main_scene` 指向 `scenes/ui/main_menu.tscn`
- 使用 `GameSession` autoload 统一：
  - 视口与活动边界常量
  - 单色风格调色板
  - 高分、总局数、最近一局结果
  - 武器标签与 HUD 展示文案
- 保持输入映射最小集合：
  - `move_up`
  - `move_down`
  - `move_left`
  - `move_right`
  - `fire`
  - `pause`
  - `confirm`
  - `back`

## 数据策略

- 当前继续采用脚本内轻量配置，而不是过早拆成资源表
- `game_root.gd` 维护五个 Sector 与最终 Boss 的：
  - `schedule`
  - `boss config`
  - 节奏 helper，如 `burst` 与 `staggered_bursts`
- `enemy_config()` 用统一入口管理敌机基础参数
- 当前已将敌人基础参数与 Boss 支援覆盖规则下沉到 `stage_catalog.gd`，后续新增敌机或微调参数时优先改配置目录，而不是继续把参数塞回主流程
- 当前已将关卡时间表拆到 `stage_schedule.gd`，将掉落与警报规则拆到 `run_balance.gd`
- Boss 使用单脚本 + 多 profile，而不是四套平行脚本，避免重复维护

## 战斗技术策略

- 主武器采用 13 级成长：
  - 1-4 级为基础扩散成长
  - 5-8 级为同模式加粗强化
  - 9-13 级切换为从机身前沿贯穿到屏幕右侧的直线主炮并持续加粗
- 掉落系统采用“击毁数保底 + 随机补偿 + 固定关卡节点”的混合方案
- 玩家受伤时：
  - 优先消耗护盾
  - 无护盾时优先损失 1 级武器
  - 只有武器回到基础等级后才开始损失船体
- Boss 战期间会按 profile 配置生成小型支援敌机，用于维持战场节奏和掉落机会
- 暂停通过 `PROCESS_MODE_PAUSABLE` 控制战斗对象冻结，HUD 和主流程维持必要的响应

## 运行时安全约束

- 物理回调内不直接做高风险状态切换
- 新生成拾取物的碰撞形状采用 deferred 安装，避免在碰撞刷新期间改动物理状态
- 玩家死亡后的 `defeated` 信号改为 deferred 发出，避免在物理回调内直接切场景
- 继续保留轻量 `feedback_burst` 反馈，不引入复杂粒子系统，保证可读性与稳定性

## 音画与反馈策略

- 敌我弹体通过尺寸、亮度、核心形状与拖尾差异进行区分
- Boss、受击、拾取、护盾破裂使用不同的 HUD 提示与 burst 模式
- 整体坚持 Nokia Space Impact 风格方向：
  - 简洁
  - 直接
  - 单色 / 低分彩屏气质
  - 短局高压

## 风险与约束

- 最大风险仍然是“可玩但不像初代 Space Impact”
- 第二风险是继续扩关卡后节奏冗长，削弱短局街机感
- 因此技术设计继续坚持：
  - 先复用现有结构
  - 先验证再扩展
  - 不引入复杂成长系统
