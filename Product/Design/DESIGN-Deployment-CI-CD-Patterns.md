# DESIGN: Deployment & CI/CD Patterns (SynapticTrading)

---
id: DESIGN-Deployment-CI-CD-Patterns
title: "Deployment & CI/CD Patterns"
product: "SynapticTrading"
artifact_type: "implementation-pattern"
status: "draft"
version: "0.1.0"
created_at: 2025-11-14T10:10:00+0530
updated_at: 2025-11-14T10:10:00+0530
owner: "platform_engineering"
reviewers:
  - engineering_lead
  - quant_lead
  - compliance_officer
tags:
  - deployment
  - docker
  - ci-cd
  - github-actions
  - gatekeeping
related_epics:
  - EPIC-007-StrategyLifecycle
  - EPIC-009-PartnerAccess
references:
  - /Users/nitindhawan/KnowledgeVaults/UPMS_Vault/Methodology/Deployment_and_CI_Patterns.md
  - /Users/nitindhawan/KnowledgeVaults/SynapticTrading_Vault/Product/IMPLEMENTATION_HIERARCHY.md
  - /Users/nitindhawan/Downloads/CodeRepository/SynapticTrading/README.md
---

## Overview

This document applies the UPMS Deployment & CI/CD Implementation Patterns to SynapticTrading. It covers the dev → local test → staging → production flow, Docker usage, GitHub gatekeeping, and shared host policy for all strategy, data pipeline, and partner-access services.

**Code Repository**: `/Users/nitindhawan/Downloads/CodeRepository/SynapticTrading/`

---

## 1. Environment Flow

| Stage | Scope | Requirements | Evidence |
|-------|-------|--------------|----------|
| Development | Quant notebooks, strategy runners, data pipeline modules | Local devcontainers + poetry, git hooks enforcing Story trailers | Notebook export + `make lint` output attached to Story |
| Local Test Stack | Deterministic Airflow-lite + TimescaleDB + strategy simulator | `infra/docker/docker-compose.yml` profile `test` spins up `data-pipeline`, `strategy-sim`, `supporting-db` | `ci/local-sim` logs attached to Feature traceability |
| Server Staging | Shared Docker host `bom-shared-docker-01:/srv/docker/synaptic` running pipelines and REST adapters | GitHub Actions `deploy/staging` with HITL approval from Quant Lead | Workflow URL + QA notes stored in Sprint README |
| Production | Same host pool, segregated namespace `synaptic/prod`, read-only containers + Vault-injected secrets | Tag-driven `deploy/production` workflow; compliance + product approvals | Release record + Telemetry dashboards linked in EPIC change log |

---

## 2. Docker Standards

1. **Images**
   - Strategy services: `ghcr.io/synaptic-platform/python-runtime:3.11-slim` + `poetry install --without dev`.
   - Data ingestion: `ghcr.io/synaptic-platform/data-pipeline:latest` derived image with DAGs mounted at `/app/dags`.
   - Partner access (FastAPI/WS): Node/Go services extend the same base runtime images referenced in the UPMS doc.

2. **Compose Profiles**
   - `dev`: minimal dependencies with mock market data feed.
   - `test`: full stack inc. TimescaleDB, Redis, S3 emulator (MinIO) for catalog tests.
   - `staging`: replicates production config; executed on shared host with `docker stack deploy`.

3. **Image Tagging**
   - `synaptic-<component>-<sha>` for CI builds, `synaptic-<component>-v<semver>` for releases.  
   - Publish to `ghcr.io/synaptic-platform/synaptictrading/<component>:tag`.

4. **Shared Host Usage**
   - Do not allocate bespoke EC2 droplets; request capacity via Platform Ops if quotas exceeded.  
   - Logs routed to central Loki instance; configuration stored under `infra/ansible/group_vars/synaptic.yml`.

---

## 3. GitHub Workflows & Gatekeeping

| Workflow | Notes |
|----------|-------|
| `ci/lint` | `ruff`, `black --check`, `poetry check`, `prettier` for partner UI |
| `ci/unit-tests` | pytest (strategy libs) + db fixtures |
| `ci/integration-tests` | Compose profile `test` running pipeline DAGs + strategy sim smoke run |
| `ci/docker-build` | Build/push all service images, run Trivy scan |
| `ci/upms-compliance` | Validate vault traceability + metadata |
| `ci/security-scan` | Bandit + dependency review |
| `ci/upms-gate-validation` | Aggregates coverage, link checks, vault references (from Gatekeeping proposal §6 & §9) |
| `deploy/staging` | Auto on `develop` merges, requires Quant Lead approval |
| `deploy/production` | Tag `v*`, requires Product Lead + Compliance approvals |

**Branch Protection**
- `main`: all workflows above, 2 approvals (Quant Lead + Code Owner).  
- `release/*`: additional `ci/full-test-suite`, `ci/performance-tests`, `ci/compliance-report`.

**Pull Request Template Requirements**
- Story/Task IDs, deployment impact statement, rollback + data migration notes.  
- Evidence of updated research/design docs when infra changes occur.  
- Checklist item confirming Docker images built locally before requesting review.

---

## 4. Implementation Checklist

1. Scaffold/verify `infra/docker/` + `infra/ansible/` directories in repo.  
2. Add Make targets: `make docker-test`, `make docker-ci-build`, `make deploy-staging`.  
3. Configure shared host namespace + secrets using Platform Ops playbooks; document path in `Product/TechnicalDocumentation/Runbooks/`.  
4. Update Sprint change logs with workflow links + approvals for every deploy.  
5. Run quarterly disaster-recovery drill to confirm backup/restore of TimescaleDB + S3 catalogs.  
6. Feed any deviations back into UPMS Issues for council review.

---

## 5. Change Log

| Date | Author | Version | Notes |
|------|--------|---------|-------|
| 2025-11-14 | platform_engineering | 0.1.0 | Initial draft aligning SynapticTrading with UPMS deployment/CI standard |
