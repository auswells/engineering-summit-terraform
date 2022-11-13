terraform {
  required_providers {
    google = "~> 4.31.0"
    kubernetes = "~>2.15.0"
    helm = "~> 2.7.1"
  }
}

provider "google" {
  project = var.gcp_project
  region = var.gcp_region
}

module "gke_cluster" {
  source = "./gke_cluster"

  cluster_name                      = var.cluster_name
  cluster_min_master_version        = var.cluster_min_master_version
  gcp_project                       = var.gcp_project
  gcp_region                        = var.gcp_region
  gcp_zone                          = var.gcp_zone
  gcp_machine_type                  = var.gcp_machine_type
  autoscaling_group_min_size        = var.autoscaling_group_min_size
  autoscaling_group_max_size        = var.autoscaling_group_max_size
  preemptible_nodes                 = var.preemptible_nodes
  actian_networks                   = var.actian_networks
  allowed_networks                  = var.allowed_networks
}

module "argocd_bootstrap" {
  source = "./argocd_bootstrap"

  cluster_name                      = var.cluster_name
  gcp_project                       = var.gcp_project
  cluster_endpoint                  = module.gke_cluster.endpoint
  cluster_certificate               = module.gke_cluster.certificate
}
