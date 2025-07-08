output "cluster_name" {
  description = "The name of the GKE cluster"
  value       = google_container_cluster.primary.name
}

output "node_pool_name" {
  description = "The name of the node pool"
  value       = google_container_node_pool.lowcost_pool.name
}

output "node_service_account_email" {
  description = "The service account email used by the GKE node pool"
  value       = google_service_account.gke_service_account.email
}

output "service_account_email" {
  description = "The service account email for GKE operations"
  value       = google_service_account.gke_service_account.email
} 