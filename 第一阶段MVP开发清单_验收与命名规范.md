# 第一阶段 MVP 开发清单、验收标准与命名规范（阶段归档）

> **归档说明**：本文档保留的是“从早期验证层推进到 3D MVP”的阶段性实施顺序，用于回看当时的拆解方法、验收口径和命名约束。  
> **当前口径**：它不再作为项目当前设计基线或工程现状说明。现行设计以根目录的 `GDD_狙击大师_完整设计方案.md` 为准，现行工程状态以 `狙击外星人升级版/Godot_MVP脚手架说明.md` 为准。  
> **使用方式**：后续如果查这份文档，应把它当成“历史实施留档”，而不是“当前仍未完成的待办清单”。

---

## 一、MVP 范围冻结

本阶段只做一个可验证核心乐趣的竖切版本，不展开完整商业化内容。

### 本阶段包含

- PVE 3 关（沿用现有 `cfg_pve_level_001~003` 配置）
- 1 个 3D 主场景（城市街区分块地图）
- 3 类目标行为（静止伪装/缓慢移动/短暂显露弱点）
- 2 个基础道具（扫描雷达/时间延长）
- 基础结算
- 基础金币成长（沿用现有 `InventoryService`/`WeaponManager`）
- 1 个新手教程（沿用 `tutorial_flow_controller`）
- PVP 本地 mock 流程（沿用 `pvp_mock_room_controller`），不做真实联网
- 激励视频 mock（沿用 `AdsService` 现有接口）
- 平台适配层骨架（沿用现有 `PlatformAdapter` 体系）
- 埋点与基础调参数据（沿用 `AnalyticsService`）

### 本阶段不包含

- 真实广告 SDK 对接
- 微信/抖音真实登录与分享
- 真实 PVP 联网对战（仅保留接口形状）
- Boss 关卡
- Battle Pass
- 段位赛季完整玩法
- 插屏和 Banner 广告
- 大规模正式美术资源导入（先保留占位模型/纯色材质）

---

## 二、核心实现口径（3D对齐）

### Godot 实现方式（已对齐现有工程架构）

- 视觉表现：`3D 画面 + 2.5D 固定斜视角玩法`
- 地图形式：`3D 分块网格地图`（沿用 `pve_spawn_entry` 刷点体系）
- 瞄准方式：`Camera3D 位置/FOV 缩放 + UI 瞄准镜叠加层`（复用 `ui_scope_overlay`）
- 命中方式：`3D 射线判定 + 射线末端小范围球形AOE容错`（使用 `PhysicsRayQueryParameters3D`）
- 目标伪装：`Shader 材质参数切换 / Albedo 颜色调整`（不换模型，只改材质表现）
- PVP 弹孔：`Godot Decal 节点贴花`（单独层 `bullet_decal`，不参与碰撞检测）
- 2D/3D 兼容规则：现有 2D 验证层保留，3D 实现脚本统一加 `_3d` 后缀，玩法逻辑接口保持一致

### PVE 规则口径

- 目标命中：3D 射线优先，射线末端附带一个很小的球形 AOE 容错区
- 推荐容错半径：`目标身体宽度的 15%`，3D 世界单位上限 `0.25m`
- 误伤对象：`普通市民`（`civilian` 碰撞层）、非任务目标 NPC、教程引导假人
- 场景物件被击中：只播放命中特效，不计误伤
- 连杀：`MVP 阶段不实现`
- 扫描雷达：目标模型轮廓闪烁高亮（使用 `outline_pass` 后处理或边缘发光 Shader，前方目标优先可见）
- 移动目标速度上限：长按 1 秒约移动半个身位（3D 世界速度约 `0.3m/s`，可在 `pve_weapon_tuning` 中调整）
- 新手提示：开局即弹出分步引导，沿用 `tutorial_flow_intro` 流程

### 时间奖励口径

先按简单线性规则落地，避免一开始过度复杂：

- 基础结算金币：按关卡配置 `cfg_pve_level_xxx.tres` 发放
- 时间奖励：和“连续未误伤存活时长”挂钩，线性增长
- 建议公式：

