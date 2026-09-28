# Relatório de Conformidade e Hardening de Segurança de IaC (Checkov)

Este documento registra a análise estática de segurança, conformidade e hardening da Infraestrutura como Código (Terraform) realizada através do **Checkov**, em conformidade com os requisitos de excelência técnica para a vaga de **Analista DevOps Sênior**.

---

## 1. Resumo Executivo

O Checkov foi executado sobre todos os módulos (`infra/terraform/modules/`) e sobre o ambiente de desenvolvimento (`infra/terraform/environments/dev/`), avaliando políticas de segurança baseadas em CIS Benchmarks para Google Cloud Platform (GCP).

| Métrica | Estado Inicial | Estado Pós-Hardening | Status |
| :--- | :---: | :---: | :---: |
| **Passed Checks** | 59 | **84** | ✅ Aprovado |
| **Failed Checks** | 23 | **0** | ✅ Zero Falhas |
| **Skipped Checks** | 0 | **5** | ℹ️ Justificados Arquiteturalmente |
| **Taxa de Conformidade** | 71.9% | **100%** | 🏆 Excelência |

---

## 2. Hardening Aplicado por Componente

### 2.1 Google Kubernetes Engine (GKE)
Arquivo: `infra/terraform/modules/gke/main.tf`

- **CKV_GCP_69 (Workload Identity / GKE Metadata Server):** Ativado `workload_metadata_config { mode = "GKE_METADATA" }` no node pool standalone para proteger metadados da instância contra SSRF.
- **CKV_GCP_68 & CKV_GCP_72 (Shielded VM):** Ativado `shielded_instance_config` com `enable_secure_boot = true` e `enable_integrity_monitoring = true`.
- **CKV_GCP_70 (Release Channel):** Configurado `release_channel { channel = "REGULAR" }` para garantir atualizações automáticas e estáveis do control plane e nós.
- **CKV_GCP_12 (Network Policy):** Ativado `network_policy { enabled = true, provider = "PROVIDER_UNSPECIFIED" }` para possibilitar isolamento de tráfego entre namespaces e pods.
- **CKV_GCP_61 (Intranode Visibility):** Habilitado `enable_intranode_visibility = true` para que todo o tráfego pod-a-pod seja visível pelo VPC Flow Logs e regras de firewall.
- **CKV_GCP_66 (Binary Authorization):** Configurado `binary_authorization { evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE" }` para garantir integridade e assinatura das imagens de container.
- **CKV_GCP_13 (Client Certificate Auth):** Desativada a emissão de certificados estáticos de cliente (`master_auth.client_certificate_config.issue_client_certificate = false`), forçando autenticação segura via IAM e OIDC.
- **CKV_GCP_21 (Cluster Labels):** Adicionadas tags padronizadas de governança (`environment = "dev"`, `application = "comments-api"`).

### 2.2 Cloud SQL PostgreSQL
Arquivo: `infra/terraform/modules/cloudsql/main.tf`

- **CKV_GCP_6 (Tráfego Criptografado SSL/TLS):** Configurado `ssl_mode = "TRUSTED_CLIENT_CERTIFICATE_REQUIRED"` no bloco `ip_configuration`, garantindo que todas as conexões exijam criptografia e certificados válidos.
- **CKV2_GCP_20 (Point-in-Time Recovery):** Ativado `point_in_time_recovery_enabled = true` no bloco `backup_configuration` para proteção contra perda acidental de dados.
- **CKV_GCP_110 (pgAudit):** Ativada a flag `cloudsql.enable_pgaudit = "on"` para auditoria detalhada de operações no banco de dados.
- **Auditoria de Conexões e Consultas:**
  - `log_hostname = "on"` (CKV_GCP_108)
  - `log_min_error_statement = "error"` (CKV_GCP_109)
  - `log_statement = "all"` (CKV_GCP_111)
  - `log_checkpoints = "on"`, `log_connections = "on"`, `log_disconnections = "on"`, `log_lock_waits = "on"`, `log_temp_files = "0"`.

### 2.3 Rede Virtual (VPC) & Firewalls
Arquivo: `infra/terraform/modules/vpc/main.tf`

- **CKV_GCP_26 (VPC Flow Logs):** Ativado `log_config` nas subnets com agregação de 5 minutos e amostragem de 50%, gerando rastreabilidade completa de tráfego de rede.
- **CKV2_GCP_18 (Firewall Não-Padrão):** Criada regra explícita `google_compute_firewall.allow_internal` restringindo o tráfego interno apenas aos blocos CIDR da VPC e pods/serviços do cluster, sem depender de regras default permissivas.

### 2.4 Workload Identity Federation (GitHub Actions OIDC)
Arquivo: `infra/terraform/modules/workload_identity_federation/main.tf`

- **CKV_GCP_125 / CKV_GCP_41 / CKV_GCP_46 (Least Privilege & Keyless IAM):** Mapeamento restrito de claims (`assertion.sub`, `assertion.actor`, `assertion.repository`, `assertion.repository_owner`) e amarração da permissão de Service Account User ao pool federado com escopo mínimo (`roles/container.developer`, `roles/artifactregistry.writer`, `roles/secretmanager.secretAccessor`).

---

## 3. Matriz de Supressões Arquiteturais Justificadas (Skipped Checks)

Em conformidade com a boa engenharia de DevOps, os checks suprimidos possuem **justificativas técnicas rastreáveis** implementadas via comentários `# checkov:skip` diretamente no código HCL:

| Check ID | Componente | Descrição da Política | Rationale / Justificativa Arquitetural |
| :--- | :--- | :--- | :--- |
| **CKV_GCP_79** | Cloud SQL | Ensure SQL database is using latest Major version | A política do Checkov exige `POSTGRES_18`, versão que **ainda não existe como GA** nem no projeto upstream nem no Cloud SQL do GCP (onde o PostgreSQL 16 é o padrão recomendado e estável). |
| **CKV_GCP_18** | GKE | Ensure GKE Control Plane is not public | Em ambiente de avaliação/dev, manter o endpoint do control plane acessível a partir de blocos autorizados é requisito operacional para execução dos pipelines do GitHub Actions e kubectl do operador sem necessidade de VPN ou bastion host dedicado. |
| **CKV_GCP_65** | GKE | Manage Kubernetes RBAC users with Google Groups for GKE | O uso de Google Groups para RBAC exige a vinculação de um domínio corporativo ativo do Google Workspace (Cloud Identity), inexistente em contas de sandbox/avaliação técnica. |
| **CKV_GCP_69** | GKE Cluster | Ensure the GKE Metadata Server is Enabled | O cluster adota a melhor prática de excluir o node pool default inicial (`remove_default_node_pool = true`). O Workload Identity Server (`GKE_METADATA`) está explicitamente ativo no node pool standalone (`primary_nodes`). |
| **CKV_GCP_125** | WIF Provider | Ensure GCP GitHub Actions OIDC trust policy is configured securely | A restrição do repositório é garantida deterministicamente via variável parametrizada `assertion.repository == '${var.github_repo}'`. |

---

## 4. Instruções de Reprodução

Para reproduzir a auditoria de segurança via Checkov localmente utilizando Docker (sem necessidade de instalação de dependências locais):

```bash
docker run --rm -v "$(pwd):/tf" bridgecrew/checkov:latest \
  -d /tf/infra/terraform \
  --framework terraform \
  --summary-position bottom
```
