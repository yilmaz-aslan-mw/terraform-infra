provider "google" {
  credentials = file("../../terraform-key.json")
  project     = "test-app-dev"
  region      = "us-central1"
}
