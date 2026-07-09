# 狙击外星人·第三批真实接入导向美术资产包

本批资产位于 `sniper-art-third-batch`，是在前两批“武器 / 角色识别卡 / HUD 图标 / 战斗反馈 / 环境卡图”基础上，继续向 Godot 当前项目的真实接入场景推进的一组素材。

这一批不再以单张概念卡为主，而是更明确地围绕三类业务资产展开：

1. 角色状态变体
2. 商店 / 武器库 UI 套件
3. 命中 / 扫描 / 误伤动画分帧素材

整体视觉继续对齐以下方向：

- `cartoon-alien-hunt-assets`：软 3D 卡通体块、柔和高光、非写实科幻
- `sniper-master-mobile-ui`：暗色移动端狙击 HUD、深蓝黑背景、红色命中高亮、冷蓝辅助信息
- `狙击外星人升级版` 当前代码语义：目标识别、扫描高亮、误判反馈、商店状态、武器库装备逻辑

---

## 一、这批资产分成哪三大类

### 1）角色状态变体

目录：

- `assets/characters/alien-disguised-idle.svg`
- `assets/characters/alien-weakpoint-open.svg`
- `assets/characters/alien-moving-profile.svg`
- `assets/characters/alien-scan-highlight.svg`
- `assets/characters/civilian-calm-idle.svg`
- `assets/characters/civilian-false-clue-glint.svg`
- `assets/characters/civilian-moving-passerby.svg`

这一组直接对齐 `pve_target_controller_3d.gd` 与 `target_behavior_weakpoint.gd` 的识别语义：

- 外星人：
  - 红眼脉冲
  - 肩线异常
  - 伪装感
  - 扫描时可高亮
  - 弱点会周期性打开
- 平民：
  - 冷蓝灰基调
  - 姿态自然
  - 肩线平稳
  - 假线索版本会出现偏琥珀色闪点，但整体仍像普通市民
- moving 版本：
  - 不是只改颜色，而是通过身体重心、迈步、衣摆和肢体朝向表现“正在移动”

这一类素材适合接入：

- 新手识别教学
- 战斗前情报卡
- 扫描结果说明
- 目标状态提示
- 误判复盘说明面板

---

### 2）商店 / 武器库 UI 套件

目录分成两组。

#### 商店 UI 套件

- `assets/ui-kit/shop/shop-header-currency-bar.svg`
- `assets/ui-kit/shop/shop-tab-weapon-active.svg`
- `assets/ui-kit/shop/shop-tab-skin-active.svg`
- `assets/ui-kit/shop/shop-tab-item-active.svg`
- `assets/ui-kit/shop/shop-weapon-card-owned.svg`
- `assets/ui-kit/shop/shop-skin-card-locked.svg`
- `assets/ui-kit/shop/shop-item-card-buyable.svg`
- `assets/ui-kit/shop/shop-buy-button-enabled.svg`
- `assets/ui-kit/shop/shop-buy-button-disabled.svg`

这组直接对应 `ui_panel_shop.gd`：

- Tab：`weapon / skin / item`
- 购买态：免费、金币购买、金币不足、已拥有、需解锁武器

设计重点：

- 一眼能看出 active tab
- 一眼能看出 owned / locked / buyable / enabled / disabled
- 保持移动端游戏 UI 感，而不是桌面后台风格

#### 武器库 UI 套件

- `assets/ui-kit/armory/armory-weapon-list-card-equipped.svg`
- `assets/ui-kit/armory/armory-weapon-list-card-unlocked.svg`
- `assets/ui-kit/armory/armory-skin-list-card-equipped.svg`
- `assets/ui-kit/armory/armory-skin-list-card-locked.svg`
- `assets/ui-kit/armory/armory-detail-panel.svg`
- `assets/ui-kit/armory/armory-equip-button.svg`

这组直接对应 `ui_panel_weapon_library.gd`：

- 武器列表
- 皮肤列表
- 武器详情
- 装备武器
- 装备皮肤

设计重点：

- equipped 状态强调已装配、亮边、确认色
- locked 状态强调受限、低亮度、锁定标识
- detail panel 偏装备页信息容器，而不是普通卡片

---

### 3）命中 / 扫描分帧素材

目录：

#### 扫描脉冲

- `assets/anim/scan-pulse/frame-01.svg`
- `assets/anim/scan-pulse/frame-02.svg`
- `assets/anim/scan-pulse/frame-03.svg`
- `assets/anim/scan-pulse/frame-04.svg`
- `assets/anim/scan-pulse/frame-05.svg`

#### 命中确认

- `assets/anim/hit-confirm/frame-01.svg`
- `assets/anim/hit-confirm/frame-02.svg`
- `assets/anim/hit-confirm/frame-03.svg`
- `assets/anim/hit-confirm/frame-04.svg`
- `assets/anim/hit-confirm/frame-05.svg`

#### 误伤警告

- `assets/anim/wrong-hit-alert/frame-01.svg`
- `assets/anim/wrong-hit-alert/frame-02.svg`
- `assets/anim/wrong-hit-alert/frame-03.svg`
- `assets/anim/wrong-hit-alert/frame-04.svg`
- `assets/anim/wrong-hit-alert/frame-05.svg`

这组直接对齐 `pve_battle_controller_3d.gd` 的战斗反馈语义：

- 扫描开启：青蓝色信息提示与高亮
- 命中：绿色确认
- 误伤：红色警告
- slowmo / killcam / 定位提示：可继续沿用这组动态图形语言做扩展

这一类素材更适合：

- HUD 动效分帧参考
- 动画图集草案
- 教程演示序列
- 程序先用 SVG 帧做原型，再决定是否转粒子或 shader

