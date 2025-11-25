---
artifact_type: story
created_at: '2025-11-25T16:23:21.847491Z'
id: DESIGN-009
manual_update: true
owner: security_architecture_team
related_epic: TBD
related_feature: TBD
related_story: TBD
requirement_coverage: TBD
seq: 1
sources: null
status: draft
title: Partner Identity & Credential Vault Design
updated_at: '2025-11-25T16:23:21.847498Z'
---

# 1. Design Summary
Build a consolidated identity stack that applies Google OAuth best practices, mock-mode parity, and the broker credential vault to every partner login, while exposing implementation-ready patterns for engineers.

# 2. Architecture Overview
```
Browser (Login, Partner Workspace)
    │
    ▼
FastAPI Identity Service (new)
    ├── OAuth Controller (Google)
    ├── Mock Auth Controller
    ├── Session Manager (JWT + refresh)
    ├── Policy Engine (roles, partner scopes)
    └── Vault Client (Credential Service)
                 │
                 ▼
Credential Vault Service
    ├── AES-256-GCM Encryption
    ├── Key Management (KMS / Vault)
    ├── Rotation Scheduler
    └── Audit Log Stream
```

# 3. Component Design
## 3.1 Identity Service
- **Technology**: FastAPI app colocated with existing backend; reuse middleware in `src/api/routes/auth_oauth_simple.py`.
- **Endpoints**:
  - `POST /api/auth/login/google` → start OAuth (returns redirect URL).
  - `GET /api/auth/google/callback` → exchange code, mint tokens, store refresh token in vault.
  - `POST /api/auth/login/mock` → developer-mode login, still stored via identity service for consistency.
  - `POST /api/auth/token/refresh` → rotate access token.
  - `POST /api/auth/logout` → revoke refresh + access tokens (invalidate vault secret).
- **Policy Enforcement**:
  - Centralize role enum (include `super_admin`, partner-role claims).
  - Issue JWTs with `partner_id`, `auth_mode`, `permissions`.
  - Use dependency injection for ProtectedRoute to read `partner_id`.

## 3.2 Google OAuth Integration
- Follow `docs/00_setup_guides/google_oauth_setup.md` for project + redirect URIs.
- **Implementation Guidance**:
  1. Keep OAuth client IDs per environment in `config/<env>/auth.json`.
  2. Validate redirect URIs via automated script every release (curl + diff).
  3. Use `state` parameter to encode `partner_id`/nonce for CSRF protection.
  4. Store `id_token` claims only transiently; persist only refresh tokens (encrypted).
  5. Log OAuth failures with correlation ID and sanitized error reason.

## 3.3 Session & Token Lifecycle
- **Token Set**:
  - Access token: 15 minutes, stored in memory/localStorage.
  - Refresh token: 30 days, encrypted in vault with metadata `next_rotation_at`.
  - Remember-me flag extends refresh token TTL to 24h sliding window for dev, configurable per env.
- **Silent Renew**: Frontend `EnhancedAuthContext` schedules refresh at 80% of TTL; fallback to BroadcastChannel to notify other tabs.
- **Forced Logout**: On refresh failure, identity service emits WebSocket event for workspace; UI prompts re-login.

## 3.4 Credential Vault Service
- Extend broker encryption module:
  - Introduce `partner_credentials` table (`id`, `partner_id`, `type`, `payload_encrypted`, `key_version`, `expires_at`, `metadata`).
  - Apply Row Level Security with `partner_id = current_setting('app.partner_id')`.
  - Encrypt payload using AES-256-GCM; derive data keys via AWS KMS or HashiCorp Vault transit engine.
  - Key rotation service: nightly job rotates keys, updates `key_version`, re-encrypts payload.
- **API Contract**:
  - `POST /vault/credentials` → store secret.
  - `GET /vault/credentials/{id}` → fetch + decrypt (requires scoped permissions).
  - `POST /vault/credentials/{id}/rotate` → rotate secret, update metadata, emit audit event.

## 3.5 Partner Workspace UX
- **Pages**:
  - `LoginHealthView`: charts login success, token age, active sessions.
  - `CredentialManager`: list all broker/OAuth credentials with status.
  - `DelegatedAccess`: table of granted scopes, expiration, revoke button.
  - `Diagnostics`: embeds troubleshooting steps (OAuth fix instructions) + button to run Playwright smoke test (calls backend script).
- **State Management**: Use Redux slice `partnerAccessSlice` powered by `/api/partner-access/*` endpoints.
- **Security**: Mask all secrets by default; require secondary confirmation (OTP/email) before revealing once.

## 3.6 Observability & Testing
- **Metrics**: publish to Prometheus
  - `identity_login_success_total{mode,partner}`  
  - `identity_login_latency_seconds` histogram  
  - `vault_rotation_errors_total`  
  - `oauth_redirect_validation_failures_total`
- **Logging**: Structured logs with fields `partner_id`, `auth_mode`, `oauth_stage`.
- **Tests**:
  - Unit tests for role enum & policy engine.
  - Integration tests for OAuth callback storing tokens in vault (use mock KMS).
  - Playwright suite triggered on CI + nightly real OAuth run (requires manual seed token).

# 4. Implementation Guidance
1. **Migration Strategy**
   - Phase 1: Identity service proxies to existing auth routes; double-write refresh tokens to vault while still reading from legacy store.
   - Phase 2: Flip read path to vault; monitor metrics; remove legacy code.
2. **Environment Management**
   - Provide `config/dev`, `config/staging`, `config/prod` for OAuth credentials and vault endpoints.
   - Document Google Console steps per environment with versioned JSON.
3. **Security Hardening**
   - Enforce TLS on all auth + vault endpoints; add HSTS headers.
   - Implement rate limiting (e.g., 5 login attempts/min per IP + partner).
   - Integrate with compliance logger (refer to `src/discord_trading/compliance_logger.py` patterns for encryption keys).
4. **Operational Runbooks**
   - OAuth redirect mismatch: script `scripts/oauth_verify.py` hits callback and compares response.
   - Vault outage: degrade gracefully by caching short-lived refresh tokens in memory; notify partners via workspace banner.
   - Key rotation failure: auto-roll back to previous key version, alert security on-call.
5. **Tooling**
   - Create CLI `scripts/partner_access_admin.py` for support staff to inspect partner sessions, revoke tokens, or trigger Playwright test.
   - Add GitHub workflow `partner-access-smoke.yml` that:
     1. Spins up backend/frontend.
     2. Runs Playwright auth test using mock mode.
     3. Uploads screenshots/logs on failure.

# 5. Open Items
- Decide between AWS KMS vs. HashiCorp Vault transit (depends on infra roadmap).
- Validate whether partner-delegated access needs approval workflows beyond simple confirmation.
- Align with compliance/legal on log retention and PII masking for audit exports.
