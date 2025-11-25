---
artifact_type: story
created_at: '2025-11-25T16:23:21.785426Z'
id: PRD-009
manual_update: true
owner: product_ops_team
related_epic: TBD
related_feature: TBD
related_story: TBD
requirement_coverage: TBD
seq: 1
sources: null
status: draft
title: Partner Access & Credential Security PRD
updated_at: '2025-11-25T16:23:21.785429Z'
---

# 1. Overview
- **Goal**: Deliver a unified, multi-tenant login system for all partners (Nikhil, Mukesh, Raja, Nitin, plus future additions) that keeps credentials encrypted end-to-end and aligns with the documented OAuth and broker integrations.
- **Scope**: Authentication modes (Google OAuth + mock), session lifecycle, credential vaulting, partner-facing workspace, and observability.
- **Out of Scope**: Strategy-specific authorization rules, third-party white-labeling, non-partner retail usage.

# 2. Problem Statement
Current authentication is fragmented (real OAuth vs. mock) and the credential security model is only implemented for broker tokens. Partners experience:
- OAuth failures due to missing enum support (`super_admin`) and redirect URI mismatches.
- Sessions expiring mid-trade because refresh tokens and silent renewal are incomplete.
- Manual credential rotation even though AES-256-GCM vaulting exists for broker accounts.
- No dashboard to self-serve approvals, token state, or alerts tied to their personas.

# 3. Personas & Needs
| Partner | Key Needs | SLAs |
| --- | --- | --- |
| **Nikhil** (Execution) | Stable login pre-market, broker token freshness | Login <2s, uptime >99.9%, refresh before expiry |
| **Mukesh** (Throughput) | Multi-connection visibility, minimal auth latency | Login <2s, throughput alerts on auth errors |
| **Raja** (Analytics) | Read-only roles, audit trail access | Data accuracy >99.9%, audit exports on demand |
| **Nitin** (Architecture) | System health overview, impersonation/testing tools | Integration latency <50ms, full visibility |

# 4. Objectives & KPIs
1. **Unified Identity** – One service issuing JWT + refresh tokens for both OAuth and mock flows.  
   - KPI: ≥99.5% success on `/api/login/google` and mock login.
2. **Credential Trust** – Encrypt OAuth refresh tokens and broker tokens using the same vault stack.  
   - KPI: Zero plaintext secrets stored outside vaults; rotation ≤30 days.
3. **Partner Autonomy** – Workspace that enables partners to add, rotate, and revoke credentials.  
   - KPI: Reduce auth-related support tickets by 70%.
4. **Operational Guardrails** – Automated regressions via Playwright + telemetry + runbooks.  
   - KPI: Detect login failures within 2 minutes; MTTR <15 minutes.

# 5. Functional Requirements
1. **Login Modes**
   - Support Google OAuth (production) and mock auth (development/testing) behind a shared interface.
   - Persist `auth_mode` metadata with each session for auditability.
2. **Role & Policy Handling**
   - Backend enum must include `super_admin`, `admin`, `trader`, `viewer`, and partner-scoped roles.
   - Protected routes enforce partner entitlements defined in partner profiles.
3. **Session Lifecycle**
   - Issue access + refresh tokens; enable silent renewal before expiry.
   - Honor “Remember Me” 24-hour sessions for both mock and real OAuth.
   - Broadcast session status across browser tabs and notify on forced logout.
4. **Credential Vault Integration**
   - Store OAuth refresh tokens, API keys, and delegated access grants via AES-256-GCM + Row Level Security.
   - Provide audit log entries for create/update/delete operations including actor, partner, channel.
5. **Partner Workspace**
   - Dashboard shows login health, token age, pending rotations, and broker connection states.
   - Workflow for adding/removing brokers with vault-backed storage and multi-factor confirmation.
   - Delegated access management (grant, revoke, expiry).
6. **Monitoring & Alerts**
   - Metrics: login success %, latency, refresh token errors, vault rotation status.
   - Alerts route to partner-specific channels (SMS/Slack/email) defined in partner views.
7. **Testing & Compliance**
   - Integrate Playwright auth smoke test into CI and nightly canary runs.
   - Document Google OAuth console steps and redirect URI updates in runbooks.

# 6. Non-Functional Requirements
| Category | Requirement |
| --- | --- |
| **Performance** | Login <2 seconds median; token refresh <500 ms; vault operations add <50 ms overhead. |
| **Security** | TLS 1.3 for auth endpoints; no secrets logged; audit-ready retention ≥1 year. |
| **Availability** | Auth service uptime ≥99.9% during market hours; degradation alerts within 2 minutes. |
| **Scalability** | Handle ≥100 concurrent partner logins and 100 credential operations/sec. |
| **Compliance** | SOC2-friendly audit logs; align with documented broker SLAs and partner personas. |

# 7. Milestones
1. **M1 – Identity Cohesion (Week 2)**: Enum fix, shared auth service, refresh token MVP.
2. **M2 – Vault Convergence (Week 4)**: OAuth tokens stored in vault, rotation scheduler online.
3. **M3 – Partner Workspace (Week 6)**: Persona dashboards, delegated access, alert hooks.
4. **M4 – Observability (Week 6+)**: CI coverage, canary monitors, runbook sign-off.

# 8. Risks & Mitigations
| Risk | Impact | Mitigation |
| --- | --- | --- |
| Refresh rollout logs out active sessions | High | Dual-token period + gradual feature flag rollout |
| Vault availability issues block logins | High | Active-active deployment + fallback cache for short outages |
| Partner UX overload | Medium | Start with the four existing personas; add templates later |
| OAuth credential misconfiguration | Medium | Automate Google Console validation script in release checklist |

# 9. Open Questions
1. Do partners require hardware-based MFA for delegated access?  
2. Should vault rotation cadence differ per broker vs. OAuth tokens?  
3. How to expose impersonation for Nitin without impacting audit integrity?
