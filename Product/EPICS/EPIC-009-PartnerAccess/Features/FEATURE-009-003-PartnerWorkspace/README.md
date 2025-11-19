---
id: FEATURE-009-003-PartnerWorkspace
parent_epic: EPIC-009
owner: partner_success_team
status: planned
priority: medium
created_at: 2025-02-15
updated_at: 2025-02-15
references:
  - documentation/localresearch/multi_user_partner_auth_inventory.md
  - documentation/vault_prd/09_PartnerAccess/PRD.md
  - documentation/vault_design/09_PartnerAccess/IDENTITY_AND_CREDENTIAL_DESIGN.md
  - SynpaticTradingV2/PRODUCT_MANAGEMENT/PARTNER_VIEWS/README.md
  - SynpaticTradingV2/docs/features/implemented/FEAT-2025-0043-INT-004_Frontend_Components.md
---

# Feature: Partner Workspace & Delegated Access

## Problem
Partner expectations (from PRODUCT_MANAGEMENT personas) demand distinct dashboards, alert rules, and broker controls, yet today partners still rely on engineering to flip configurations or inspect credential health. Broker connection UI exists, but it is not persona-aware, lacks delegated approvals, and does not expose credential/audit insights.

## Objective
Ship a workspace that gives every partner (Nikhil, Mukesh, Raja, Nitin, and future additions) a tailored view to:
- Authenticate (mock or real) with role-appropriate access,
- Manage broker/OAuth credentials stored in the new vault,
- Approve or revoke delegated access for analysts or bots,
- Monitor login/session health and receive proactive alerts.

## Scope
1. **Persona-Aware Dashboards**
   - Derive defaults from partner profiles (latency, SLA widgets, alert channels).
   - Surface login status, token age, upcoming rotations, and broker connection states.
2. **Credential Management UI**
   - Embed flows from FEAT-0043 components with vault hooks (Add, Rotate, Revoke).
   - Provide download-free credential sharing (link-based approvals, OTP, etc.).
3. **Delegated Access Controls**
   - Allow partners to grant limited roles to teammates/bots (scope + expiry).
   - Record approvals in audit trail; require multi-factor confirmation for critical scopes.
4. **Alerting & Notifications**
   - Connect to existing alert channels per partner (SMS, Slack, email).
   - Send proactive warnings for login failures, expiring tokens, or policy violations.
5. **Self-Service Diagnostics**
   - Embed troubleshooting guides (OAuth fixes, redirect URI checklist) contextually.
   - Provide “Run Playwright smoke test” button to validate login from portal.

## Deliverables
- UX specs + prototypes covering desktop + tablet flows.
- React components (tabs/cards/modal patterns) layered on top of existing broker UI.
- APIs for delegated access + notification triggers, backed by identity + vault services.
- Documentation for partner onboarding and internal support runbooks.

## Acceptance Criteria
- [ ] Partners can complete broker onboarding, rotation, and revocation without developer intervention.
- [ ] Workspace auto-selects persona widgets and alert defaults with ability to customize.
- [ ] Delegated access creation triggers approval notifications and stores audit entries.
- [ ] Embedded diagnostics guide resolves top 3 OAuth issues without support tickets.
- [ ] Partner feedback ≥95% satisfaction on login/credential UX (survey).

## Dependencies
- Identity Federation + Credential Vault features.
- Notification infrastructure (SMS, Slack, email) enumerated in partner profiles.
- Frontend design system updates for secure modal + wizard patterns.

## Risks & Mitigation
| Risk | Mitigation |
| --- | --- |
| Persona creep complicates UX | Limit GA scope to existing 4 partners; treat new partner templates as backlog. |
| Sensitive data exposure in UI | Render decrypted data only transiently, mask by default, require re-auth for reveal. |
| Alert fatigue | Allow partners to tune thresholds + channels per metric. |

## Metrics
- Time-to-onboard new partner (goal: <30 minutes self-serve).
- Number of delegated access approvals per month.
- Support tickets related to login/credential handling (target: ↓70%).
