# Dev Environment Infrastructure
# Uses modules for reusability and consistency

module "network" {
  source                = "../../modules/network"
  network_name          = "${var.environment}-vpc-network"
  subnet_name           = "${var.environment}-subnet"
  subnet_cidr_range     = "10.0.0.0/24"
  region                = var.region
  firewall_name         = "allow-internal-and-http"
  private_ip_range_name = "${var.environment}-private-ip-range"
}

module "sql" {
  source                 = "../../modules/sql"
  db_instance_name       = "${var.environment}-postgres-instance"
  db_version             = "POSTGRES_14"
  region                 = var.region
  tier                   = "db-f1-micro"
  authorized_network     = "0.0.0.0/0"
  private_network        = module.network.vpc_id
  private_vpc_connection = module.network.private_vpc_connection
  db_name                = "main-application-service"
  db_user                = "myuser"
  db_password            = var.db_password
}

module "gke" {
  source             = "../../modules/gke"
  cluster_name       = "${var.environment}-gke-cluster"
  region             = var.region
  vpc_name           = module.network.vpc_name
  subnet_name        = module.network.subnet_name
  node_pool_name     = "lowcost-pool"
  machine_type       = "e2-small"
  preemptible        = false
  initial_node_count = 1
  project_id         = var.project_id
  environment        = var.environment   # <-- Add this line

}

# Secrets management using the secrets module
module "secrets" {
  source = "../../modules/secrets"
  project_id = var.project_id
  environment = var.environment
  namespace = "default"
  gke_service_account_email = module.gke.service_account_email
  create_namespace = false
  depends_on = [module.gke]
  
  secrets = {
    database_url = {
      name = "dev_main_application_service_database_url"
      value = "postgresql://dbuser:${var.db_password}@${module.sql.instance_connection_name}:5432/mydb"
    }

    clerk_publishable_key = {
      name = "dev_main_application_service_clerk_publishable_key"
      value = var.clerk_publishable_key
    }
    clerk_secret_key = {
      name = "dev_main_application_service_clerk_secret_key"
      value = var.clerk_secret_key
    }
  }
  
  common_labels = {
    app = "vunapay"
    environment = "dev"
    managed_by = "terraform"
  }
}
module "registry" {
  source        = "../../modules/registry"
  project_id    = var.project_id
  region        = var.region
  repository_id = "docker-images" # or another name you prefer
}
