# Dev Environment Infrastructure
# Uses modules for reusability and consistency

module "network" {
  source                = "../../modules/network"
  network_name          = "dev-vpc-network"
  subnet_name           = "dev-subnet"
  subnet_cidr_range     = "10.0.0.0/24"
  region                = "us-central1"
  firewall_name         = "allow-internal-and-http"
  private_ip_range_name = "private-ip-range"
}

module "sql" {
  source                 = "../../modules/sql"
  db_instance_name       = "dev-postgres-instance"
  db_version             = "POSTGRES_14"
  region                 = "us-central1"
  tier                   = "db-f1-micro"
  authorized_network     = "0.0.0.0/0"
  private_network        = module.network.vpc_id
  private_vpc_connection = module.network.private_vpc_connection
  db_name                = "mydb"
  db_user                = "dbuser"
  db_password            = "your-secure-password" # Better to store in secret manager
}

module "gke" {
  source             = "../../modules/gke"
  cluster_name       = "dev-gke-cluster"
  region             = "us-central1"
  vpc_name           = module.network.vpc_name
  subnet_name        = module.network.subnet_name
  node_pool_name     = "lowcost-pool"
  machine_type       = "e2-small"
  preemptible        = false
  initial_node_count = 1
}

