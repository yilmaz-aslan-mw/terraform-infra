provider "google" {
  credentials = file("../../terraform-key.json")
  project     = "test-app-stage"
  region      = "us-central1"
} 