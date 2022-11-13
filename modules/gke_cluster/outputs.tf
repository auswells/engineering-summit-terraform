output "kubectl_config" {
  value = "gcloud container clusters get-credentials ${google_container_cluster.main.name} --region=${google_container_cluster.main.location} --project=${var.gcp_project}"
}

output "external_ip" {
  value = google_compute_address.external_ip.address
}

output "endpoint" {
  value = google_container_cluster.main.endpoint
}

output "certificate" {
  value = base64decode(google_container_cluster.main.master_auth[0].cluster_ca_certificate)
}
