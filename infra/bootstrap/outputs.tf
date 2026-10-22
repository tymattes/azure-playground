# Values each target's backend needs, via -backend-config.
output "state_backends" {
  description = "Per-env backend settings for infra/<target>."
  value = {
    for env in var.environments : env => {
      resource_group_name  = azurerm_resource_group.env[env].name
      storage_account_name = azurerm_storage_account.tfstate[env].name
      container_name       = azurerm_storage_container.tfstate[env].name
    }
  }
}
