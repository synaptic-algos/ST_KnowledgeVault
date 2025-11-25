---
artifact_type: feature
created_at: '2025-11-25T16:23:21.774530Z'
id: FEATURE-006-001-IdentityFederation
manual_update: true
owner: identity_platform_team
parent_epic: EPIC-006
priority: critical
progress_pct: 0
references: null
related_epic: TBD
related_feature: TBD
related_story: TBD
requirement_coverage: TBD
seq: 1
status: planned
title: Auto-generated title for README
updated_at: '2025-11-25T16:23:21.774535Z'
---

# Feature: Identity Federation & Session Resilience

## Problem
- Google OAuth + mock login operate independently, causing role mismatches (`super_admin` rejected) and inconsistent redirects (see OAuth fix summary).
- Refresh tokens and tab/session persistence are unfinished, forcing partners to re-authenticate mid-session.
- Auth regressions are only caught manually; Playwright JWT helpers are not part of CI, so login loops reach production.

## Objective
Deliver a unified identity module that normalizes OAuth + mock flows, enforces partner-aware roles, and provides resilient sessions with automated regression coverage.

## Scope
1. **Unified Auth Service**
   - Normalize login callbacks, role mapping, and auth_mode flags.
   - Add `super_admin` + partner-specific roles in backend enums and policy middleware.
2. **Session Durability**
   - Implement refresh-token rotation + silent renew (leveraging `FEAT-2025-0100-AUTH-002` backlog).
   - Align remember-me controls between mock and real OAuth (24h vs 30m logic).
   - Broadcast session status across tabs via `BroadcastChannel` or service worker.
3. **Regression Guardrails**
   - Promote Playwright auth modules into CI smoke suite covering all roles/partners.
   - Add synthetic monitors for `/api/login/google` + callback success rates.
4. **Operational Runbooks**
   - Document redirect URI updates, Google Console steps, and fallback procedures.

## Deliverables
- Identity service design doc + updated FastAPI routes.
- Enum + RBAC updates across backend + frontend guard components.
- Refresh + silent-renew pipeline with observability metrics (token age, failure reasons).
- CI-ready Playwright auth regression script + GitHub workflow.
- Runbook and dashboard for login health.

## Acceptance Criteria
- [ ] Login success rate ≥99.5% across partners (mock + real).
- [ ] Refresh tokens rotate without forcing logout; sessions survive backend restarts.
- [ ] Protected routes honor partner roles; unauthorized partners get deterministic errors.
- [ ] Playwright auth suite blocks deployments if login or redirect fails.
- [ ] Documentation updated in `documentation/research` and product README.

## Dependencies
- Google OAuth credentials + redirect URIs.
- Backend role enum fix (currently tracked as FEAT-2025-0100-AUTH-001).
- Session manager scaffolding from SynpaticTradingV2 codebase.

## Risks & Mitigation
| Risk | Mitigation |
| --- | --- |
| Refresh token rollout logs out active partners | Dual-token strategy + staged release + rollback plan. |
| New roles break legacy automation | Create compatibility layer mapping old roles to new scopes until migration complete. |
| Playwright suite becomes flaky | Use mock auth for most CI runs; schedule daily real OAuth canary with retry budget. |

## Metrics
- Login success %, mean login latency, number of forced re-auth events per day.
- Refresh token failure counts + top error categories.
- CI auth suite pass/fail trends.
