from __future__ import annotations

from pathlib import Path

from common import find_project_root
from doc_baseline_extractor import build_current_baseline
from asset_contract_builder import build_asset_contract
from test_regression_mapper import build_test_regression_matrix
from common import write_text


def main() -> int:
    here = Path(__file__).resolve()
    root = find_project_root(here)
    out_dir = root / "project-execution-retro" / "automation" / "outputs"

    # 1) 文档口径
    write_text(out_dir / "current_baseline.md", build_current_baseline(root))

    # 2) 资产接入合同
    csv_text, md_text = build_asset_contract(root)
    if csv_text:
        write_text(out_dir / "asset_integration_contract.csv", csv_text)
    write_text(out_dir / "asset_integration_contract.md", md_text)

    # 3) 测试回归矩阵
    write_text(out_dir / "test_regression_matrix.md", build_test_regression_matrix(root))

    print("[ok] outputs:")
    print(f"- {out_dir / 'current_baseline.md'}")
    print(f"- {out_dir / 'asset_integration_contract.csv'}")
    print(f"- {out_dir / 'asset_integration_contract.md'}")
    print(f"- {out_dir / 'test_regression_matrix.md'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

