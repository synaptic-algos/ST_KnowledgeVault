#!/usr/bin/env python3
"""
Regenerate the auto-summary block in the roadmap based on epic metadata.
"""

from __future__ import annotations

import argparse
import datetime as dt
import re
from pathlib import Path
from typing import Any, Dict, List, Tuple

import yaml

AUTO_START = "<!-- AUTO-ROADMAP-SUMMARY:START -->"
AUTO_END = "<!-- AUTO-ROADMAP-SUMMARY:END -->"

STATUS_EMOJI = {
    "completed": "✅",
    "in_progress": "🟡",
    "planned": "📋",
    "blocked": "⛔",
    "at_risk": "⚠️",
    "identified": "🔍",
    "not_started": "📋",
}


def read_front_matter(path: Path) -> Tuple[Dict[str, Any], str]:
    text = path.read_text()
    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        return {}, text
    end_idx = None
    for idx, line in enumerate(lines[1:], start=1):
        if line.strip() == "---":
            end_idx = idx
            break
    if end_idx is None:
        raise ValueError(f"Front matter in {path} is not closed with '---'.")
    front = "\n".join(lines[1:end_idx])
    body = "\n".join(lines[end_idx + 1 :]).lstrip("\n")
    data = yaml.safe_load(front) or {}
    return data, body


def collect_epic_metadata(epics_dir: Path) -> List[Dict[str, Any]]:
    rows: List[Dict[str, Any]] = []
    for dir_path in epics_dir.glob("EPIC-*"):
        if not dir_path.is_dir():
            continue
        readme_path = dir_path / "README.md"
        if not readme_path.exists():
            continue
        metadata, _ = read_front_matter(readme_path)
        epic_id = metadata.get("id") or metadata.get("epic_id")
        if not epic_id:
            continue
        rows.append(
            {
                "id": epic_id,
                "title": metadata.get("title", dir_path.name),
                "status": metadata.get("status", metadata.get("epic_status", "planned")),
                "progress_pct": metadata.get("progress_pct", metadata.get("progress", 0)),
                "linked_sprints": metadata.get("linked_sprints", metadata.get("sprints", [])),
                "change_log": metadata.get("change_log", []),
                "updated_at": metadata.get("updated_at"),
            }
        )
    rows.sort(key=lambda row: row["id"])
    return rows


def build_table(rows: List[Dict[str, Any]]) -> str:
    header = [
        "| Epic | Status | Progress | Recent Sprints | Last Update |",
        "|------|--------|----------|----------------|-------------|",
    ]
    for row in rows:
        emoji = STATUS_EMOJI.get(row["status"], "•")
        progress = f"{row.get('progress_pct', 0)}%"
        linked = row.get("linked_sprints") or []
        recent = ", ".join(linked[-3:])
        updated = row.get("updated_at", "—")
        header.append(
            f"| {row['id']} | {emoji} {row['status']} | {progress} | {recent or '—'} | {updated} |"
        )
    return "\n".join(header)


def replace_block(content: str, block: str) -> str:
    pattern = re.compile(
        rf"{re.escape(AUTO_START)}.*?{re.escape(AUTO_END)}",
        flags=re.DOTALL,
    )
    replacement = f"{AUTO_START}\n{block}\n{AUTO_END}"
    if pattern.search(content):
        return pattern.sub(replacement, content)
    return content.rstrip() + "\n\n" + replacement + "\n"


def main() -> None:
    parser = argparse.ArgumentParser(description="Sync roadmap summary with epic metadata.")
    parser.add_argument(
        "--vault",
        type=Path,
        required=True,
        help="Path to product root (e.g., SynapticTrading_Vault/Product)",
    )
    parser.add_argument(
        "--roadmap",
        type=Path,
        default=Path("ROADMAP.md"),
        help="Roadmap file relative to the product root",
    )
    args = parser.parse_args()

    epics_dir = args.vault / "EPICS"
    if not epics_dir.exists():
        raise FileNotFoundError(epics_dir)

    rows = collect_epic_metadata(epics_dir)
    table = build_table(rows)
    synced_at = (
        dt.datetime.now(dt.timezone.utc)
        .replace(microsecond=0)
        .isoformat()
        .replace("+00:00", "Z")
    )
    block = f"_Auto-sync: {synced_at}_\n\n{table}"

    roadmap_path = (args.vault / args.roadmap).resolve()
    if not roadmap_path.exists():
        raise FileNotFoundError(roadmap_path)
    content = roadmap_path.read_text()
    updated = replace_block(content, block)
    roadmap_path.write_text(updated)
    print(f"Updated roadmap summary in {roadmap_path}")


if __name__ == "__main__":
    main()
