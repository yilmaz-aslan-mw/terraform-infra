# Staging Environment Infrastructure
# Uses separate GCP project for complete isolation

module "network" {
  source                = "../../modules/network"
  network_name          = "stage-vpc-network"
  subnet_name           = "stage-subnet"
  subnet_cidr_range     = "10.2.0.0/24"
  region                = "us-central1"
  firewall_name         = "allow-internal-and-http"
  private_ip_range_name = "stage-private-ip-range"
}

module "sql" {
  source                 = "../../modules/sql"
  db_instance_name       = "stage-postgres-instance"
  db_version             = "POSTGRES_14"
  region                 = "us-central1"
  tier                   = "db-f1-micro"  # Same as dev for cost
  authorized_network     = "0.0.0.0/0"
  private_network        = module.network.vpc_id
  private_vpc_connection = module.network.private_vpc_connection
  db_name                = "vunapay_stage"
  db_user                = "vunapay_user"
  db_password            = "your-secure-stage-password"
}

module "gke" {
  source             = "../../modules/gke"
  cluster_name       = "stage-gke-cluster"
  region             = "us-central1"
  vpc_name           = module.network.vpc_name
  subnet_name        = module.network.subnet_name
  node_pool_name     = "stage-pool"
  machine_type       = "e2-small"
  preemptible        = false
  initial_node_count = 1
  project_id         = "ya-test-project-1-stage"  # Separate project
}

# External Secrets Service Account for Staging
resource "google_service_account" "external_secrets" {
  account_id   = "external-secrets-sa"
  display_name = "External Secrets Operator Service Account - Staging"
  project      = "ya-test-project-1-stage"
}

# Workload Identity binding for External Secrets Operator
resource "google_service_account_iam_member" "external_secrets_wi" {
  service_account_id = google_service_account.external_secrets.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:ya-test-project-1-stage.svc.id.goog[default/external-secrets-sa]"
}

# Secret Manager access for External Secrets
resource "google_project_iam_member" "external_secrets_secretmanager" {
  project = "ya-test-project-1-stage"
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.external_secrets.email}"
}

# Secrets management using the secrets module
module "secrets" {
  source = "../../modules/secrets"
  
  project_id = "ya-test-project-1-stage"
  environment = "stage"
  namespace = "default"
  create_namespace = false
  gke_service_account_email = module.gke.service_account_email
  
  secrets = {
    database_url = {
      name = "stage_main_application_service_database_url"
      value = "postgresql://vunapay_user:your-secure-stage-password@${module.sql.instance_connection_name}:5432/vunapay_stage"
    }
    api_key = {
      name = "stage_main_application_service_api_key"
      value = "stage-api-key-67890"
    }
    clerk_publishable_key = {
      name = "stage_main_application_service_clerk_publishable_key"
      value = "pk_test_stage_clerk_publishable_key"
    }
    clerk_secret_key = {
      name = "stage_main_application_service_clerk_secret_key"
      value = "sk_test_stage_clerk_secret_key"
    }
  }
  
  common_labels = {
    app = "vunapay"
    environment = "stage"
    managed_by = "terraform"
  }
} 