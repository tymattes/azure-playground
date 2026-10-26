# Entra side (Microsoft Graph). Role assignments live in rbac.tf.

data "azuread_client_config" "current" {}

# One deploy identity per env, used by GitHub Actions via OIDC.
resource "azuread_application" "deploy" {
  for_each = var.environments

  display_name = "adp-${each.key}-github-deploy"
  owners       = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal" "deploy" {
  for_each = var.environments

  client_id = azuread_application.deploy[each.key].client_id
  owners    = [data.azuread_client_config.current.object_id]
}

# Trust GitHub OIDC tokens only for jobs running in the matching GitHub environment,
# so that environment's protection rules (branch policy, prod approval) gate Azure access.
resource "azuread_application_federated_identity_credential" "github" {
  for_each = var.environments

  application_id = azuread_application.deploy[each.key].id
  display_name   = "github-${each.key}"
  issuer         = "https://token.actions.githubusercontent.com"
  audiences      = ["api://AzureADTokenExchange"]
  subject        = "repo:${var.github_repository}:environment:${each.key}"
}
