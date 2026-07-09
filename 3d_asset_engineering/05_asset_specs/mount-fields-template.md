# 接入字段模板

## 目的
这份文档用于统一后续资源从“工程化准备层”并入主项目时的记录字段。

目标是保证每个资源都能回答这几个问题：

1. 它是什么
2. 它属于哪一类
3. 它应该挂到哪里
4. 它什么时候出现
5. 它什么时候替换
6. 它没有正式版时怎么办

---

## 1. 推荐字段

每个资源建议统一记录以下字段：

| 字段 | 必填 | 说明 |
|---|---|---|
| `asset_name` | 是 | 实际资源名，按命名规则填写 |
| `asset_type` | 是 | 角色 / 掩体 / 反馈 / 贴花 / 武器 |
| `asset_state` | 是 | 当前资源对应的状态 |
| `source_stage` | 是 | 准备层 / 占位版 / 正式版 |
| `target_node` | 是 | 推荐挂载节点位置 |
| `trigger_condition` | 是 | 出现的逻辑条件 |
| `replace_timing` | 是 | 替换到主项目的时机 |
| `fallback_plan` | 是 | 没有正式版时的兜底方案 |
| `collision_layer` | 否 | 如果涉及碰撞，记录使用层 |
| `mount_points` | 否 | 相关挂点，如 `WeakPoint` |
| `notes` | 否 | 额外说明 |

---

## 2. 模板示例

```text
asset_name:
asset_type:
asset_state:
source_stage:
target_node:
trigger_condition:
replace_timing:
fallback_plan:
collision_layer:
mount_points:
notes:
```

---

## 3. 角色类示例

```text
asset_name: alien_costume_disguise
asset_type: 角色
asset_state: 服装化伪装态
source_stage: 占位版
target_node: ActorRoot/TargetActor
trigger_condition: 目标生成且伪装类型为服装化伪装
replace_timing: Step 2~3 角色可读性验证通过后
fallback_plan: 使用 alien_base_disguise 替代
collision_layer: target
mount_points: HitFocus, WeakPoint, ScanHighlight, ReviewFocus
notes: 服装层增强伪装感，但不能遮掉红眼和异常肩线
```

---

## 4. 掩体类示例

```text
asset_name: cover_wall_corner_placeholder
asset_type: 掩体
asset_state: 占位结构
source_stage: 占位版
target_node: WorldRoot/LevelRoot
trigger_condition: 关卡初始化时生成基础掩体
replace_timing: Step 2 掩体遮挡验证通过后
fallback_plan: 使用 BoxMesh 纯色结构代替
collision_layer: obstacle
mount_points: DecalSurface, ImpactFx
notes: 必须稳定挡弹，优先提供边缘露头识别
```

---

## 5. 反馈类示例

```text
asset_name: fx_hit_confirm_world
asset_type: 反馈
asset_state: 命中成功
source_stage: 占位版
target_node: WorldRoot/FxRoot
trigger_condition: shot_result == hit
replace_timing: Step 3 命中反馈验证通过后
fallback_plan: 使用最小亮色闪点反馈
collision_layer:
mount_points: HitFocus
notes: 不应与 wrong_hit 或 blocked 混淆
```

---

## 6. 贴花类示例

```text
asset_name: decal_bullet_hole_basic
asset_type: 贴花
asset_state: 普通命中痕迹
source_stage: 准备层
target_node: WorldRoot/DecalRoot
trigger_condition: 子弹命中允许贴花的表面
replace_timing: Step 3 射击结果链稳定后
fallback_plan: 暂不生成贴花，仅保留命中特效
collision_layer: bullet_decal
mount_points: DecalSurface
notes: 不参与碰撞判定
```

---

## 7. 建议的使用方式

后续每一个准备层资源，都建议配一份这样的记录。

优点：

1. 程序知道挂哪
2. 美术知道自己做的是哪个状态
3. 替换正式资源时不会漏规则
4. 测试时可以直接对照资源与状态

---

## 8. 最低要求

如果前期不想填太重，最低也必须先填这 5 个字段：

1. `asset_name`
2. `asset_type`
3. `target_node`
4. `trigger_condition`
5. `fallback_plan`

这 5 个字段不齐，后续接入主项目时最容易返工。
