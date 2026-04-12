# Distribution Guide

## 目标

为当前版本准备可重复执行的导出与分发流程，避免每次发布都临时摸索。

## 当前建议发布版本

- 推荐标签：`v1.1.1`
- 当前分支：`main`
- 当前许可证：`Apache-2.0`

## 建议导出目标

- 平台：Windows Desktop
- 架构：x86_64
- 产物形式：`exe + pck` 或单文件嵌入包

## 建议输出目录

```text
build/
build/windows/
```

## 本地导出前检查

1. 用 Godot 4.6.1 打开项目，确认主菜单、战斗、结算流程可正常运行
2. 确认 `README.md`、`CHANGELOG.md`、`LICENSE`、`docs/17_release_notes_v1.1.1.md` 已是最新
3. 确认截图资源位于：
   - `docs/media/menu.png`
   - `docs/media/gameplay.png`
   - `docs/media/result.png`

## 当前环境结论

- 本项目已补好 `export_presets.cfg`
- 已尝试执行 headless Windows 导出
- 当前环境下导出阶段出现 Godot safe-save / 导出流程异常，未生成稳定的最终产物
- 因此当前最稳妥的方式仍然是在 Godot 编辑器中手动导出并做脱离编辑器验证

## 推荐导出步骤

### 在 Godot 编辑器中

1. 打开 `Project -> Export`
2. 新建 `Windows Desktop` 预设
3. 导出到 `build/windows/v1.1.1/SpaceWar.exe`
4. 勾选适合当前发布方式的 PCK 选项
5. 完成后脱离编辑器直接运行一次导出产物

### 建议验证点

- 双击 `SpaceWar.exe` 可以正常启动
- 主菜单能开始游戏
- 一局通关或失败后能进入结算
- 暂停和重新开始流程正常
- 音频、HUD、输入和窗口尺寸与编辑器内体验一致

## Release 页面建议附带内容

- `build/windows/v1.1.1/SpaceWar.exe`
- `build/windows/v1.1.1/SpaceWar.pck`
- `LICENSE`
- `README.md`
- `docs/17_release_notes_v1.1.1.md`
- 三张展示截图

## 若要继续做下一个版本

如果后续继续更新，不建议覆盖当前已发布附件，而应：

1. 新建标签
2. 重新导出独立版本
3. 新建对应 Release

这样能保留每个阶段的稳定归档版本。
