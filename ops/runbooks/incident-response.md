# Runbook: Resposta a Incidentes (Comments API)

Este documento estabelece o procedimento operacional padrão para triagem, diagnóstico e contenção de incidentes críticos envolvendo a Comments API.

---

## 1. Alertas e Critérios de Severidade

| Alerta Prometheus | Severidade | Condição de Disparo | Ação Imediata |
| :--- | :--- | :--- | :--- |
| `CommentsAPIDown` | **P1 / Crítico** | `up{job="comments-api"} == 0` por > 30s | Verificar pods no GKE/KinD e logs de inicialização. |
| `CommentsAPIHigh5xxErrorRate` | **P1 / Crítico** | Taxa de erro 5xx > 1% por > 1m (SLO violation) | Inspecionar erros do banco de dados e tráfego anômalo. |
| `CommentsAPIDatabaseDisconnected` | **P1 / Crítico** | Health check reporta banco inacessível | Validar conectividade VPC com Cloud SQL e Secret Manager. |
| `CommentsAPIHighLatencyP95` | **P2 / Alto** | Latência p95 > 200ms por > 1m | Avaliar saturação de CPU/Memória e pool de conexões. |

---

## 2. Diagnóstico Rápido via CLI

### 2.1 Verificar Status dos Pods e Eventos
```bash
# Listar pods no namespace comments
kubectl get pods -n comments -o wide

# Verificar se há pods em CrashLoopBackOff ou OOMKilled
kubectl describe pods -l app.kubernetes.io/name=comments-api -n comments
```

### 2.2 Inspecionar Logs da Aplicação
```bash
# Logs em tempo real com timestamp
kubectl logs -l app.kubernetes.io/name=comments-api -n comments --tail=100 -f

# Filtrar por exceções 500 ou erros de banco
kubectl logs -l app.kubernetes.io/name=comments-api -n comments --tail=500 | grep -iE "error|exception|critical"
```

### 2.3 Validar External Secrets e Segredos Reconciliados
```bash
# Verificar status de reconciliação do ESO
kubectl get externalsecrets -n comments
kubectl describe externalsecret comments-api-db-secret -n comments

# Confirmar se a Secret nativa foi gerada
kubectl get secret comments-api-db-secret -n comments
```

### 2.4 Teste de Conectividade Interna com o PostgreSQL
```bash
# Executar ping de rede a partir de um pod efêmero na VPC
kubectl run netshoot --rm -i --tty --image nicolaka/netshoot -n comments -- \
  nc -zv <CLOUDSQL_PRIVATE_IP> 5432
```

---

## 3. Ações de Contenção

1. **Reinício de emergência dos pods:**
   ```bash
   kubectl rollout restart deployment/comments-api -n comments
   ```
2. **Escalonamento manual preventivo caso o HPA atinja o teto:**
   ```bash
   kubectl scale deployment/comments-api --replicas=5 -n comments
   ```
3. **Rollback de versão (caso o incidente decorra de deploy recente):**
   - Consulte o [Runbook de Rollback](./rollback-procedure.md).
