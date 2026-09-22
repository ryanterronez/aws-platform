variable "workload_account_name" {
  description = "Workload account name."
  type        = string
  default     = "Areopagus"
}

variable "workload_account_email" {
  description = "Unique AWS account email."
  type        = string
}

variable "existing_account_departure_protection_policy_id" {
  description = "Non-null indicates an equivalent account-departure-protection SCP is already effective; null creates and attaches this stack's policy."
  type        = string
  default     = null
}
