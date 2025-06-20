provider "google" {
  credentials = file("../../terraform-key.json")
  project     = "yilmaz-test-app-dev-1"
  region      = "us-central1"
}
