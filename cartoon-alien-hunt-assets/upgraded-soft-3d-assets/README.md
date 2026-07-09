# 升级版卡通游戏素材说明

本目录是一套新增的 v2 风格包，定位为“软 3D 卡通 + 轻微体积感 + 轻休闲潜行伪装”素材，不替换旧素材，只做补充。

## 风格关键词

- 软塑料 / 软黏土质感
- 柔和 3D 卡通
- 轻微高光与阴影
- 色彩饱和但不刺眼
- 可爱、轻休闲、非写实
- 透明背景优先，便于直接叠到原型场景

## 外星人参考外形语言

这套外星人不是机械照搬参考图，而是保留了参考图最有识别度的轮廓语言：

- 泪滴形绿色大头
- 黑色大眼
- 红色球头触角
- 细长四肢
- 头部比身体更大，整体偏 Q 版
- 表面带轻微高光，呈现软塑料/软黏土般的圆润体积感

为了让角色在游戏里更容易识别，这版增加了简洁的身体分区和小面积配色装饰，让正面、侧面、背面在同一套视觉系统里更统一。

## 升级版动作帧

新增目录：`aliens-animated/`

这一组动作帧延续静态外星人的软 3D 卡通语言，统一保留泪滴形大头、黑色大眼、红色球头触角、细长四肢和轻微高光阴影。帧间变化主要集中在手脚摆动、躯干倾斜、头部朝向和触角角度，便于在三帧静态分镜里快速读出动作意图。

### 动作分组

- `aliens-animated/patrol-soft-1.svg` `patrol-soft-2.svg` `patrol-soft-3.svg`
  - 用途：巡逻、常态移动、低警觉状态
  - 节奏：前探迈步 → 重心居中 → 收步续巡

- `aliens-animated/scan-soft-1.svg` `scan-soft-2.svg` `scan-soft-3.svg`
  - 用途：侧向观察、路口扫描、发现异动前的试探动作
  - 节奏：抬手探查 → 正向停留 → 回摆收势

- `aliens-animated/panic-soft-1.svg` `panic-soft-2.svg` `panic-soft-3.svg`
  - 用途：受惊、逃离、被发现后的应激切换
  - 节奏：受惊外张 → 抬臂失衡 → 俯身冲离

## 使用建议

### 角色朝向

- `aliens/alien-front.svg`：适合站立待机、正面遇敌、对话、角色选择页
- `aliens/alien-side.svg`：适合横向移动、巡逻、侧向观察、潜行经过障碍物
- `aliens/alien-back.svg`：适合背对镜头移动、离开镜头、被玩家尾随时的视角

## 视角修正说明

本轮精修重点统一了三视角中背包的真实朝向关系，避免“正面像胸包、背面看不到包正面”的问题：

- `aliens/alien-front.svg`
  - 背包位于角色身后，正面只保留肩带与包体侧边的轻微露出
  - 正面中心仍可有小识别装饰，但不再与背包混淆
- `aliens/alien-side.svg`
  - 背包斜挂在身体后侧，可同时读出包体正面、侧厚度与肩带路径
  - 与侧面头身比例和身体朝向保持一致，适合作为横向移动参考
- `aliens/alien-back.svg`
  - 直接展示角色背后的背包正面，使背包成为背面视角的主要可见物
  - 保留同一套材质语言、高光节奏和服装比例，确保三视角切换时不跳戏

### 武器道具

- `guns/pistol-soft.svg`：适合基础敌人、轻量攻击或新手关卡
- `guns/rifle-soft.svg`：适合中距离敌人或巡逻单位
- `guns/energy-gun-soft.svg`：适合科幻精英单位、Boss 小技能或高辨识度拾取物

### 环境伪装

以下素材适合直接用作“伪装玩法”的环境对象：

- `environment/bush-rounded.svg`
- `environment/shrub-layered-soft.svg`
- `environment/rock-stack-soft.svg`
- `environment/tree-bouncy.svg`
- `environment/cactus-twin-soft.svg`
- `environment/crate-wood-soft.svg`
- `environment/sign-post-soft.svg`
- `environment/mushroom-soft.svg`
- `environment/grass-clump-soft.svg`
- `environment/wall-cover-intact.svg`
- `environment/wall-cover-breached.svg`
- `environment/wall-cover-collapsed.svg`

