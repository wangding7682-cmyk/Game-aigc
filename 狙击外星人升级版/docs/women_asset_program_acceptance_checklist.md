# women1 / women2 程序接入验收清单

## 适用范围

这份清单用于程序验收 women 第一版资产接入后的状态，目标是确认：

- `allien-product-women1.glb`
- `allien-product-women2.glb`

是否已经能被当前 3D 战斗链路稳定使用，并正确支持：

- `AccentMesh`
- `WeakpointMesh`
- `CoreMesh`

以及 women 方案下的：

- 常驻腰侧结构
- 弱点显隐
- emissive 开关

---

## 当前接入现实

截至目前，`women1 / women2` 这两份资产的真实结构还是：

- 单 mesh
- 单节点 `node_0`
- 没有原生 `AccentMesh / WeakpointMesh / CoreMesh`

程序当前已经做了兼容：

1. 目标会优先加载 women 资产
2. 如果缺少关键节点，程序会自动挂 helper：
   - `AccentMesh`
   - `WeakpointMesh`
   - `CoreMesh`
   - `HaloMesh`

当前项目内对外命名统一为：

- `平民`
- `可疑平民`
- `潜伏者`
- `显形者`
- `裂隙体`

所以这份清单分两种情况验收：

1. `当前阶段`
   - 单 mesh women 资产 + 程序 helper fallback
2. `下一阶段`
   - 美术补齐真节点后的 women 正式接入

---

## 第一阶段验收

## 资源加载

- [ ] `static target` 会优先使用 `allien-product-women1.glb`
- [ ] `moving target` 会优先使用 `allien-product-women1.glb`
- [ ] `weakpoint target` 会优先使用 `allien-product-women2.glb`
- [ ] `civilian` 仍然使用 civilian 资产，不误用 women 目标资产

通过标准：

- 运行时 women 目标外轮廓已经不是旧 placeholder 的默认视觉
- `civilian` 不会误切到 women 资产

---

## helper fallback 生效

- [ ] 当 women 资产只有单 mesh 时，程序会判定为 `imported_generic_actor`
- [ ] `ImportedFeatureLayer` 会被自动创建
- [ ] 自动挂出的 `AccentMesh` 存在
- [ ] 自动挂出的 `WeakpointMesh` 存在
- [ ] 自动挂出的 `CoreMesh` 存在
- [ ] 自动挂出的 `HaloMesh` 存在
- [ ] helper 默认显示在角色 `正上方`
- [ ] helper 不再落在角色背后

通过标准：

- 即使美术尚未补真节点，也能看到 women 目标的腰侧结构和弱点开窗逻辑

失败现象：

- women 目标只剩一个单 mesh，完全没有腰侧结构件
- `weakpoint_open` 时没有任何可击确认点
- helper 仍然主要出现在角色背后

---

## women 常驻结构

- [ ] 目标常驻时能看到 `AccentMesh`
- [ ] 当前 fallback 下，`AccentMesh` 作为顶部分类标签可见
- [ ] `AccentMesh` 不会平时完全消失
- [ ] `潜伏者 / 显形者 / 裂隙体` 的顶部标签颜色有稳定差异

通过标准：

- 不开窗时，玩家能从顶部 helper 和局部颜色读到分类差异
- 不会所有目标都长成同一套积木颜色

失败现象：

- `AccentMesh` 没有出现
- 顶部标签位置杂乱，难以辨认
- 平时亮度过高，看起来像常驻弱点

---

## weakpoint 显隐

- [ ] `static target` 不显示 `WeakpointMesh`
- [ ] `moving target` 不显示 `WeakpointMesh`
- [ ] `weakpoint target` 在关闭态不显示 `WeakpointMesh`
- [ ] `weakpoint target` 在打开态显示 `WeakpointMesh`
- [ ] `weakpoint target` 在打开态显示 `WeakpointMesh`
- [ ] `裂隙体` 打开态时，整组 helper 一起进入异常闪烁
- [ ] `WeakpointMesh` 保留白色椭圆识别

通过标准：

- `weakpoint_open` 是裂隙体异常表现的触发条件
- 玩家在打开窗口时能一眼确认“现在可以打”

失败现象：

- `static / moving` 目标也出现裂隙体异常闪烁
- 窗口未开时，`WeakpointMesh` 仍可见
- 裂隙体和显形者看不出明显差别

---

## emissive 逻辑

- [ ] `AccentMesh` 常驻低亮 emissive
- [ ] `显形者` 比 `潜伏者` 更亮、更容易识别
- [ ] `裂隙体` 时整组 helper 进入 `红黑危险感`
- [ ] `裂隙体` 时 `WeakpointMesh` 保留白色椭圆
- [ ] `裂隙体` 时 `HaloMesh` 有外沿光晕闪烁
- [ ] 发光颜色与 `可疑平民` 的暖金误导色能区分

