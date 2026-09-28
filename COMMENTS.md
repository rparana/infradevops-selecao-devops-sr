# Decisões de Arquitetura, Experimentos e Registro Técnico (COMMENTS.md)

Este documento registra as decisões técnicas, trade-offs arquiteturais, estimativas de custos, testes e transparência do desafio técnico para a vaga de **Analista DevOps Sênior**.

---

## 1. Visão Geral da Arquitetura e Decisões Técnicas

Toda a solução foi concebida seguindo as melhores práticas cloud-native, segurança com *least privilege*, observabilidade por padrão e automação via GitOps/IaC.

As decisões arquiteturais fundamentais estão formalizadas nos seguintes **Architecture Decision Records (ADRs)**:

| ADR | Título | Resumo da Decisão |
| :--- | :--- | :--- |
| [ADR-0001](docs/adr/0001-cloud-provider-gcp.md) | Target Cloud Provider: GCP | Padronização integral no Google Cloud Platform para máxima aderência à stack da empresa. |
| [ADR-0002](docs/adr/0002-compute-gke-standard.md) | Compute: GKE Standard | GKE Standard com node pool otimizado para controle fino de custos, DaemonSets e HPA. |
| [ADR-0003](docs/adr/0003-api-stack-fastapi.md) | Backend Stack: Python FastAPI | FastAPI + SQLAlchemy + asyncpg, com OpenAPI em `/docs` e instrumentação Prometheus nativa. |
| [ADR-0004](docs/adr/0004-ci-cd-github-actions-oidc.md) | CI/CD: GitHub Actions OIDC | Autenticação keyless via Workload Identity Federation, eliminando credenciais estáticas. |
| [ADR-0005](docs/adr/0005-database-cloudsql-private-ip.md) | Database: Cloud SQL Postgres | PostgreSQL 16 em Private IP (Private Services Access / PSC), sem IP público. |
| [ADR-0006](docs/adr/0006-secrets-external-secrets-operator.md) | Segredos: ESO + Secret Manager | External Secrets Operator sincronizando do Secret Manager via Workload Identity. |
| [ADR-0007](docs/adr/0007-iac-modular-terraform.md) | IaC: Terraform Modular | Módulos desacoplados (`vpc`, `gke`, `cloudsql`, `secrets`, `workload_identity_federation`). |
| [ADR-0008](docs/adr/0008-observability-and-sre.md) | Observabilidade e SRE | Prometheus, dashboard Grafana JSON, alert rules, HPA, SLO/SLI e Runbooks operacionais. |
| [ADR-0009](docs/adr/0009-database-migrations-lifespan-alembic.md) | Migrações de Banco | Inicialização assíncrona tolerante no lifespan + migrações estruturadas no Alembic. |
| [ADR-0010](docs/adr/0010-container-security-multistage-nonroot.md) | Segurança do Container | Multi-stage build com `python:3.12-slim`, rodando com usuário `appuser` (UID 10001). |
| [ADR-0011](docs/adr/0011-local-dev-and-simulation.md) | Validação Dual (Local & Cloud) | Docker Compose completo (API, DB, Prom, Grafana provisionado) + deploy em cluster KinD. |
| [ADR-0012](docs/adr/0012-iac-security-hardening-checkov.md) | Hardening de IaC (Checkov) | Hardening de GKE, Cloud SQL e VPC alinhado a CIS Benchmarks com zero falhas no Checkov. |

---

## 2. Dimensionamento e Gestão de Custos no GCP (FinOps)

O teste requer dimensionamento consciente com uso de tamanhos mínimos e boas práticas de economia:

1. **GKE Standard Cluster**:
   - Master plane gerenciado pelo Google.
   - Node Pool: 1 a 2 nós `e2-standard-2` ou `e2-medium` (2 vCPU, 4GB RAM) com auto-repair e auto-upgrade habilitados.
   - Utilização de preemptible / Spot VMs no node pool de desenvolvimento para reduzir custos de compute em até 60-80%.
2. **Cloud SQL**:
   - Tier `db-f1-micro` ou `db-g1-small` (1 vCPU, 1.7GB RAM) em disco SSD de 10GB.
   - Desativação de alta disponibilidade (HA) multirregional desnecessária em ambiente de teste técnico.
3. **Rede e Cloud NAT**:
   - 1 Cloud NAT Gateway configurado na região do cluster para viabilizar saída dos nós privados à internet sem necessidade de IPs públicos nos nodes.
4. **Clean-up Automatizado**:
   - O repositório inclui instruções para `terraform destroy` pós-validação para evitar faturamento ocioso.

---

## 3. Estratégia de Segurança e Least Privilege

- **Sem chaves estáticas:** O pipeline GitHub Actions conecta no GCP via OIDC (Workload Identity Federation) trocando tokens efêmeros com escopo limitado ao repositório.
- **Isolamento de Banco:** A instância do Cloud SQL não possui IP público atribuído; o acesso ocorre exclusivamente através de IP privado peered na VPC com `ssl_mode = "TRUSTED_CLIENT_CERTIFICATE_REQUIRED"`.
- **Injeção de Segredos Segura:** A aplicação não armazena credenciais em variáveis de ambiente abertas nos arquivos de manifesto. O External Secrets Operator gerencia a reconciliação direta a partir do GCP Secret Manager.
- **Hardening de Container:** A imagem de container roda com usuário sem privilégios (`appuser` UID 10001) e passa por varredura com **Trivy**.
- **Hardening de IaC (Checkov):** Todo o código Terraform passa por análise estática de conformidade e segurança com o Checkov. O resultado obtido foi de **84 checks aprovados e 0 falhas**, com relatório detalhado disponível em [docs/security/iac-security-checkov.md](docs/security/iac-security-checkov.md).

