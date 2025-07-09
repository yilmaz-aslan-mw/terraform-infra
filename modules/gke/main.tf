# GKE Service Account
resource "google_service_account" "gke_service_account" {
  account_id   = "gke-service-account"
  display_name = "GKE Service Account"
  project      = var.project_id
}

# IAM bindings for GKE service account
resource "google_project_iam_binding" "gke_roles" {
  for_each = toset([
    "roles/secretmanager.secretAccessor",
    "roles/artifactregistry.reader"
  ])
  project = var.project_id
  role    = each.value
  members = ["serviceAccount:${google_service_account.gke_service_account.email}"]
}

resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.region
  network  = var.vpc_name
  subnetwork = var.subnet_name

  remove_default_node_pool = true
  initial_node_count       = 1

  ip_allocation_policy {}

  deletion_protection = false

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
}

resource "google_container_node_pool" "lowcost_pool" {
  name     = var.node_pool_name
  cluster  = google_container_cluster.primary.name
  location = var.region

  node_config {
    machine_type = var.machine_type
    preemptible  = var.preemptible
    service_account = google_service_account.gke_service_account.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }

  initial_node_count = var.initial_node_count
} 