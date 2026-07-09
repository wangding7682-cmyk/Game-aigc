# 命名规则

## 目的
这份文档用于统一第一阶段 MVP 的 3D 美术素材工程化命名。

目标：

1. 一眼看懂资源是什么
2. 一眼看懂资源属于哪一类
3. 一眼看懂它是什么状态
4. 后续能稳定并入主项目

---

## 总原则

统一采用：

1. 小写英文
2. 下划线分隔
3. 先类别
4. 再对象
5. 最后状态

禁止：

1. `new`
2. `final`
3. `tmp`
4. `test2`
5. `版本2`

---

## 角色命名

### 推荐格式

`角色类别_对象_状态`

### 示例

| 用途 | 推荐名 |
|---|---|
| 外星人基础伪装态 | `alien_base_disguise` |
| 外星人服装化伪装态 | `alien_costume_disguise` |
| 外星人移动态 | `alien_moving_profile` |
| 外星人扫描高亮态 | `alien_scan_highlight` |
| 外星人弱点开启态 | `alien_weakpoint_open` |
| 平民普通待机 | `civilian_calm_idle` |
| 平民移动态 | `civilian_moving` |
| 平民假线索态 | `civilian_false_clue` |

---

## 掩体命名

### 推荐格式

`cover_对象_状态`

### 示例

| 用途 | 推荐名 |
|---|---|
| 墙角掩体占位 | `cover_wall_corner_placeholder` |
| 路灯掩体占位 | `cover_street_lamp_placeholder` |
| 货车掩体占位 | `cover_parked_van_placeholder` |
| 广告牌掩体占位 | `cover_billboard_placeholder` |

---

## 反馈命名

### 推荐格式

`fx_语义_对象`

### 示例

| 用途 | 推荐名 |
|---|---|
| 扫描反馈 | `fx_scan_pulse_world` |
| 命中确认 | `fx_hit_confirm_world` |
| 误伤警告 | `fx_wrong_hit_warning` |
| 掩体挡弹 | `fx_cover_impact_world` |
| 枪口火焰 | `fx_muzzle_flash_basic` |

---

## 贴花命名

### 推荐格式

`decal_对象_状态`

### 示例

| 用途 | 推荐名 |
|---|---|
| 普通弹孔 | `decal_bullet_hole_basic` |
| 掩体命中痕迹 | `decal_cover_impact_mark` |

---

## 挂点命名

挂点统一使用 `PascalCase`。

### 角色挂点

1. `HitFocus`
2. `WeakPoint`
3. `ScanHighlight`
4. `ReviewFocus`
5. `HeadLook`

### 武器挂点

1. `Muzzle`
2. `Grip`
3. `ScopeFocus`

### 场景挂点

1. `DecalSurface`
2. `ImpactFx`
3. `ScanFadeAnchor`

---

## 文件名与展示名的关系

建议：

- 文件名严格按规则
- 展示名可以更自然

例如：

| 文件名 | 展示名 |
|---|---|
| `alien_costume_disguise` | 外星人服装化伪装态 |
| `cover_wall_corner_placeholder` | 墙角掩体占位 |

---

## 验收口径

1. 同类资源命名顺序必须一致
2. 文件名应能直接推断用途
3. 不允许同一状态出现多种命名方式
4. 后续新资源必须沿用本规则，不另起体系
