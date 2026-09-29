from datetime import datetime
from pydantic import BaseModel, ConfigDict, EmailStr, Field


class CommentCreate(BaseModel):
    email: EmailStr = Field(..., description="Email do autor do comentário", examples=["devops@example.com"])
    comment: str = Field(..., min_length=1, max_length=2000, description="Texto do comentário", examples=["Excelente artigo sobre Kubernetes!"])
    content_id: int = Field(..., gt=0, description="Identificador da matéria/conteúdo", examples=[42])


class CommentResponse(BaseModel):
    id: int = Field(..., description="ID único do comentário")
    email: EmailStr = Field(..., description="Email do autor")
    comment: str = Field(..., description="Texto do comentário")
    content_id: int = Field(..., description="Identificador da matéria/conteúdo")
    created_at: datetime = Field(..., description="Timestamp de criação")

    model_config = ConfigDict(from_attributes=True)


class HealthResponse(BaseModel):
    status: str = Field("healthy", description="Status da aplicação")
    database: str = Field("connected", description="Status da conexão com banco")
    version: str = Field("1.0.0", description="Versão da aplicação")


class LivenessResponse(BaseModel):
    status: str = Field("alive", description="Status de vivacidade do processo")
    version: str = Field("1.0.0", description="Versão da aplicação")

