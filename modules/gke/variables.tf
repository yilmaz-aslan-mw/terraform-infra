variable "cluster_name" {
  description = "The name of the GKE cluster"
  type        = string
}

variable "region" {
  description = "The region where the cluster will be created"
  type        = string
}

variable "vpc_name" {
  description = "The name of the VPC network"
  type        = string
}

variable "subnet_name" {
  description = "The name of the subnet"
  type        = string
}

variable "node_pool_name" {
  description = "The name of the node pool"
  type        = string
}

variable "machine_type" {
  description = "The machine type for the nodes"
  type        = string
  default     = "e2-small"
}

variable "preemptible" {
  description = "Whether to use preemptible nodes"
  type        = bool
  default     = false
}

variable "initial_node_count" {
  description = "The initial number of nodes in the pool"
  type        = number
  default     = 1
}

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "environment" {
  description = "The environment name"
  type        = string
}