output "instance_name" {
  description = "The name of the Cloud SQL instance"
  value       = google_sql_database_instance.postgres_instance.name
}

output "db_name" {
  description = "The name of the database"
  value       = google_sql_database.default_db.name
}

output "db_user" {
  description = "The database user name"
  value       = google_sql_user.users.name
}

output "instance_connection_name" {
  description = "The connection name of the Cloud SQL instance (for connecting from GKE)"
  value       = google_sql_database_instance.postgres_instance.connection_name
} 