其中灌木、草丛、树、仙人掌更适合自然场景伪装；木箱、路牌、岩石更适合做路线节点与障碍掩体；蘑菇可用于风格化地图里的伪装点或装饰性诱饵；新增掩体墙则更适合 PVP 对抗中的临时躲藏、探头射击和破坏反馈。

## PVP 掩体墙状态

新增目录素材：

- `environment/wall-cover-intact.svg`
  - 完整墙体，适合放在交火点、路口或中线位置，提供稳定遮挡
- `environment/wall-cover-breached.svg`
  - 墙体局部被击穿后形成明显缺口，仍保留部分遮挡和探头空间
- `environment/wall-cover-collapsed.svg`
  - 墙体进一步塌陷成低矮残骸，遮挡能力明显下降，更适合做残局或高压交火后的场景反馈

三个状态保持同一堵墙的造型基因、配色和断面关系，方便在关卡中作为连续破坏阶段使用。

## PVP 弹孔/裂纹贴花

新增目录：`decals/`

- `decals/wall-bullet-hole-soft.svg`
  - 单点受击后的中心弹孔贴花，适合叠加在完整墙面上做第一层命中反馈
- `decals/wall-bullet-hole-cluster-soft.svg`
  - 连发扫射后的多点弹孔簇，适合强调压制火力或连续命中
- `decals/wall-crack-radial-soft.svg`
  - 以一点冲击向外扩散的放射裂纹，适合重击或高动能命中
- `decals/wall-crack-corner-soft.svg`
  - 墙体边角被削掉后的裂损贴花，适合放在掩体边缘和转角
- `decals/wall-debris-scatter-soft.svg`
  - 崩边碎屑和粉尘散点贴花，适合补充破损周边的环境反馈

这组贴花统一采用透明背景、卡通化崩边轮廓、柔和高光与轻微体积感，能够直接叠加到 `wall-cover-intact.svg`、`wall-cover-breached.svg`、`wall-cover-collapsed.svg` 或其他墙面素材上，用更低成本补充 PVP 受击后的连续反馈。

## 穿透贴花说明

本轮对墙体受击贴花做了“穿透贴花”升级，核心变化不是颜色更深，也不是表面裂纹更多，而是关键受击区域改成了真实透明洞口：

- `decals/wall-bullet-hole-soft.svg`
- `decals/wall-bullet-hole-cluster-soft.svg`
- `decals/wall-crack-radial-soft.svg`
- `decals/wall-crack-corner-soft.svg`
- `decals/wall-debris-scatter-soft.svg`

### 表现原则

- 透明背景保持不变，便于继续叠加到墙体素材上
- 关键破损区必须能透出后方对象，不再用深色假装洞口
- 洞口边缘通过碎边、断面、内壁阴影和小面积高光表达厚度
- `wall-debris-scatter-soft.svg` 以碎屑和透明间隙为主，不形成整块遮挡

### 使用含义

- 当贴花叠加在完整墙体上时，非洞口区域仍由墙体正常遮挡
- 当角色、目标或场景对象位于墙后时，受击洞口区域应直接可见
- 这组贴花不再提供“完整遮挡的表面裂纹假象”，而是明确表达“遮挡已失效一部分”

因此，穿透贴花更适合用于静态画布演示、PVP 掩体受损反馈，以及需要让玩家一眼看懂“这里已经能看过去”的场景。

## 目标行为补充

新增目录：`aliens-behaviors/`

- 静止伪装
  - 可直接使用现有静态三视角作为基础轮廓，再通过换材质、换颜色或叠加伪装壳来表达“混入环境”的状态
- 缓慢移动
  - 可直接使用现有 `patrol-soft-*`、`scan-soft-*`、`panic-soft-*` 三组动作分镜表达，其中巡逻和扫描最适合慢速移动与试探前进
- 短暂显露弱点
  - 使用 `aliens-behaviors/weakpoint-soft-1.svg`、`weakpoint-soft-2.svg`、`weakpoint-soft-3.svg`
  - 节奏为：隐藏待机 → 半显露预警 → 明显打开并发亮
  - 适合作为短时间可攻击窗口、技能前摇或机制提示

这样可以在不新增复杂骨骼动画的前提下，用静态分镜快速表达“可伪装、可移动、可暴露弱点”的目标行为层次。
