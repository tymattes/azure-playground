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
- **Environments:** `dev` → `staging` → `prod`, same names everywhere (GitHub, Azure, Terraform). One subscription, one resource group per env. `dev` is the playground (any branch); `staging` is the prod-like gate (`main` only).
- **Terraform from day one**, split into:
  - `infra/bootstrap/` — run once locally with `az login`. Per env: a resource group, a tfstate container, and an Entra app registration (federated credential `environment:<env>`) with Contributor on that env's RG and Storage Blob Data Contributor on that env's state container only. The dev identity can't touch prod, and the pipeline never needs Owner.
    - **One storage account per env** (in that env's RG), not a shared one: RG Contributor can `listKeys`, and a key bypasses container-scoped RBAC, so only separate accounts truly isolate envs. Shared key access disabled, blob versioning on; delete lock later.
    - **Bootstrap's own state is local** (gitignored, backed up outside the repo): it creates the remote backend (chicken-and-egg), has one operator, rarely changes, and is recoverable via `import` blocks. In a team it would move to a separately governed account.
  - `infra/<target>/` (`appservice/`, `containerapps/`, `functions/`) — run by the pipeline. Same code for every env; differences in `<env>.tfvars`. State: `<target>.tfstate` in the env's container, chosen with `-backend-config`; backend uses `use_azuread_auth = true` (RBAC, not storage keys). No workspaces.
- **Pipeline:**
  - **PR:** test + `terraform fmt/validate/plan`. *Open question:* which identity runs PR plans.
  - **Manual (`workflow_dispatch`):** test + build a chosen branch → deploy to **dev** only. The next merge resets dev to `main`.
  - **Merge to `main`:** test + build one artifact (*open question for v1:* ship deps in the zip, or let App Service `pip install` per env) → **dev** → **staging** (automatic) → **prod** (⏸ approval first — the only manual gate). Each env: plan + apply, deploy the **same** artifact, `/health` check.
  - A `concurrency:` group per env so runs queue instead of racing.
- **Guardrails:** `main` requires a PR (add required status checks once workflows exist). GitHub envs: `staging` and `prod` deploy from `main` only (deployment branch policy); `prod` requires my approval. CODEOWNERS on `infra/` + `.github/`; Dependabot for pip + Actions.
- **Rollback:** app → redeploy the previous artifact; infra → revert the PR and re-apply.
- **One repo, side-by-side targets**, each with its own workflow (path filters). Milestones saved as git tags (e.g. `v1-app-service`), then `terraform destroy` all envs to save cost.
- **Naming:** `adp-<env>-…` plus a `random_string` suffix for globally unique names. Cheapest SKUs.

## Planned layout
```
infra/bootstrap/
infra/appservice/  infra/containerapps/  infra/functions/   (each with dev/staging/prod.tfvars)
src/api/  src/functions/
.github/workflows/appservice.yml  containerapps.yml  functions.yml
docs/pipeline.md   (pipeline diagrams; update in the same PR as workflow changes)
```

## Later iterations (after v1)
Read-only plan identity (PR plans + approve the exact saved prod plan) · App Service deployment slot + swap for zero-downtime prod deploys · modules · Key Vault + managed identity · tflint/checkov + drift detection.

## Current milestone
- [ ] Step 0: Azure account + budget alert, `az`/`terraform`/Python 3.12 installed, Terraform entries added to `.gitignore` (commit `.terraform.lock.hcl` and the `*.tfvars` files — they hold no secrets here)
  - [x] Python 3.12 (via uv)
  - [x] `az` + `terraform` installed, Terraform entries in `.gitignore`
  - [ ] Budget alert confirmed saved
- [x] Local FastAPI app with `GET /health` → `{"status": "ok"}`, one pytest test (FastAPI `TestClient`), runs with `uvicorn`
- [x] `infra/bootstrap` — state storage only first; init/plan/apply by hand, inspect in the portal
- [ ] `infra/bootstrap` identities — per-env Entra app registration, federated credential, role assignments; delete locks on state accounts
