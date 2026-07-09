# women 外星人 3D 弱点显隐 / emissive 开关实现方案

## 目标

只实现最小可用版本：

1. `弱点平时隐藏`
2. `窗口打开时显示`
3. `同时切换 emissive 强度`

不做：

- 连续脉冲动画
- 呼吸式亮灭
- 复杂 shader 过渡
- 多段动画联动

这版是“状态开关方案”，不是“动画方案”。

---

## 对齐当前边界

当前项目边界已经确认：

- 美术只先做 `头部轮廓 + 肩袖轮廓 + 腰侧亮线`
- 程序只做 `弱点显隐 / emissive 开关`
- `civilian` 只补 `饰品反光类假线索`

所以程序实现的重点不是“让弱点演得更复杂”，而是：

- 把 `weakpoint target` 的窗口状态做清楚
- 把 women 外星人的 `腰侧亮线` 做成弱点表现
- 保证 imported mesh 和占位 mesh 都能跑

### 当前预览命名

当前预览和验收场景统一使用：

- `平民`
- `可疑平民`
- `潜伏者`
- `显形者`
- `裂隙体`

其中：

- `裂隙体` 对应当前 `weakpoint_open` 的危险态
- `显形者` 对应特征更明显、但未进入裂隙态的目标

---

## 当前代码基础

当前 `scripts/pve/pve_target_controller_3d.gd` 已经有现成挂点：

- `weakpoint_mesh`
- `core_mesh`
- `halo_mesh`
- `accent_mesh`
- `weakpoint_material`
- `accent_material`
- `halo_material`

并且当前 `_update_visual()` 里已经有：

- `weakpoint_open`
- `weakpoint_mesh.visible = weakpoint_open`
- `core_mesh.visible = weakpoint_open`
- `weakpoint_material.emission = ...`

这说明功能并不是“从零开始”，而是：

- 从“旧弱点外观逻辑”
- 收敛成“women 版腰侧亮线 + emissive 开关”

同时，当前 `women1 / women2` 还是单 mesh 资产，所以程序还承担一层 `helper fallback`：

- 自动补 `AccentMesh`
- 自动补 `WeakpointMesh`
- 自动补 `CoreMesh`
- 自动补 `HaloMesh`

这层 fallback 当前已经调整为：

- helper 放在角色 `正上方`
- 更像程序标签层
- 不再放在角色后方

---

## 推荐实现策略

## 一层结构

把 women 弱点只收敛成 3 层：

1. `显隐层`
- `weakpoint_mesh`
- `core_mesh`

2. `发光层`
- `accent_material`
- `weakpoint_material`

3. `氛围层`
- `halo_material`

其中：

- `显隐层` 是主逻辑
- `发光层` 是确认逻辑
- `氛围层` 是辅助，不是必须大做

---

## 节点职责建议

### `accent_mesh`

角色常驻可见的 women 特征件。

建议用途：

- 腰侧亮线所在的基底结构
- 平时低亮度可见
- 开窗时亮度抬升

建议：

- 不隐藏
- 只切 emissive 强度

### `weakpoint_mesh`

弱点窗口出现时的显性件。

建议用途：

- 腰侧亮线强化件
- 或锁骨下短线强化件

建议：

- 平时 `visible = false`
- 开窗时 `visible = true`
- 当前 `裂隙体` 预览里承担 `白色椭圆` 的识别职责

### `core_mesh`

比 `weakpoint_mesh` 更小、更亮的核心点。

建议用途：

- 只在窗口打开时提供一个“你现在可以打”的确认点
- 当前版本中已不再强调“单独红球”是唯一主视觉
- 更推荐与整组 helper 的危险感同步联动

建议：

- 平时 `visible = false`
- 开窗时 `visible = true`
- 比 `weakpoint_mesh` 更亮，但面积更小

### `halo_mesh`

只做极轻的辅助氛围。

建议用途：

- 开窗时给一点弱光外扩

建议：

- 平时隐藏或 alpha 为 0
- 开窗时显示，但强度要低
- 不要做成目标外整圈大光圈
- 当前 `裂隙体` 方案允许把 halo 提升成 `外沿光晕闪烁`

