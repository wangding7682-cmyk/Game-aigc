# 菜单 UI 安全基类使用规范

## 目标

避免菜单页、设置页、商店页这类 `Control` 界面反复出现“按钮点击不响应”。

## 基类

统一使用：

`res://scripts/ui/ui_safe_page.gd`

## 用法

新页面脚本统一写法：

```gdscript
extends "res://scripts/ui/ui_safe_page.gd"

func _ready() -> void:
    _prepare_safe_ui_root()
    _build_ui()
    _finalize_safe_ui_tree()
    _refresh_ui()
```

## 规则

基类会在 `_finalize_safe_ui_tree()` 中统一收口 `mouse_filter`：

- 根页面：`PASS`
- 容器节点：`PASS`
  - `MarginContainer`
  - `VBoxContainer`
  - `HBoxContainer`
  - `GridContainer`
  - `PanelContainer`
  - `ScrollContainer`
- 纯展示叶子：`IGNORE`
  - `ColorRect`
  - `Label`
  - `RichTextLabel`
  - `TextureRect`
  - `NinePatchRect`
- 按钮：保留交互，不被基类覆盖

## 禁止事项

- 禁止把承载按钮的父容器手动设为 `IGNORE`
- 禁止为了“防透明层挡点击”把整棵容器树都改成 `IGNORE`
- 禁止新菜单页绕开 `UISafePage` 直接手写一套 `mouse_filter`

## 已迁移页面

- 主菜单 `menu_main_menu.gd`
- 设置页 `ui_panel_settings.gd`
- 测试中心 `ui_panel_test_center.gd`
- 结算页 `ui_panel_result.gd`
- 升级页 `ui_panel_upgrade.gd`
- 商店 `ui_panel_shop.gd`
- 武器库 `ui_panel_weapon_library.gd`
- 调参页 `ui_panel_tuning.gd`
