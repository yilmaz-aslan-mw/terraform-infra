# Production Environment Infrastructure
# Uses modules for reusability and consistency

# GitHub Actions Service Account for CI/CD
module "github_actions_sa" {
  source      = "../../modules/iam"
  account_id  = "github-actions-sa"
  display_name = "GitHub Actions Service Account"
  project_id  = var.project_id
  iam_roles   = [
    "roles/artifactregistry.admin",
    "roles/artifactregistry.reader",
    "roles/artifactregistry.writer",
    "roles/container.developer",
    "roles/storage.admin"
  ]
  create_key  = false
}

module "network" {
  source                = "../../modules/network"
  network_name          = "vpc-network"
  subnet_name           = "subnet"
  subnet_cidr_range     = "10.0.0.0/24"
  region                = var.region
  firewall_name         = "allow-internal-and-http"
  private_ip_range_name = "private-ip-range"
}

module "sql" {
  source                 = "../../modules/sql"
  db_instance_name       = "postgres-instance"
  db_version             = "POSTGRES_14"
  region                 = var.region
  tier                   = "db-f1-micro"
  authorized_network     = "0.0.0.0/0"
  private_network        = module.network.vpc_id
  private_vpc_connection = module.network.private_vpc_connection
  db_name                = "main-application-service"
  db_user                = "myuser"
  db_password            = var.db_password
  depends_on             = [module.network]
}

module "gke" {
  source             = "../../modules/gke"
  cluster_name       = "gke-cluster"
  region             = var.region
  vpc_name           = module.network.vpc_name
  subnet_name        = module.network.subnet_name
  node_pool_name     = "lowcost-pool"
  machine_type       = "e2-small"
  preemptible        = false
  initial_node_count = 1
  project_id         = var.project_id
  depends_on         = [module.network, module.github_actions_sa]
}

module "secrets" {
  source = "../../modules/secrets"
  project_id = var.project_id
  namespace = "default"
  gke_service_account_email = module.gke.service_account_email
  create_namespace = false
  depends_on = [module.gke, module.network, module.sql]
  
  secrets = {
    database_url = {
      name = "main_application_service_database_url"
      value = "postgresql://${module.sql.db_user}:${var.db_password}@${module.sql.private_ip_address}:5432/${module.sql.db_name}"
    }

    clerk_publishable_key = {
      name = "main_application_service_clerk_publishable_key"
      value = var.clerk_publishable_key
    }
    clerk_secret_key = {
      name = "main_application_service_clerk_secret_key"
      value = var.clerk_secret_key
    }
  }
  
  common_labels = {
    app = "vunapay"
    managed_by = "terraform"
  }
}

module "registry" {
  source        = "../../modules/registry"
  project_id    = var.project_id
  region        = var.region
  repository_id = "docker-images"
}

# Static IP for Load Balancer
resource "google_compute_address" "main_app_static_ip" {
  name         = "main-app-static-ip"
  region       = var.region
  project      = var.project_id
  description  = "Static IP for main application service load balancer"
}

# Outputs
output "static_ip_address" {
  description = "Static IP address for the main application service"
  value       = google_compute_address.main_app_static_ip.address
}

output "static_ip_name" {
  description = "Name of the static IP resource"
  value       = google_compute_address.main_app_static_ip.name
}
