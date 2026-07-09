# 《第一阶段 MVP 美术收口清单》

## 1. 使用原则
本清单严格遵循《第一阶段 MVP 开发清单、验收标准与命名规范（2.5D玩法+3D画面对齐版）》。

本阶段目标不是继续扩素材，而是：

1. 从现有素材中收口出一套 **MVP 最小可用集**
2. 只服务 Step 1 ~ Step 5 的核心验证
3. 把美术准备从“继续扩展”切换到“支持 3D 占位接入”

核心边界：

- 不做大规模正式美术导入
- 不做第二阶段内容
- 不做完整商业化视觉升级
- 先验证 3D 场景、识别、射击、道具、教程的基本成立

---

## 2. 当前准备度判断

### 2.1 已基本充足

以下内容对 MVP 已经足够：

1. HUD / UI 组件
2. 扫描 / 命中 / 误伤反馈
3. 商店 / 武器库界面方向
4. 外星人 / 平民状态设计方向
5. 环境障碍物视觉方向
6. 主菜单 / 战斗 / 教程 / 结算 / PVP mock 页面方向

### 2.2 还需要补“最小 3D 占位”

真正还没落到 MVP 里的，不是“设计方向”，而是：

1. 角色 3D 占位表现
2. 武器 3D 占位表现
3. 关卡最小 3D 场景占位
4. 世界空间扫描 / 命中 / 挡弹最小表现
5. Decal / 贴花占位表现

### 2.3 结论

当前阶段不建议继续横向扩素材。  
更合理的方式是：**收口现有素材 -> 整理 MVP 素材包 -> 开始按 Step 1 ~ 5 实施接入。**

---

## 3. 现有素材分级

### A 类：直接可用于 MVP 接入

这些内容可以直接进入 MVP 验证层，不需要继续设计：

#### HUD / UI

- `hud-scope-frame.svg`
- `hud-target-lock-frame.svg`
- `hud-health-bar.svg`
- `hud-time-bar.svg`
- `icon-scan-radar.svg`
- `icon-time-extend.svg`
- `menu-key-art.jpg`
- `loading-scope-art.jpg`

#### 角色状态参考

- `alien-disguised-idle.svg`
- `alien-moving-profile.svg`
- `alien-weakpoint-open.svg`
- `alien-scan-highlight.svg`
- `civilian-calm-idle.svg`
- `civilian-false-clue-glint.svg`

#### 战斗反馈

- `fx-scan-pulse.svg`
- `fx-hit-confirm.svg`
- `fx-wrong-hit-alert.svg`
- `fx-cover-impact.svg`
- `fx-muzzle-flash.svg`
- 三组分帧：`scan-pulse` / `hit-confirm` / `wrong-hit-alert`

#### 环境障碍参考

- `env-wall-corner.svg`
- `env-street-lamp.svg`
- `env-parked-van.svg`
- `env-billboard.svg`

---

### B 类：需要转成 3D 占位版

这些不是继续画新图，而是要转成 Godot 里能用的最小 3D 表现：

1. 外星人占位体
2. 平民占位体
3. 弱点区节点 / 弱点碰撞区
4. 扫描高亮材质切换
5. 一套最小武器占位体
6. 基础掩体体块
7. Decal / 弹孔占位
8. 世界空间扫描轮廓效果

---

### C 类：延后到第二阶段

以下内容本阶段不做：

1. 正式高模角色
2. 正式完整武器模型库
3. 完整城市场景模块库
4. 全量皮肤生产
5. 高品质世界空间粒子系统
6. 大规模正式商业化 UI 深化

---

## 4. 已开始执行的收口动作

为了避免素材继续分散，当前已经在 Godot 项目内建立统一入口：

- 目录：`狙击外星人升级版/assets_mvp_placeholder/`

当前已整理进去的最小素材组：

### `ui/`

- `menu-key-art.jpg`
- `loading-scope-art.jpg`
- `hud-scope-frame.svg`
- `hud-target-lock-frame.svg`
- `hud-health-bar.svg`
- `hud-time-bar.svg`
- `icon-scan-radar.svg`
- `icon-time-extend.svg`

### `characters/`

- `alien-disguised-idle.svg`
- `alien-moving-profile.svg`
- `alien-weakpoint-open.svg`
- `alien-scan-highlight.svg`
- `civilian-calm-idle.svg`
- `civilian-false-clue-glint.svg`

### `feedback/`

