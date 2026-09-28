# 9. Database Migrations: Inicialização Resiliente no Lifespan com Versionamento Alembic

Adotamos uma abordagem híbrida para criação e evolução do schema de banco de dados:
1. Na inicialização da aplicação FastAPI (via context manager de `lifespan`), a API executa `Base.metadata.create_all` de forma assíncrona para garantir a existência das tabelas sem bloquear ou quebrar ambientes efêmeros (testes locais, KinD, pipelines de CI);
2. A evolução controlada de schema em ambientes produtivos é gerenciada com scripts de migração do Alembic versionados no repositório (`app/src/alembic/`), permitindo auditoria, rollbacks e rastreabilidade de DDL.
