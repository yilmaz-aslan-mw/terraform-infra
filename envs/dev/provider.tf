provider "google" {
  credentials = file("../../terraform-key-${var.project_id}.json")
  project     = var.project_id
  region      = var.region
}
