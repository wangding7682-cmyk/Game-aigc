# 第一人称战斗资产材质收口第一轮

## 目标

把当前第一人称战斗中的“模型感”进一步压低，先完成一轮最小可用的材质工程化：

- 武器近景材质
- 目标角色材质
- 掩体 / 环境材质
- 近景 `decal / grime / edge wear`

本轮不追求正式高精 PBR 管线，只做 MVP 阶段最直接影响观感的近景材质收口。

## 新增资产

### 武器

- `res://assets_mvp_placeholder/materials/material-weapon-grime-overlay.svg`
- `res://assets_mvp_placeholder/materials/material-weapon-edge-wear-overlay.svg`

用途：

- 机匣近景脏污层
- 枪托 / 握把轻度污渍层
- 瞄具与机匣上沿磨损层

### 角色

- `res://assets_mvp_placeholder/materials/material-actor-fabric-breakup.svg`

用途：

- 服装近景 breakup
- 胸前 / 肩侧轻度材质层次
- 扫描命中时的材质强化层

### 环境

- `res://assets_mvp_placeholder/materials/material-environment-grime-overlay.svg`
- `res://assets_mvp_placeholder/materials/material-environment-edge-wear-overlay.svg`

用途：

- 掩体表面脏污
- 墙角 / 车辆 / 广告牌边缘磨损
- 近景可见层的表面旧化

## 运行时注入规则

### 武器近景材质

- 贴膜只挂第一人称武器视模型，不挂 UI
- 至少包含：
  - 主体 grime 层
  - 枪托 / 握把 grime 层
  - scope / 机匣上沿 edge wear 层
- 贴膜强度不能盖过武器主色，必须保持“看起来更真实”，而不是“像贴了一张海报”

### 目标角色材质

- 角色材质要分开处理：
  - body
  - head
  - limb
  - costume
  - accent
- fabric breakup 只作为近景层次增强，不替代识别图层
- 受扫描时允许材质层产生亮度 / 冷色变化，但不能破坏目标识别逻辑

### 掩体 / 环境材质

- 环境 grime / edge wear 只挂在近景正面可见层
- 对导入模型：优先复制材质后调 roughness / alpha
- 对程序生成体块：允许直接在正面挂 overlay quad
- 不把环境贴膜做成 billboard 漂浮效果

## 颜色与质感原则

### 武器

- 主金属层：低饱和深色
- 握把 / 枪托：更高 roughness、更低 metallic
- edge wear：只点边，不大面积发白

### 角色

- 目标：冷灰 + 冷青 accent
- 平民：灰蓝 + 更低发光感
- 被扫描时：允许冷色抬亮，但不能直接变成纯霓虹

### 环境

- 墙角：偏冷灰旧化
- 路灯：深金属 + 暖灯罩
- 面包车：浅车漆 + 深 trim + 轻度旧化
- 广告牌：亮色主体 + 暗边框 + 局部磨损

## 最小验收

- 武器在第一人称视角下不再只像纯色模型块
- 角色胸前 / 肩部 / accent 区域出现可见材质层次
- 环境掩体正面出现轻度 grime / edge wear
- 材质增强不影响：
  - 命中判定
  - 扫描判定
  - 挡弹反馈
  - 当前烟雾测试

## 当前边界

- 本轮不引入法线贴图流程
- 本轮不引入正式 roughness/metallic 贴图烘焙
- 本轮不重做模型 UV
- 本轮不扩成第二阶段正式 PBR 资产生产规范
