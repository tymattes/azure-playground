terraform {
  required_version = "~> 1.9"

  required_providers {
    # Terraform AzureRM provider is used to create and manage Azure resources.
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    # Random provider generates the globally unique storage account suffix.
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    # Terraform AzureAD provider is used to create and manage Entra ID resources.
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
  }

  # No backend block: bootstrap creates the remote backend, so its own state is local.
}
