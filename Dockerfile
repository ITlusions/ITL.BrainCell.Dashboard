# Dockerfile for BrainCell Dashboard Web UI
# Build context must be D:\repos\ (parent of all ITL.BrainCell* repos)
FROM python:3.12-alpine AS builder

WORKDIR /build

RUN apk add --no-cache build-base postgresql-dev

COPY ITL.BrainCell/requirements.txt .
RUN pip install --no-cache-dir --target ./python-packages -r requirements.txt

# ========== Runtime Stage ==========
FROM python:3.12-alpine

WORKDIR /app

RUN apk add --no-cache postgresql-client curl

COPY --from=builder /build/python-packages /usr/local/lib/python3.12/site-packages

# Copy shared core from ITL.BrainCell
COPY ITL.BrainCell/src/core src/core
COPY ITL.BrainCell/src/cells src/cells
COPY ITL.BrainCell/src/services src/services

# Copy Dashboard-specific code
COPY ITL.BrainCell.Dashboard/src/web src/web
COPY ITL.BrainCell.Dashboard/src/__init__.py src/__init__.py

RUN addgroup braincell && adduser -D -G braincell braincell && \
    chown -R braincell:braincell /app

USER braincell

EXPOSE 8001

HEALTHCHECK --interval=10s --timeout=5s --retries=5 \
    CMD curl -f http://localhost:8001/ || exit 1

CMD ["python", "-m", "uvicorn", "src.web.app:app", "--host", "0.0.0.0", "--port", "8001"]
