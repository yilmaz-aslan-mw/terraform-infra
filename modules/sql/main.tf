resource "google_sql_database_instance" "postgres_instance" {
  name             = var.db_instance_name
  database_version = var.db_version
  region           = var.region
  deletion_protection = false

  settings {
    tier = var.tier
    ip_configuration {
      authorized_networks {
        value = var.authorized_network
        name  = "public"
      }
      ipv4_enabled        = true
      private_network     = var.private_network
    }
  }
  depends_on = [var.private_vpc_connection]
}

resource "google_sql_database" "default_db" {
  name     = var.db_name
  instance = google_sql_database_instance.postgres_instance.name
}

resource "google_sql_user" "users" {
  name     = var.db_user
  instance = google_sql_database_instance.postgres_instance.name
  password = var.db_password
} 