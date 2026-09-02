FROM python:3.11-slim

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    zip \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Pre-cache the internal sandboxed runner inside the image build
RUN python -c "import docker; \
try: docker.from_env().images.pull('python:3.11-slim') \
except Exception: pass"

COPY . .
