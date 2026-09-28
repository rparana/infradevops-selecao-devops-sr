# Comments API & Cloud-Native Platform — Desafio Técnico DevOps Sênior

Solução completa para o desafio técnico de **Analista DevOps Sênior**, contemplando desenvolvimento de API REST em Python (FastAPI), conteinerização segura não-root, observabilidade nativa (Prometheus e Grafana), manifests Helm com HPA e probes, Infraestrutura como Código (Terraform) padronizada no **Google Cloud Platform (GCP)** com autenticação OIDC (Workload Identity Federation), esteira de CI/CD automatizada com scans de segurança (Trivy e Checkov) e runbooks operacionais.

---

## 🏛️ Arquitetura da Solução

```
                    ┌────────────────────────────────────────────────────────┐
                    │               Google Cloud Platform (GCP)              │
                    │                                                        │
                    │   ┌────────────────────────────────────────────────┐   │
                    │   │                  Custom VPC                    │   │
                    │   │                                                │   │
                    │   │   ┌───────────────────┐    Private Services    │   │
                    │   │   │   GKE Standard    │        Access          │   │
Internet ──HTTPS──> │   │   │  (Private Nodes)  │ ────────────────────── │── │ ──> Cloud SQL (Postgres 16)
                    │   │   │                   │                        │   │     (Private IP Only)
                    │   │   │  ┌─────────────┐  │                        │   │
                    │   │   │  │Comments API │  │                        │   │
                    │   │   │  │ (Non-root)  │  │                        │   │
                    │   │   │  └──────┬──────┘  │                        │   │
                    │   │   │         │ ESO     │                        │   │
                    │   │   └─────────┼─────────┘                        │   │
                    │   │             ▼                                  │   │
                    │   │   Secret Manager                               │   │
                    │   └────────────────────────────────────────────────┘   │
                    └────────────────────────────────────────────────────────┘
                                      ▲
                                 OIDC │ (Keyless Auth)
                                      ▼
                         GitHub Actions CI/CD Pipeline
                  (Test ➔ Trivy/Checkov Scan ➔ Push ➔ Deploy)
```

### Principais Decisões Arquiteturais (ADRs)
- [ADR-0001: Target Cloud Provider: GCP](docs/adr/0001-cloud-provider-gcp.md)
- [ADR-0002: Compute: GKE Standard](docs/adr/0002-compute-gke-standard.md)
- [ADR-0003: Backend Stack: Python FastAPI](docs/adr/0003-api-stack-fastapi.md)
- [ADR-0004: CI/CD: GitHub Actions OIDC](docs/adr/0004-ci-cd-github-actions-oidc.md)
- [ADR-0005: Database: Cloud SQL Postgres Private IP](docs/adr/0005-database-cloudsql-private-ip.md)
- [ADR-0006: Segredos: External Secrets Operator (ESO)](docs/adr/0006-secrets-external-secrets-operator.md)
- [ADR-0007: IaC: Terraform Modular](docs/adr/0007-iac-modular-terraform.md)
- [ADR-0008: Observabilidade e SRE](docs/adr/0008-observability-and-sre.md)
- [ADR-0009: Migrações de Banco Resilientes (Alembic)](docs/adr/0009-database-migrations-lifespan-alembic.md)
- [ADR-0010: Container Hardening Não-Root](docs/adr/0010-container-security-multistage-nonroot.md)
- [ADR-0011: Validação Dual (Local & Cloud)](docs/adr/0011-local-dev-and-simulation.md)

---

## 🚀 Como Rodar Localmente (Ambiente de Desenvolvimento)

### Opção 1: Docker Compose (Recomendado — 1 Comando)
Sobe a aplicação completa com PostgreSQL 16, Prometheus coletando métricas e Grafana com dashboard pré-provisionado:

```bash
docker compose up -d
```

