# Step 1 项目骨架与规范

## 当前目标

本次脚手架只解决三件事：

1. 项目可直接启动到主菜单
2. 主菜单、PVE 战斗、结算三段主流程可以切换
3. 后续系统开发遵守同一套目录、命名、Autoload 职责边界

## 已落地目录

```text
res://
  scenes/
    core/
    menu/
    pve/
    pvp/
    ui/
    tutorial/
  scripts/
    core/
    menu/
    pve/
    pvp/
    ui/
    platform/
    analytics/
  configs/
    pve/
    reward/
    tutorial/
    rank/
  audio/
    sfx/
    ui/
    amb/
  art_temp/
    materials/
    decals/
  docs/
```

## 命名约束

- 目录：`lower_snake_case`
- 场景：`模块_功能_名称.tscn`
- 脚本：`模块_职责.gd`
- 节点：`PascalCase`
- 配置：`cfg_模块_名称`

## 已建立的入口与骨架

### 主场景

- `res://scenes/core/core_game_root.tscn`
- 职责：作为项目运行入口，承载场景切换和统一 UI 层

### 三个最小流程场景

- `res://scenes/menu/menu_main_menu.tscn`
- `res://scenes/pve/pve_battle_main.tscn`
- `res://scenes/ui/ui_panel_result.tscn`

### Autoload 约束

- `CoreEventBus`：只发事件，不存业务状态
- `CoreGameState`：只维护全局流程状态与结算数据
- `CoreInputRegistry`：只负责输入映射注册
- `CoreSaveService`：只负责存档读写接口
- `PlatformService`：只负责平台能力代理，不直接写业务逻辑

## Step 1 已配置输入映射

- `ui_confirm`
- `ui_back`
- `camera_drag`
- `camera_zoom_in`
- `camera_zoom_out`
- `shoot_hold`
- `shoot_fire`
- `item_scan`
- `item_time_extend`
- `debug_complete`
- `debug_fail`

说明：

- 首次运行时由 `CoreInputRegistry` 自动补齐并保存到项目设置
- 这样可以先保证脚手架可运行，再在编辑器里继续细调按键

## 当前测试路径

### 场景切换验证

1. 启动项目，进入主菜单
2. 点击 `进入 PVE 战斗`
3. 在战斗场景点击 `模拟通关` 或 `模拟失败`
4. 进入结算场景
5. 点击 `再来一局` 或 `返回主菜单`

### 快捷键验证

1. 主菜单按 `Enter` 或 `Space`
2. 战斗场景按 `C` 模拟通关
3. 战斗场景按 `V` 模拟失败
4. 战斗场景按 `Esc` 返回主菜单
5. 结算场景按 `Enter` 重开，按 `Esc` 返回菜单

### 贴近业务的烟雾测试

按下面流程连续执行 10 次：

`主菜单 -> 进入战斗 -> 通关/失败 -> 返回主菜单 -> 再进入`

观察点：

- 不出现黑屏
- 不出现节点找不到
- 不出现场景引用丢失
- 金币累计数字正常变化
- 结算信息与本局结果一致

## 下一步建议

下一步直接进入 Step 2，继续把“主菜单 -> 进入关卡 -> 结算 -> 下一关/返回主页”的完整闭环细化成可配置流程，不要先扩战斗细节。