`time_bonus = floor(survive_time_sec * (1.0 + miss_count * -0.15))`

说明：
- `survive_time_sec`：本局累计存活时长
- `miss_count`：本局误伤次数，每误伤一次扣 15% 时间奖励
- 保底奖励不低于基础通关奖励的 30%

### PVP mock 口径（对齐现有接口）

- 玩法模型：`强回合制`
- 当前回合发起权：`射击者回合`
- 最终状态裁定接口形状：`按服务端权威设计`（复用 `NetworkManager` 接口形状，本地 mock 返回裁定结果）
- 姿势切换：即时广播，用世界空间漂浮字幕展示
- 命中判定：客户端提交射击请求，按“服务端（mock）返回结果”更新表现，不信任本地命中
- 断线重连：本阶段只保留接口与假恢复流程，沿用 `pvp_mock_room` 的重入逻辑
- 弹孔同步：射击结果返回后，客户端在对应位置创建 Decal 贴花

---

## 三、推荐开发顺序（基于现有工程现状）

现有工程已完成：项目骨架、主流程路由、2D玩法手感验证、平台适配层骨架、PVP mock 房间骨架。
建议按下面 10 步推进，每一步都要满足“可运行、可验证、可回归”。

1. 3D 场景骨架与镜头规范
2. 3D 分块地图与刷点对齐
3. PVE 3D 观察、瞄准、射击手感
4. 三类 3D 目标行为实现
5. 两个基础道具 3D 表现
6. 3 关配置与难度校准
7. 新手教程 3D 适配
8. 结算与金币成长（逻辑复用，只适配3D表现）
9. PVP 本地 mock 3D 场景适配
10. 平台 mock 验证与埋点对齐

---

## 四、开发清单与验收

## Step 0 现状基线确认（已完成，验收通过）

### 已完成内容（现有脚手架）

- 主入口：`scenes/core/core_game_root.tscn`
- Autoload：`CoreEventBus`/`CoreGameState`/`PlatformService`/`AnalyticsService`/`NetworkManager`/`InventoryService`/`WeaponManager`/`ResourceManager`
- 主流程：主菜单 -> PVE 战斗 -> 结算 -> 升级 -> 下一关 已跑通
- 配置：`configs/pve/cfg_pve_level_001~003.tres` 3关配置已存在
- 2D 验证层：观察/缩放/屏息/命中容错/误伤惩罚/2个道具/3类目标行为已验证手感
- 平台层：`platform_adapter_mock`/`platform_adapter_wechat`/`platform_adapter_douyin`/`platform_bridge_web` 骨架已存在

### 验收标准（已通过）

- 项目启动无报错，主菜单可正常进入
- 2D 代理场景可完整走完一局流程
- 所有信号和服务接口调用无空引用

---

## Step 1 3D 场景骨架与镜头规范

### 目标

建立 2.5D 固定斜视角 3D 战斗场景，定死镜头参数，避免后续所有资产挂载返工。

### 开发内容

- 创建 `scenes/pve/pve_battle_main_3d.tscn` 主战斗场景
- 节点结构严格按：`LevelRoot`（地图/静态碰撞）+ `ActorRoot`（目标/平民）+ `DecalRoot`（弹孔/贴花）+ `FxRoot`（特效）+ `UiRoot`（HUD/瞄准镜）
- 配置 Camera3D 默认参数：
  - 高度：`12m`
  - 俯角：`45度`
  - 默认 FOV：`60度`
  - 瞄准最大 FOV：`15度`（对应 4x 放大）
- 配置 3D 碰撞层（沿用命名规范）
- 配置光照：默认平行光 + 环境光，保证目标轮廓清晰

### 产出

- 可进入 3D 空白战斗场景，镜头滑动/缩放手感符合 2.5D 玩法

### 验收标准

- 滑动平移镜头时无明显跳帧和漂移，边界限制正确
- 缩放中心稳定在屏幕准星位置，不出现镜头错位
- 长按屏息后，镜头抖动明显降低
- UI 瞄准镜叠加层和 3D 相机缩放同步，无错位
- 近景/中景/远景目标可见度符合识别要求

