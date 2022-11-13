locals {
  master_ipv4_cidr_block = "172.16.0.32/28"
}

resource "google_compute_network" "vpc" {
  name = var.cluster_name
}

resource "google_compute_router" "router" {
  name    = var.cluster_name
  region  = var.gcp_region
  network = google_compute_network.vpc.name
}

resource "google_compute_address" "external_ip"{
  name = "${var.cluster_name}-ext-ip"
  description = "static external IP address"
  region = google_compute_router.router.region
}

resource "google_compute_router_nat" "nat" {

  depends_on = [google_compute_address.external_ip,
    google_compute_router.router]

  name                               = var.cluster_name
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  nat_ip_allocate_option             = "MANUAL_ONLY"
  nat_ips = google_compute_address.external_ip.*.self_link
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

resource "google_compute_firewall" "webhook_firewall" {
  name = "gke-${var.cluster_name}-allow-webhooks"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports = [
      "8443"
    ]
  }

  source_ranges = [
    local.master_ipv4_cidr_block]

  target_tags = [
    "gke-${var.cluster_name}-node"]
}

resource "google_container_cluster" "main" {
  lifecycle {ignore_changes = [node_config]}
  name     = var.cluster_name
  location = var.gcp_region

  network = google_compute_network.vpc.name
  remove_default_node_pool = true
  initial_node_count       = 1
  min_master_version       = var.cluster_min_master_version

  ip_allocation_policy {
    cluster_ipv4_cidr_block  = "/16"
    services_ipv4_cidr_block = "/22"
  }

  private_cluster_config {
    enable_private_nodes = true
    enable_private_endpoint = false
    master_ipv4_cidr_block = local.master_ipv4_cidr_block
  }

  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = var.actian_networks
      content {
        cidr_block   = cidr_blocks.value["cidr_block"]
        display_name = cidr_blocks.value["display_name"]
      }
    }
    dynamic "cidr_blocks" {
      for_each = var.allowed_networks
      content {
        cidr_block   = cidr_blocks.value["cidr_block"]
        display_name = cidr_blocks.value["display_name"]
      }
    }
  }

  workload_identity_config {
    workload_pool = "${var.gcp_project}.svc.id.goog"
  }

  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  addons_config {
    network_policy_config {
      disabled = true
    }
  }

  maintenance_policy {
    daily_maintenance_window {
      start_time = "00:00"
    }
    maintenance_exclusion{
      exclusion_name = "Engineering Summit Window"
      start_time = "2022-11-11T00:00:00Z"
      end_time = "2022-11-18T00:00:00Z"
      exclusion_options {
        scope = "NO_UPGRADES"
      }
    }
  }

  node_config {
    preemptible  = true
    machine_type = "e2-standard-2"
    service_account = google_service_account.service_account.email
    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
    tags = [
      "gke-${var.cluster_name}-node"
    ]
  }

}

resource "google_container_node_pool" "main" {
  name       = "${var.cluster_name}-main-node-pool"
  location   = var.gcp_region
  cluster    = google_container_cluster.main.name
  version = google_container_cluster.main.master_version

  autoscaling {
    max_node_count = var.autoscaling_group_max_size
    min_node_count = var.autoscaling_group_min_size
  }
  initial_node_count = var.autoscaling_group_min_size
  node_config {
    preemptible  = var.preemptible_nodes
    machine_type = var.gcp_machine_type
    service_account = google_service_account.service_account.email
    image_type   = var.node_pool_image_type
    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    tags = [
      "gke-${var.cluster_name}-node"
    ]
  }
  depends_on = [
    google_service_account.service_account,]
}

resource "google_service_account" "service_account" {
  account_id = "gke-${var.cluster_name}"
  display_name = "GKE ${var.cluster_name} Service Account"
  project = var.gcp_project
}
data "google_iam_policy" "main_cluster" {
  binding {
    role = "roles/monitoring.viewer"
    members = [ google_service_account.service_account.email ]
  }
  binding {
    role = "roles/monitoring.metricWriter"
    members = [ google_service_account.service_account.email ]
  }
  binding {
    role = "roles/logging.logWriter"
    members = [ google_service_account.service_account.email ]
  }

}
