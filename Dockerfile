# Use Python 3.12 slim image for smaller footprint
FROM python:3.12-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    POETRY_VERSION=1.8.3 \
    UV_VERSION=0.4.4

# Set work directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install uv (modern Python package installer)
RUN pip install uv==$UV_VERSION

# Copy project files
COPY . .

# Install Python dependencies using uv
RUN uv sync --frozen

# Create a non-root user
RUN useradd --create-home --shell /bin/bash penpot && \
    chown -R penpot:penpot /app
USER penpot

# Expose the default port
EXPOSE 5000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:5000/health')" || exit 1

# Default command - can be overridden
CMD ["uv", "run", "penpot-mcp"]
