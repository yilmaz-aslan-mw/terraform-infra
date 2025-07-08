variable "db_password" {
  description = "Database password for production"
  type        = string
  sensitive   = true
}

variable "api_key" {
  description = "API key for production"
  type        = string
  sensitive   = true
}

variable "clerk_publishable_key" {
  description = "Clerk publishable key for production"
  type        = string
  sensitive   = true
}

variable "clerk_secret_key" {
  description = "Clerk secret key for production"
  type        = string
  sensitive   = true
} 