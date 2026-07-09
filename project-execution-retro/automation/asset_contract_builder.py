from __future__ import annotations

import re
from pathlib import Path

from common import (
    AssetContractRow,
    extract_backticked_tokens,
    find_project_root,
    guess_asset_type,
    iter_files,
    read_text,
    slugify,
    write_text,
)


def _collect_batch_folders(root: Path) -> list[Path]:
    candidates = []
    for name in [
        "sniper-art-first-batch",
        "sniper-art-second-batch",
        "sniper-art-third-batch",
        "cartoon-alien-hunt-assets",
        "sniper-game-asset-board",
        "sniper-master-mobile-ui",
    ]:
        p = root / name
        if p.exists():
            candidates.append(p)
    return candidates


def _extract_script_refs(md: str) -> list[str]:
    """
    README 里经常用 `xxx.gd` 形式引用脚本；这里做一个保守抽取。
    """
    refs: set[str] = set()
    for tok in extract_backticked_tokens(md):
        if tok.endswith(".gd") or tok.endswith(".tscn"):
            refs.add(tok)
    # 也补一个非反引号的兜底（避免漏掉）
    for m in re.findall(r"[\w/\-\u4e00-\u9fff]+\.gd", md):
        refs.add(m)
    for m in re.findall(r"[\w/\-\u4e00-\u9fff]+\.tscn", md):
        refs.add(m)
    return sorted(refs)


def _guess_trigger_by_type(asset_type: str) -> str:
    if asset_type == "hud":
        return "HUD 初始化/进入瞄准/锁定/提示刷新"
    if asset_type == "effect":
        return "开火/扫描/命中/误伤/挡弹/slowmo/killcam"
    if asset_type == "anim":
        return "命中确认/误伤告警/扫描脉冲（序列帧播放）"
    if asset_type == "ui-kit":
        return "商店 Tab/购买态/武器库装备态（状态驱动切换）"
    if asset_type == "weapon":
        return "武器切换/进入战斗/武器库展示"
    if asset_type == "character":
        return "教学/扫描高亮/弱点窗口/误判复盘"
    if asset_type == "environment":
        return "关卡预览/掩体说明/图鉴（优先 UI 展示，不直接做贴图）"
    if asset_type == "decal":
        return "子弹命中表面/挡弹冲击/墙体破损反馈"
    return ""


def build_asset_contract(root: Path) -> tuple[str, str]:
    """
    输出：
    - CSV：程序可直接加载（后续也可导入 xlsx）
    - MD：更方便人读与补空
    """
    rows: list[AssetContractRow] = []
    md_lines: list[str] = []
    md_lines.append("# 资产接入合同表（自动生成草稿）")
    md_lines.append("")
    md_lines.append("这份表的作用不是“替你决定挂点”，而是把接入必需字段显式化，避免后续靠猜。")
    md_lines.append("")

    batch_folders = _collect_batch_folders(root)
    if not batch_folders:
        md_lines.append("未找到常见素材批次目录，跳过生成。")
        return "", "\n".join(md_lines) + "\n"

    for batch_dir in batch_folders:
        batch = batch_dir.name
        readme = batch_dir / "README.md"
        readme_text = read_text(readme) if readme.exists() else ""
        script_refs = _extract_script_refs(readme_text) if readme_text else []

        # 扫描常见资源后缀
        assets: list[Path] = []
        assets += list(iter_files(batch_dir, ["*.svg", "*.png", "*.jpg", "*.jpeg", "*.webp"]))
        # 过滤一些非资源目录（例如 pages/ preview.html 的引用图仍算资源，但不入合同表）
        assets = [p for p in assets if "pages" not in [x.lower() for x in p.parts]]
        assets = [p for p in assets if p.name.lower() != "preview.html"]

        if not assets and not readme.exists():
            continue

        md_lines.append(f"## {batch}")
        md_lines.append("")
        if readme.exists():
            md_lines.append(f"- README：`{batch}/README.md`")
        if script_refs:
            md_lines.append("- README 中提到的脚本/场景（可能的接入点）：")
            for r in script_refs[:18]:
                md_lines.append(f"  - `{r}`")
            if len(script_refs) > 18:
                md_lines.append("  - （更多略）")
        md_lines.append("")

        for asset in sorted(assets):
            rel = asset.relative_to(root).as_posix()
            asset_type = guess_asset_type(asset)

            # 这些字段先给“合理默认”，后续你可以在 csv 里补齐
            intended_script = ""
            if script_refs:
                # 粗略：把最像接入点的脚本放进来，方便后续筛选
                intended_script = "; ".join(script_refs[:3])

            row = AssetContractRow(
                batch=batch,
                asset_path=rel,
                asset_type=asset_type,
                intended_scene="",
                intended_script=intended_script,
                trigger=_guess_trigger_by_type(asset_type),
                fallback="无正式资源则保留占位/纯色/文本提示",
            )
            rows.append(row)

        md_lines.append("建议补齐字段：`intended_scene`（挂载到哪个场景/节点层级）、`trigger`（具体触发条件）、`fallback`（缺资源时如何兜底）。")
        md_lines.append("")

    # --- CSV ---
    csv_lines = [
        ",".join(
            [
                '"batch"',
                '"asset_path"',
                '"asset_type"',
                '"intended_scene"',
                '"intended_script"',
                '"trigger"',
                '"fallback"',
            ]
        )
    ]
    csv_lines.extend([r.to_csv_row() for r in rows])
    csv_text = "\n".join(csv_lines) + "\n"

    # --- MD: 把重点资产按类型汇总一下，便于你补空 ---
    md_lines.append("## 按类型快速抽查（建议）")
    md_lines.append("")
    md_lines.append("- `hud/effect/anim`：优先确认是否已经进入 `HUD + 反馈` 的运行消费链路。")
    md_lines.append("- `decal`：优先确认锚点、表面分类、生命周期与性能约束是否被执行。")
    md_lines.append("- `ui-kit`：优先确认状态驱动切换（tab/owned/locked/equipped）。")
    md_lines.append("")

    return csv_text, "\n".join(md_lines).strip() + "\n"


def main() -> int:
    here = Path(__file__).resolve()
    root = find_project_root(here)
    out_dir = root / "project-execution-retro" / "automation" / "outputs"

    csv_text, md_text = build_asset_contract(root)
    if csv_text:
        write_text(out_dir / "asset_integration_contract.csv", csv_text)
    write_text(out_dir / "asset_integration_contract.md", md_text)

    print(f"[ok] wrote: {out_dir / 'asset_integration_contract.csv'}")
    print(f"[ok] wrote: {out_dir / 'asset_integration_contract.md'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

