FROM ubuntu:jammy-20240627.1 AS base

# Build arguments - Use Railway's UID 1000
ARG ARG_UID=1000
ARG ARG_GID=1000

FROM base AS build-arm64
RUN echo "Preparing build of AnythingLLM image for arm64 architecture"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install system dependencies
# hadolint ignore=DL3008,DL3013
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
        unzip curl gnupg libgfortran5 libgbm1 tzdata netcat \
        libasound2 libatk1.0-0 libc6 libcairo2 libcups2 libdbus-1-3 libexpat1 libfontconfig1 \
        libgcc1 libglib2.0-0 libgtk-3-0 libnspr4 libpango-1.0-0 libx11-6 libx11-xcb1 libxcb1 \
        libxcomposite1 libxcursor1 libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 \
        libxss1 libxtst6 ca-certificates fonts-liberation libappindicator1 libnss3 lsb-release \
        xdg-utils git build-essential ffmpeg && \
    mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_18.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list && \
    apt-get update && \
    # Install node and yarn
    apt-get install -yq --no-install-recommends nodejs && \
    curl -LO https://github.com/yarnpkg/yarn/releases/download/v1.22.19/yarn_1.22.19_all.deb \
        && dpkg -i yarn_1.22.19_all.deb \
        && rm yarn_1.22.19_all.deb && \
    # Install uvx (pinned to 0.6.10) for MCP support
    curl -LsSf https://astral.sh/uv/0.6.10/install.sh | sh && \
        mv /root/.local/bin/uv /usr/local/bin/uv && \
        mv /root/.local/bin/uvx /usr/local/bin/uvx && \
        echo "Installed uvx! $(uv --version)" && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create a group and user with specific UID and GID
RUN groupadd -g "$ARG_GID" anythingllm && \
    useradd -l -u "$ARG_UID" -m -d /app -s /bin/bash -g anythingllm anythingllm && \
    mkdir -p /app/frontend/ /app/server/ /app/collector/ && chown -R anythingllm:anythingllm /app

# Copy docker helper scripts
COPY ./docker/docker-entrypoint.sh /usr/local/bin/
COPY ./docker/docker-healthcheck.sh /usr/local/bin/
COPY --chown=anythingllm:anythingllm ./docker/.env.example /app/server/.env

# Ensure the scripts are executable
RUN chmod +x /usr/local/bin/docker-entrypoint.sh && \
    chmod +x /usr/local/bin/docker-healthcheck.sh

USER anythingllm
WORKDIR /app

# Puppeteer does not ship with an ARM86 compatible build for Chromium
# so web-scraping would be broken in arm docker containers unless we patch it
# by manually installing a compatible chromedriver.
RUN echo "Need to patch Puppeteer x Chromium support for ARM86 - installing dep!" && \
    curl https://playwright.azureedge.net/builds/chromium/1088/chromium-linux-arm64.zip -o chrome-linux.zip && \
    unzip chrome-linux.zip && \
    rm -rf chrome-linux.zip

ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV CHROME_PATH=/app/chrome-linux/chrome
ENV PUPPETEER_EXECUTABLE_PATH=/app/chrome-linux/chrome

RUN echo "Done running arm64 specific installation steps"

#############################################

# amd64-specific stage
FROM base AS build-amd64
RUN echo "Preparing build of AnythingLLM image for non-ARM architecture"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install system dependencies
# hadolint ignore=DL3008,DL3013
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
        curl gnupg libgfortran5 libgbm1 tzdata netcat \
        libasound2 libatk1.0-0 libc6 libcairo2 libcups2 libdbus-1-3 libexpat1 libfontconfig1 \
        libgcc1 libglib2.0-0 libgtk-3-0 libnspr4 libpango-1.0-0 libx11-6 libx11-xcb1 libxcb1 \
        libxcomposite1 libxcursor1 libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 \
        libxss1 libxtst6 ca-certificates fonts-liberation libappindicator1 libnss3 lsb-release \
        xdg-utils git build-essential ffmpeg && \
    mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_18.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list && \
    apt-get update && \
    # Install node and yarn
    apt-get install -yq --no-install-recommends nodejs && \
    curl -LO https://github.com/yarnpkg/yarn/releases/download/v1.22.19/yarn_1.22.19_all.deb \
        && dpkg -i yarn_1.22.19_all.deb \
        && rm yarn_1.22.19_all.deb && \
    # Install uvx (pinned to 0.6.10) for MCP support
    curl -LsSf https://astral.sh/uv/0.6.10/install.sh | sh && \
        mv /root/.local/bin/uv /usr/local/bin/uv && \
        mv /root/.local/bin/uvx /usr/local/bin/uvx && \
        echo "Installed uvx! $(uv --version)" && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create a group and user with specific UID and GID
RUN groupadd -g "$ARG_GID" anythingllm && \
    useradd -l -u "$ARG_UID" -m -d /app -s /bin/bash -g anythingllm anythingllm && \
    mkdir -p /app/frontend/ /app/server/ /app/collector/ && chown -R anythingllm:anythingllm /app

# Copy docker helper scripts
COPY ./docker/docker-entrypoint.sh /usr/local/bin/
COPY ./docker/docker-healthcheck.sh /usr/local/bin/
COPY --chown=anythingllm:anythingllm ./docker/.env.example /app/server/.env

# Ensure the scripts are executable
RUN chmod +x /usr/local/bin/docker-entrypoint.sh && \
    chmod +x /usr/local/bin/docker-healthcheck.sh

#############################################
# COMMON BUILD FLOW FOR ALL ARCHS
#############################################

