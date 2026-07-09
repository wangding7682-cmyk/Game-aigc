# LLM 提示词：从设计/说明生成“接入合同”

把下面的模板复制到任意 LLM（如你团队内部工具），把“素材说明/设计板内容/需求描述”粘进去即可。

---

## 任务

请把输入内容翻译成“资产接入合同表”，每条资产/状态输出一行，字段如下：

- `asset_name`：资源名（含扩展名或逻辑名）
- `asset_path`：相对路径（如果输入未给，留空）
- `asset_type`：weapon/icon/hud/effect/anim/character/ui-kit/environment/decal/other
- `intended_scene`：建议挂载场景（例如 `scenes/ui/ui_hud_pve.tscn`），不确定就给候选
- `mount_node`：建议挂点节点名（例如 `HudLayer/root/scope_draw_layer`），不确定就给候选
- `trigger`：触发条件（变量/状态/事件）
- `replace_timing`：替换时机（进入瞄准、命中后、扫描启动等）
- `fallback`：资源缺失时的兜底表现
- `acceptance_test`：贴近业务的快速测试（玩家能否读懂、程序能否挂上）

输出要求：

1. 先输出 CSV（第一行是表头）
2. 再输出“缺口清单”：哪些字段经常空、为什么空、下一步找谁补
3. 不要写泛泛建议，要写可执行字段

---

## 输入

（把素材 README、设计说明、或你的临时需求粘贴在这里）

