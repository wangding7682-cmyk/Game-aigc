from pathlib import Path
import re


ROOT = Path(r"c:\Users\Admin\Documents\trae_projects\游戏AIGC\狙击外星人升级版\configs\pve")

PLAN = {
    1: {"targets": 2, "civilians": 4, "moving": 0, "weakpoint": 0, "scan": 1, "time_extend": 0, "greenery": 0},
    2: {"targets": 3, "civilians": 4, "moving": 1, "weakpoint": 0, "scan": 1, "time_extend": 0, "greenery": 1},
    3: {"targets": 4, "civilians": 5, "moving": 1, "weakpoint": 2, "scan": 1, "time_extend": 0, "greenery": 2},
    4: {"targets": 5, "civilians": 5, "moving": 2, "weakpoint": 2, "scan": 1, "time_extend": 0, "greenery": 2},
    5: {"targets": 6, "civilians": 6, "moving": 2, "weakpoint": 1, "scan": 1, "time_extend": 1, "greenery": 3},
    6: {"targets": 6, "civilians": 6, "moving": 3, "weakpoint": 1, "scan": 1, "time_extend": 1, "greenery": 3},
    7: {"targets": 7, "civilians": 7, "moving": 3, "weakpoint": 2, "scan": 1, "time_extend": 1, "greenery": 3},
    8: {"targets": 8, "civilians": 7, "moving": 4, "weakpoint": 2, "scan": 1, "time_extend": 1, "greenery": 4},
    9: {"targets": 8, "civilians": 8, "moving": 4, "weakpoint": 2, "scan": 1, "time_extend": 1, "greenery": 4},
    10: {"targets": 9, "civilians": 8, "moving": 4, "weakpoint": 3, "scan": 2, "time_extend": 1, "greenery": 4},
    11: {"targets": 9, "civilians": 9, "moving": 5, "weakpoint": 3, "scan": 2, "time_extend": 1, "greenery": 4},
    12: {"targets": 10, "civilians": 9, "moving": 5, "weakpoint": 3, "scan": 2, "time_extend": 1, "greenery": 5},
    13: {"targets": 10, "civilians": 10, "moving": 5, "weakpoint": 4, "scan": 2, "time_extend": 1, "greenery": 5},
    14: {"targets": 11, "civilians": 10, "moving": 6, "weakpoint": 4, "scan": 2, "time_extend": 1, "greenery": 5},
    15: {"targets": 11, "civilians": 10, "moving": 6, "weakpoint": 4, "scan": 2, "time_extend": 2, "greenery": 5},
    16: {"targets": 12, "civilians": 11, "moving": 6, "weakpoint": 4, "scan": 2, "time_extend": 2, "greenery": 6},
    17: {"targets": 12, "civilians": 11, "moving": 7, "weakpoint": 4, "scan": 2, "time_extend": 2, "greenery": 5},
    18: {"targets": 13, "civilians": 11, "moving": 6, "weakpoint": 5, "scan": 2, "time_extend": 2, "greenery": 6},
    19: {"targets": 14, "civilians": 12, "moving": 7, "weakpoint": 5, "scan": 2, "time_extend": 2, "greenery": 7},
    20: {"targets": 14, "civilians": 12, "moving": 8, "weakpoint": 5, "scan": 2, "time_extend": 2, "greenery": 7},
}


SUB_RE = re.compile(r'^\[sub_resource type="Resource" id="([^"]+)"\]$')
LEVEL_RE = re.compile(r"level_id = (\d+)")


def replace_scalar(text: str, key: str, value: int) -> str:
    return re.sub(rf"^{re.escape(key)} = .*$", f"{key} = {value}", text, flags=re.MULTILINE)


def main() -> None:
    files = sorted(ROOT.glob("cfg_pve_level_*.tres"))
    for path in files:
        text = path.read_text(encoding="utf-8")
        level_match = LEVEL_RE.search(text)
        if not level_match:
            continue
        level_id = int(level_match.group(1))
        if level_id not in PLAN:
            continue
        plan = PLAN[level_id]

        lines = text.splitlines()
        subresources = []
        i = 0
        while i < len(lines):
            match = SUB_RE.match(lines[i])
            if not match:
                i += 1
                continue
            start = i
            sub_id = match.group(1)
            j = i + 1
            while j < len(lines) and not lines[j].startswith("[sub_resource") and not lines[j].startswith("[resource]"):
                j += 1
            block = lines[start:j]
            actor_kind = None
            behavior_idx = None
            for idx, line in enumerate(block):
                if line.startswith("actor_kind = "):
                    actor_kind = line.split('"')[1]
                if line.startswith("behavior_type = "):
                    behavior_idx = start + idx
            subresources.append({
                "id": sub_id,
                "actor_kind": actor_kind,
                "behavior_idx": behavior_idx,
            })
            i = j

        target_blocks = [s for s in subresources if s["actor_kind"] == "target"]
        civilian_blocks = [s for s in subresources if s["actor_kind"] == "civilian"]

        target_needed = plan["targets"]
        civilian_needed = plan["civilians"]
        moving_needed = plan["moving"]
        weak_needed = plan["weakpoint"]
        static_needed = max(target_needed - moving_needed - weak_needed, 0)

        selected_targets = target_blocks[:target_needed]
        selected_civilians = civilian_blocks[:civilian_needed]

        for idx, block in enumerate(target_blocks):
            if idx < static_needed:
                behavior = "static"
            elif idx < static_needed + moving_needed:
                behavior = "moving"
            elif idx < static_needed + moving_needed + weak_needed:
                behavior = "weakpoint"
            else:
                behavior = "static"
            if block["behavior_idx"] is not None:
                lines[block["behavior_idx"]] = f'behavior_type = "{behavior}"'

        for block in civilian_blocks:
            if block["behavior_idx"] is not None:
                lines[block["behavior_idx"]] = 'behavior_type = "static"'

        spawn_refs = [f'SubResource("{block["id"]}")' for block in selected_targets + selected_civilians]
        spawn_line = "spawn_entries = Array[Resource]([%s])" % ", ".join(spawn_refs)

        new_text = "\n".join(lines)
        new_text = re.sub(r"^spawn_entries = Array\[Resource\]\(\[.*\]\)$", spawn_line, new_text, flags=re.MULTILINE)
        new_text = replace_scalar(new_text, "required_targets", plan["targets"])
        new_text = replace_scalar(new_text, "civilian_count", plan["civilians"])
        new_text = replace_scalar(new_text, "scan_count", plan["scan"])
        new_text = replace_scalar(new_text, "time_extend_count", plan["time_extend"])
        new_text = replace_scalar(new_text, "moving_targets", plan["moving"])
        new_text = replace_scalar(new_text, "weakpoint_targets", plan["weakpoint"])
        new_text = replace_scalar(new_text, "runtime_greenery_cover_budget", plan["greenery"])

        path.write_text(new_text + "\n", encoding="utf-8")
        print(f"updated level {level_id:02d}: T{plan['targets']} C{plan['civilians']} M{plan['moving']} W{plan['weakpoint']} G{plan['greenery']}")


if __name__ == "__main__":
    main()
