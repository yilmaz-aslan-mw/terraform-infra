variable "network_name" {
  description = "Name of the VPC network"
  type        = string
  default     = "my-vpc-network"
}

variable "subnet_name" {
  description = "Name of the subnet"
  type        = string
  default     = "my-subnet"
}

variable "subnet_cidr_range" {
  description = "CIDR range for the subnet"
  type        = string
  default     = "10.0.0.0/24"
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "firewall_name" {
  description = "Name of the firewall rule"
  type        = string
  default     = "allow-internal-and-http"
}

variable "private_ip_range_name" {
  description = "Name of the private IP range for VPC peering"
  type        = string
  default     = "private-ip-range"
} 