# 5. Database Architecture: Cloud SQL PostgreSQL com Private IP e Workload Identity

A persistência de dados utilizará uma instância gerenciada de PostgreSQL (versão 15 ou 16) no Google Cloud SQL, configurada exclusivamente com Private IP atrelado à VPC via Private Services Access (sem IP público), garantindo conformidade com os requisitos de segurança e least-privilege. Para compatibilidade e segurança máxima, os workloads no GKE conectar-se-ão diretamente via rede privada interna com suporte opcional a Cloud SQL Auth Proxy autenticado via Workload Identity.
