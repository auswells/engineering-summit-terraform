output "aw_es_argocd_kube_context" {
  value = module.aw_es_argocd.kubectl_config
}

output "aw_es_dev_kube_context" {
  value = module.aw_es_dev.kubectl_config
}

output "aw_es_prod_kube_context" {
  value = module.aw_es_prod.kubectl_config
}
