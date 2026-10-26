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
