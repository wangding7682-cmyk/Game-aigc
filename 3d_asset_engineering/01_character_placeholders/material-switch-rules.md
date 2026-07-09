# 材质切换规则

## 目的
这份文档用于统一 MVP 阶段角色占位的材质切换逻辑。

目标不是做最终 Shader 方案，而是先明确：

1. 什么状态要切材质
2. 切哪一层
3. 强度怎么控制
4. 哪些状态不能混在一起

---

## 1. 材质分层

角色占位阶段建议把材质分成 5 层：

1. `body_material`
2. `head_material`
3. `costume_material`
4. `accent_material`
5. `special_material`

其中：

- `special_material` 主要承载：
  - 弱点
  - 红眼
  - 扫描高亮
  - 假线索闪点

---

## 2. 外星人材质切换

## 2.1 `alien_base_disguise`

### 目标
让外星人处于“能混入人群，但仍然有轻微危险感”的基础状态。

### 规则

| 材质层 | 规则 |
|---|---|
| `body_material` | 偏深、偏冷、低饱和 |
| `head_material` | 比身体略亮一点，便于读头部 |
| `costume_material` | 深灰蓝 / 深灰绿 / 脏棕灰均可，但不能太鲜艳 |
| `accent_material` | 低强度红或暗红棕，只做轻微异化 |
| `special_material` | 红眼允许低频脉冲，弱点关闭 |

### 禁止项

1. 不能红得太明显
2. 不能一眼像纯怪物
3. 不能没有任何可疑感

---

## 2.2 `alien_costume_disguise`

### 目标
把“服装化伪装”拉出来，但仍然保留识别玩法。

### 规则

| 材质层 | 规则 |
|---|---|
| `body_material` | 更压暗，减少裸露怪物感 |
| `head_material` | 可保留轻微异色，但不能完全人类化 |
| `costume_material` | 服装占主视觉，优先都市潜伏者气质 |
| `accent_material` | 可以出现服装异化细节，但不能压过识别点 |
| `special_material` | 红眼更弱，但不能完全消失 |

### 重点

1. 服装层增强伪装
2. 肩线异常仍可读
3. 眼部危险感不消失

---

## 2.3 `alien_scan_highlight`

### 目标
扫描后让玩家明显更容易判断它是目标。

### 规则

| 材质层 | 规则 |
|---|---|
| `body_material` | 可略提亮，但不是主变化 |
| `head_material` | 可略提亮 |
| `costume_material` | 可被扫描轻微提亮或压暗背景对比 |
| `accent_material` | 允许局部增强 |
| `special_material` | 青蓝外轮廓、高亮最强，优先覆盖头/肩/胸 |

### 重点

1. 扫描不是整个人变白
2. 扫描应当强化“可疑结构”，不是单纯加亮

---

## 2.4 `alien_weakpoint_open`

### 目标
弱点开启时，让玩家明确看到“现在是窗口”。

### 规则

| 材质层 | 规则 |
|---|---|
| `body_material` | 维持基础态 |
| `head_material` | 可略增强危险感 |
| `costume_material` | 允许局部让位给弱点区域 |
| `accent_material` | 可同步轻微增强 |
| `special_material` | 弱点高亮最强，优先用红 / 亮红 / 红白核心感 |

### 禁止项

1. 弱点位置不稳定
2. 弱点亮度低于扫描高亮
3. 弱点和命中成功反馈做得像同一种效果

---

## 3. 平民材质切换

## 3.1 `civilian_calm_idle`

### 目标
形成稳定安全感。

### 规则

| 材质层 | 规则 |
|---|---|
| `body_material` | 中性冷灰、冷蓝灰 |
| `head_material` | 正常肤色或中性亮灰 |
| `costume_material` | 普通城市衣着基调 |
| `accent_material` | 低存在感 |
| `special_material` | 默认关闭 |

---

## 3.2 `civilian_false_clue`

### 目标
制造轻度误导，但不能做成第二种外星人。

### 规则

| 材质层 | 规则 |
|---|---|
| `body_material` | 基本不变 |
| `head_material` | 基本不变 |
| `costume_material` | 基本不变 |
| `accent_material` | 局部短时琥珀色闪点 |
| `special_material` | 不允许出现真正弱点和持续红眼 |

### 禁止项

1. 不允许持续闪烁
2. 不允许整个人被染成危险色
3. 不允许出现明显外星器官结构

---

## 4. 切换优先级

当多个状态可能叠加时，统一优先级如下：

1. `alien_weakpoint_open`
2. `alien_scan_highlight`
3. `alien_costume_disguise`
4. `alien_base_disguise`
5. `civilian_false_clue`
6. `civilian_calm_idle`

说明：

- 弱点窗口优先级最高
- 扫描增强不能压过弱点
- 假线索绝不能压过真正外星人危险态

---

## 5. 验收口径

1. 扫描态必须明显提升判断效率
2. 弱点态必须明显像“可击中窗口”
3. 平民假线索能误导，但不会被误认成稳定目标
4. 服装化伪装不会把关键识别特征完全遮没
