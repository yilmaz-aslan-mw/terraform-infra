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

resource "google_project_iam_member" "roles" {
  for_each = toset(var.iam_roles)
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.this.email}"
}

output "email" {
  value = google_service_account.this.email
}

output "key_private" {
  value     = var.create_key ? google_service_account_key.this[0].private_key : null
  sensitive = true
} 