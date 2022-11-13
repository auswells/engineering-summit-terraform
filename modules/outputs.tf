output "kubectl_config" {
  value = module.gke_cluster.kubectl_config
}

output "cluster_nat_external_ip" {
  value = module.gke_cluster.external_ip
}
