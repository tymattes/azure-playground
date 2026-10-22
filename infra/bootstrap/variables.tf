variable "environments" {
  description = "Environments that get their own resource group and state storage."
  type        = set(string)
  default     = ["dev", "staging", "prod"]
}

variable "location" {
  description = "Azure region for all bootstrap resources."
  type        = string
  default     = "eastus"
}