### 场景测试

- 连续滑动镜头1分钟，不出现穿模、飞到地图外
- 连续缩放20次，镜头位置始终对准准星中心
- 不同距离下，纯色块占位目标可被清晰区分

---

## Step 2 3D 分块地图与刷点对齐

### 目标

将现有 2D 刷点体系平移到 3D，用简单方块搭建分块地图，不依赖正式美术。

### 开发内容

- 用 `CSGBox3D` 搭建 1 个城市街区基础分块地图（地面、墙体、简单掩体）
- 复用现有 `pve_spawn_entry` 逻辑，在 3D 场景中放置刷点
- 碰撞层配置：
  1. `world`：地面/静态墙体
  2. `target`：外星人目标
  3. `civilian`：普通市民
  4. `obstacle`：可掩体
  5. `interactive`：可交互物
  6. `bullet_decal`：弹孔贴花（不参与碰撞）
  7. `pvp_actor`：PVP 玩家单位
  8. `scan_only`：扫描可见标记
- 复用现有 `pve_level_config` 加载逻辑，3D 场景可读取现有关卡配置

### 产出

- 3D 分块地图可加载，刷点可正常生成占位目标

### 验收标准

- 改配置不改代码即可改变目标数量、时限、奖励
- 掩体碰撞正确，射线可被阻挡
- 刷点位置不会出现在墙体/地面下
- 地图边界正确，镜头不会滑出可玩区域

### 场景测试

- 加载3个关卡配置，目标数量、位置、时限都正确
- 射击墙体时，射线正确被阻挡，不穿透
- 目标生成在地面上，无浮空/陷地

---

## Step 3 PVE 3D 观察、瞄准、射击手感

### 目标

验证 3D 下核心射击手感，这是 MVP 最关键的一步。

### 开发内容

- 复用 `camera_controller_3d.gd`，完成镜头平移、缩放、屏息逻辑
- 复用 `battle_core_3d.gd`，实现 3D 射线发射
- 实现射线末端小范围 AOE 容错判定
- 基础命中反馈：命中目标播放绿色闪烁，误伤平民播放红色警告
- 子弹特效：简单 Line3D 弹道，枪口火焰占位
- 误伤惩罚：3次误伤失败，正确触发结算

### 产出

- 玩家能在 3D 场景中观察、缩放、瞄准并击中目标

### 验收标准

- 射线命中和容错命中都能正确识别
- 贴边射击容错不出现明显“打空却命中”的违和感
- 掩体挡弹时反馈正确，玩家能理解“被挡住了”
- 误伤普通 NPC 时，正确扣除生命，3次后失败
- 射击帧率稳定在 60fps（PC 测试环境）

### 场景测试

- 静止目标在中距离下，连续 10 次射击，至少 8 次命中符合预期
- 贴边射击 20 次，容错率符合预期，不出现误判
- 故意射击普通市民 3 次，失败逻辑正确触发

---

## Step 4 三类 3D 目标行为

### 目标

在3D场景中实现3类目标行为，保持和2D验证层一致的手感。

### 三类目标行为（复用现有行为类）

1. 静止伪装：`target_behavior_static`，材质颜色接近环境，不移动
2. 缓慢移动：`target_behavior_moving`，沿预设路径缓慢巡逻，速度不超过 0.3m/s
3. 短暂显露弱点：`target_behavior_weakpoint`，定时显示红色弱点区域，仅弱点可被击杀

### 开发内容

- 复用 `target_behavior_factory.gd`，在 3D 目标上挂载对应行为脚本
- 目标伪装：用纯色材质/简单 Shader 实现颜色融入环境
- 缓慢移动路径：在场景中放置 Path3D 节点，目标沿路径移动
- 弱点：目标上挂一个单独的 MeshInstance3D 作为弱点碰撞区，仅弱点区域可命中
- 平民目标：`target_behavior_civilian`，随机缓慢移动，作为误伤干扰

### 产出

- 三类目标都能在同一 3D 主场景中配置出来

### 验收标准

