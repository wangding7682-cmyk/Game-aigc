from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Optional

from common import extract_section, find_project_root, read_text, write_text


@dataclass
class BaselineInputs:
    calibration_doc: Optional[Path]
    godot_mvp_doc: Optional[Path]
    art_audit_doc: Optional[Path]


def _find_baseline_docs(root: Path) -> BaselineInputs:
    calibration_doc = root / "文档校准说明_20260630.md"
    godot_mvp_doc = root / "狙击外星人升级版" / "Godot_MVP脚手架说明.md"
    art_audit_doc = root / "当前美术素材规范盘点.md"

    return BaselineInputs(
        calibration_doc=calibration_doc if calibration_doc.exists() else None,
        godot_mvp_doc=godot_mvp_doc if godot_mvp_doc.exists() else None,
        art_audit_doc=art_audit_doc if art_audit_doc.exists() else None,
    )


def build_current_baseline(root: Path) -> str:
    ins = _find_baseline_docs(root)
    lines: list[str] = []
    lines.append("# 当前有效口径（自动汇总）")
    lines.append("")
    lines.append("这份文件的目标是让团队在开工前先统一“项目现在是什么”。如果出现冲突，以 `文档校准说明` 的“当前有效口径”优先。")
    lines.append("")

    # --- 校准文档 ---
    if ins.calibration_doc:
        md = read_text(ins.calibration_doc)
        current = extract_section(md, "当前有效口径")
        archived = extract_section(md, "历史留档")
        removed = extract_section(md, "本次移除的旧口径")
        usage = extract_section(md, "当前最适合的使用方式")
        conclusion = extract_section(md, "一句话结论")

        lines.append("## 口径优先级")
        lines.append("")
        if usage:
            lines.append(usage.strip())
            lines.append("")
        else:
            lines.append("- 建议顺序：先看 GDD，再看工程说明，再看素材盘点，最后看专项细则。")
            lines.append("")

        lines.append("## 当前有效文档（来自校准）")
        lines.append("")
        lines.append(current.strip() if current else "（未在校准文档中找到该段落）")
        lines.append("")

        lines.append("## 历史留档（来自校准）")
        lines.append("")
        lines.append(archived.strip() if archived else "（未在校准文档中找到该段落）")
        lines.append("")

        lines.append("## 已移除的旧口径（来自校准）")
        lines.append("")
        lines.append(removed.strip() if removed else "（未在校准文档中找到该段落）")
        lines.append("")

        if conclusion:
            lines.append("## 校准一句话结论")
            lines.append("")
            lines.append(conclusion.strip())
            lines.append("")
    else:
        lines.append("## 口径优先级")
        lines.append("")
        lines.append("未找到 `文档校准说明_20260630.md`，建议先补一份“当前有效口径”，否则很容易被历史过程文档误导。")
        lines.append("")

    # --- 工程真实状态 ---
    if ins.godot_mvp_doc:
        md = read_text(ins.godot_mvp_doc)
        cur = extract_section(md, "当前结论")
        done = extract_section(md, "当前已经跑通的内容")
        skeleton = extract_section(md, "当前仍然属于骨架或预留的内容")
        focus = extract_section(md, "当前最值得关注的工程问题")
        verify = extract_section(md, "轻量验证方法")

        lines.append("## 工程真实状态（Godot MVP）")
        lines.append("")
        lines.append(cur.strip() if cur else "（未找到“当前结论”段落）")
        lines.append("")

        if focus:
            lines.append("### 当前重点")
            lines.append("")
            lines.append(focus.strip())
            lines.append("")

        if verify:
            lines.append("### 推荐验证入口")
            lines.append("")
            lines.append(verify.strip())
            lines.append("")

        if skeleton:
            lines.append("### 仍属于骨架或预留")
            lines.append("")
            lines.append(skeleton.strip())
            lines.append("")

        # done 段落可能很长：保留，但不重复贴太多
        if done:
            lines.append("### 已跑通的内容（摘要）")
            lines.append("")
            snippet = done.strip().splitlines()
            snippet = snippet[:40]  # 控制长度，避免一页太长
            lines.extend(snippet)
            lines.append("")
    else:
        lines.append("## 工程真实状态（Godot MVP）")
        lines.append("")
        lines.append("未找到 `狙击外星人升级版/Godot_MVP脚手架说明.md`，建议补一份“工程真实已经跑通/仍是骨架/如何验证”。")
        lines.append("")

    # --- 素材盘点 ---
    if ins.art_audit_doc:
        md = read_text(ins.art_audit_doc)
        summary = extract_section(md, "总结论")
        next_step = extract_section(md, "当前最适合继续推进的事")
        one_line = extract_section(md, "一句话结论")

        lines.append("## 素材与规范盘点（摘要）")
        lines.append("")
        lines.append(summary.strip() if summary else "（未找到“总结论”段落）")
        lines.append("")
        if next_step:
            lines.append("### 当前最适合继续推进的事")
            lines.append("")
            lines.append(next_step.strip())
            lines.append("")
        if one_line:
            lines.append("### 盘点一句话结论")
            lines.append("")
            lines.append(one_line.strip())
            lines.append("")
    else:
        lines.append("## 素材与规范盘点（摘要）")
        lines.append("")
        lines.append("未找到 `当前美术素材规范盘点.md`，建议补一份“够不够跑闭环 / 哪些已转为量产与规则收口问题”的盘点文档。")
        lines.append("")

    # --- 本轮必做 ---
    lines.append("## 本轮开工前的最小动作（建议）")
    lines.append("")
    lines.append("- 先确认“当前有效口径”是否仍一致：如果不一致，先校准，不继续扩展。")
    lines.append("- 把本轮要接入的资源按“接入合同”补齐字段：资源名/挂点/触发/替换/兜底。")
    lines.append("- 先跑最小闭环，再扩外围：主菜单 → 进入关卡 → 观察/扫描/开火 → 结算。")
    lines.append("- 每次改动后优先走测试中心的业务烟雾测试，而不是只看脚本是否报错。")
    lines.append("")

    return "\n".join(lines).strip() + "\n"


def main() -> int:
    here = Path(__file__).resolve()
    root = find_project_root(here)
    out = root / "project-execution-retro" / "automation" / "outputs" / "current_baseline.md"
    write_text(out, build_current_baseline(root))
    print(f"[ok] wrote: {out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

