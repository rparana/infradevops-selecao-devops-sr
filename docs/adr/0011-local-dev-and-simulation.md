# 11. Local Development and Dual Simulation: Docker Compose e KinD

Para viabilizar validação rápida, desenvolvimento isolado e demonstração imediata sem custos obrigatórios de nuvem:
1. Disponibilizaremos um ambiente de desenvolvimento local via Docker Compose contendo a API (com hot-reload), PostgreSQL 16, Prometheus e uma instância do Grafana pré-configurada provisionando automaticamente o dashboard em `ops/grafana/comments-api.json`;
2. Forneceremos automação de cluster KinD local (`ops/scripts/test-local-kind.sh`) para validar o ciclo completo de Kubernetes: instalação do Ingress NGINX, deploy do Helm chart `comments-api`, sondagem de probes de saúde e teste de Horizontal Pod Autoscaler (HPA).
