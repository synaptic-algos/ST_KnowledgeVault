---
artifact_type: story
created_at: '2025-11-25T16:23:21.853516Z'
id: AUTO-DEPENDENCY_RULES
manual_update: true
owner: Auto-assigned
related_epic: TBD
related_feature: TBD
related_story: TBD
requirement_coverage: TBD
seq: 1
status: pending
title: Auto-generated title for DEPENDENCY_RULES
updated_at: '2025-11-25T16:23:21.853520Z'
---

# Dependency Rules

## Goals
- Prevent accidental coupling between domain logic and framework-specific adapters.
- Enforce layering so that ports and domain objects remain reusable.

## Layering Constraints
1. **Domain Layer (`src/domain`)**
   - May depend on: `src/domain` (same layer), `src/core` utilities.
   - Must not depend on: `src/application`, `src/adapters`, external frameworks.
2. **Application Layer (`src/application`)**
   - May depend on: domain layer, core utilities.
   - Must not depend on: adapter implementations.
3. **Adapter Layer (`src/adapters`)**
   - May depend on: application layer interfaces, adapter-specific SDKs.
   - Must not introduce imports into domain/application packages.
4. **Tests (`tests/`)**
   - May depend on all layers but should use mocks/fixtures for external systems.

## Tooling
- `import-linter` contract: domain package is an **independent** package; application imports domain only; adapters import application but not vice versa.
- `ruff` and `mypy` enforce consistent naming and type boundaries.

## Enforcement Plan
- Add pre-commit hook running `import-linter --config=config/import_linter.cfg`.
- CI pipeline blocks merges if dependency violations occur.
- Architecture review checklist includes dependency diagrams for new modules.
