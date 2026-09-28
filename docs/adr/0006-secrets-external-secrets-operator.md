# 6. Secrets Management: External Secrets Operator (ESO) e GCP Secret Manager

Os segredos da aplicação (credenciais do banco de dados, chaves de API, etc.) residirão no GCP Secret Manager e serão sincronizados automaticamente para os namespaces do GKE utilizando o External Secrets Operator (ESO). A autenticação do ESO com o GCP Secret Manager ocorrerá via Workload Identity (ServiceAccount K8s vinculada a uma IAM Service Account com role `roles/secretmanager.secretAccessor`), prevenindo qualquer exposição de credenciais estáticas em manifests ou pipelines de CI/CD.
