---
id: EPIC-009
seq: 9
title: "Partner Access & Credential Security"
owner: security_architecture_team
status: planned
artifact_type: epic_overview
related_epic:
  - EPIC-009
related_feature:
  - FEATURE-009-001-IdentityFederation
  - FEATURE-009-002-CredentialVault
  - FEATURE-009-003-PartnerWorkspace
related_story: []
created_at: 2025-02-15T00:00:00Z
updated_at: 2025-02-15T00:00:00Z
last_review: 2025-02-15
change_log:
  - 2025-02-15 – security_architecture_team – Created epic after reviewing `documentation/research/multi_user_partner_auth_inventory.md` – documentation/research/multi_user_partner_auth_inventory.md
progress_pct: 0
requirement_coverage: 0
linked_sprints: []
---

# EPIC-009: Partner Access & Credential Security

- **Research Input**: [Multi-User Partner Auth Inventory](../../localresearch/multi_user_partner_auth_inventory.md)
- **Product Requirements**: [PRD-009](../../vault_prd/09_PartnerAccess/PRD.md)
- **Design Guide**: [Partner Identity & Credential Vault](../../vault_design/09_PartnerAccess/IDENTITY_AND_CREDENTIAL_DESIGN.md)
- **Drivers**: OAuth parity for partners, encrypted credential lifecycle, persona-aware access.
- **Gate Status**: Pre-G0 – discovery completed, solution architecture pending approval.

## Epic Overview

| Field | Detail |
| --- | --- |
| **Objective** | Deliver a multi-tenant identity plane that lets any partner log in, manage broker connections, and store credentials with auditable encryption. |
| **Duration** | 6 weeks (Discovery 1, Build 4, Hardening 1) |
| **Priority** | P0 – Required before onboarding new partners beyond Nikhil/Mukesh/Raja/Nitin. |
| **KPIs** | 99.5% login success, <2s OAuth round trip, zero credential-leak incidents, MTTR <15m for auth regressions. |

## Problem Statement
Real Google OAuth, mock login, and broker credential vaults evolved separately. Partners still face role errors (`super_admin` rejection), abrupt session drops (no refresh tokens), and manual handling of encrypted broker tokens. The system needs a cohesive partner access layer that unifies login, authorization, and key management backed by telemetry.

## Business Value
- **Partner Scale**: Onboard additional partners without bespoke auth code.
- **Security Posture**: Align login token handling with the AES-256 vault already used for broker secrets.
- **Operational Efficiency**: Encode OAuth regression checks into CI, reducing reactive firefighting.
- **Persona Alignment**: Map PRODUCT_MANAGEMENT partner SLAs into access policies and workspace defaults.

## Success Criteria
- [ ] Identity service issues JWT + refresh grants aligned with Google OAuth + mock flows.
- [ ] Role enums + policies support `super_admin`, `admin`, `trader`, `viewer`, and future partner-specific scopes.
- [ ] Credential vault encrypts all broker/OAuth tokens with per-partner keys and RLS, sharing telemetry with SOC tooling.
- [ ] Partner workspace exposes self-service onboarding, connection approvals, and audit trails.
- [ ] Auth health dashboard tracks login success rate, redirect failures, token age, and key-rotation SLAs.

## Feature Breakdown

| Feature ID | Name | Scope | Status |
| --- | --- | --- | --- |
| [FEATURE-009-001-IdentityFederation](./FEATURE-009-001-IdentityFederation/README.md) | Identity Federation & Session Resilience | OAuth/multi-mode alignment, role governance, refresh tokens, Playwright regression hooks. | 📋 Planned |
| [FEATURE-009-002-CredentialVault](./FEATURE-009-002-CredentialVault/README.md) | Partner Credential Vault & Key Ops | Extend AES-256 vaulting to OAuth tokens, automate rotation, expose compliance logs. | 📋 Planned |
| [FEATURE-009-003-PartnerWorkspace](./FEATURE-009-003-PartnerWorkspace/README.md) | Partner Workspace & Delegated Access | Persona-aware UI for login, broker linking, approvals, and alert routing. | 📋 Planned |

## Milestones
1. **M1 – Identity Cohesion (Week 2)**  
   - Enum fix deployed, refresh token API active, OAuth redirect monitors live.
2. **M2 – Vault Convergence (Week 4)**  
   - Shared encryption/key-rotation service governs broker + OAuth tokens.  
   - Compliance log streaming to monitoring stack.
3. **M3 – Partner Workspace GA (Week 6)**  
   - Partner portal with delegated access + self-serve credential onboarding.  
   - Playwright auth suite added to CI gate.

## Dependencies
- **Upstream**: Existing Google OAuth implementation, broker connection service, monitoring stack.
- **Downstream**: Live trading orchestration, options strategy enablement, external partner integrations.

## Deliverables
- Unified identity microservice design + ADRs.
- Refresh token + remember-me harmonization spec and code.
- KMS-backed credential vault module (encryption, RLS, audit).
- Partner workspace UX flows and component library updates.
- Observability dashboards + alert runbooks for login regressions.

## Risks & Mitigation
| Risk | Impact | Likelihood | Mitigation |
| --- | --- | --- | --- |
| Refresh token rollout breaks existing sessions | High | Medium | Double-write tokens (legacy + new) with feature flags and Playwright regression suite. |
| Key rotation causes broker disconnects | High | Low | Vault service exposes dry-run rotations + staged rollouts per partner. |
| Partner UX overload | Medium | Medium | Use persona SLAs from `PRODUCT_MANAGEMENT/PARTNER_VIEWS` to tailor defaults. |
| Compliance gaps | High | Low | Tie vault events to audit log (SOC2-ready) and run chaos exercises before GA. |

## Partner Alignment
- **Nikhil & Mukesh**: Requires uninterrupted live-session access; identity service must guarantee <2s login and proactive refresh.
- **Raja**: Needs secure analytics-only role with scoped broker permissions.
- **Nitin**: Demands cross-system visibility plus ability to simulate partner accounts for validation.

## Reporting & Metrics
- Daily auth health report (success %, avg latency, # rotating keys).
- Weekly credential vault compliance digest.
- Partner satisfaction pulse on login friction (target >95%).

## Next Steps
1. Approve epic scope and staffing at next product review.
2. Draft detailed design doc for identity service interface contracts.
3. Schedule spike to evaluate reusing broker encryption stack for OAuth tokens.
