resource "google_service_account" "this" {
  account_id   = var.account_id
  display_name = var.display_name
  project      = var.project_id
}

resource "google_service_account_key" "this" {
  count              = var.create_key ? 1 : 0
  service_account_id = google_service_account.this.name
  keepers = {
    key_version = 1
  }
}

resource "google_project_iam_binding" "roles" {
  for_each = toset(var.iam_roles)
  project  = var.project_id
  role     = each.value
  members  = ["serviceAccount:${google_service_account.this.email}"]
} 