- 静止伪装目标在远景下不应一眼过于明显
- 移动目标速度符合“1 秒半个身位”的上限，不会过快导致无法瞄准
- 弱点显露节奏可观测、可射击，不是纯随机赌运气（暴露时间 1.5~2秒，间隔 5~8秒）
- 平民移动自然，不会出现瞬移/卡墙

### 场景测试

- 让同一个测试者试玩 3 关，确认三类目标有明显体感差异
- 记录首次发现时间：静止目标 < 5秒，移动目标 < 8秒，弱点目标首次暴露后可被命中
- 不出现“弱点永远打不中”或“弱点一直开着”的情况

---

## Step 5 两个基础道具 3D 表现

### 目标

验证道具是否真的改善决策，保持逻辑和2D层一致，只做3D表现适配。

### 道具范围

1. 扫描雷达
2. 时间延长

### 开发内容

- 复用道具库存逻辑，适配 3D 场景调用
- 扫描雷达：触发后，所有外星人目标播放轮廓闪烁高亮，持续 3 秒（世界空间效果，不是UI效果）
- 时间延长：触发后立即增加 30 秒剩余时间，HUD 正确更新
- 道具按钮UI复用现有 `ui_hud_pve.gd`，不重新设计

### 产出

- 玩家可在 3D 战斗中主动使用 2 个道具

### 验收标准

- 扫描后仅外星人目标出现轮廓闪烁，平民不高亮
- 时间延长立即生效，倒计时不会提前结算
- 道具用完后 UI 状态正确灰化，无法重复点击
- 道具使用有明确音效和视觉反馈

### 场景测试

- 在“难以发现目标”的位置使用扫描，确认能明显降低找目标时间
- 在倒计时剩余 3 秒时使用时间延长，确认关卡不会提前结算失败
- 连续点击道具按钮，不会出现多次扣除次数的bug

---

## Step 6 三关配置与难度校准

### 目标

用最小内容验证难度曲线是否成立，复用现有配置资源。

### 关卡建议（对齐现有配置）

- 第 1 关：5个静止伪装目标 + 3个平民，时限 120 秒，教学型
- 第 2 关：5个静止 + 3个缓慢移动目标 + 5个平民，时限 120 秒
- 第 3 关：3个静止 + 3个移动 + 2个弱点目标 + 6个平民，时限 150 秒

### 开发内容

- 调整3D场景刷点，适配3个关卡的目标分布
- 校准三星评价规则：
  - 3星：0误伤 + 剩余时间 > 30秒
  - 2星：误伤≤1 + 剩余时间 > 10秒
  - 1星：通关即可
- 复用现有结算逻辑，只适配3D场景结算触发

### 产出

- 至少 3 关可按配置在3D场景中运行

### 验收标准

- 改配置不改代码即可改变关卡目标数量、时限、奖励
- 第 1 到第 3 关难度有递增，但不会突变
- 三星评价统计正确，和战斗过程一致

### 场景测试

- 新玩家首次试玩，第 1 关应能大概率通过（通过率 > 80%）
- 有基础说明后，第 2 关应能感受到压力但不至于立刻弃坑
- 第 3 关应让玩家开始愿意主动使用道具（道具使用率 > 50%）

---

## Step 7 新手教程 3D 适配

### 目标

确保玩家第一次进入3D场景就知道自己要干什么，复用现有教程流程。

### 开发内容

- 复用 `tutorial_flow_controller.gd`，适配3D场景的引导定位
- 开局分步提示：
  1. 滑动屏幕观察周围
  2. 找到发光眼睛的外星人
  3. 双击/点击瞄准按钮放大
  4. 长按屏息，松手开火
  5. 使用扫描道具找剩余目标
- 引导箭头在3D世界空间指向目标位置，UI层显示提示文字
- 每一步必须完成当前操作才进入下一步，失败不惩罚，无限重试

### 产出

- 1 个可完整跑通的3D新手教程

### 验收标准

- 教程步骤必须按顺序推进
- 每一步提示都和当前操作对应，箭头指向正确
- 未完成当前步骤前，下一步不提前放开
- 教程中误伤平民不扣血，避免新手挫败

