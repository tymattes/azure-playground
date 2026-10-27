locals {
  tags = {
    project    = "azure-playground"
    managed_by = "terraform-bootstrap"
  }
}

# Storage account names are global, 3-24 chars, lowercase alphanumeric only.
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# One resource group per env, to isolate resources and RBAC.
resource "azurerm_resource_group" "env" {
  for_each = var.environments

  name     = "adp-${each.key}-rg"
  location = var.location
  tags     = merge(local.tags, { env = each.key })
}

# One account per env: RG Contributor can list keys, and a key bypasses
# container-scoped RBAC, so only separate accounts isolate envs.
resource "azurerm_storage_account" "tfstate" {
  for_each = var.environments

  name                     = "adp${each.key}tf${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.env[each.key].name
  location                 = azurerm_resource_group.env[each.key].location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  min_tls_version                 = "TLS1_2"
  shared_access_key_enabled       = false
  allow_nested_items_to_be_public = false

  blob_properties {
    versioning_enabled = true
  }

  tags = merge(local.tags, { env = each.key })
}

# Container names are 3-63 chars: lowercase letters, numbers and single hyphens, starting with a letter or number.
resource "azurerm_storage_container" "tfstate" {
  for_each = var.environments

  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.tfstate[each.key].id
  container_access_type = "private"
}

# Blocks deleting the state account, and therefore its RG, until the lock is removed.
# Control plane only: blobs can still be overwritten or deleted (versioning covers that).
# Deploy SPs are Contributor, which can't remove locks.
resource "azurerm_management_lock" "tfstate" {
  for_each = var.environments

  name       = "tfstate-lock"
  scope      = azurerm_storage_account.tfstate[each.key].id
  lock_level = "CanNotDelete"
  notes      = "Protects the tfstate storage account from accidental deletion."
}
