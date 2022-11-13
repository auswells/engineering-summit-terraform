locals {
  external_secrets_namespace_name = "external-secrets"
  external_secrets_service_account_name = "external-secrets"
}

resource "google_service_account" "external-secrets" {
  project = var.gcp_project
  account_id = "${var.cluster_name}-external-secrets"
  display_name = "Service Account for External Secrets Workload Identity"
}

resource "google_project_iam_member" "external-secrets-workload-identity-role" {
  project = var.gcp_project
  role   = "roles/iam.workloadIdentityUser"
  member = "serviceAccount:${var.gcp_project}.svc.id.goog[${local.external_secrets_namespace_name}/${local.external_secrets_service_account_name}]"
}

resource "google_project_iam_member" "external-secrets-secrets-manager-role" {
  project = var.gcp_project
  role   = "roles/secretmanager.secretAccessor"
  member = "serviceAccount:${google_service_account.external-secrets.email}"
}

resource "kubernetes_namespace" "external-secrets" {
  depends_on = [
  ]
  metadata {
    name = local.external_secrets_namespace_name
  }
}

resource "helm_release" "external-secrets" {
  name       = "external-secrets"
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  version    = "0.6.1"
  namespace  = local.external_secrets_namespace_name

  values = [ <<EOF
serviceAccount:
  annotations:
    iam.gke.io/gcp-service-account: ${google_service_account.external-secrets.account_id}@${var.gcp_project}.iam.gserviceaccount.com
  name: ${local.external_secrets_service_account_name}
EOF
  ]
}

resource "kubernetes_manifest" "external-secrets-cluster-secret-store" {
  depends_on = [
    helm_release.external-secrets
  ]
  manifest = {
    "apiVersion" = "external-secrets.io/v1beta1"
    "kind" = "ClusterSecretStore"
    "metadata" = {
      "name" = "gcpsm"
    }
    "spec" = {
      "provider" = {
        "gcpsm" = {
          "projectID" = var.gcp_project
        }
      }
    }
  }
}
