data "google_client_config" "provider" {}

module "aw_es_argocd" {
  source = "./modules"

  cluster_name = "aw-es-argocd"
  cluster_min_master_version = "1.21"
  gcp_project = "datacloud-dev"
  gcp_region = "us-east1"
  gcp_zone = "us-east1-b"
  gcp_machine_type = "n2-standard-4"
  autoscaling_group_min_size = 1
  autoscaling_group_max_size = 4
  preemptible_nodes = false
  actian_networks = [
    { cidr_block = "149.20.195.26/32", display_name = "Dallas Cato VPN IP" }
  ]
  allowed_networks = []
}

module "aw_es_dev" {
  source = "./modules"

  cluster_name = "aw-es-dev"
  cluster_min_master_version = "1.21"
  gcp_project = "datacloud-dev"
  gcp_region = "us-east1"
  gcp_zone = "us-east1-b"
  gcp_machine_type = "n2-standard-4"
  autoscaling_group_min_size = 1
  autoscaling_group_max_size = 3
  preemptible_nodes = false
  actian_networks = [
    { cidr_block = "149.20.195.26/32", display_name = "Dallas Cato VPN IP" }
  ]
  allowed_networks = [
    { cidr_block = "${module.aw_es_argocd.cluster_nat_external_ip}/32", display_name = "ArgoCD"}
  ]
}

module "aw_es_prod" {
  source = "./modules"

  cluster_name = "aw-es-prod"
  cluster_min_master_version = "1.21"
  gcp_project = "datacloud-dev"
  gcp_region = "us-east1"
  gcp_zone = "us-east1-b"
  gcp_machine_type = "n2-standard-4"
  autoscaling_group_min_size = 1
  autoscaling_group_max_size = 3
  preemptible_nodes = false
  actian_networks = [
    { cidr_block = "149.20.195.26/32", display_name = "Dallas Cato VPN IP" }
  ]
  allowed_networks = [
    { cidr_block = "${module.aw_es_argocd.cluster_nat_external_ip}/32", display_name = "ArgoCD"}
  ]
}
