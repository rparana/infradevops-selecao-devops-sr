# 3. Backend Stack: Python com FastAPI e SQLAlchemy

A API de comentários será desenvolvida em Python utilizando FastAPI e SQLAlchemy com driver assíncrono (asyncpg). A escolha provê geração automática de documentação interativa OpenAPI/Swagger (`/docs`), validação estrita de dados com Pydantic, e instrumentação nativa de métricas Prometheus através do `prometheus-fastapi-instrumentator`, atendendo a todos os requisitos de endpoints (`/api/comment/new`, `/api/comment/list/{id}`, `/health`, `/metrics`) com código limpo e testabilidade via pytest.
