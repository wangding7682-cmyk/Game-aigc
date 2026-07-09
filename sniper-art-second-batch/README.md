# 狙击外星人·第二批战斗内资产包

本批资产位于 `sniper-art-second-batch`，是在首批“武器卡图 / 角色识别卡 / HUD 图标”基础上，继续往 Godot 项目真实战斗内需求推进的一组素材。整体视觉仍然延续：

- `cartoon-alien-hunt-assets` 的软 3D 卡通体块、轻塑料高光、圆润边缘
- `sniper-master-mobile-ui` 的暗色夜战狙击 HUD、冷蓝辅助光、红色战斗高亮

但这一次更聚焦在三类真实接入点：

1. PVE 关卡中的环境掩体原型
2. 瞄准镜与主 HUD 需要的界面组件
3. 命中、误伤、扫描、慢动作等战斗反馈贴图

---

## 一、这批资产包含什么

### 1）环境卡图

目录：

- `assets/environment/env-wall-corner.svg`
- `assets/environment/env-street-lamp.svg`
- `assets/environment/env-parked-van.svg`
- `assets/environment/env-billboard.svg`

这组主要对齐 `狙击外星人升级版\scripts\pve\pve_cover_obstacle_3d.gd` 中的四种障碍物样式：

- `wall_corner`
- `street_lamp`
- `parked_van`
- `billboard`

用途：

- 关卡预览页中的掩体卡片
- 关卡编辑器 / 拼装页中的障碍物示意图
- 教程说明中“哪些城市道具会挡枪线”的可视化说明
- 商店 / 图鉴 / 战斗情报页中的环境原型展示

设计意图：

- 墙角强调厚度感和拐角遮挡感，能一眼理解“这是能躲的掩体”
- 路灯强调细长立柱与暖光，适合夜战街景
- 停放货车强调横向体块和城市轮廓感，适合大型掩体语义
- 广告牌强调高处遮挡和轻微发光屏，适合远处遮挡物与扫描场景

---

### 2）HUD 组件

目录：

- `assets/hud/hud-scope-frame.svg`
- `assets/hud/hud-health-bar.svg`
- `assets/hud/hud-time-bar.svg`
- `assets/hud/hud-target-lock-frame.svg`
- `assets/hud/hud-feedback-panel.svg`

这组主要对齐：

- `狙击外星人升级版\scripts\ui\ui_scope_overlay.gd`
- `狙击外星人升级版\scripts\ui\ui_hud_pve.gd`

对应关系：

- `hud-scope-frame.svg`
  - 对齐圆形瞄准镜、外圈、准星、中心点语义
- `hud-health-bar.svg`
  - 对齐顶部状态中的生命信息
- `hud-time-bar.svg`
  - 对齐顶部状态中的剩余时间 / 加时语义
- `hud-target-lock-frame.svg`
  - 对齐锁定、扫描、locator hint、识别框语义
- `hud-feedback-panel.svg`
  - 对齐顶部状态条、反馈消息、提示消息底板

适合接入的 Godot 场景：

- `scenes/ui/ui_hud_pve.tscn`
- `scenes/pve/pve_battle_main.tscn`
- 教程流程里的瞄准、扫描、命中说明页

---

### 3）特效贴图

目录：

- `assets/effects/fx-muzzle-flash.svg`
- `assets/effects/fx-scan-pulse.svg`
- `assets/effects/fx-hit-confirm.svg`
- `assets/effects/fx-wrong-hit-alert.svg`
- `assets/effects/fx-cover-impact.svg`
- `assets/effects/fx-slowmo-ring.svg`

这组主要对齐：

- `狙击外星人升级版\scripts\ui\ui_scope_overlay.gd`
- `狙击外星人升级版\scripts\pve\visual_feedback.gd`

对应逻辑：

- 枪口火光：开火瞬间、射击教学
- 扫描脉冲：扫描按钮触发、掩体透视、目标高亮
- 命中确认：成功命中、锁定成功、击杀反馈
- 误伤警告：打错目标、误伤平民、错误识别复盘
- 掩体命中：打到 cover 时的反馈层
- 慢动作环：slowmo、killcam、镜头聚焦时刻

用途：

- HUD 叠加层
- 教程说明页中的状态示意图
- 动效设计基底
- 图集切片参考图

---

## 二、适合接入哪些 Godot 场景

### 场景一：PVE 主战斗

推荐场景：

- `狙击外星人升级版\scenes\pve\pve_battle_main.tscn`
- `狙击外星人升级版\scenes\ui\ui_hud_pve.tscn`

适合接入：

- HUD 组件
- 特效贴图
- 环境卡图作为关卡预览和说明素材

业务价值：

- 能更快把“扫描 / 锁定 / 命中 / 打到掩体 / 误伤”这些反馈做得更清楚
- 能在试玩阶段先验证 UI 信息层是否够直观，而不是一开始就依赖完整 3D 资源

### 场景二：教程与新手引导

推荐场景：

- `狙击外星人升级版\scenes\tutorial\tutorial_flow_intro.tscn`

适合接入：