---

## 状态定义

建议把 women 弱点逻辑明确成两个状态。

### 关闭态

条件：

- `behavior_type != "weakpoint"`
- 或 `weakpoint_open == false`

表现：

- `weakpoint_mesh.visible = false`
- `core_mesh.visible = false`
- `halo_mesh.visible = false` 或 alpha 很低
- `accent_material.emission_enabled = true`
- `accent_material.emission = very_low`
- `weakpoint_material.emission = Color.BLACK`

视觉目标：

- 只让玩家觉得“腰侧有一点材质特征”
- 不让玩家觉得“这里明显就是弱点”

### 打开态

条件：

- `behavior_type == "weakpoint"`
- 且 `weakpoint_open == true`

表现：

- `weakpoint_mesh.visible = true`
- `core_mesh` 不再作为唯一主视觉
- `halo_mesh.visible = true`
- `accent_material.emission` 提升
- `weakpoint_material.emission` 提升
- `halo_material.emission` 低强度开启

视觉目标：

- 玩家一眼看出“弱点现在打开了”
- 但仍然符合 women 方案，不是旧版胸口大红点

### 当前裂隙体口径

当前 `裂隙体` 已收敛成下面这版：

- 整组 helper 一起进入 `红黑危险感`
- `weakpoint_mesh` 保留白色椭圆识别
- `halo_mesh` 提供外沿光晕闪烁
- 不再依赖“一颗红球本身”来承担全部信息

---

## 推荐颜色与强度

正式 women 资产仍以轮廓与结构为主，但当前程序 fallback / 预览允许更明显的颜色区分。

### 常驻 accent

- 颜色：冷青 / 冷白蓝
- 强度：低
- 目的：只提供结构识别

建议值思路：

- `accent_material.emission = Color(0.10, 0.38, 0.52) * 0.06~0.10`

### 裂隙体打开态

- 颜色：`红黑危险感 + 白色椭圆`
- 强度：中高
- 目的：明确告诉玩家现在是射击窗口，并与其他类型明显区分

建议值思路：

- `accent_material.albedo_color` 压到深红黑
- `weakpoint_material` 保留白色椭圆
- `halo_material` 做红色外沿光晕
- `flicker_ratio` 用不规则跳闪，不做平滑呼吸灯

### civilian 假线索

- 不用这套 `红黑危险感 + 白色椭圆` 的裂隙体配色
- 用更像饰品反光的暖白 / 金属反光 / 暖金色

这样能把：

- 真弱点
- 假线索

从色相上拉开。

---

## 当前代码建议怎么改

## 核心原则

不要再让 `weakpoint_mesh` 看起来像“胸口外挂球”。

应改成：

- `accent_mesh` 是 women 腰侧常驻结构
- `weakpoint_mesh` / `core_mesh` 是窗口打开时的短时强化件

## `_update_visual()` 建议收敛

当前 `_update_visual()` 已经很复杂，建议不要继续加新分支，而是提取一个专门方法：

- `_apply_target_weakpoint_visual(weakpoint_open: bool, highlighted: bool, scan_burst_active: bool, scan_burst_ratio: float)`

这个方法只管：

- `weakpoint_mesh/core_mesh/halo_mesh` 的显隐
- `accent_material/weakpoint_material/halo_material` 的 emissive

这样能把 women 弱点逻辑从大坨 `_update_visual()` 里拆出来。

## 推荐伪代码

```gdscript
func _apply_target_weakpoint_visual(weakpoint_open: bool) -> void:
	if accent_mesh != null:
		accent_mesh.visible = true

	if weakpoint_mesh != null:
		weakpoint_mesh.visible = weakpoint_open

	if core_mesh != null:
		core_mesh.visible = weakpoint_open

	if halo_mesh != null:
		halo_mesh.visible = weakpoint_open

	accent_material.emission_enabled = true
	weakpoint_material.emission_enabled = true
	halo_material.emission_enabled = weakpoint_open

	if weakpoint_open:
		accent_material.emission = Color(0.22, 0.82, 1.0) * 0.22
		weakpoint_material.emission = Color(0.52, 1.0, 0.96) * 0.36
		halo_material.emission = Color(0.18, 0.72, 1.0) * 0.10
	else:
		accent_material.emission = Color(0.10, 0.38, 0.52) * 0.08
		weakpoint_material.emission = Color.BLACK
		halo_material.emission = Color.BLACK
```

