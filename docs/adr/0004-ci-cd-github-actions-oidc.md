# 4. CI/CD: GitHub Actions com OIDC Workload Identity Federation

A esteira de integração e entrega contínua será executada pelo GitHub Actions, autenticando-se no GCP via OpenID Connect (OIDC) e Workload Identity Federation, eliminando credenciais de longa duração (service account keys JSON). O pipeline orquestra os estágios exigidos: build da aplicação, security scans com Trivy (vulnerabilidades em containers) e Checkov (análise estática de IaC Terraform), push para o Artifact Registry do GCP, e deploy automatizado via Helm no cluster GKE.