- 环境卡图：讲解“哪些场景物件会挡枪线”
- 特效贴图：讲解“命中 / 误伤 / 掩体命中 / 慢动作”
- HUD 组件：讲解“瞄准镜状态、时间条、生命条、反馈消息”

业务价值：

- 玩家第一次接触玩法时，不需要先理解全部系统，只要通过图示就能快速掌握反馈含义

### 场景三：关卡预览 / 图鉴 / 编辑器工具

适合接入：

- 环境卡图作为关卡元素预览
- HUD 组件作为 UI 样式板
- 特效贴图作为后续动画开发说明图

业务价值：

- 方便策划、程序、美术在同一套语义下讨论资源和反馈，不容易发生“代码里叫这个、界面看起来像另一个”的偏差

---

## 三、哪些是环境卡图、哪些是 HUD 组件、哪些是特效贴图

### 环境卡图

- `assets/environment/env-wall-corner.svg`
- `assets/environment/env-street-lamp.svg`
- `assets/environment/env-parked-van.svg`
- `assets/environment/env-billboard.svg`

### HUD 组件

- `assets/hud/hud-scope-frame.svg`
- `assets/hud/hud-health-bar.svg`
- `assets/hud/hud-time-bar.svg`
- `assets/hud/hud-target-lock-frame.svg`
- `assets/hud/hud-feedback-panel.svg`

### 特效贴图

- `assets/effects/fx-muzzle-flash.svg`
- `assets/effects/fx-scan-pulse.svg`
- `assets/effects/fx-hit-confirm.svg`
- `assets/effects/fx-wrong-hit-alert.svg`
- `assets/effects/fx-cover-impact.svg`
- `assets/effects/fx-slowmo-ring.svg`

---

## 四、简洁接入建议

### 1. 环境卡图接法

建议先不要把它们当成 3D 模型贴图用，而是优先用于：

- 关卡预览卡片
- 掩体图鉴
- 教程说明页
- 关卡拼装工具中的预览缩略图

这样做的好处是：

- 上手快
- 不依赖完整建模管线
- 可以先验证掩体语义是否清楚

### 2. HUD 组件接法

建议直接挂到 Godot 的：

- `TextureRect`
- `Panel`
- `PanelContainer`
- `Control`

使用建议：

1. `hud-scope-frame.svg` 优先作为瞄准镜正式外框或高保真占位图
2. `hud-health-bar.svg` 与 `hud-time-bar.svg` 可以先做静态条，再逐步接动态填充
3. `hud-feedback-panel.svg` 上面再叠加 `Label` / `RichTextLabel`
4. `hud-target-lock-frame.svg` 可在目标被扫描或锁定时显示

### 3. 特效贴图接法

建议分两步：

第一步，先静态接入：

- 做按钮示意
- 做教程页说明图
- 做原型状态演示

第二步，再做动态化：

- 缩放
- 淡入淡出
- 旋转
- 颜色切换

这样既贴近业务，也能降低一次性改造风险。

---

## 五、贴近业务场景的快速测试建议

这里不建议做“只看图好不好看”的测试，而建议做更接近战斗业务的快速测试。

### 测试 1：掩体识别测试

场景：

- 在同一关卡预览页里并排放入墙角、路灯、货车、广告牌四张图

检查点：

1. 玩家是否能快速理解哪种是厚掩体、哪种是高遮挡、哪种是街景道具
2. 程序和策划在讨论 `style_id` 时，是否能和图示一一对应

通过标准：

- 不看文字说明，团队成员也能大致判断每种障碍物的语义

### 测试 2：命中反馈可区分测试

场景：

- 在同一个 HUD 原型页里切换三种反馈：
  - 命中成功
  - 误伤
  - 打到掩体

检查点：

1. 是否能靠颜色和形状快速区分三类结果
2. 是否会与准星或扫描提示混淆

通过标准：

- 1 秒内能说出是哪一种结果

### 测试 3：扫描与锁定叠加测试

场景：

- 把 `fx-scan-pulse.svg` 和 `hud-target-lock-frame.svg` 叠到一个目标提示 UI 上

检查点：

1. 扫描脉冲是否过强，影响锁定框清晰度
2. 锁定框是否足够像“识别中 / 被标记”，而不是普通装饰框

通过标准：

- 玩家能知道这是“正在识别或锁定”，而不是普通提示板

### 测试 4：瞄准镜阅读性测试

场景：

- 在深色背景上使用 `hud-scope-frame.svg`

检查点：

1. 圆形镜框和中心点是否清楚
2. 外圈、内圈和中心是否层次明确
3. 与命中反馈、慢动作环叠加后是否仍然可读

通过标准：

- 屏幕信息变多时，玩家仍能第一眼找到中心瞄准点

---

## 六、附加文件

- `preview.html`：中文预览页，汇总所有第二批资产与用途说明
- `styles.css`：预览页样式文件

---

## 七、这一批的定位

如果说第一批更像“武器库、识别页和通用图标”的首轮视觉落地，那么第二批更偏“战斗中真正会被看到和被触发的场景资产”。

它的重点不是做更多卡片，而是把：

- 掩体语义
- HUD 结构
- 命中反馈
- 扫描提示
- 慢动作氛围

真正往 Godot 的 PVE 战斗主链路里推进一步。