- `fx-scan-pulse.svg`
- `fx-hit-confirm.svg`
- `fx-wrong-hit-alert.svg`
- `fx-cover-impact.svg`
- `fx-muzzle-flash.svg`
- `scan-pulse-frame-01~05.svg`
- `hit-confirm-frame-01~05.svg`
- `wrong-hit-alert-frame-01~05.svg`

### `environment/`

- `env-wall-corner.svg`
- `env-street-lamp.svg`
- `env-parked-van.svg`
- `env-billboard.svg`

---

## 5. 下一步只推进什么

### Step 1：3D 场景骨架与镜头规范

美术只服务这 4 件事：

1. 镜头下目标可读
2. UI 镜框与 3D 相机同步
3. 近中远景辨识度成立
4. 基础光照不吞目标

#### 最小产出

- 纯色 / 简材质 3D 占位角色
- HUD 镜框叠加
- 场景基础色与光照基线

#### 业务测试

1. 连续缩放 20 次，镜头和准星不跑偏
2. 近景 / 中景 / 远景下目标仍可分辨
3. HUD 不挡主要目标区

---

### Step 2：3D 分块地图与刷点

美术只服务这 4 件事：

1. 地图有基本街区语义
2. 掩体能挡弹
3. 刷点位置可读
4. world / obstacle 区分清楚

#### 最小产出

- 地面块
- 墙体块
- 掩体体块
- 路灯 / 货车 / 广告牌最低限占位

#### 业务测试

1. 目标不会刷进墙里
2. 掩体确实挡住射线
3. 玩家能看懂哪里能藏目标

---

### Step 3：3D 观察、瞄准、射击手感

美术只服务这 5 件事：

1. 最小枪口火焰
2. 命中确认
3. 误伤确认
4. 掩体挡弹反馈
5. 画面节奏不乱

#### 最小产出

- `fx-muzzle-flash`
- `fx-hit-confirm`
- `fx-wrong-hit-alert`
- `fx-cover-impact`

#### 业务测试

1. 玩家 0.5 秒内能看懂射击结果
2. 命中和平民误伤不会混淆
3. 掩体挡弹有明确区分

---

### Step 4：三类目标行为

美术只服务这 4 件事：

1. 静止伪装
2. 缓慢移动
3. 弱点开启
4. 平民假线索

#### 最小产出

- 外星人材质切换参考
- 平民材质切换参考
- 弱点表现参考
- 移动态参考

#### 业务测试

1. 静止、移动、弱点目标体感必须不同
2. 平民假线索能误导但不过界
3. 弱点开启像“可射击窗口”

---

### Step 5：两个基础道具

美术只服务这 3 件事：

1. 扫描高亮
2. 时间延长按钮
3. 使用后成功反馈

#### 最小产出

- 扫描世界高亮基线
- 扫描按钮状态
- 时间延长按钮状态

#### 业务测试

1. 使用扫描后，找目标速度明显提升
2. 倒计时快结束时，加时能明显救场
3. 道具按钮用完后状态明确

---

## 6. 现阶段禁止蔓延项

为了避免偏离 MVP，本阶段明确不做：

1. 继续扩角色种类
2. 继续扩环境种类
3. 继续扩商店 / 武器库组件库
4. 做正式高模和完整贴图库
5. 为第二阶段提前生产整套场景资源
6. 把 UI 做到商业化正式上线水平

---

## 7. 推荐推进方式

从现在开始，推进方式改为：

1. **先按 Step 验收推进**
2. **每一步只启用最小素材集**
3. **不新增不必要的美术分支**
4. **先验证玩法成立，再决定是否升级为正式资产**

---

## 8. 当前执行建议

如果继续往下做，建议立刻进入下面这一小段执行：

### 本周只做

1. `Step 1` 的镜头 + HUD 叠加验证
2. `Step 2` 的最小街区占位 + 掩体验证
3. `Step 3` 的命中 / 误伤 / 挡弹反馈验证

### 暂时不做

1. 正式角色模型
2. 正式武器模型
3. 大量场景装饰
4. 商店与武器库正式视觉深化

---

## 9. 阶段判断标准

只有当下面这 4 条都成立，才值得继续扩第二阶段资产：

1. 玩家能在 3D 里快速识别目标
2. 射击结果能被稳定理解
3. 扫描与加时真正改善决策
4. 3 关难度能用最小占位资产验证出来

如果这 4 条还没成立，就不要继续扩素材。
