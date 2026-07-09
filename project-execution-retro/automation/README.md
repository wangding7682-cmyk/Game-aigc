# 文档口径 / 资产接入 / 测试回归：一键产出工具

这套小工具把你关心的 3 件事落成可重复运行的产物：

1. **文档口径**：从现行“校准文档 + 工程说明 + 素材盘点”自动整理出当前有效口径与下次关注点。
2. **资产接入**：扫描各批素材与目录结构，生成一份“接入合同表”（CSV/Markdown），便于程序按表挂载/对照。
3. **测试回归**：从测试中心相关脚本里提取烟雾测试清单，并给出“改动 → 建议回归”的映射基线。

## 使用方式

在项目根目录运行：

```bash
python project-execution-retro/automation/run_all.py
```

运行后会在 `project-execution-retro/automation/outputs/` 生成：

- `current_baseline.md`：当前有效口径（自动汇总）
- `asset_integration_contract.csv`：资产接入合同表（可给程序直接用）
- `asset_integration_contract.md`：合同表的可读版说明
- `test_regression_matrix.md`：测试中心/烟雾测试清单与回归映射基线

## 贴近业务的“简单测试”

你可以把下面当作每轮最小回归动作：

1. 先运行脚本：`python project-execution-retro/automation/run_all.py`
2. 打开 `outputs/current_baseline.md`，确认本轮口径是否仍一致
3. 打开 `outputs/asset_integration_contract.csv`，随机抽 5 个资源，看“挂点/触发/兜底”是否能让另一人不追问就接入
4. 打开 `outputs/test_regression_matrix.md`，按你本轮改动命中的模块建议，去测试中心跑对应烟雾测试

## 说明

- 这套工具**不依赖 Git**（你的工程不是单一仓库），只依赖当前文件夹结构与现有文档/脚本。
- 资产合同表里某些字段可能会先留空（例如“具体挂点节点名”），它的目的就是把空缺显式化，让你能一眼看到哪里仍在“靠猜”。

