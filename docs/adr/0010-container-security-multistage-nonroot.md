# 10. Container Security: Multi-Stage Build Não-Root com Python Slim

A imagem de container da API de comentários utilizará compilação multi-stage baseada em `python:3.12-slim`:
1. **Stage builder**: Instala dependências e compila wheels necessários;
2. **Stage final**: Copia estritamente o virtualenv gerado e os arquivos da aplicação para uma imagem limpa, executando sob um usuário não-root dedicado (`appuser` com UID/GID 10001) e sem permissões de sudo;
3. O filesystem root é tratado como read-only (com tmpfs quando aplicável). Essa abordagem reduz a superfície de ataque, otimiza o tamanho da imagem (< 150MB) e garante aprovação limpa nos scanners de segurança (Trivy).
