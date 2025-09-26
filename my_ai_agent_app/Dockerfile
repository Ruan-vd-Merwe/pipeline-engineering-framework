# syntax=docker/dockerfile:1

# 1) Base image
FROM python:3.11-slim

# 2) Set workdir
WORKDIR /app

# 3) System deps (optional: for dbt adapters / postgres libs etc.)
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       build-essential \
       git \
       curl \
       ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 4) Copy requirements and install
COPY requirements.txt ./
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt

# 5) Copy application code
COPY agent.py ./
COPY dbt_project ./dbt_project

# 6) Environment variables (placeholders)
# Set at runtime or via docker-compose; not recommended to bake secrets into images
ENV OPENAI_API_KEY=""
ENV DBT_PROFILES_DIR="/app/dbt_project" 

# 7) Expose ports (if agent.py starts a server). Not strictly needed for CLI.
# EXPOSE 8000

# 8) Default entrypoint / command. Allows passing arbitrary args to agent.py
ENTRYPOINT ["python", "agent.py"]
CMD ["--help"]
