# 测试回归矩阵（从测试中心脚本自动提取）

这份文件的目标是：把“应该跑哪些烟雾测试”变成一份可复用映射，而不是靠记忆。

## 测试中心烟雾测试清单

| 测试名 | Runner 脚本（推断） | 输出结果文件 |
|---|---|---|
| 主流程烟雾 | `狙击外星人升级版\scripts\tests\flow_smoke_runner.gd` | `user://flow_smoke_result.txt` |
| 下一关烟雾 | `狙击外星人升级版\scripts\tests\next_level_smoke_runner.gd` | `user://next_level_smoke_result.txt` |
| 完整集成烟雾 | `狙击外星人升级版\scripts\tests\integration_smoke_runner.gd` | `user://integration_smoke_result.txt` |
| 路由守卫烟雾 | `狙击外星人升级版\scripts\tests\route_guard_smoke_runner.gd` | `user://route_guard_smoke_result.txt` |
| 3D 占位烟雾 | `狙击外星人升级版\scripts\tests\placeholder_3d_smoke_runner.gd` | `user://placeholder_3d_smoke_result.txt` |

## 改动到测试的建议映射（基线）

这部分是“经验化映射”，用于快速选最小回归集合。你可以后续按项目实际再补充。

| 改动点 | 优先回归的烟雾测试 | 说明 |
|---|---|---|
| 路由/入口（主菜单、返回逻辑、路由守卫） | `路由守卫烟雾`、`主流程烟雾` | 入口断了会导致所有验证失效 |
| PVE 主链（`pve_battle_controller_3d.gd` / `battle_core_3d.gd`） | `3D 占位烟雾`、`完整集成烟雾` | 判定/反馈/结算容易被连带影响 |
| HUD 与瞄准（`ui_hud_pve.gd` / `ui_scope_overlay.gd`） | `主流程烟雾`、`完整集成烟雾` | UI 断了会表现为“能跑但不可玩” |
| 资源显示轨道（`weapon_renderer_3d.gd` 的 track） | `3D 占位烟雾`、`完整集成烟雾` | 重点验证 `attempted_scene_track` vs `scene_track` |
| 贴花/挡弹/命中反馈（`visual_feedback_3d.gd` + DecalRoot） | `3D 占位烟雾`、`完整集成烟雾` | 重点看挡弹后贴花/冲击反馈是否生成 |

## 最小回归动作（贴近业务）

1. 每次改动后，至少跑 `3D 占位烟雾` 与 `完整集成烟雾`。
2. 如果本轮改动涉及入口/返回/路由，再补跑 `路由守卫烟雾` 与 `主流程烟雾`。
3. 如果本轮改动涉及资源轨道或武器显示，对照检查：逻辑轨道与屏幕显示轨道一致。
