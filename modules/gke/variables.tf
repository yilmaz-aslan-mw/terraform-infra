variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "vpc_name" {
  description = "VPC network name"
  type        = string
}

variable "subnet_name" {
  description = "Subnet name"
  type        = string
}

variable "node_pool_name" {
  description = "Name of the node pool"
  type        = string
  default     = "lowcost-pool"
}

variable "machine_type" {
  description = "Machine type for nodes"
  type        = string
  default     = "e2-small"
}

variable "preemptible" {
  description = "Whether nodes are preemptible"
  type        = bool
  default     = false
}

variable "initial_node_count" {
  description = "Initial node count"
  type        = number
  default     = 1
} 