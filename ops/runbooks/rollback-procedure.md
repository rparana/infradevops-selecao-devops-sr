# Runbook: Procedimento de Rollback (Comments API)

Instruções para reverter rapidamente uma versão da aplicação em caso de regressão, falha de integridade ou violação de SLOs pós-deploy.

---

## 1. Estratégia de Rollback via Helm (Recomendado)

O Helm mantém o histórico de revisões de releases no cluster.

### 1.1 Inspecionar Histórico de Releases
```bash
helm history comments-api -n comments
```

Exemplo de saída:
```text
REVISION    UPDATED                     STATUS          CHART                 APP VERSION    DESCRIPTION
1           Mon Sep 28 14:00:00 2026    superseded      comments-api-1.0.0    1.0.0          Install complete
2           Mon Sep 28 15:30:00 2026    deployed        comments-api-1.0.0    1.0.1          Upgrade complete
```

### 1.2 Executar Rollback para a Revisão Anterior
```bash
# Reverter para a revisão imediatamente anterior
helm rollback comments-api 1 -n comments --wait --timeout=3m
```

### 1.3 Validar Status do Rollback
```bash
# Checar rollout dos pods
kubectl rollout status deployment/comments-api -n comments

# Testar health check
kubectl exec -i -t deployment/comments-api -n comments -c comments-api -- \
  python -c "import urllib.request; print(urllib.request.urlopen('http://localhost:8000/health').read().decode())"
```

---

## 2. Estratégia de Rollback Rápido via Kubectl (Alternativa Emergencial)

Caso o Helm não esteja disponível ou se pretenda reverter apenas o `Deployment` do Kubernetes:

### 2.1 Verificar Histórico de Rollout do Deployment
```bash
kubectl rollout history deployment/comments-api -n comments
```

### 2.2 Desfazer o Último Rollout
```bash
kubectl rollout undo deployment/comments-api -n comments
```

### 2.3 Reverter para uma Revisão Específica
```bash
kubectl rollout undo deployment/comments-api --to-revision=1 -n comments
```

---

## 3. Pós-Rollback

1. Notificar os stakeholders e registrar o evento no canal de incidentes.
2. Analisar os logs e métricas da versão revertida no Grafana (`uid: comments-api-sre`).
3. Registrar a falha no `COMMENTS.md` como aprendizado pós-incidente.
