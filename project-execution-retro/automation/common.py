from __future__ import annotations

import os
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, Optional


def find_project_root(start: Path) -> Path:
    """
    从当前脚本位置向上找“项目根”。
    判定规则：存在 `狙击外星人升级版/` 或 `3d_asset_engineering/` 任一目录。
    """
    cur = start.resolve()
    for p in [cur, *cur.parents]:
        if (p / "狙击外星人升级版").exists() or (p / "3d_asset_engineering").exists():
            return p
    return start.resolve()


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="ignore")


def write_text(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def slugify(s: str) -> str:
    s = s.strip().lower()
    s = re.sub(r"\s+", "_", s)
    s = re.sub(r"[^0-9a-zA-Z_\u4e00-\u9fff-]", "", s)
    return s[:80] if len(s) > 80 else s


def extract_section(md: str, heading: str) -> Optional[str]:
    """
    提取 markdown 中某个二级标题(##)或三级标题(###)对应的内容。
    heading 传入的是不带 # 的标题文本（精确匹配）。
    """
    pattern = re.compile(
        r"(^#{2,3}\s+" + re.escape(heading) + r"\s*$)([\s\S]*?)(?=^#{2,3}\s+|\Z)",
        re.M,
    )
    m = pattern.search(md)
    if not m:
        return None
    return m.group(2).strip()


def extract_backticked_tokens(text: str) -> list[str]:
    return [t.strip() for t in re.findall(r"`([^`]+)`", text)]


def guess_asset_type(path: Path) -> str:
    parts = [p.lower() for p in path.parts]
    name = path.name.lower()
    if "weapons" in parts or "guns" in parts or name.startswith("weapon-"):
        return "weapon"
    if "icons" in parts or name.startswith("icon-"):
        return "icon"
    if "hud" in parts or name.startswith("hud-"):
        return "hud"
    if "effects" in parts or "fx" in name or name.startswith("fx-"):
        return "effect"
    if "characters" in parts or "aliens" in parts or "civilian" in name or "alien" in name:
        return "character"
    if "ui-kit" in parts or "armory" in parts or "shop" in parts:
        return "ui-kit"
    if "anim" in parts or "frame" in name:
        return "anim"
    if "environment" in parts or name.startswith("env-"):
        return "environment"
    if "decals" in parts or name.startswith("decal-") or "bullet-hole" in name:
        return "decal"
    return "other"


@dataclass
class AssetContractRow:
    batch: str
    asset_path: str
    asset_type: str
    intended_scene: str
    intended_script: str
    trigger: str
    fallback: str

    def to_csv_row(self) -> str:
        def esc(x: str) -> str:
            x = (x or "").replace('"', '""')
            return f'"{x}"'

        return ",".join(
            [
                esc(self.batch),
                esc(self.asset_path),
                esc(self.asset_type),
                esc(self.intended_scene),
                esc(self.intended_script),
                esc(self.trigger),
                esc(self.fallback),
            ]
        )


def iter_files(base: Path, patterns: Iterable[str]) -> Iterable[Path]:
    for pat in patterns:
        yield from base.rglob(pat)

