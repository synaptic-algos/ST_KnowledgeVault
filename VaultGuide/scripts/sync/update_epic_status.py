#!/usr/bin/env python3
"""
Update story/feature/epic metadata using a sprint execution summary.

Summary file format (YAML):
---
sprint_id: SPRINT-20251104-epic001
ended_at: 2025-11-06T23:59:00Z
status: completed
epic_updates:
  - id: EPIC-001
    path: EPICS/EPIC-001-Foundation/README.md
    status: in_progress
    progress_pct: 12
    requirement_coverage: 20
    change_log_entry: "2025-11-06 – SPRINT-20251104-epic001 – Repo + tooling ready."
    features:
      - id: FEATURE-001
        path: EPICS/EPIC-001-Foundation/FEATURE-001-PortInterfaces/README.md
        status: in_progress
        progress_pct: 10
"""

from __future__ import annotations

import argparse
import datetime as dt
from pathlib import Path
from typing import Any, Dict, Tuple

import yaml


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


def _normalize(value: Any) -> Any:
    if isinstance(value, dict):
        return {k: _normalize(v) for k, v in value.items()}
    if isinstance(value, list):
        return [_normalize(v) for v in value]
    if isinstance(value, dt.datetime):
        iso = value.replace(microsecond=0).isoformat()
        if value.tzinfo:
            iso = iso.replace("+00:00", "Z")
        return iso
    return value


def write_front_matter(path: Path, metadata: Dict[str, Any], body: str) -> None:
    metadata = _normalize(metadata)
    front = yaml.safe_dump(metadata, sort_keys=False).strip()
    content = f"---\n{front}\n---\n\n{body}".rstrip() + "\n"
    path.write_text(content)


def ensure_list(value: Any) -> list:
    if value is None:
        return []
    if isinstance(value, list):
        return value
    return [value]


def apply_update(
    vault_path: Path,
    file_path: Path,
    sprint_id: str,
    update: Dict[str, Any],
    now_iso: str,
) -> None:
    metadata, body = read_front_matter(file_path)
    if not metadata:
        raise ValueError(f"{file_path} is missing YAML front matter.")

    changed = False

    for field in ("status", "progress_pct", "requirement_coverage"):
        if field in update:
            if metadata.get(field) != update[field]:
                metadata[field] = update[field]
                changed = True

    fields_extra = update.get("fields", {})
    for key, value in fields_extra.items():
        if metadata.get(key) != value:
            metadata[key] = value
            changed = True

    change_entry = update.get("change_log_entry")
    if change_entry:
        change_log = ensure_list(metadata.get("change_log"))
        if change_entry not in change_log:
            change_log.insert(0, change_entry)
            metadata["change_log"] = change_log
            changed = True

    linked = ensure_list(metadata.get("linked_sprints"))
    if sprint_id not in linked:
        linked.append(sprint_id)
        metadata["linked_sprints"] = linked
        changed = True

    extra_links = update.get("linked_sprints", [])
    for sid in extra_links:
        if sid not in linked:
            linked.append(sid)
            changed = True

    if changed:
        metadata["updated_at"] = now_iso
        metadata["last_review"] = update.get("last_review", now_iso.split("T")[0])

        write_front_matter(file_path, metadata, body)
        rel_path = file_path.relative_to(vault_path)
        print(f"Updated {rel_path}")
    else:
        print(f"No changes for {file_path}")


def process_summary(vault_path: Path, summary_path: Path) -> None:
    summary = yaml.safe_load(summary_path.read_text())
    if not summary:
        raise ValueError("Summary file is empty.")

    sprint_id = summary["sprint_id"]
    now_iso = dt.datetime.now(dt.timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")

    for epic in summary.get("epic_updates", []):
        epic_path = vault_path / epic["path"]
        apply_update(vault_path, epic_path, sprint_id, epic, now_iso)

        for feature in epic.get("features", []):
            feature_path = vault_path / feature["path"]
            apply_update(vault_path, feature_path, sprint_id, feature, now_iso)

            for story in feature.get("stories", []):
                story_path = vault_path / story["path"]
                apply_update(vault_path, story_path, sprint_id, story, now_iso)


def main() -> None:
    parser = argparse.ArgumentParser(description="Update epic metadata from sprint summary.")
    parser.add_argument(
        "--vault",
        type=Path,
        required=True,
        help="Path to product root (e.g., SynapticTrading_Vault/Product)",
    )
    parser.add_argument(
        "--summary",
        type=Path,
        required=True,
        help="Path to execution_summary.yaml for the sprint",
    )
    args = parser.parse_args()

    if not args.summary.exists():
        raise FileNotFoundError(args.summary)

    process_summary(args.vault.resolve(), args.summary.resolve())


if __name__ == "__main__":
    main()
