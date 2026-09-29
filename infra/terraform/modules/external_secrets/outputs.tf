output "namespace" {
  description = "Namespace onde o External Secrets Operator foi instalado"
  value       = helm_release.external_secrets.namespace
}

output "release_name" {
  description = "Nome do release do Helm para o External Secrets Operator"
  value       = helm_release.external_secrets.name
}
