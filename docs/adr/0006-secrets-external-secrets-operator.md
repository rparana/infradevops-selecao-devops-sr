# 6. Secrets Management: External Secrets Operator (ESO) e GCP Secret Manager

Os segredos da aplicação (credenciais do banco de dados, chaves de API, etc.) residirão no GCP Secret Manager e serão sincronizados automaticamente para os namespaces do GKE utilizando o External Secrets Operator (ESO). A autenticação do ESO com o GCP Secret Manager ocorrerá via Workload Identity (ServiceAccount K8s vinculada a uma IAM Service Account com role `roles/secretmanager.secretAccessor`), prevenindo qualquer exposição de credenciais estáticas em manifests ou pipelines de CI/CD.

### Separação de Responsabilidades (Platform vs Application)
A instalação e o ciclo de vida do External Secrets Operator e de suas CRDs (`installCRDs=true`) são de responsabilidade exclusiva da **Infraestrutura como Código (Terraform)** via módulo `modules/external_secrets` e provider `helm`. Isso desacopla o pipeline de CD da aplicação, assegurando que o operador e suas definições de recursos customizados (CRDs) já estejam ativos e saudáveis no cluster antes de qualquer deployment de aplicação.

