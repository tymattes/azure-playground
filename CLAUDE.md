# CLAUDE.md

## How to work with me
I'm building this to **learn** Azure CI/CD. Coach, don't build.
- Default to hints, questions, and code review. Don't write code or config for me unless I explicitly ask.
- When I'm stuck, give the smallest nudge that unblocks me (a concept, a doc link, the name of a resource or flag), then escalate only if I ask.
- Explain the *why* behind Azure/Terraform/GitHub Actions choices — I want to be able to explain this project in an interview.
- Keep answers short. I usually have limited time per session.
- Background: 11+ years backend (AWS, Kafka, API design). New to Azure. Python is my language here.

## Goal
One Python (FastAPI) REST API deployed to Azure three ways, each via GitHub Actions + Terraform:
1. **v1 – App Service** (code deploy, no containers)
2. **v2 – Container Apps** (Dockerfile → ACR → Container Apps)
3. **v3 – Azure Functions** (same API, serverless)

AKS is out of scope for now. Repo is **public** (needed for free branch protection + environments).

## Decisions so far
- **Auth:** GitHub Actions → Azure via OIDC (federated credentials). No client secrets, no publish profiles.
- **Terraform from day one**, split into:
  - `infra/bootstrap/` — run once locally with `az login`: tfstate storage, app resource group(s), Entra app registration + federated credentials (`pull_request` for plan, `environment:production` for apply), role assignments (Contributor on the app RG, Storage Blob Data Contributor on the state container). Role assignments live here so the pipeline never needs Owner.
  - `infra/<target>/` (`appservice/`, `containerapps/`, `functions/`) — run by the pipeline. Separate state key per target.
- **Pipeline shape:** PR → test + `terraform fmt/validate/plan`. Merge to `main` → test → `terraform apply` → deploy app → `/health` smoke check.
- **Repo guardrails:** branch protection on `main` (PR + required checks), GitHub environment `production`.
- **One repo, side-by-side targets.** Each target gets its own workflow with path filters.
- **Milestones saved as git tags** (e.g. `v1-app-service`). `terraform destroy` old targets after tagging to save cost.
- Resource naming prefix: short (e.g. `adp`) with a `random_string` suffix for globally unique names.

## Planned layout
```
infra/bootstrap/  infra/appservice/  infra/containerapps/  infra/functions/
src/api/          src/functions/
.github/workflows/appservice.yml  containerapps.yml  functions.yml
```

## Later iterations (after v1)
Staging slot + swap · separate read-only plan identity · required reviewers on `production` · modules + dev/prod envs · Key Vault + managed identity · tflint/checkov + drift detection.

## Current milestone
- [ ] Step 0: Azure account + budget alert, `az`/`terraform`/Python 3.12 installed, Terraform entries added to `.gitignore` (commit `.terraform.lock.hcl`)
- [ ] Local FastAPI app with `GET /health` → `{"status": "ok"}`, one pytest test (FastAPI `TestClient`), runs with `uvicorn`
- [ ] `infra/bootstrap` — state storage only first; init/plan/apply by hand, inspect in the portal
