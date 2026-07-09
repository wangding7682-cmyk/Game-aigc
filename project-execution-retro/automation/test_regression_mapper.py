from __future__ import annotations

import re
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Tuple

from common import find_project_root, read_text, write_text


@dataclass
class SmokeTest:
    name: str
    runner_script: str
    result_path: str


def _find_test_files(root: Path) -> Tuple[Path, Path, Path]:
    test_center = root / "狙击外星人升级版" / "scripts" / "ui" / "ui_panel_test_center.gd"
    batch_runner = root / "狙击外星人升级版" / "scripts" / "tests" / "batch_smoke_runner.gd"
    tests_dir = root / "狙击外星人升级版" / "scripts" / "tests"
    return test_center, batch_runner, tests_dir


def _parse_result_map(test_center_gd: str) -> Dict[str, str]:
    """
    从 ui_panel_test_center.gd 里解析：
      "主流程烟雾": "user://flow_smoke_result.txt"
    """
    mapping: Dict[str, str] = {}
    for m in re.finditer(r'"([^"]+)"\s*:\s*"([^"]+)"', test_center_gd):
        k, v = m.group(1).strip(), m.group(2).strip()
        if "烟雾" in k:
            mapping[k] = v
    return mapping


def _guess_runner_for_test(test_name: str, tests_dir: Path) -> str:
    """
    非严格：按文件名关键词猜 runner。
    """
    keywords = {
        "主流程烟雾": "flow_smoke_runner.gd",
        "下一关烟雾": "next_level_smoke_runner.gd",
        "完整集成烟雾": "integration_smoke_runner.gd",
        "路由守卫烟雾": "route_guard_smoke_runner.gd",
        "3D 占位烟雾": "placeholder_3d_smoke_runner.gd",
    }
    guess = keywords.get(test_name)
    if guess and (tests_dir / guess).exists():
        return str((tests_dir / guess).relative_to(tests_dir.parent.parent.parent))

    # fallback: 尝试包含关键词的任意 gd
    for gd in sorted(tests_dir.glob("*.gd")):
        if any(k in gd.name for k in ["smoke", "runner"]):
            return str(gd.relative_to(tests_dir.parent.parent.parent))
    return ""


def build_test_regression_matrix(root: Path) -> str:
    test_center, batch_runner, tests_dir = _find_test_files(root)
    lines: List[str] = []
    lines.append("# 测试回归矩阵（从测试中心脚本自动提取）")
    lines.append("")
    lines.append("这份文件的目标是：把“应该跑哪些烟雾测试”变成一份可复用映射，而不是靠记忆。")
    lines.append("")

    if not test_center.exists():
        lines.append("未找到 `ui_panel_test_center.gd`，无法提取测试中心定义。")
        return "\n".join(lines).strip() + "\n"

    tc = read_text(test_center)
    result_map = _parse_result_map(tc)

    # 从 batch_smoke_runner 提取顺序（有则以它为准）
    test_order: List[str] = []
    if batch_runner.exists():
        br = read_text(batch_runner)
        for m in re.finditer(r'"([^"]+烟雾)"', br):
            test_order.append(m.group(1))
        # 去重
        seen = set()
        test_order = [x for x in test_order if not (x in seen or seen.add(x))]

    if not test_order:
        test_order = list(result_map.keys())

    tests: List[SmokeTest] = []
    for name in test_order:
        tests.append(
            SmokeTest(
                name=name,
                runner_script=_guess_runner_for_test(name, tests_dir),
                result_path=result_map.get(name, ""),
            )
        )

    lines.append("## 测试中心烟雾测试清单")
    lines.append("")
    lines.append("| 测试名 | Runner 脚本（推断） | 输出结果文件 |")
    lines.append("|---|---|---|")
    for t in tests:
        lines.append(f"| {t.name} | `{t.runner_script}` | `{t.result_path}` |")
    lines.append("")

    lines.append("## 改动到测试的建议映射（基线）")
    lines.append("")
    lines.append("这部分是“经验化映射”，用于快速选最小回归集合。你可以后续按项目实际再补充。")
    lines.append("")
    lines.append("| 改动点 | 优先回归的烟雾测试 | 说明 |")
    lines.append("|---|---|---|")
    lines.append("| 路由/入口（主菜单、返回逻辑、路由守卫） | `路由守卫烟雾`、`主流程烟雾` | 入口断了会导致所有验证失效 |")
    lines.append("| PVE 主链（`pve_battle_controller_3d.gd` / `battle_core_3d.gd`） | `3D 占位烟雾`、`完整集成烟雾` | 判定/反馈/结算容易被连带影响 |")
    lines.append("| HUD 与瞄准（`ui_hud_pve.gd` / `ui_scope_overlay.gd`） | `主流程烟雾`、`完整集成烟雾` | UI 断了会表现为“能跑但不可玩” |")
    lines.append("| 资源显示轨道（`weapon_renderer_3d.gd` 的 track） | `3D 占位烟雾`、`完整集成烟雾` | 重点验证 `attempted_scene_track` vs `scene_track` |")
    lines.append("| 贴花/挡弹/命中反馈（`visual_feedback_3d.gd` + DecalRoot） | `3D 占位烟雾`、`完整集成烟雾` | 重点看挡弹后贴花/冲击反馈是否生成 |")
    lines.append("")

    lines.append("## 最小回归动作（贴近业务）")
    lines.append("")
    lines.append("1. 每次改动后，至少跑 `3D 占位烟雾` 与 `完整集成烟雾`。")
    lines.append("2. 如果本轮改动涉及入口/返回/路由，再补跑 `路由守卫烟雾` 与 `主流程烟雾`。")
    lines.append("3. 如果本轮改动涉及资源轨道或武器显示，对照检查：逻辑轨道与屏幕显示轨道一致。")
    lines.append("")

    return "\n".join(lines).strip() + "\n"


def main() -> int:
    here = Path(__file__).resolve()
    root = find_project_root(here)
    out = root / "project-execution-retro" / "automation" / "outputs" / "test_regression_matrix.md"
    write_text(out, build_test_regression_matrix(root))
    print(f"[ok] wrote: {out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