#### Endpoints Disponíveis Localmente:
- **API Swagger / OpenAPI:** [http://localhost:8000/docs](http://localhost:8000/docs)
- **Health Check Probe:** [http://localhost:8000/health](http://localhost:8000/health)
- **Prometheus Metrics:** [http://localhost:8000/metrics](http://localhost:8000/metrics)
- **Prometheus Server:** [http://localhost:9090](http://localhost:9090)
- **Grafana Dashboard:** [http://localhost:3000](http://localhost:3000) *(User: `admin` / Senha: `admin`)*
  - O dashboard **"Comments API — SRE Observability Dashboard"** já estará carregado e ativo!

#### Exemplos de Chamadas da API via cURL:

1. **Inserir um novo comentário:**
```bash
curl -X POST http://localhost:8000/api/comment/new \
  -H "Content-Type: application/json" \
  -d '{
    "email": "devops@empresa.com",
    "comment": "Infraestrutura resiliente e código limpo!",
    "content_id": 42
  }'
```

2. **Listar comentários de uma matéria (`content_id`):**
```bash
curl http://localhost:8000/api/comment/list/42
```

3. **Verificar saúde da API e conectividade com o banco:**
```bash
curl http://localhost:8000/health
```

---

### Opção 2: Testes Unitários e de Integração Locais
Para rodar a suíte automatizada de testes com Pytest:

```bash
# Criar virtualenv e instalar dependências
python3 -m venv .venv
source .venv/bin/activate
pip install -r app/requirements.txt

# Executar testes
PYTHONPATH=. pytest -v app/tests
```

---

### Opção 3: Simulação Kubernetes Local com KinD
Para testar o ciclo completo do Kubernetes (Helm Chart + Ingress NGINX + Probes + HPA):

```bash
chmod +x ops/scripts/test-local-kind.sh
./ops/scripts/test-local-kind.sh
```

---

### Opção 4: Dev Container (Zero Instalação na Máquina Host)
O repositório possui suporte nativo a **Dev Containers** (`.devcontainer/`). Ao abrir este projeto no VS Code ou Antigravity IDE com a extensão Remote - Containers:
1. Pressione `F1` (ou `Ctrl/Cmd + Shift + P`) e selecione **"Dev Containers: Reopen in Container"**.
2. O container provisionará automaticamente todas as ferramentas necessárias no PATH:
   - **Terraform**, **Helm 3**, **Kubectl**, **Google Cloud CLI (`gcloud`)**
   - **Docker CLI** (integrado ao daemon do host), **KinD**, **Trivy** e **Checkov**
   - Python 3.12 com virtualenv e dependências já instaladas
   - Extensões do VS Code pré-configuradas para syntax highlight e formatação de Terraform, Python e YAML.

---

## ☁️ Provisionamento na Nuvem (GCP via Terraform)

A infraestrutura está modularizada em `infra/terraform/modules/` e o ambiente de desenvolvimento em `infra/terraform/environments/dev/`.

### 1. Pré-requisitos
- Conta no Google Cloud Platform (GCP) com um projeto ativo.
- `gcloud` CLI autenticado: `gcloud auth login` e `gcloud auth application-default login`.
- Terraform >= 1.5.0.

### 2. Passo a Passo do Provisionamento
```bash
cd infra/terraform/environments/dev

# Copiar arquivo de variáveis de exemplo
cp terraform.tfvars.example terraform.tfvars

# Editar terraform.tfvars preenchendo seu project_id do GCP
# Exemplo:
# project_id  = "meu-projeto-gcp"
# region      = "us-central1"
# environment = "dev"
# github_repo = "seu-usuario/infradevops-selecao-devops-sr"

# Inicializar e aplicar
terraform init
terraform plan
terraform apply
```

### 3. O que o Terraform Provisiona:
1. **Rede:** VPC customizada, subnets privadas, Cloud NAT Gateway e Private Services Access para o Cloud SQL.
2. **Compute:** GKE Standard Cluster privado, node pool com instâncias Spot para redução de custos (FinOps) e Workload Identity habilitado.
3. **Banco de Dados:** Cloud SQL PostgreSQL 16 em IP privado (sem IP público exposto).
4. **Segredos:** Secret Manager com a string de conexão do PostgreSQL e permissões IAM restritas.
5. **Autenticação CI/CD:** Pool e Provider OIDC (Workload Identity Federation) para conexão sem chaves estáticas a partir do GitHub Actions.

---

## 🔐 Gestão de Segredos

- **Em Nuvem (GKE / GCP):**
  - O segredo da conexão com o banco reside no **GCP Secret Manager**.
  - O **External Secrets Operator (ESO)** é executado no cluster e autentica no GCP via **Workload Identity** (sem chaves JSON de Service Account).
  - O manifest [externalsecret.yaml](helm/comments-api/templates/externalsecret.yaml) sincroniza o segredo diretamente para uma `Secret` nativa do Kubernetes em tempo de execução.
- **Local (Docker Compose):**
  - Injetado via variáveis de ambiente isoladas na rede bridge interna do Compose.

---

## 📊 Observabilidade e SRE (Diferenciais)

- **Métricas Prometheus:** Expostas em `/metrics` cobrindo RPS, percentis de latência (p50, p95, p99), status HTTP (2xx, 4xx, 5xx) e estatísticas de runtime.
- **Dashboard Grafana:** Versionado em formato JSON em [ops/grafana/comments-api.json](ops/grafana/comments-api.json) contendo 6 painéis organizados segundo os *Google Golden Signals*.
- **Alertas Prometheus:** Versionados em [ops/alerts/comments-api-alerts.yaml](ops/alerts/comments-api-alerts.yaml) com regras para violação de SLO, indisponibilidade e perda de banco.
- **Resiliência Kubernetes:** [HPA configurado](helm/comments-api/templates/hpa.yaml) escalonando entre 2 e 10 réplicas com base em CPU e Memória.
- **Runbooks Operacionais:**
  - [Triagem e Resposta a Incidentes](ops/runbooks/incident-response.md)
  - [Procedimento de Rollback de Aplicação](ops/runbooks/rollback-procedure.md)
  - [Backup e Disaster Recovery do Banco de Dados](ops/runbooks/database-disaster-recovery.md)

---

## 🤖 Transparência de Ferramentas e IA

- **Ferramentas de IA Utilizadas:** Pair-programming e aceleração assistida por IA (Google Antigravity IDE / Gemini 3.8 Flash) utilizada para exploração arquitetural, redação de ADRs e estruturação dos testes automatizados.
- **Boilerplates / Templates:** Práticas recomendadas do Google Cloud Foundation Toolkit para IaC Terraform; `prometheus-fastapi-instrumentator` para métricas.
- **Tempo Estimado Gasto:** Planejamento arquitetural e documentação (1.5h), desenvolvimento da API, container, observabilidade, Helm, Terraform e pipelines (3.5h).
- **Registro Detalhado:** Consulte o arquivo [COMMENTS.md](COMMENTS.md) para o histórico completo de experimentos, testes e custos.
