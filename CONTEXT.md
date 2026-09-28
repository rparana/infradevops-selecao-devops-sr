# Comments API & Infrastructure Context

Contexto do desafio técnico para a vaga de DevOps Sênior: API de Comentários, infraestrutura gerenciada no Google Cloud Platform (GCP), automação CI/CD e observabilidade.

## Language

**Comment**:
Registro textual publicado por um usuário vinculado a um identificador de conteúdo específico, contendo email do autor, corpo do texto e timestamp.
_Avoid_: Mensagem, post, review

**Content**:
Identificador da matéria ou artigo (`content_id`) ao qual uma lista de comentários pertence.
_Avoid_: Artigo, post_id, page_id

**Health Probe**:
Mecanismo de verificação de disponibilidade (`/health`) consumido pelos probes de liveness e readiness do Kubernetes.
_Avoid_: Ping, status check

**Metrics Endpoint**:
Endpoint HTTP (`/metrics`) que expõe métricas de aplicação e runtime no formato texto padrão do Prometheus.
_Avoid_: Telemetry endpoint, stats

**External Secret**:
Recurso customizado (`ExternalSecret`) gerenciado pelo External Secrets Operator (ESO) que sincroniza dados sensíveis do GCP Secret Manager para `Secret` nativos do Kubernetes.
_Avoid_: Kube secret, hardcoded secret

**Service Level Objective (SLO)**:
Meta quantitativa formal de confiabilidade e desempenho (ex.: disponibilidade 99.9%, latência p95 < 200ms) baseada em Service Level Indicators (SLIs).
_Avoid_: KPI, SLA interno