### 场景测试

- 找 1 个没接触过项目的人试玩
- 不额外口头说明，只看教程能否在 2 分钟内完成第一枪
- 如果在 30 秒内仍不知道怎么开枪，说明提示位置/文案要改

---

## Step 8 结算与金币成长（逻辑复用）

### 目标

让单局结果能反馈到成长，形成继续玩的理由，现有逻辑已存在，只做3D适配。

### 开发内容

- 通关 / 失败结算面板复用 `ui_panel_result.gd`
- 统计数据：命中率、误伤次数、通关时长、基础奖励、时间奖励分开展示
- 金币奖励正确发放到 `InventoryService`
- 升级入口复用 `ui_panel_upgrade.gd`，MVP先开放2项升级：
  1. 瞄准稳定性：降低镜头抖动
  2. 瞄准倍率：提高最大缩放倍数
- 升级后数值正确生效到下一局

### 产出

- 3D 战斗结果可以沉淀到玩家成长

### 验收标准

- 关卡基础奖励与时间奖励分开展示
- 命中率、误伤次数统计正确
- 升级后下一关能感受到轻微正反馈
- 金币数值跨局持久化正确，重启游戏不丢失

### 场景测试

- 通关 3 局后，玩家金币累计正确
- 升级一次稳定性后，瞄准抖动有可感知变化
- 故意打得很差（3次误伤失败）和打得很好（0误伤快速通关），结算奖励差异明显可见

---

## Step 9 PVP 本地 mock 3D 适配

### 目标

先验证 PVP 回合流程在3D场景下是否成立，不接真网络，复用现有 mock 控制器。

### 开发内容

- 创建 `scenes/pvp/pvp_mock_room_3d.tscn` 场景
- 复用 `pvp_mock_room_controller.gd` 逻辑，只适配3D表现：
  - 本地房间模拟
  - 假对手状态
  - 强回合制切换
  - 姿势切换（站立/蹲伏/横躺 3个MVP姿势）
  - 姿势切换时世界空间漂浮字幕即时广播
  - 射击动作提交后，等待 mock 服务端裁定返回结果
  - 命中结果返回后，创建 Decal 弹孔贴花 + 命中反馈
  - 断线重连假恢复入口
- 弹孔使用 Decal 节点，投射到墙体/掩体表面

### 产出

- 能完成一场本地模拟 3D PVP

### 验收标准

- 回合切换清晰，不会双方同时操作
- 姿势切换后漂浮字幕能立即出现
- 子弹命中结果不直接由本地表现定死，而是等 mock 裁定返回
- Decal 弹孔贴花位置正确，投影到墙体表面，不出现穿模/悬空
- 弹孔在对局内永久存在，回合切换不消失

### 场景测试

- 连续打满 3 回合，状态不会乱，血量/子弹数正确
- 中途触发“断线”，重新进入后能恢复到一个合理状态
- 相同射击位置，弹孔贴花位置一致，不出现随机偏移

---

## Step 10 平台适配层、激励视频 mock、埋点对齐

### 目标

把未来一定会接入的平台差异和广告差异隔离掉，现有骨架已存在，只做流程打通验证。

### 开发内容（复用现有接口，不新增接口名）

- `AdsService`：验证 `show_rewarded_ad(placement)` 接口，1秒后返回观看成功
- `PlatformService`：验证 mock 登录/获取用户信息接口
- `ShareService`：验证 mock 分享接口，弹出“分享成功”提示
- `SaveService`：验证本地存档/读档接口，跨场景数据不丢失
- `AnalyticsService`：验证埋点接口，所有核心事件正确打印日志
- 激励视频触发点：
  1. 结算页奖励翻倍
  2. 失败后复活继续
- 广告失败兜底：返回失败时提示“广告加载失败”，不阻塞主流程

### 产出

- 主业务流程不直接依赖具体平台 SDK，所有平台调用都走适配层

### 验收标准