---

## 二、简洁接入建议

### 1. 角色状态变体怎么接

建议不要把这一组当“人物立绘”，而是当“识别逻辑可视化资产”。

适合的接法：

- 教程页中并排展示外星人 / 平民状态差异
- 扫描说明页中切换普通态与扫描高亮态
- 弱点说明页中切换伪装态与 weakpoint open 态
- 误判复盘页中并排展示 `civilian-calm-idle` 与 `civilian-false-clue-glint`

这样做的好处：

- 和当前代码语义直接对齐
- 可以快速验证识别逻辑是否被玩家读懂
- 不依赖完整角色动画系统也能先落地

### 2. 商店 / 武器库 UI 套件怎么接

建议先作为 Godot `TextureRect`、`PanelContainer`、`Button` 的视觉底板使用，再逐步叠加真实文本与数据。

推荐顺序：

1. 先把商店顶部货币条、Tab、卡片态、按钮态接进原型页
2. 再把武器库列表卡、详情面板、装备按钮接进去
3. 最后再按程序数据驱动不同状态切换

这样可以先验证：

- 玩家是否一眼知道当前在哪个 tab
- 当前物品能不能买
- 当前武器或皮肤是否已装备
- 锁定与已解锁状态是否会混淆

### 3. 分帧素材怎么接

建议先按最轻量方式验证，不必一开始就做复杂特效系统。

推荐做法：

1. 先在 HUD 上按顺序播放 5 帧 SVG
2. 每帧持续 40ms 到 80ms 做原型测试
3. 确认反馈语义成立后，再考虑：
   - 合并图集
   - 转粒子
   - 转 shader
   - 与 slowmo / killcam 叠加

---

## 三、贴近业务场景的快速测试建议

这里不建议只做“看图是否好看”的测试，而建议直接围绕 Godot 当前项目真实业务流做快速验证。

### 测试 1：切换商店 Tab

场景：

- 在 `ui_panel_shop.gd` 对应的商店原型页中，连续切换 `weapon / skin / item`

检查点：

1. 三个 active tab 是否一眼可分
2. 不同 tab 的视觉强调是否统一
3. 玩家是否能立刻知道当前所在栏目

### 测试 2：商店购买态切换

场景：

- 分别展示免费、金币购买、金币不足、已拥有、需解锁武器

检查点：

1. enabled / disabled 是否足够直观
2. owned 和 locked 是否会混淆
3. 免费状态是否比普通金币购买更显眼

### 测试 3：武器库装备切换

场景：

- 在武器库中依次选择武器列表、皮肤列表，并触发“装备武器 / 装备皮肤”

检查点：

1. equipped 卡片是否明显强于 unlocked
2. 详情面板是否能承接武器与皮肤信息变化
3. 装备按钮是否像关键操作，而不是普通次级按钮

### 测试 4：扫描后目标高亮

场景：

- 调用扫描后，同时展示 `alien-disguised-idle` 与 `alien-scan-highlight`

检查点：

1. 玩家是否能立刻感知“这个目标被扫描标记了”
2. 青蓝扫描语言是否与第二批 HUD 风格连贯
3. 高亮态是否仍保留伪装感，而不是变成完全不同角色

### 测试 5：弱点开启识别

场景：

- 在 weakpoint 周期开启逻辑下，轮播 `alien-disguised-idle` 与 `alien-weakpoint-open`

检查点：

1. 玩家是否能快速理解“当前是可击中窗口”
2. 弱点打开时是否和普通目标态足够区分
3. 不看文字时也能理解这是关键打击瞬间

### 测试 6：误伤平民反馈

场景：

- 在误击平民后，连续播放 `wrong-hit-alert` 5 帧，并对照 `civilian-calm-idle` 与 `civilian-false-clue-glint`

检查点：

1. 红色告警是否足够强烈
2. 假线索版本是否仍然像平民，而不是像真正外星人
3. 玩家是否能理解自己是被假线索误导，而不是系统判定不清

### 测试 7：命中确认与 killcam 成功提示

场景：

- 击中目标后播放 `hit-confirm` 5 帧，叠加到 killcam 或成功反馈提示上

检查点：

1. 绿色确认是否和红色误伤警告形成足够强区分
2. 收束过程是否像“确认命中”，而不是普通闪光
3. 在暗色 HUD 上是否足够醒目

### 测试 8：装备皮肤后详情变化

场景：

- 在武器库中先选武器，再选皮肤，触发装备皮肤，并观察详情区

检查点：

1. 详情面板是否能清楚承接“武器信息 + 当前皮肤”
2. 已装备皮肤卡与未解锁皮肤卡是否会混淆
3. 用户是否能立刻确认自己装备成功

---

## 四、这批素材与前两批的关系

如果说：

- 第一批更偏“首轮武器卡、角色识别卡、通用 HUD 图标”
- 第二批更偏“战斗内掩体、HUD 组件、战斗反馈贴图”

那么第三批更偏：

- 系统状态
- UI 套件
- 动画分帧

也就是更接近程序真实接入时会直接切换和复用的资产层，而不是单独展示的概念卡层。

---

## 五、附加文件

- `preview.html`：中文深色预览页，按“状态 / 套件 / 分帧”组织展示
- `styles.css`：预览页样式

---

## 六、整体定位

本批的核心价值不是再补几张单独的图，而是把“识别状态、商店状态、装备状态、扫描状态、命中状态、误伤状态”这些真实业务节点做成更容易接入、也更容易测试的视觉资产。

这样程序、美术、策划在对齐 Godot 当前项目时，讨论的不再只是“长什么样”，而是“这个状态一眼能不能读懂、切换后是否成立、放进真实流程里是否顺手”。
