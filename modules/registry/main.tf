resource "google_artifact_registry_repository" "docker_repo" {
  provider      = google
  project       = var.project_id
  location      = var.region
  repository_id = var.repository_id
  description   = "Docker repository for application images"
  format        = "DOCKER"
}