- 战斗结算中可触发一次 mock 激励视频
- 观看成功后正确发放双倍奖励
- 模拟广告失败时，系统有兜底提示但不阻塞主流程
- 所有必做埋点事件都能正确触发并记录
- 切换 `platform_adapter_mock`/`platform_adapter_wechat`/`platform_adapter_douyin` 时，主流程不需要修改代码

### 场景测试

- 通关后点击“奖励翻倍”，1 秒后返回成功，金币翻倍
- 人为模拟广告失败，确认可以正常点击“返回主页”不卡死
- 登录 / 分享 / 存档接口在菜单中可正常调用，返回mock结果正确
- 一局游戏下来，埋点日志覆盖教程开始、第一关进入、射击、命中、误伤、通关/失败、结算所有节点

---

## 五、阶段验收标准

完成 MVP 不看“写了多少系统”，只看下面 7 件事是否成立：

1. 玩家能在 1 分钟内理解 3D 场景下的核心操作
2. 第 1 关能稳定完成（新玩家通过率 > 80%）
3. 3 关难度逐步抬升，没有突然卡关
4. 扫描道具确实帮助找到目标，时间延长确实能救场
5. 结算能驱动玩家继续玩下一关，升级有可感知正反馈
6. PVP mock 能完整走完一场3D对战，回合逻辑清晰
7. 平台mock和埋点流程跑通，业务代码和平台代码完全解耦

如果这 7 条都成立，就可以进入第二阶段扩展；如果不成立，优先回头调3D镜头、手感、关卡和目标识别度，不要急着加功能。

---

## 六、建议埋点（对齐现有AnalyticsService接口）

### 必做埋点（通过 `CoreEventBus.log_event` 触发）

- `tutorial_start` 教程开始
- `tutorial_complete` 教程完成
- `level_enter` 关卡进入，带参数 level_id
- `level_complete` 关卡完成，带参数 level_id/used_time/hit_rate/miss_count
- `level_fail` 关卡失败，带参数 level_id/fail_reason
- `shot_fired` 开枪
- `target_hit` 命中目标
- `wrong_hit` 误伤平民
- `item_used` 道具使用，带参数 item_id
- `pvp_round_start` PVP回合开始
- `pvp_round_end` PVP回合结束
- `ad_rewarded_watched` 激励视频观看完成

### 先看哪几个数据

优先看这 5 个：

1. 教程完成率
2. 第 1 关完成率
3. 单局平均时长
4. 平均误伤次数
5. 道具使用率

如果第 1 关完成率低，先看教程引导和3D目标识别度；如果道具使用率低，先看按钮露出位置和道具收益感；如果单局时长过长，先看目标数量和移动速度。

---

## 七、命名规范（完全对齐现有工程命名，不做修改）

命名规范沿用现有工程约定，只补充3D相关规则，不改变已有接口/文件命名。

### 1. 目录命名

- 目录统一使用：`lower_snake_case`（现有目录已符合，不调整）

现有目录结构保持不变：
```text
res://
  scenes/
    core/
    menu/
    pve/
    pvp/
    tests/
    tutorial/
    ui/
  scripts/
    analytics/
    core/
    menu/
    network/
    platform/
    pve/
    pvp/
    tests/
    tutorial/
    ui/
  configs/
    platform/
    pve/
    skin/
    weapon/
```

### 2. 场景文件命名

- 场景文件统一：`模块_功能_名称.tscn`（现有命名已符合，不调整）
- **3D场景统一加 `_3d` 后缀**，和现有脚本命名保持一致

示例（现有+新增）：
- `core_game_root.tscn`（保持不变）
- `menu_main_menu.tscn`（保持不变）
- `pve_battle_main.tscn`（2D验证层，保持不变）
- `pve_battle_main_3d.tscn`（新增3D战斗场景）
- `pve_level_city_01.tscn`（3D关卡分块场景）
- `pvp_mock_room.tscn`（保持不变）
- `pvp_mock_room_3d.tscn`（新增3D PVP场景）
- `ui_hud_pve.tscn`（保持不变）
- `ui_panel_result.tscn`（保持不变）
- `tutorial_flow_intro.tscn`（保持不变）

