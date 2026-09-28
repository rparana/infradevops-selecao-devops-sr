# 2. Kubernetes Compute Engine: GKE Standard

Adotamos o Google Kubernetes Engine (GKE) no modo Standard em vez de GKE Autopilot ou Cloud Run/GCE. O modo Standard concede controle determinístico sobre node pools, alocação de recursos mínimos/máximos para controle de custo em testes, customização de DaemonSets para métricas e observabilidade, e total compatibilidade com manifests Kubernetes, Helm charts e políticas de HPA exigidas no desafio.
