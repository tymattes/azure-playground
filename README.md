# azure-playground
Hands-on lab for Azure deployment patterns: Terraform IaC, GitHub Actions OIDC pipelines, and a FastAPI service evolving from App Service to containers to serverless.

## Status
- [ ] v1 – App Service (code deploy)
- [ ] v2 – Container Apps
- [ ] v3 – Azure Functions

## Local development
Requires [`uv`](https://docs.astral.sh/uv/) and Python 3.12 (matches the Azure runtime).

```sh
uv python install 3.12
uv venv --python 3.12 .venv
source .venv/bin/activate          # once per terminal
uv pip install -r requirements-dev.txt
```

Run the API, then open http://127.0.0.1:8000/health:
```sh
uvicorn main:app --reload --app-dir src/api
```

Run the tests from the repo root:
```sh
pytest
```

## Structure
- [`docs/pipeline.md`](docs/pipeline.md) — how changes flow from PR → dev → staging → prod

## Notes / decisions
- **dev → staging → prod:** one subscription, with a separate resource group, state container and deploy identity per environment. Each identity can only touch its own environment. Dev accepts branch builds; staging and prod take `main` only, and prod waits for manual approval.
