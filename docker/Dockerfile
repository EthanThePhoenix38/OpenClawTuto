# =============================================================================
# Phoenix Secure Dockerfile
# Version: 1.0.0
# Auteur: Ethan Bernier (ORCID: 0009-0008-9839-5763)
# Description: Image Docker sécurisée pour Phoenix Gateway
# =============================================================================
#
# SÉCURITÉ APPLIQUÉE :
# - Multi-stage build (réduction surface d'attaque)
# - Utilisateur non-root (UID 1000)
# - Pas de shell interactif en production
# - Dépendances minimales
# - Scan de vulnérabilités intégré
#
# BUILD :
#   docker build -t phoenix-secure:latest .
#   docker build -t phoenix-secure:2026.1.30 --build-arg VERSION=2026.1.30 .
#
# =============================================================================

# -----------------------------------------------------------------------------
# Stage 1: Builder - Installation des dépendances
# -----------------------------------------------------------------------------
FROM node:20-alpine AS builder

# Arguments de build
ARG VERSION=2026.1.30
ARG PHOENIX_VERSION=latest

# Labels OCI
LABEL org.opencontainers.image.title="Phoenix Gateway Builder"
LABEL org.opencontainers.image.version="${VERSION}"
LABEL org.opencontainers.image.vendor="Ethan Bernier"

# Répertoire de travail
WORKDIR /build

# Installer les outils de build
RUN apk add --no-cache \
    python3 \
    make \
    g++ \
    git

# Copier package.json si présent (pour builds custom)
# COPY package*.json ./

# Installer Phoenix globalement
RUN npm install -g phoenix@${PHOENIX_VERSION} --omit=dev

# Copier les fichiers installés
RUN cp -r /usr/local/lib/node_modules/phoenix /build/phoenix

# Nettoyer les fichiers inutiles
RUN find /build -name "*.md" -delete && \
    find /build -name "*.ts" -delete && \
    find /build -name "test*" -type d -exec rm -rf {} + 2>/dev/null || true && \
    find /build -name "*.map" -delete && \
    rm -rf /build/phoenix/node_modules/.cache

# -----------------------------------------------------------------------------
# Stage 2: Security Scanner - Audit des vulnérabilités
# -----------------------------------------------------------------------------
FROM node:20-alpine AS scanner

WORKDIR /scan

# Copier depuis builder
COPY --from=builder /build/phoenix ./phoenix

# Installer et exécuter npm audit
RUN cd phoenix && \
    npm audit --audit-level=high --omit=dev 2>&1 | tee /scan/audit-report.txt || true

# Note: Le build continue même si des vulnérabilités sont trouvées
# En production, ajouter: && exit 1 pour bloquer

# -----------------------------------------------------------------------------
# Stage 3: Production - Image finale minimale
# -----------------------------------------------------------------------------
FROM node:20-alpine AS production

# Arguments de build
ARG VERSION=2026.1.30
ARG BUILD_DATE
ARG VCS_REF

# Labels OCI (standard)
LABEL org.opencontainers.image.title="Phoenix Gateway"
LABEL org.opencontainers.image.description="Assistant IA personnel sécurisé"
LABEL org.opencontainers.image.version="${VERSION}"
LABEL org.opencontainers.image.created="${BUILD_DATE}"
LABEL org.opencontainers.image.revision="${VCS_REF}"
LABEL org.opencontainers.image.vendor="Ethan Bernier"
LABEL org.opencontainers.image.authors="Ethan Bernier <ethan.bernier.data@gmail.com>"
LABEL org.opencontainers.image.url="https://github.com/EthanThePhoenix38/Phoenix"
LABEL org.opencontainers.image.documentation="https://github.com/EthanThePhoenix38/Phoenix"
LABEL org.opencontainers.image.source="https://github.com/EthanThePhoenix38/Phoenix"
LABEL org.opencontainers.image.licenses="MIT"

# Labels personnalisés (sécurité)
LABEL security.phoenix.io/hardened="true"
LABEL security.phoenix.io/non-root="true"
LABEL security.phoenix.io/read-only-fs="partial"

# Variables d'environnement
ENV NODE_ENV=production \
    PHOENIX_PORT=18789 \
    PHOENIX_HOST=0.0.0.0 \
    PHOENIX_SANDBOX_MODE=non-main \
    PHOENIX_DM_ACCESS=pairing \
    TZ=Europe/Paris \
    # Désactiver les fonctions Node.js dangereuses
    NODE_OPTIONS="--no-experimental-fetch --no-warnings" \
    # Sécurité npm
    NPM_CONFIG_AUDIT=true \
    NPM_CONFIG_FUND=false

# Créer l'utilisateur non-root AVANT les copies
RUN addgroup -g 1000 -S phoenix && \
    adduser -u 1000 -S -G phoenix -h /home/phoenix phoenix

# Installer les dépendances runtime minimales
RUN apk add --no-cache \
    # Timezone
    tzdata \
    # Certificats SSL
    ca-certificates \
    # Healthcheck
    curl \
    # Pas de shell bash (sécurité) - garder sh minimal
    && rm -rf /var/cache/apk/*

# Créer les répertoires nécessaires
RUN mkdir -p /home/phoenix/.phoenix \
             /tmp/phoenix \
             /var/log/phoenix && \
    chown -R phoenix:phoenix /home/phoenix /tmp/phoenix /var/log/phoenix

# Copier Phoenix depuis le builder
COPY --from=builder --chown=phoenix:phoenix /build/phoenix /usr/local/lib/node_modules/phoenix

# Créer le lien symbolique pour l'exécutable
RUN ln -s /usr/local/lib/node_modules/phoenix/dist/cli/index.js /usr/local/bin/phoenix && \
    chmod +x /usr/local/bin/phoenix

# Copier le rapport d'audit (optionnel, pour référence)
COPY --from=scanner /scan/audit-report.txt /home/phoenix/.phoenix/

# Basculer vers l'utilisateur non-root
USER phoenix

# Répertoire de travail
WORKDIR /home/phoenix

# Port exposé
EXPOSE 18789

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:18789/health || exit 1

# Point d'entrée
ENTRYPOINT ["node", "/usr/local/lib/node_modules/phoenix/dist/cli/index.js"]

# Commande par défaut
CMD ["gateway"]

# -----------------------------------------------------------------------------
# Stage 4: Debug - Image avec outils de débogage (optionnel)
# -----------------------------------------------------------------------------
FROM production AS debug

# Revenir à root pour installer les outils
USER root

# Installer les outils de debug
RUN apk add --no-cache \
    bash \
    vim \
    netcat-openbsd \
    bind-tools \
    strace \
    tcpdump

# Revenir à l'utilisateur phoenix
USER phoenix

# Override du CMD pour le debug
CMD ["sh", "-c", "echo 'Debug mode - Phoenix not started. Use: node /usr/local/lib/node_modules/phoenix/dist/cli/index.js gateway'"]