# hadolint ignore=DL3006
FROM build-${TARGETARCH} AS build
RUN echo "Running common build flow of AnythingLLM image for all architectures"

USER anythingllm
WORKDIR /app

# Install & Build frontend layer
FROM build AS frontend-build
COPY --chown=anythingllm:anythingllm ./frontend /app/frontend/
WORKDIR /app/frontend
RUN yarn install --network-timeout 100000 && yarn cache clean
RUN yarn build && \
    cp -r dist /tmp/frontend-build && \
    rm -rf * && \
    cp -r /tmp/frontend-build dist && \
    rm -rf /tmp/frontend-build
WORKDIR /app

# Install server layer
# Also pull and build collector deps (chromium issues prevent bad bindings)
FROM build AS backend-build
COPY --chown=anythingllm:anythingllm ./server /app/server/
WORKDIR /app/server
RUN yarn install --production --network-timeout 100000 && yarn cache clean
WORKDIR /app

# Install collector dependencies
COPY --chown=anythingllm:anythingllm ./collector/ ./collector/
WORKDIR /app/collector
ENV PUPPETEER_DOWNLOAD_BASE_URL=https://storage.googleapis.com/chrome-for-testing-public
RUN yarn install --production --network-timeout 100000 && yarn cache clean

WORKDIR /app
USER anythingllm

# Since we are building from backend-build we just need to move built frontend into server/public
FROM backend-build AS production-build
WORKDIR /app
COPY --chown=anythingllm:anythingllm --from=frontend-build /app/frontend/dist /app/server/public
USER root

# RAILWAY STORAGE PERMISSIONS FIX - Create ALL possible storage directories
RUN mkdir -p /app/server/storage \
    /app/server/storage/documents \
    /app/server/storage/vector-cache \
    /app/server/storage/lancedb \
    /app/server/storage/outputs \
    /app/server/storage/uploads \
    /app/server/storage/workspaces \
    /app/server/storage/chats \
    /app/server/storage/models \
    /app/server/storage/models/context-windows \
    /app/server/storage/models/embeddings \
    /app/server/storage/models/custom \
    /app/server/storage/tmp \
    /app/server/storage/cache \
    /app/server/storage/logs \
    /app/collector/hotdir \
    /app/collector/outputs \
    /app/logs

# RAILWAY STORAGE PERMISSIONS FIX - Set ownership for everything under /app
RUN chown -R 1000:1000 /app

# RAILWAY STORAGE PERMISSIONS FIX - Set write permissions for entire storage tree
# This allows the app to create any subdirectories it needs at runtime
RUN chmod -R 755 /app && \
    chmod -R 777 /app/server/storage && \
    chmod -R 777 /app/collector && \
    chmod -R 777 /app/logs

# RAILWAY STORAGE PERMISSIONS FIX - Handle potential Railway volume mount paths
RUN mkdir -p /storage /data && \
    chown -R 1000:1000 /storage /data && \
    chmod -R 777 /storage /data

# RAILWAY STORAGE PERMISSIONS FIX - Create symbolic links for various mount possibilities
RUN ln -sf /storage /app/server/storage 2>/dev/null || true && \
    ln -sf /data /app/server/storage 2>/dev/null || true

USER anythingllm

# Setup the environment
ENV NODE_ENV=production
ENV ANYTHING_LLM_RUNTIME=docker
ENV DEPLOYMENT_VERSION=1.8.5

# RAILWAY STORAGE PERMISSIONS FIX - Add Railway-specific environment variables
ENV STORAGE_DIR=/app/server/storage \
    PERSIST_DATA=true \
    SERVER_PORT=3001 \
    FILE_UPLOAD_MAX_SIZE=100mb

# Setup the healthcheck
HEALTHCHECK --interval=1m --timeout=10s --start-period=1m \
  CMD /bin/bash /usr/local/bin/docker-healthcheck.sh || exit 1

# Run the server
# CMD ["sh", "-c", "tail -f /dev/null"] # For development: keep container open

# Create custom entrypoint script for Railway permissions
RUN echo '#!/bin/bash' > /usr/local/bin/railway-entrypoint.sh && \
    echo 'echo "Setting up storage directories for Railway..."' >> /usr/local/bin/railway-entrypoint.sh && \
    echo 'mkdir -p /app/server/storage/{documents,vector-cache,lancedb,outputs,uploads,workspaces,chats,models,tmp,cache,logs}' >> /usr/local/bin/railway-entrypoint.sh && \
    echo 'mkdir -p /app/server/storage/models/{context-windows,embeddings,custom}' >> /usr/local/bin/railway-entrypoint.sh && \
    echo 'mkdir -p /app/collector/{hotdir,outputs}' >> /usr/local/bin/railway-entrypoint.sh && \
    echo 'mkdir -p /app/logs' >> /usr/local/bin/railway-entrypoint.sh && \
    echo 'chmod -R 777 /app/server/storage /app/collector /app/logs 2>/dev/null || true' >> /usr/local/bin/railway-entrypoint.sh && \
    echo 'echo "Storage setup complete, starting AnythingLLM..."' >> /usr/local/bin/railway-entrypoint.sh && \
    echo 'exec /bin/bash /usr/local/bin/docker-entrypoint.sh "$@"' >> /usr/local/bin/railway-entrypoint.sh && \
    chmod +x /usr/local/bin/railway-entrypoint.sh

# Use the custom entrypoint
ENTRYPOINT ["/bin/bash", "/usr/local/bin/railway-entrypoint.sh"]
# ENTRYPOINT ["/bin/bash", "/usr/local/bin/docker-entrypoint.sh"]
