---
id: EPIC-006
seq: 6
title: "Partner Access & Credential Security"
owner: security_architecture_team
status: planned
artifact_type: epic_overview
related_epic:
  - EPIC-006
related_feature:
  - FEATURE-006-001-IdentityFederation
  - FEATURE-006-002-CredentialVault
  - FEATURE-006-003-PartnerWorkspace
  - FEATURE-006-004-MultiStrategyIsolation
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

# EPIC-006: Partner Access & Credential Security

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
Real Google OAuth, mock login, and broker credential vaults evolved separately. Partners need unified access to both single-strategy operations and multi-strategy portfolio management capabilities from EPIC-001's framework. Current system lacks role differentiation for single vs. multi-strategy access, multi-strategy workspace isolation, and credential scoping for complex portfolio operations.

## Business Value
- **Partner Scale**: Onboard partners with appropriate access to single-strategy or multi-strategy capabilities
- **Multi-Strategy Security**: Isolate partner access to different portfolio complexity levels
- **Operational Efficiency**: Unified authentication for both simple and complex trading operations
- **Capability Alignment**: Map partner sophistication to appropriate platform capabilities
- **Portfolio Isolation**: Ensure partner strategies don't interfere with each other's portfolios

## Success Criteria
- [ ] Identity service supports single-strategy and multi-strategy capability scoping
- [ ] Role-based access controls differentiate between single-strategy and portfolio management permissions
- [ ] Partner workspaces support both individual strategy management and portfolio operations
- [ ] Credential vault handles both simple strategy credentials and complex portfolio access tokens
- [ ] Multi-strategy partner isolation prevents cross-portfolio interference
- [ ] Portfolio-level audit trails and compliance logging implemented
- [ ] Auth health dashboard tracks usage patterns for both operational modes

## Feature Breakdown

| Feature ID | Name | Scope | Multi-Strategy Support | Status |
| --- | --- | --- | --- | --- |
| [FEATURE-006-001-IdentityFederation](./FEATURE-006-001-IdentityFederation/README.md) | Identity Federation & Session Resilience | OAuth/multi-mode alignment, role governance, refresh tokens, capability-based access. | ✅ Full Support | 📋 Planned |
| [FEATURE-006-002-CredentialVault](./FEATURE-006-002-CredentialVault/README.md) | Partner Credential Vault & Key Ops | AES-256 vaulting for strategy & portfolio tokens, multi-strategy credential scoping. | ✅ Portfolio Credentials | 📋 Planned |
| [FEATURE-006-003-PartnerWorkspace](./FEATURE-006-003-PartnerWorkspace/README.md) | Partner Workspace & Delegated Access | Capability-aware UI for strategy and portfolio management, multi-strategy isolation. | ✅ Portfolio Workspaces | 📋 Planned |
| [FEATURE-006-004-MultiStrategyIsolation](./Features/FEATURE-006-004-MultiStrategyIsolation/README.md) | Multi-Strategy Partner Isolation | Portfolio-level tenant isolation, cross-portfolio security, capability management. | ✅ Core Multi-Strategy | 📋 Planned |

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
