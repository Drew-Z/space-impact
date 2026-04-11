# Media

该目录用于存放适合仓库首页、Release 页面和项目展示页使用的媒体资源。

建议保留这些文件名：

- `menu.png`
- `gameplay.png`
- `result.png`
- `gameplay.gif` 或 `gameplay.mp4`

如果自动截图成功，README 可以直接引用这里的 PNG。

当前仓库中的 `menu.png`、`gameplay.png`、`result.png` 已由测试脚本自动生成。

可复用的采集脚本：

- `tests/capture_screens.gd`

本地重新生成示例：

```bat
cmd /d /c "D:\Development\Godot\godot.cmd --path . --script res://tests/capture_screens.gd"
```

如果当前环境无法自动截图，建议在本地 Godot 编辑器中手动采集：

1. 启动主菜单并截取菜单界面
2. 进入 Sector 1 或 Sector 2 战斗中段截取 gameplay
3. 通关后截取结果页
4. 如需 GIF，录制 8-12 秒包含移动、射击、拾取和 Boss 警报的片段

建议输出分辨率保持 `960x540`，这样与项目当前视口一致。
