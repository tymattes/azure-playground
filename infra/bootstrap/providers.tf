# Subscription comes from ARM_SUBSCRIPTION_ID; credentials from `az login`.
provider "azurerm" {
  features {}

  # Shared keys are disabled on the state accounts, so data-plane calls must use Entra ID.
  storage_use_azuread = true
}
