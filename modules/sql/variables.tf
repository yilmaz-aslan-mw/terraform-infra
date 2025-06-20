variable "db_instance_name" {
  description = "Name of the Cloud SQL instance"
  type        = string
}

variable "db_version" {
  description = "Database version (e.g., POSTGRES_14)"
  type        = string
  default     = "POSTGRES_14"
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "tier" {
  description = "Machine tier for Cloud SQL instance"
  type        = string
  default     = "db-f1-micro"
}

variable "authorized_network" {
  description = "CIDR for authorized network access"
  type        = string
  default     = "0.0.0.0/0"
}

variable "private_network" {
  description = "VPC network ID for private IP"
  type        = string
}

variable "private_vpc_connection" {
  description = "Private VPC connection resource for dependency"
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_user" {
  description = "Database user name"
  type        = string
}

variable "db_password" {
  description = "Database user password"
  type        = string
} 