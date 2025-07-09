output "email" {
  description = "The email address of the created service account"
  value       = google_service_account.this.email
}

output "key_private" {
  description = "The private key for the service account (if created)"
  value       = var.create_key ? google_service_account_key.this[0].private_key : null
  sensitive   = true
} 