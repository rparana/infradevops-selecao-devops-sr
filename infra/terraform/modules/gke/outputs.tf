output "cluster_name" {
  description = "Nome do cluster GKE"
  value       = google_container_cluster.primary.name
}

output "cluster_endpoint" {
  description = "Endpoint do cluster GKE"
  value       = google_container_cluster.primary.endpoint
}

output "cluster_ca_certificate" {
  description = "Certificado CA do cluster GKE"
  value       = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "workload_identity_pool" {
  description = "Workload Identity Pool do GKE"
  value       = "${var.project_id}.svc.id.goog"
}

output "nodes_service_account" {
  description = "Service Account dos nós do GKE"
  value       = google_service_account.gke_nodes_sa.email
}