### 3. 脚本文件命名

- 脚本文件统一：`模块_职责.gd`（现有命名已符合，不调整）
- **3D实现脚本统一加 `_3d` 后缀**，和现有工程命名一致（现有已存在 `battle_core_3d.gd`/`pve_battle_controller_3d.gd`等，保持这个约定）

示例（现有+新增）：
- `core_game_state.gd`（保持不变）
- `core_event_bus.gd`（保持不变，信号命名全部保持不变）
- `pve_battle_controller.gd`（2D基类，保持不变）
- `pve_battle_controller_3d.gd`（3D实现，已存在）
- `pve_target_controller.gd`（保持不变）
- `pve_target_controller_3d.gd`（3D实现，已存在）
- `camera_controller.gd`（保持不变）
- `camera_controller_3d.gd`（3D实现，已存在）
- `pvp_mock_room_controller.gd`（保持不变）
- `platform_service.gd`（保持不变，所有平台接口名不变）
- `ads_service.gd`（保持不变，广告接口名不变）
- `analytics_service.gd`（保持不变）

### 4. 节点命名

- 节点统一使用：`PascalCase`（现有约定保持不变）

3D场景固定节点结构（强制遵守，避免挂载混乱）：
```
BattleRoot3D
├─ LevelRoot          # 地图/静态碰撞/分块场景
├─ ActorRoot          # 所有目标/平民/玩家单位
├─ DecalRoot          # 弹孔/贴花/投影特效
├─ FxRoot             # 世界空间特效（枪口火焰/命中火花/扫描波纹）
├─ AudioRoot          # 3D音效音源
└─ UiRoot             # UI层（HUD/瞄准镜/弹窗/引导）
   ├─ HudLayer
   ├─ PopupLayer
   ├─ GuideLayer
   ├─ LoadingLayer
   └─ DebugLayer
```

常用节点命名示例：
- `AimCamera3D`
- `TargetSpawnPoint`
- `CivilianSpawnPoint`
- `WeakPointCollider`
- `DecalBulletHole`
- `PathPatrol`
- `FloatingText`

### 5. 配置文件命名

- 配置统一使用：`cfg_模块_名称`（现有命名已符合，不调整）
- 继续优先使用 `Resource(.tres)` 格式，方便Godot编辑器内配置

现有配置保持不变：
- `cfg_pve_level_001.tres/json`
- `cfg_pve_weapon_default.tres`
- `cfg_weapon_default.tres`
- `cfg_platform_channels.json`

### 6. UI 层级命名

保持现有约定不变：
- `HudLayer`：常驻战斗信息（血条/时间/子弹/道具按钮）
- `PopupLayer`：所有弹窗（结算/升级/商店/设置）
- `GuideLayer`：教程引导/箭头/提示文字
- `LoadingLayer`：加载遮罩
- `DebugLayer`：调试信息/调参面板

规则：
- 不要把临时提示散落在各节点里，统一归到对应层级
- 世界空间3D提示（如漂浮字幕）放在 `FxRoot`，不要放到UI层

### 7. 动画命名

- 动画统一：`行为_状态`（现有约定保持不变）

3D动画补充示例：
- `aim_idle`
- `aim_zoom_in`
- `aim_hold_breath`
- `target_idle_disguised`
- `target_move_slow`
- `target_reveal_weakpoint`
- `target_hit`
- `target_die`
- `decal_bullet_hole_spawn`
- `fx_scan_pulse`
- `ui_panel_open`
- `ui_panel_close`

### 8. 音效命名

- 音效统一：`类别_事件`（现有约定保持不变）

3D音效补充示例：
- `sfx_shot_fire`（世界空间3D音效）
- `sfx_shot_hit_target`
- `sfx_shot_hit_wall`
- `sfx_shot_hit_wrong`
- `sfx_scan_activate`
- `sfx_time_extend`
- `sfx_weakpoint_reveal`
- `ui_button_click`（2D UI音效）
- `ui_result_win`
- `amb_city_day`（环境音）

### 9. 信号命名

