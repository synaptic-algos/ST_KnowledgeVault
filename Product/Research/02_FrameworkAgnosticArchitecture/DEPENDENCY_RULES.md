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