---

## imported mesh 适配要求

当前脚本已经会找这些名字：

- `AccentMesh`
- `WeakpointMesh`
- `CoreMesh`
- `HaloMesh`

这很好，说明最小接入标准已经存在。

程序侧只需要继续坚持这套命名，不要再加新命名规范。

### 给美术的最小要求

women 外星人资源里只需要保证：

- `AccentMesh`
  - 腰侧常驻亮线结构
- `WeakpointMesh`
  - 开窗强化件
- `CoreMesh`
  - 更小更亮的中心确认点
- `HaloMesh`
  - 很轻的外扩层

如果缺其中某个：

- `HaloMesh` 可以没有
- `CoreMesh` 最好有
- `AccentMesh` 和 `WeakpointMesh` 最关键

### 当前 fallback 补充规则

当导入资产仍为单 mesh 时：

- helper 顶部堆叠显示
- `平民 / 可疑平民 / 潜伏者 / 显形者 / 裂隙体` 用不同颜色和组合做分类
- `裂隙体` 使用整组 helper 跳闪，而不是单一球体

---

## billboard / 旧贴图兼容

当前脚本里还有：

- `main_billboard`
- `overlay_billboard`
- `TEX_ALIEN_WEAKPOINT_OPEN`

这套最好不要继续扩功能。

建议：

- 仅用于占位兼容
- women 方案的主要弱点逻辑放在 3D mesh + emissive

也就是说：

- `billboard` 不再承担“核心识别表达”
- 只做 fallback

---

## 和扫描状态的关系

扫描状态当前会抬亮一大批材质，这里要注意不要让扫描把弱点逻辑淹没。

建议规则：

### 扫描开启但弱点未开

- `accent_material` 可以略提亮
- `weakpoint_mesh` 仍隐藏
- `core_mesh` 仍隐藏

### 扫描开启且裂隙体激活

- 允许扫描进一步提亮 `accent_material`
- 但 `weakpoint_open` 仍是唯一决定 `weakpoint_mesh/core_mesh.visible` 的条件

也就是说：

- 扫描能“更容易看见”
- 但不能“替代窗口打开”

---

## civilian 假线索处理

因为当前边界已经定了：`civilian` 只补饰品反光类假线索。

所以程序侧不要给 civilian 上任何类似真实弱点的显隐件。

civilian 只建议：

- `accent_material.emission_enabled = has_false_clue_active()`
- 颜色用暖白 / 金属反光色
- 只亮饰品区域，不亮身体结构

不要让 civilian 出现：

- 腰侧亮线显隐
- core 点
- halo

否则真假线索会混掉。

---

## 验收标准

程序实现完成后，至少应满足：

1. `weakpoint target`
- 关闭态时，看得到 women 结构特征，但看不出明确可击点
- 打开态时，腰侧亮线和弱点件明显出现

2. `static / moving target`
- 没有窗口件显隐
- 只保留轮廓和材质识别

3. `civilian`
- 只出现饰品反光类假线索
- 不出现真实弱点件

4. `扫描`
- 能辅助看到弱点
- 但不能绕过 `weakpoint_open`

---

## 最小落地顺序

推荐程序按这个顺序做：

1. 把 women 弱点视觉提取成单独方法
2. 收敛 `weakpoint_mesh/core_mesh/halo_mesh` 的显隐逻辑
3. 收敛 `accent_material/weakpoint_material/halo_material` 的 emissive 值
4. 确保 civilian 不会走真实弱点显隐
5. 最后再调扫描时的亮度叠加

---

## 一句话总结

这版程序实现的关键不是“做更炫的弱点动画”，而是：

`把 women 外星人的弱点做成一个清楚、便宜、稳定的显隐开关；在当前单 mesh fallback 里，再用顶部 helper 分类和裂隙体红黑光晕跳闪，把状态区分拉清楚。`
