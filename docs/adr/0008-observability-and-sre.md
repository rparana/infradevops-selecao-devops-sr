# 8. Observability and SRE Artifacts: Prometheus, Grafana, HPA e Runbooks

Implementaremos a suíte completa de diferenciais técnicos de confiabilidade e observabilidade:
1. Endpoint `/metrics` instrumentado nativamente com métricas HTTP (latências p50/p95/p99, RPS, taxas de erro 4xx/5xx) e métricas de pool de conexões com o banco;
2. Dashboard do Grafana versionado em formato JSON (`ops/grafana/comments-api.json`);
3. Regras de alertas Prometheus (`ops/alerts/comments-api-alerts.yaml`) cobrindo saturação, erro e latência;
4. Resiliência através de Horizontal Pod Autoscaler (HPA) baseado em CPU/memória;
5. Runbooks operacionais documentados em `ops/runbooks/` para incidentes críticos (deploy, rollback e disaster recovery de banco).
