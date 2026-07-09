# 资产接入合同表（自动生成草稿）

这份表的作用不是“替你决定挂点”，而是把接入必需字段显式化，避免后续靠猜。

## sniper-art-first-batch

- README：`sniper-art-first-batch/README.md`

建议补齐字段：`intended_scene`（挂载到哪个场景/节点层级）、`trigger`（具体触发条件）、`fallback`（缺资源时如何兜底）。

## sniper-art-second-batch

- README：`sniper-art-second-batch/README.md`
- README 中提到的脚本/场景（可能的接入点）：
  - `pve_battle_main.tscn`
  - `pve_cover_obstacle_3d.gd`
  - `scenes/pve/pve_battle_main.tscn`
  - `scenes/ui/ui_hud_pve.tscn`
  - `tutorial_flow_intro.tscn`
  - `ui_hud_pve.gd`
  - `ui_hud_pve.tscn`
  - `ui_scope_overlay.gd`
  - `visual_feedback.gd`
  - `狙击外星人升级版\scenes\pve\pve_battle_main.tscn`
  - `狙击外星人升级版\scenes\tutorial\tutorial_flow_intro.tscn`
  - `狙击外星人升级版\scenes\ui\ui_hud_pve.tscn`
  - `狙击外星人升级版\scripts\pve\pve_cover_obstacle_3d.gd`
  - `狙击外星人升级版\scripts\pve\visual_feedback.gd`
  - `狙击外星人升级版\scripts\ui\ui_hud_pve.gd`
  - `狙击外星人升级版\scripts\ui\ui_scope_overlay.gd`

建议补齐字段：`intended_scene`（挂载到哪个场景/节点层级）、`trigger`（具体触发条件）、`fallback`（缺资源时如何兜底）。

## sniper-art-third-batch

- README：`sniper-art-third-batch/README.md`
- README 中提到的脚本/场景（可能的接入点）：
  - `pve_battle_controller_3d.gd`
  - `pve_target_controller_3d.gd`
  - `target_behavior_weakpoint.gd`
  - `ui_panel_shop.gd`
  - `ui_panel_weapon_library.gd`

建议补齐字段：`intended_scene`（挂载到哪个场景/节点层级）、`trigger`（具体触发条件）、`fallback`（缺资源时如何兜底）。

## cartoon-alien-hunt-assets


建议补齐字段：`intended_scene`（挂载到哪个场景/节点层级）、`trigger`（具体触发条件）、`fallback`（缺资源时如何兜底）。

## sniper-game-asset-board


建议补齐字段：`intended_scene`（挂载到哪个场景/节点层级）、`trigger`（具体触发条件）、`fallback`（缺资源时如何兜底）。

## sniper-master-mobile-ui


建议补齐字段：`intended_scene`（挂载到哪个场景/节点层级）、`trigger`（具体触发条件）、`fallback`（缺资源时如何兜底）。

## 按类型快速抽查（建议）

- `hud/effect/anim`：优先确认是否已经进入 `HUD + 反馈` 的运行消费链路。
- `decal`：优先确认锚点、表面分类、生命周期与性能约束是否被执行。
- `ui-kit`：优先确认状态驱动切换（tab/owned/locked/equipped）。
