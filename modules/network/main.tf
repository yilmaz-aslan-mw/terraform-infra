# VPC Network
resource "google_compute_network" "vpc_network" {
  name                    = var.network_name
  auto_create_subnetworks = false
}

# Subnet
resource "google_compute_subnetwork" "subnet" {
  name          = var.subnet_name
  ip_cidr_range = var.subnet_cidr_range
  network       = google_compute_network.vpc_network.id
  region        = var.region
}

# Firewall rule (allow HTTP, HTTPS, internal)
resource "google_compute_firewall" "default" {
  name    = var.firewall_name
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [var.subnet_cidr_range]
}

# Global address for VPC peering (must come before service networking)
resource "google_compute_global_address" "private_ip_range" {
  name          = var.private_ip_range_name
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc_network.id
}

# Service networking connection (must come before Cloud SQL)
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_range.name]
  
  depends_on = [google_compute_global_address.private_ip_range]
} 