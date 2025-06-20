provider "google" {
  credentials = file("../../terraform-key.json")
  project     = "yilmaz-test-app-stage"
  region      = "us-central1"
} 