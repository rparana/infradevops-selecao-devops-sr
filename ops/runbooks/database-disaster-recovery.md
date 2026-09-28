# Runbook: Recuperação de Desastre e Backup do Banco (Cloud SQL)

Orientações para operações de backup, restore pontual (Point-in-Time Recovery - PITR) e recuperação do PostgreSQL no Google Cloud SQL.

---

## 1. Rotinas de Backup Automatizadas

O módulo Terraform (`infra/terraform/modules/cloudsql`) configura backups automáticos diários com janela às 03:00 UTC e retenção ativa.

### 1.1 Listar Backups Existentes
```bash
gcloud sql backups list --instance=<CLOUDSQL_INSTANCE_NAME> --project=<PROJECT_ID>
```

### 1.2 Disparar um Backup Manual Sob Demanda
Antes de migrações críticas ou mudanças estruturais:
```bash
gcloud sql backups create \
  --instance=<CLOUDSQL_INSTANCE_NAME> \
  --description="Backup pré-migração de schema $(date +%Y%m%d%H%M)" \
  --project=<PROJECT_ID>
```

---

## 2. Procedimento de Restauração (Restore)

> [!WARNING]
> A restauração de um backup sobrescreve os dados existentes na instância de destino. Recomenda-se realizar um clone ou criar uma instância de teste caso deseje inspecionar dados históricos sem impacto em produção.

### 2.1 Restaurar Backup Específico na Mesma Instância
```bash
# 1. Identificar o ID do backup
BACKUP_ID=$(gcloud sql backups list --instance=<CLOUDSQL_INSTANCE_NAME> --project=<PROJECT_ID> --format="value(id)" --limit=1)

# 2. Executar o restore
gcloud sql backups restore "${BACKUP_ID}" \
  --restore-instance=<CLOUDSQL_INSTANCE_NAME> \
  --project=<PROJECT_ID>
```

### 2.2 Point-in-Time Recovery (PITR)
Para restaurar a base para um timestamp exato antes de uma perda acidental de dados:
```bash
# Clonar para uma nova instância com timestamp específico (RFC 3339)
gcloud sql instances clone <CLOUDSQL_INSTANCE_NAME> <NEW_CLONE_INSTANCE_NAME> \
  --point-in-time="2026-09-28T14:30:00.000Z" \
  --project=<PROJECT_ID>
```

---

## 3. Validação Pós-Recuperação

1. Conectar na instância e inspecionar a contagem de registros na tabela de comentários:
   ```sql
   SELECT count(*) FROM comments;
   ```
2. Verificar se a API restabeleceu a conectividade através do `/health`:
   ```bash
   curl -s https://<API_DOMAIN>/health
   ```
