# Production Environment Infrastructure
# Uses separate GCP project for complete isolation

module "network" {
  source                = "../../modules/network"
  network_name          = "prod-vpc-network"
  subnet_name           = "prod-subnet"
  subnet_cidr_range     = "10.1.0.0/24"
  region                = "us-central1"
  firewall_name         = "allow-internal-and-https"
  private_ip_range_name = "prod-private-ip-range"
}

module "sql" {
  source                 = "../../modules/sql"
  db_instance_name       = "prod-postgres-instance"
  db_version             = "POSTGRES_14"
  region                 = "us-central1"
  tier                   = "db-custom-1-3840"  # Production tier
  authorized_network     = "0.0.0.0/0"
  private_network        = module.network.vpc_id
  private_vpc_connection = module.network.private_vpc_connection
  db_name                = "vunapay_prod"
  db_user                = "vunapay_user"
  db_password            = var.db_password  # Use variable for sensitive data
}

module "gke" {
  source             = "../../modules/gke"
  cluster_name       = "prod-gke-cluster"
  region             = "us-central1"
  vpc_name           = module.network.vpc_name
  subnet_name        = module.network.subnet_name
  node_pool_name     = "prod-pool"
  machine_type       = "e2-standard-2"  # Production machine type
  preemptible        = false
  initial_node_count = 2  # Production minimum
  project_id         = "ya-test-project-1-prod"
}

# External Secrets Service Account for Production
resource "google_service_account" "external_secrets" {
  account_id   = "external-secrets-sa"
  display_name = "External Secrets Operator Service Account - Production"
  project      = "ya-test-project-1-prod"
}

# Workload Identity binding for External Secrets Operator
resource "google_service_account_iam_member" "external_secrets_wi" {
  service_account_id = google_service_account.external_secrets.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:ya-test-project-1-prod.svc.id.goog[default/external-secrets-sa]"
}

# Secret Manager access for External Secrets
resource "google_project_iam_member" "external_secrets_secretmanager" {
  project = "ya-test-project-1-prod"
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.external_secrets.email}"
}

# Secrets management using the secrets module
module "secrets" {
  source = "../../modules/secrets"
  
  project_id = "ya-test-project-1-prod"
  environment = "prod"
  namespace = "default"
  create_namespace = false
  gke_service_account_email = module.gke.service_account_email
  
  secrets = {
    database_url = {
      name = "prod_main_application_service_database_url"
      value = "postgresql://vunapay_user:${var.db_password}@${module.sql.instance_connection_name}:5432/vunapay_prod"
    }
    api_key = {
      name = "prod_main_application_service_api_key"
      value = var.api_key
    }
    clerk_publishable_key = {
      name = "prod_main_application_service_clerk_publishable_key"
      value = var.clerk_publishable_key
    }
    clerk_secret_key = {
      name = "prod_main_application_service_clerk_secret_key"
      value = var.clerk_secret_key
    }
  }
  
  common_labels = {
    app = "vunapay"
    environment = "prod"
    managed_by = "terraform"
  }
} 