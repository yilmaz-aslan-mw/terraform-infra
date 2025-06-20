resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.region
  network  = var.vpc_name
  subnetwork = var.subnet_name

  remove_default_node_pool = true
  initial_node_count       = 1

  ip_allocation_policy {}

  deletion_protection = false
}

resource "google_container_node_pool" "lowcost_pool" {
  name     = var.node_pool_name
  cluster  = google_container_cluster.primary.name
  location = var.region

  node_config {
    machine_type = var.machine_type
    preemptible  = var.preemptible
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  initial_node_count = var.initial_node_count
} 