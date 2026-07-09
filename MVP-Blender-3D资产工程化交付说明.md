# MVP Blender 3D 资产工程化交付说明

## 本次完成内容

本轮按第一阶段 MVP 范围，已经把原先偏程序化的 3D 占位层，补成了可直接进主项目的 Blender 产物，并完成了 Godot 工程接入。

目标覆盖范围：

1. 角色占位
2. 武器占位
3. 关卡基础街区占位
4. 掩体占位
5. 与现有 3D 战斗链路的直接工程化接入

---

## 已生成的 Blender 资产

生成目录：

- `狙击外星人升级版/assets_mvp_3d/`

### 角色

1. `characters/alien_base_placeholder.glb`
2. `characters/alien_costume_placeholder.glb`
3. `characters/civilian_base_placeholder.glb`
4. `characters/weakpoint_marker_placeholder.glb`

### 关卡与掩体

1. `level/street_block_mvp.glb`
2. `environment/wall_corner_cover.glb`
3. `environment/street_lamp_cover.glb`
4. `environment/parked_van_cover.glb`
5. `environment/billboard_cover.glb`

### 第一人称武器

1. `weapons/weapon_fps_rifle.glb`
2. `weapons/weapon_fps_precision.glb`
3. `weapons/weapon_fps_auto.glb`
4. `weapons/weapon_fps_plasma.glb`

合计：`13` 个 `.glb` 资产

---

## 已完成的主项目接入

### 1. 角色接入

已修改：

- `狙击外星人升级版/scripts/pve/pve_target_controller_3d.gd`

接入结果：

1. 目标角色优先加载 Blender 角色模型，而不是只用程序拼盒子
2. 外星人根据伪装强度切换基础版/服装版占位
3. 平民走独立角色占位
4. 角色仍保留原有状态逻辑：
   - 红眼
   - 肩线异常
   - 弱点显示
   - 扫描高亮
   - 假线索
5. 原有 billboard 状态图仍保留，保证 MVP 阶段远景可读性不丢

### 2. 掩体接入

已修改：

- `狙击外星人升级版/scripts/pve/pve_cover_obstacle_3d.gd`

接入结果：

1. 四类掩体优先加载 Blender 掩体模型
2. 保留原有碰撞、受击、坍塌、贴花逻辑
3. 现在 `wall_corner / street_lamp / parked_van / billboard` 都有真实 3D 资产落点

### 3. 关卡街区接入

已修改：

- `狙击外星人升级版/scripts/pve/pve_battle_controller_3d.gd`

接入结果：

1. `LevelRoot` 现在优先加载 Blender 导出的街区基础占位
2. 保留现有掩体生成与战斗流程，不重构玩法链路
3. 导入后的街道底板、窗带、地标节点已经摊平到 `LevelRoot` 下，方便测试和后续替换

### 4. 武器接入

已修改：

- `狙击外星人升级版/scripts/ui/weapon_renderer_3d.gd`

接入结果：

1. 第一人称武器现在优先加载 Blender 产物
2. 根据武器 profile 切换 `rifle / precision / auto / plasma`
3. 保留原有：
   - 枪口点
   - 抛壳点
   - 搜索态/瞄准态挂点
   - 开火闪光
   - recoil 反馈

### 5. 烟雾测试对齐

已修改：

- `狙击外星人升级版/scripts/tests/placeholder_3d_smoke_runner.gd`

调整原因：

原测试是按“SVG 挂图占位”写的；现在已经升级为“Blender 3D 资产 + 兼容旧图层”，所以测试口径同步放宽为：

1. 接受旧 SVG 占位
2. 也接受新的 `.glb` 3D 资产
3. 支持递归检查导入后的街区节点

---

## 本次验证结果

已运行：

- `res://scenes/tests/placeholder_3d_smoke_runner.tscn`

结果：

- `PLACEHOLDER_3D_SMOKE = PASS`

说明当前至少已经验证通过：

1. 主项目能加载新的 Blender 3D 资产
2. 战斗场景能正常进入
3. 角色占位正常生成
4. 掩体占位正常生成并支持受击坍塌
5. 第一人称武器挂载有效
6. 街区基础占位结构存在

---

## 当前工程化特点

这次不是另起一套新工程，而是直接贴着现有主项目做增量接入：

1. 不改已有核心玩法接口
2. 不推翻现有 2D/3D 验证层结构
3. 先把 Blender 产物塞进现有 MVP 战斗链路
4. 保留原有状态图层作为远景和识别兜底

这意味着你现在已经从“纯脚本占位”推进到了“Blender 资产可直接跑进战斗场景”的阶段。

---

## 下一步最值得继续做的三件事

### 1. 角色状态细化

建议继续补：

1. 外星人服装层切换规则
2. 弱点单独命中区
3. 平民假线索时序曲线

### 2. 掩体体量校准

建议继续补：

1. 四类掩体的真实遮挡高度
2. 可挂弹孔表面分类
3. 扫描状态下的掩体淡化策略差异

### 3. Step 1 到 Step 3 场景实测

建议按业务口径测：

1. 镜头放大后能不能更快识别外星人
2. 掩体是否真的形成可读遮挡
3. 武器视角是否挡中心视区
4. 误伤与正确命中反馈是否仍然清楚

---

## 一句话结论

本轮已经把 MVP 范围内最关键的 Blender 3D 素材落成并接进主项目，当前状态不是“资源准备好”，而是“资源已经能在工程里跑起来并通过烟雾验证”。
