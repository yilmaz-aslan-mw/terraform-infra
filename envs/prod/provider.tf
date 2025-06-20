provider "google" {
  credentials = file("../../terraform-key.json")
  project     = "yilmaz-test-app-prod"
  region      = "us-central1"
} 