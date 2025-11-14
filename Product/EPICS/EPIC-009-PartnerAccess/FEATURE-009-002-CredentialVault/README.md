---
id: FEATURE-009-002-CredentialVault
parent_epic: EPIC-009
owner: platform_security_team
status: planned
priority: high
created_at: 2025-02-15
updated_at: 2025-02-15
references:
  - documentation/localresearch/multi_user_partner_auth_inventory.md
  - documentation/vault_prd/09_PartnerAccess/PRD.md
  - documentation/vault_design/09_PartnerAccess/IDENTITY_AND_CREDENTIAL_DESIGN.md
  - SynpaticTradingV2/docs/features/in_progress/FEAT-2025-0043-INT_Broker_Connections_Management.md
  - SynpaticTradingV2/docs/features/implemented/FEAT-2025-0043-INT-001_Database_Security_Layer.md
  - SynpaticTradingV2/PRODUCT_MANAGEMENT/OPTIONS_TRADING/zerodha_integration.yaml
---

# Feature: Partner Credential Vault & Key Operations

## Problem
- Broker connection work already uses AES-256-GCM encryption, RLS, and key rotation, but OAuth refresh tokens and partner secrets still live in app memory or `.env`.
- There is no unified audit log tying credential creation, rotation, or deletion to partner identities, leaving compliance gaps.
- Operational tooling for key rotation (KMS integration, dry-runs, alerting) is ad-hoc.

## Objective
Create a centralized vault service that stores **all** partner-sensitive artifacts (broker creds, OAuth refresh tokens, delegated access keys) with consistent encryption, rotation, audit, and monitoring semantics.

## Scope
1. **Vault Service Layer**
   - Promote `broker_encryption.py` capabilities into a reusable service (library or microservice).
   - Support per-partner key derivation, envelope encryption via KMS (AWS KMS/HashiCorp Vault) with AES-256-GCM payloads.
2. **Schema + RLS Enhancements**
   - Extend `broker_connections` tables or add `partner_credentials` table with row-level security keyed by partner + role.
   - Capture credential metadata (type, last rotated, owning persona).
3. **Lifecycle Automation**
   - Implement rotation scheduler + alerting (pre-expiry notifications, failure alarms).
   - Add bulk rotation & recovery workflows with dry-run validation.
4. **Audit & Compliance**
   - Stream vault events to monitoring stack + long-term storage.
   - Provide tamper-evident audit trail linking credential changes to user actions (UI or API).
5. **API & SDK**
   - Expose service APIs for identity module + partner workspace.
   - Provide SDK wrappers (Python/Node) with retries, rate limiting, and structured errors.

## Deliverables
- Vault architecture document + ADR.
- Database migration + ORM models for partner credential entities.
- Vault service package + integration tests covering encryption/decryption, RLS enforcement, rotation flows.
- Observability dashboards + PagerDuty runbooks for vault health.
- Documentation aligning with Zerodha integration SLAs (token storage = secure vault).

## Acceptance Criteria
- [ ] All credential types (broker + OAuth + delegated tokens) stored encrypted at rest, never logged in plaintext.
- [ ] Keys managed via centralized KMS with rotation ≤30 days; audit log captures every access.
- [ ] Access attempts outside a partner’s scope blocked at DB + service layers.
- [ ] Failed rotation or decrypt events trigger alerts within 2 minutes.
- [ ] Vault API throughput supports ≥100 ops/sec with <50ms latency overhead.

## Dependencies
- Identity Federation feature for binding OAuth refresh tokens to partner IDs.
- Infrastructure support for KMS / Vault secrets engine.
- Monitoring stack (Prometheus/Grafana/ELK) for telemetry sinks.

## Risks & Mitigation
| Risk | Mitigation |
| --- | --- |
| KMS integration delays | Provide local dev fallback using file-based master keys, swapped via config in staging/prod. |
| Rotation breaks broker connections | Blue/green token storage with verification step before commit; rollback pointer retained. |
| Audit log volume overloads monitoring | Batch/async exporters with rate limiting + sampling. |

## Metrics
- Number of credentials onboarded per partner.
- Rotation success rate and average rotation time.
- Unauthorized access attempts blocked.
- Vault latency and error rates.
