# Retrieve an access token as the Terraform runner
data "google_client_config" "provider" {}

provider "kubernetes" {
  host = "https://${var.cluster_endpoint}"
  token = data.google_client_config.provider.access_token
  cluster_ca_certificate = var.cluster_certificate
}

provider "helm" {
  kubernetes {
    host = "https://${var.cluster_endpoint}"
    token = data.google_client_config.provider.access_token
    cluster_ca_certificate = var.cluster_certificate
  }
}
