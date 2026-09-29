variable "namespace" {
  description = "Namespace do Kubernetes para o External Secrets Operator"
  type        = string
  default     = "external-secrets"
}

variable "chart_version" {
  description = "Versão do Helm chart do External Secrets Operator"
  type        = string
  default     = "0.10.4"
}
