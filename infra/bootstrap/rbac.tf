# Azure RBAC (ARM). Identities themselves live in identity.tf.

# Deploy identity manages everything in its own env's RG, and nothing outside it.
resource "azurerm_role_assignment" "deploy_rg_contributor" {
  for_each = var.environments

  scope                = azurerm_resource_group.env[each.key].id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.deploy[each.key].object_id
  # Skip the Graph lookup so a just-created SP doesn't fail with "principal not found".
  principal_type = "ServicePrincipal"
}

# Data-plane access to its own state container only (shared keys are off, so this is the only way in).
resource "azurerm_role_assignment" "deploy_tfstate_blob" {
  for_each = var.environments

  scope                = azurerm_storage_container.tfstate[each.key].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.deploy[each.key].object_id
  principal_type       = "ServicePrincipal"
}

# Operator (whoever runs bootstrap) gets standing data-plane access for state recovery and inspection.
resource "azurerm_role_assignment" "operator_tfstate_blob" {
  for_each = var.environments

  scope                = azurerm_storage_container.tfstate[each.key].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azuread_client_config.current.object_id
}