- 信号统一使用过去式或完成态，表示“事件已发生”（现有CoreEventBus信号全部保持不变，不新增不修改）

现有信号保持不变，3D事件通过现有信号透传，不新造信号：
- `shot_fired`
- `target_hit`
- `target_missed`
- `civilian_hit`
- `round_started`
- `round_finished`
- `battle_finished(result: Dictionary)`
- `reward_granted`
- `ad_reward_granted`
- `analytics_logged(event_name: String, payload: Dictionary)`

### 10. 碰撞层命名（3D版本）

固定8层，和2D层语义保持一致：

| 层号 | 层名 | 说明 |
|------|------|------|
| 1 | `world` | 地面/静态墙体/不可穿透建筑 |
| 2 | `target` | 外星人目标（可击杀） |
| 3 | `civilian` | 普通市民（误伤惩罚） |
| 4 | `obstacle` | 可破坏掩体/遮挡物 |
| 5 | `interactive` | 可交互物（道具拾取/开关） |
| 6 | `bullet_decal` | 弹孔贴花（不参与碰撞检测，仅渲染） |
| 7 | `pvp_actor` | PVP玩家单位 |
| 8 | `scan_only` | 扫描标记/高亮区域（仅射线扫描检测，普通射击不命中） |

规则：
- 目标和误伤对象必须分层，碰撞掩码配置正确
- 弹孔贴花所在层不加入任何碰撞掩码，避免干扰命中检测
- 扫描射线额外检测 `scan_only` 层，普通射击射线不检测该层

---

## 八、现有接口对齐清单（全部保留，不改名）

以下接口/Autoload在现有工程中已存在，本阶段**完全保留命名和调用方式**，仅补充3D实现，不做重构改名：

| 类型 | 名称 | 用途 | 本阶段处理 |
|------|------|------|------------|
| Autoload | `/root/CoreEventBus` | 全局事件总线 | 保持不变，所有事件走它 |
| Autoload | `/root/CoreGameState` | 全局游戏状态/关卡进度/玩家数据 | 保持不变 |
| Autoload | `/root/PlatformService` | 平台适配入口 | 保持不变，走现有Adapter体系 |
| Autoload | `/root/AnalyticsService` | 埋点上报 | 保持不变 |
| Autoload | `/root/NetworkManager` | 网络连接管理 | 保持接口形状，PVP mock复用它的接口定义 |
| Autoload | `/root/InventoryService` | 金币/道具/库存管理 | 保持不变 |
| Autoload | `/root/WeaponManager` | 武器/皮肤/升级管理 | 保持不变 |
| Autoload | `/root/ResourceManager` | 资源加载管理 | 保持不变 |
| 服务接口 | `AdsService.show_rewarded_ad(placement: String) -> Dictionary` | 激励视频 | 保持签名不变，mock实现已存在 |
| 服务接口 | `PlatformService.login() -> Dictionary` | 平台登录 | 保持签名不变 |
| 服务接口 | `PlatformService.share(content: Dictionary) -> Dictionary` | 分享 | 保持签名不变 |
| 服务接口 | `SaveService.save(data: Dictionary) -> bool` | 存档 | 保持签名不变 |
| 服务接口 | `SaveService.load() -> Dictionary` | 读档 | 保持签名不变 |
| 服务接口 | `AnalyticsService.track_event(event_name: String, payload: Dictionary)` | 埋点 | 保持签名不变 |

---

## 九、下一步建议

严格按照这个顺序推进，不要跳步：

1. 先搭 3D 场景骨架，定死镜头参数（这是所有3D资产挂载的基础）
2. 再做 3D 地图刷点和射击射线手感
3. 然后接三类目标行为，验证识别玩法
4. 然后做道具和三关难度校准
5. 补教程适配
6. 逻辑层直接复用现有结算/成长/平台mock，不需要重写
7. 最后适配PVP mock 3D场景

核心原则：**玩法逻辑层已经在2D验证层跑通，本阶段只做3D表现层迁移和手感校准，不重构逻辑接口，不改名。** 所有3D实现都加`_3d`后缀，和2D验证层并存，方便对照调手感。
