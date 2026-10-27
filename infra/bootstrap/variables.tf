# This file contains variables for the bootstrap module. The bootstrap module creates the resource groups and storage accounts for each environment, as well as the Entra ID identities that will be used to access those resources.
variable "environments" {
  description = "Environments that get their own resource group and state storage."
  type        = set(string)
  default     = ["dev", "staging", "prod"]
}

# The Azure region for all bootstrap resources. The region is used for the RGs and storage accounts, but not for Entra ID identities, which are global.
variable "location" {
  description = "Azure region for all bootstrap resources."
  type        = string
  default     = "eastus"
}

# Pinned in each federated credential's subject alongside `environment:<env>`; the GitHub
# environment's protection rules (branch policy, prod approval) are what gate access.
variable "github_repository" {
  description = "GitHub repo (owner/name) whose environments may federate into each env's identity."
  type        = string
  default     = "tymattes/azure-playground"
}
