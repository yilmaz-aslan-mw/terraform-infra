variable "account_id" {
  description = "The account ID for the service account (no domain, just the name)"
  type        = string
}

variable "display_name" {
  description = "The display name for the service account"
  type        = string
}

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "iam_roles" {
  description = "List of IAM roles to assign to the service account"
  type        = list(string)
}

variable "create_key" {
  description = "Whether to create and output a service account key"
  type        = bool
  default     = false
} 