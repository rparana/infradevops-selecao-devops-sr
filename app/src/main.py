import logging
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from typing import List

from fastapi import Depends, FastAPI, HTTPException, status
from prometheus_fastapi_instrumentator import Instrumentator
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.src.config import settings
from app.src.database import check_db_health, get_db, init_db
from app.src.models import Comment
from app.src.schemas import CommentCreate, CommentResponse, HealthResponse, LivenessResponse

logging.basicConfig(
    level=getattr(logging, settings.LOG_LEVEL.upper(), logging.INFO),
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger("comments_api")


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    logger.info("Starting up %s v%s", settings.APP_NAME, settings.APP_VERSION)
    try:
        await init_db()
    except Exception as exc:
        logger.error("Failed to initialize database on startup: %s", exc)
    yield
    logger.info("Shutting down %s", settings.APP_NAME)


app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description="API REST de Comentários desenvolvida para o Desafio Técnico de Analista DevOps Sênior.",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan,
)

# Instrument Prometheus metrics endpoint at /metrics
instrumentator = Instrumentator(
    should_group_status_codes=False,
    should_ignore_untemplated=True,
    should_respect_env_var=False,
    excluded_handlers=["/metrics", "/health"],
    env_var_name="ENABLE_METRICS",
)
instrumentator.instrument(app).expose(app, endpoint="/metrics", include_in_schema=True)


@app.get(
    "/health/live",
    response_model=LivenessResponse,
    tags=["Observability"],
    summary="Liveness probe para Kubernetes (indica que o processo da API está ativo)",
)
async def liveness_check() -> LivenessResponse:
    return LivenessResponse(status="alive", version=settings.APP_VERSION)


@app.get(
    "/health/ready",
    response_model=HealthResponse,
    tags=["Observability"],
    summary="Readiness probe para Kubernetes (indica prontidão para receber tráfego com banco)",
)
async def readiness_check() -> HealthResponse:
    db_healthy = await check_db_health()
    if not db_healthy:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail={"status": "not_ready", "database": "disconnected", "version": settings.APP_VERSION},
        )
    return HealthResponse(
        status="ready",
        database="connected",
        version=settings.APP_VERSION,
    )


@app.get(
    "/health",
    response_model=HealthResponse,
    tags=["Observability"],
    summary="Health check probe geral (Liveness/Readiness legado)",
)
async def health_check() -> HealthResponse:
    db_healthy = await check_db_health()
    if not db_healthy:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail={"status": "unhealthy", "database": "disconnected", "version": settings.APP_VERSION},
        )
    return HealthResponse(
        status="healthy",
        database="connected",
        version=settings.APP_VERSION,
    )


@app.post(
    "/api/comment/new",
    response_model=CommentResponse,
    status_code=status.HTTP_201_CREATED,
    tags=["Comments"],
    summary="Inserir um novo comentário em uma matéria",
)
async def create_comment(
    payload: CommentCreate,
    db: AsyncSession = Depends(get_db),
) -> CommentResponse:
    comment = Comment(
        email=payload.email,
        comment=payload.comment,
        content_id=payload.content_id,
    )
    db.add(comment)
    await db.commit()
    await db.refresh(comment)
    logger.info("Created comment ID %d for content_id %d", comment.id, comment.content_id)
    return CommentResponse.model_validate(comment)


@app.get(
    "/api/comment/list/{id}",
    response_model=List[CommentResponse],
    status_code=status.HTTP_200_OK,
    tags=["Comments"],
    summary="Listar comentários de uma matéria específica",
)
async def list_comments(
    id: int,
    db: AsyncSession = Depends(get_db),
) -> List[CommentResponse]:
    query = (
        select(Comment)
        .where(Comment.content_id == id)
        .order_by(Comment.created_at.desc())
    )
    result = await db.execute(query)
    comments = result.scalars().all()
    return [CommentResponse.model_validate(c) for c in comments]
