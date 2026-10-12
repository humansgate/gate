FROM ubuntu:24.04

# Éviter les questions interactives
ENV DEBIAN_FRONTEND=noninteractive

# Installer les dépendances de base
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    unzip \
    xz-utils \
    git \
    ca-certificates \
    apt-transport-https \
    gnupg \
    sudo \
    && rm -rf /var/lib/apt/lists/*


# ======================
# Node.js 20
# ======================
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# ======================
# Dart SDK (ARM64)
# ======================
ARG DART_VERSION=3.10.4
RUN wget -q https://storage.googleapis.com/dart-archive/channels/stable/release/${DART_VERSION}/sdk/dartsdk-linux-arm64-release.zip \
    && unzip dartsdk-linux-arm64-release.zip -d /usr/lib \
    && rm dartsdk-linux-arm64-release.zip \
    && ln -s /usr/lib/dart-sdk /usr/lib/dart

# ======================
# OpenCode (installé pour l'utilisateur ubuntu)
# ======================
USER ubuntu
WORKDIR /home/ubuntu

RUN curl -fsSL https://opencode.ai/install | bash

# Config OpenCode → Ollama sur le host Mac
RUN mkdir -p /home/ubuntu/.config/opencode \
    && cat > /home/ubuntu/.config/opencode/opencode.json << 'EOF'
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "ollama": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Ollama (host)",
      "options": {
        "baseURL": "http://host.docker.internal:11434/v1"
      },
      "models": {
        "qwen3.8:latest": {
          "name": "Qwen3.8",
          "tools": true
        }
      }
    }
  },
  "model": "ollama/qwen3.8:latest"
}
EOF

# Ajouter OpenCode + Dart au PATH
ENV PATH="/home/ubuntu/.opencode/bin:/usr/lib/dart/bin:${PATH}"

# Définir l'utilisateur par défaut
USER ubuntu
WORKDIR /workspace