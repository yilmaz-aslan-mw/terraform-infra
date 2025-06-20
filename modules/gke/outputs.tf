output "cluster_name" {
  description = "The name of the GKE cluster"
  value       = google_container_cluster.primary.name
}

output "node_pool_name" {
  description = "The name of the node pool"
  value       = google_container_node_pool.lowcost_pool.name
} 