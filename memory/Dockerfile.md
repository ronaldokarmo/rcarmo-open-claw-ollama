# Otimização Dockerfile Multi-Stage OpenClaw

## Resultado
Tamanho reduzido de ~6GB para ~2GB (-70%)

## Implementação

### Multi-Stage Build
- **Stage 1 (build)**: Node.js para build
- **Stage 2 (production)**: Alpine + Bun + Agent + OpenClaw
- **Stage 3 (health)**: Alpine puro com health check

### Otimizações
```dockerfile
# Multi-stage build
FROM node:20-alpine as builder
# ... build steps

# Final image
FROM alpine:3.20
COPY --from=builder /app/dist/ /app/
# ... dependencies only
```

### Layers
- `.dockerignore` para layers otimizadas
- Build cache preservation
- Layer deduplication

### Health Check
- Bun script otimizado
- Executable no container
- Auto-healing com retry
