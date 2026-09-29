terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.10.0"
    }
  }
}

# 1. Google Service Account (GSA) dedicada para o External Secrets Operator
resource "google_service_account" "eso_sa" {
  account_id   = var.gsa_name
  display_name = "Service Account para External Secrets Operator"
  project      = var.project_id
}

# 2. Concessão de permissão de leitura de segredos no GCP Secret Manager
resource "google_project_iam_member" "eso_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.eso_sa.email}"
}

# 3. Associação Workload Identity (GSA <-> KSA)
resource "google_service_account_iam_member" "eso_workload_identity_user" {
  service_account_id = google_service_account.eso_sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[${var.namespace}/${var.service_account_name}]"
}

# 4. Helm Release do External Secrets Operator com anotação da GSA na KSA
resource "helm_release" "external_secrets" {
  name             = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  version          = var.chart_version
  namespace        = var.namespace
  create_namespace = true
  

  set {
    name  = "installCRDs"
    value = "true"
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = var.service_account_name
  }

  set {
    name  = "serviceAccount.annotations.iam\\.gke\\.io/gcp-service-account"
    value = google_service_account.eso_sa.email
  }

  # Desativa o webhook validador síncrono para prevenir falhas de chamada à API
  set {
    name  = "webhook.create"
    value = "false"
  }

  # Desativa o cert-controller caso o webhook não esteja ativo
  set {
    name  = "certController.create"
    value = "false"
  }

  wait          = true
  wait_for_jobs = true
  timeout       = 300

  depends_on = [
    google_service_account_iam_member.eso_workload_identity_user
  ]
}

# ClusterRole declarativa para cobrir as permissões de cache e watch em falta
resource "kubernetes_cluster_role" "external_secrets_controller_fix" {
  metadata {
    name = "external-secrets-controller-fix"
  }

  rule {
    api_groups = ["generators.external-secrets.io"]
    resources  = ["generatorstates"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["external-secrets.io"]
    resources  = ["clusterpushsecrets", "pushsecrets"]
    verbs      = ["get", "list", "watch"]
  }

  depends_on = [helm_release.external_secrets]
}

# Associação da Role à ServiceAccount do operador
resource "kubernetes_cluster_role_binding" "external_secrets_controller_fix_binding" {
  metadata {
    name = "external-secrets-controller-fix-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.external_secrets_controller_fix.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = "external-secrets"
    namespace = "external-secrets"
  }

  depends_on = [kubernetes_cluster_role.external_secrets_controller_fix]
}