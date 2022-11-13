resource "kubernetes_service_account" "argocd" {
  depends_on = [
  ]
  metadata {
    name = "argocd"
    namespace = "kube-system"
  }
}

resource "kubernetes_cluster_role_binding" "argocd" {
  depends_on = [
    kubernetes_service_account.argocd
  ]
  metadata {
    name = "argocd"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind = "ClusterRole"
    name = "cluster-admin"
  }
  subject {
    kind = "ServiceAccount"
    name = "argocd"
    namespace = "kube-system"
  }
}

data "kubernetes_secret" "argocd" {
  metadata {
    name = kubernetes_service_account.argocd.default_secret_name
    namespace = "kube-system"
  }
}

resource "google_secret_manager_secret" "cluster-secret" {
  secret_id = "cluster-${var.cluster_name}"

  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret_version" "cluster-secret-version" {
  secret = google_secret_manager_secret.cluster-secret.id
  enabled = true

  secret_data = jsonencode(
    {
      name: var.cluster_name,
      server: "https://${var.cluster_endpoint}",
      token: lookup(data.kubernetes_secret.argocd.data, "token"),
      certificate: base64encode(lookup(data.kubernetes_secret.argocd.data, "ca.crt"))
    }
  )
}
