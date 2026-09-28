variable "project_id" {
  description = "ID do projeto no Google Cloud"
  type        = string
}

variable "region" {
  description = "Região do cluster GKE"
  type        = string
  default     = "us-central1"
}

variable "cluster_name" {
  description = "Nome do cluster GKE"
  type        = string
  default     = "comments-gke-cluster"
}

variable "network_id" {
  description = "ID da VPC Network"
  type        = string
}

variable "subnet_id" {
  description = "ID da sub-rede do GKE"
  type        = string
}

variable "pods_range_name" {
  description = "Nome do range secundário para pods"
  type        = string
  default     = "gke-pods"
}

variable "services_range_name" {
  description = "Nome do range secundário para services"
  type        = string
  default     = "gke-services"
}

variable "machine_type" {
  description = "Tipo de máquina para os nós do GKE"
  type        = string
  default     = "e2-standard-2"
}

variable "min_node_count" {
  description = "Quantidade mínima de nós para autoscaling"
  type        = number
  default     = 1
}

variable "max_node_count" {
  description = "Quantidade máxima de nós para autoscaling"
  type        = number
  default     = 3
}

variable "spot" {
  description = "Utilizar instâncias Spot/Preemptible para redução de custos"
  type        = bool
  default     = true
}
