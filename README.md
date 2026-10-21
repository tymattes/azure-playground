# azure-playground
Hands-on lab for Azure deployment patterns: Terraform IaC, GitHub Actions OIDC pipelines, and a FastAPI service evolving from App Service to containers to serverless.

## Status
- [ ] v1 – App Service (code deploy)
- [ ] v2 – Container Apps
- [ ] v3 – Azure Functions

## Structure
- [`docs/pipeline.md`](docs/pipeline.md) — how changes flow from PR → dev → staging → prod

## Notes / decisions
- **dev → staging → prod:** one subscription, with a separate resource group, state container and deploy identity per environment. Each identity can only touch its own environment. Dev accepts branch builds; staging and prod take `main` only, and prod waits for manual approval.
