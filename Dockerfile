# ================================
# Etapa 1: construcción
# ================================
FROM python:3.11-slim AS builder

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

# ================================
# Etapa 2: producción
# ================================
FROM python:3.11-slim

WORKDIR /app

# Usuario sin privilegios root
RUN groupadd --system appgroup && \
    useradd --system --gid appgroup --no-create-home appuser

# Copiar dependencias instaladas desde la etapa builder
COPY --from=builder /root/.local /home/appuser/.local

# Copiar código fuente con el dueño correcto
COPY --chown=appuser:appgroup . .

USER appuser

ENV PATH=/home/appuser/.local/bin:$PATH
ENV PYTHONUNBUFFERED=1

EXPOSE 5000

CMD ["python", "app.py"]
