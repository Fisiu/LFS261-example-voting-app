# STAGE 1
FROM python:3.11-slim AS builder

WORKDIR /app

# Prevent Python from writing .pyc files and enable unbuffered logging
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# RUN apt-get update && apt-get install -y --no-cache \
#     build-essential curl \
#     && rm -rf /var/lib/apt/lists/*

# Use a virtual environment to make copying to the next stage easier
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# STAGE 2
FROM python:3.11-slim AS runner

WORKDIR /app

# Install tini to handle signals correctly (the Python version of what we did for Node)
RUN apt-get update && apt-get install -y tini curl && rm -rf /var/lib/apt/lists/*

# Copy the virtual environment from the builder
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copy application code
COPY . .

# Set default Environment Variables
ENV FLASK_APP=app.py
ENV FLASK_RUN_HOST=0.0.0.0
ENV PORT=5000
EXPOSE 5000

RUN useradd -m flask
USER flask

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["sh", "-c", "gunicorn", "--bind", "0.0.0.0:$PORT", "app:app"]
