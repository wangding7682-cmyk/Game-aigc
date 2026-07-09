# Step 3~5 反馈与贴花运行时规范

## 目标

把第一阶段 MVP 中已经存在的反馈素材真正接入运行态，并补齐 `DecalRoot` 的最小贴花资产与挂载规则。

本规范只覆盖：

- `FxRoot`：枪口火焰、命中 / 误伤 / 扫描反馈
- `DecalRoot`：弹孔、挡弹贴花
- `UiRoot/HudLayer`：命中 / 误伤 / 扫描序列帧显示

## 资产清单

### 直接使用现有素材

- `res://assets_mvp_placeholder/feedback/fx-muzzle-flash.svg`
- `res://assets_mvp_placeholder/feedback/fx-hit-confirm.svg`
- `res://assets_mvp_placeholder/feedback/fx-wrong-hit-alert.svg`
- `res://assets_mvp_placeholder/feedback/fx-cover-impact.svg`
- `res://assets_mvp_placeholder/feedback/fx-scan-pulse.svg`
- `res://assets_mvp_placeholder/feedback/hit-confirm-frame-01.svg` ~ `05.svg`
- `res://assets_mvp_placeholder/feedback/wrong-hit-alert-frame-01.svg` ~ `05.svg`
- `res://assets_mvp_placeholder/feedback/scan-pulse-frame-01.svg` ~ `05.svg`

### 本轮新增最小贴花素材

- `res://assets_mvp_placeholder/decals/decal-bullet-hole-placeholder.svg`
- `res://assets_mvp_placeholder/decals/decal-cover-impact-mark-placeholder.svg`

## 命名规则

- 反馈素材继续沿用现有 `kebab-case`
- 贴花素材统一前缀：`decal-`
- 运行时节点继续遵守现有规范：
  - `FxRoot`
  - `DecalRoot`
  - `DecalBulletHole`
  - `DecalCoverImpact`

## 注入规则

### 1. 枪口火焰

- 只挂在武器 3D 视模型的 `MuzzlePoint`
- 运行时表现为短时世界空间 quad，不落到 UI 层
- 只在开火瞬间显示，不持续常亮

### 2. 命中 / 误伤 / 扫描序列帧

- 命中与误伤：优先叠加在准镜 / HUD 反馈层
- 扫描：既允许 HUD 层序列反馈，也允许世界空间 pulse 补充
- 同一反馈只允许一个主序列，不重复叠加多个同类动画

### 3. DecalRoot 贴花

- 所有弹孔 / 挡弹贴花统一挂到 `DecalRoot` 或障碍物局部 damage root
- 贴花不参与碰撞
- 贴花只贴在命中表面前方极小偏移量，避免 Z-fighting
- 贴花寿命可以长于粒子 / 闪光反馈，但必须轻量

## 最小验收口径

### Step 3

- 开火时能看到世界空间枪口火焰
- 玩家在 0.5 秒内能区分命中 / 误伤 / 挡弹
- 命中与误伤序列帧已进入运行态

### Step 5

- 扫描触发后至少出现一次扫描序列帧反馈
- 扫描反馈不会与命中 / 误伤序列冲突

### Decal

- 挡弹后能看到贴花
- 贴花挂点稳定，不漂浮、不反向、不参与碰撞

## 当前限制

- 仍然以 MVP 最小可用为目标，不扩展正式高精贴图库
- 不在本阶段引入复杂 shader 轮廓系统
- 不把贴花系统扩成第二阶段的大规模正式资源生产方案
