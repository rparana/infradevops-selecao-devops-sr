# ADR-0012: IaC Security Hardening e Conformidade CIS Benchmarks com Checkov

- **Status:** Aceito
- **Data:** 2026-09-28
- **Decisores:** Time de Engenharia DevOps

## Contexto

Para garantir que a infraestrutura provisionada no Google Cloud Platform (GCP) via Terraform siga padrões elevados de segurança, auditoria e conformidade, é necessário submeter o código de IaC a análises estáticas rigorosas (SAST para IaC) antes de qualquer deployment. O desafio técnico requer explicitamente a utilização do Checkov para validação de segurança.

## Decisão

Adotamos o **Checkov** como scanner estático obrigatório de IaC integrado à esteira de CI/CD e verificação local. Implementamos o hardening nos módulos Terraform cobrindo:

1. **GKE:** Workload Identity Metadata Server, Shielded VM (Secure Boot + Integrity Monitoring), Release Channel Regular, Network Policy, Intranode Visibility, Binary Authorization e desativação de Client Certificates.
2. **Cloud SQL:** Criptografia ponta-a-ponta (SSL/TLS obrigatório), Point-in-time Recovery (PITR), extensão pgAudit ativa e flags detalhadas de log (conexões, desconexões, checkpoints, temp files, hostnames e statements).
3. **VPC:** VPC Flow Logs ativados nas subnets e regras de firewall internas dedicadas (least-privilege).
4. **WIF (Workload Identity Federation):** Mapeamento granular de claims do GitHub Actions eliminando Service Account Keys persistentes.

Para políticas do Checkov incompatíveis com ambientes de avaliação/sandbox (como exigência de domínio Google Workspace ou versions ainda não lançadas como PostgreSQL 18), foram documentadas supressões rastreáveis via `# checkov:skip` com justificativas técnicas detalhadas no relatório `docs/security/iac-security-checkov.md`.

## Consequências

- **Positivas:** Conformidade total (84 passed, 0 failed, 5 justificados), infraestrutura auditável alinhada aos CIS Benchmarks do GCP e proteção contra vazamento de credenciais e escalonamento de privilégios.
- **Negativas / Custos:** Maior volume de logs gerados (VPC Flow Logs e pgAudit) requerem retenção gerenciada em ambientes produtivos para controle de custos de armazenamento no Cloud Logging.
