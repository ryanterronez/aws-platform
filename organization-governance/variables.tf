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
  description = "Equivalent SCP already effective; null creates our own."
  type        = string
  default     = null
}