---

## 4. SLOs e SLIs Definidos

Para o serviço de Comentários (`comments-api`), estabelecemos os seguintes objetivos de nível de serviço:

| Indicador (SLI) | Métrica / Fonte | Meta (SLO) | Justificativa |
| :--- | :--- | :--- | :--- |
| **Disponibilidade (Availability)** | Proporção de requisições HTTP retornando status `< 500` sobre o total de requisições. | **99.9%** em janela móvel de 30 dias | Tolerância a falhas transitórias, garantindo que matérias não fiquem sem comentários. |
| **Latência (Latency p95)** | Duração das requisições em `POST /api/comment/new` e `GET /api/comment/list/{id}`. | **p95 < 200ms** | Garantir que o carregamento da página de matérias não sofra atrasos perceptíveis. |
| **Integridade de Inicialização** | Probes de Liveness/Readiness passando em `/health`. | **100% dos pods saudáveis** em < 15s de startup | Evitar roteamento de tráfego para instâncias que ainda não estabilizaram a conexão com o banco. |

---

## 5. Testes Executados e Evidências

Durante o ciclo de desenvolvimento, foram validadas as seguintes camadas de qualidade:

1. **Testes Unitários e de Integração da API (Pytest):**
   - 6 testes cobrindo healthcheck, métricas Prometheus, criação de comentários, validações de payload (email inválido, corpo vazio) e listagem filtrada por matéria.
   - Resultado: 100% aprovados em 0.12s.
2. **Hardening de Container e Usuário Não-Root:**
   - Container executado localmente e inspecionado via `docker exec id`.
   - Resultado: `uid=10001(appuser) gid=10001(appgroup)`.
3. **Ambiente Local Multi-Container (Docker Compose):**
   - 4 serviços orquestrados: `comments-postgres`, `comments-api`, `comments-prometheus`, `comments-grafana`.
   - Resultado: Inserção de dados persistida no PostgreSQL, Prometheus coletando métricas em tempo real (`health: up`), Grafana respondendo com dashboard provisionado em `http://localhost:3000`.
4. **Validação Sintática de Helm:**
   - `helm lint` executado no chart `helm/comments-api`.
   - Resultado: `1 chart(s) linted, 0 chart(s) failed`.
5. **Validação de IaC Terraform:**
   - `terraform fmt -check` e `terraform validate` executados no ambiente `environments/dev/`.
   - Resultado: `Success! The configuration is valid.`
6. **Auditoria de Segurança de IaC (Checkov):**
   - Varredura de conformidade CIS Benchmark para GCP sobre todos os módulos de IaC.
   - Resultado: **84 passed, 0 failed, 5 skipped** (com justificativas arquiteturais). Relatório completo em [docs/security/iac-security-checkov.md](docs/security/iac-security-checkov.md).
7. **Evidências Visuais e Operacionais (Screenshots em `docs/evidences/`):**
   - `terraform-apply.png`: Execução do provisionamento completo da infraestrutura no GCP via Terraform.
   - `cloudsql.png`: Instância Cloud SQL PostgreSQL provisionada com Private IP e políticas de SSL.
   - `gsm.png`: Google Secret Manager com segredos armazenados e integrados ao External Secrets Operator.
   - `prometheus-local.png`: Alvos de scraping ativos e métricas da API sendo coletadas com sucesso.
   - `graffana-local.png`: Dashboard executivo e operacional exibindo latência, taxa de erros e volume de requisições.

---

## 6. Ideias de Evolução Futura (Com Mais Tempo)

1. **Canary Releases com Argo Rollouts ou Flagger:** Implementar análise automatizada de métricas (taxa de erro e latência) para promoção progressiva de tráfego durante rollouts.
2. **Service Mesh (Istio ou Linkerd):** Implementar mTLS estrito entre todos os serviços no cluster, autorização granular com `AuthorizationPolicy` e tracing distribuído com OpenTelemetry / Jaeger.
3. **FinOps Contínuo com Infracost:** Integrar o Infracost nos Pull Requests do GitHub Actions para estimar o impacto financeiro de qualquer alteração de IaC antes do merge.
4. **Centralização de Logs com Grafana Loki ou Cloud Logging:** Exportar logs estruturados em JSON via fluentbit/promtail com correlação direta entre trace IDs e logs de erro.

---

## 7. Transparência de Ferramentas, Boilerplates e IA

Em conformidade com as orientações do desafio:

- **Ferramentas de IA Utilizadas:** Pair-programming e automação assistida por IA (Google Antigravity IDE / Gemini 3.8 Flash) utilizada para exploração de trade-offs de design, redação de ADRs, estruturação de manifests e testes de regressão.
- **Boilerplates / Templates:** Estrutura base de módulos Terraform seguindo as melhores práticas do Google Cloud Foundation Toolkit; instrumentação Prometheus via biblioteca oficial `prometheus-fastapi-instrumentator`.
- **Tempo Estimado Gasto:** Planejamento e design (1.5h), implementação completa e testes (3.5h).