通过标准：

- emissive 既能负责分类，也能负责状态确认
- `裂隙体` 看起来像一整组危险特效，而不是单独一颗球在闪

失败现象：

- 开窗亮度变化不明显
- `HaloMesh` 没有形成明显外沿光晕
- 发光颜色和 `可疑平民` 的暖色误导太像

---

## civilian 假线索

- [ ] `平民` 后方球体为白色
- [ ] `可疑平民` 后方球体为白色，并带黄色块
- [ ] `平民 / 可疑平民` 不出现裂隙体整组跳闪
- [ ] `可疑平民` 只表现为暖色误导，不表现真实危险态

通过标准：

- civilian 会误导，但不会像真目标

失败现象：

- civilian 出现和 women 一样的腰侧亮线
- civilian 也有 core 点
- 真假线索都用同一冷青色

---

## 扫描联动

- [ ] 扫描开启但弱点未开时，`AccentMesh` 可略提亮
- [ ] 扫描开启但弱点未开时，`WeakpointMesh` 仍隐藏
- [ ] 扫描开启且 `裂隙体` 激活时，亮度可进一步提升
- [ ] 扫描不能绕过 `weakpoint_open`

通过标准：

- 扫描帮助“看见”
- 但不替代“窗口打开”

失败现象：

- 扫描一开，所有 weakpoint target 都像已经打开弱点

---

## 姿态与表现约束

- [ ] women 目标仍然保留基础站姿/移动姿态
- [ ] `weakpoint_open` 不再触发大幅特殊 pose
- [ ] 不出现明显旧版弱点脉冲缩放感
- [ ] 视觉重点落在显隐与 emissive，而不是动作演出

通过标准：

- 这版看起来像“弱点被打开”
- 而不是“角色开始表演弱点动画”

---

## 第二阶段验收

这一部分在美术补齐真节点后使用。

## 节点命名

- [ ] `AccentMesh` 真节点存在
- [ ] `WeakpointMesh` 真节点存在
- [ ] `CoreMesh` 真节点存在
- [ ] 如有 `HaloMesh`，其命名正确
- [ ] 节点挂在 imported 角色层级中，而不是额外挂在错误根节点下

通过标准：

- `_find_mesh_instance(imported_visual_root, "...")` 能直接找到真节点

失败现象：

- 程序仍回退到 helper fallback
- 真节点明明有，但命名不对导致找不到

---

## 真节点优先

- [ ] 当资产自带真节点时，不再依赖 helper fallback 才能表现 women 逻辑
- [ ] 真节点位置优于程序 helper 的默认位置
- [ ] 真节点材质能正确吃到：
  - `accent_material`
  - `weakpoint_material`
  - `halo_material`

通过标准：

- 真节点成为主表现
- helper 只保留 fallback 价值

失败现象：

- 真节点存在，但程序仍只显示 helper
- 真节点位置正确，但材质没被接管

---

## women1 / women2 分工

- [ ] `women1` 更适合 `static / moving`
- [ ] `women2` 更适合 `weakpoint`
- [ ] 两者 silhouette 有差异，但仍属于同一 women 家族
- [ ] `weakpoint target` 的腰侧区域比 `women1` 更适合挂弱点件

通过标准：

- 不是两份完全一样的皮
- 也不是风格断裂的两套角色

---

## 建议验收顺序

1. 先验 `资源是否加载正确`
2. 再验 `helper fallback 是否挂出`
3. 再验顶部 helper 分类是否符合 5 类命名
4. 再验 `WeakpointMesh / HaloMesh` 的裂隙体表现
5. 再验 `emissive` 颜色和强度
6. 最后验 `civilian` 假线索是否没有串味

---

## 最终通过标准

这轮 women1 / women2 程序接入通过，至少要满足：

- 目标已经优先使用 women 资产
- 就算资产还是单 mesh，也能自动挂出 `AccentMesh / WeakpointMesh / CoreMesh`
- helper 已经稳定放在角色正上方
- `裂隙体` 的开窗逻辑已经稳定落成红黑危险感 + 外沿光晕闪烁
- `civilian` 不会误用真实弱点结构
- 视觉重点落在 `分类可识别 + 状态可识别`，而不是旧版动画感

---

## 当前阶段一句话判断

如果你们现在拿第一版 women 资产来验，最关键不是“它够不够精致”，而是：

`程序是否已经能稳定把单 mesh women 资产转成可识别、可开窗、可发光确认的 women 目标。`
