FROM node:18-alpine

# Install system dependencies for faster builds
RUN apk add --no-cache python3 make g++

WORKDIR /app

# Copy package files first for better Docker layer caching
COPY package*.json ./
COPY server/package*.json ./server/
COPY collector/package*.json ./collector/
COPY frontend/package*.json ./frontend/

# Install dependencies (this layer will be cached if package.json doesn't change)
RUN npm ci --only=production --legacy-peer-deps && \
    cd server && npm ci --only=production --legacy-peer-deps && \
    cd ../collector && npm ci --only=production --legacy-peer-deps && \
    cd ../frontend && npm ci --legacy-peer-deps

# Copy source code
COPY . .

# Build frontend (most time-consuming step)
RUN cd frontend && npm run build

# Generate Prisma client
RUN cd server && npx prisma generate

# Clean up to reduce image size
RUN npm cache clean --force && \
    rm -rf /tmp/* /var/cache/apk/*

USER root

# Your storage permissions (keeping exactly as you had)
RUN mkdir -p /app/server/storage \
    /app/server/storage/documents \
    /app/server/storage/vector-cache \
    /app/server/storage/lancedb \
    /app/server/storage/outputs \
    /app/server/storage/uploads \
    /app/server/storage/workspaces \
    /app/server/storage/chats \
    /app/collector/hotdir \
    /app/collector/outputs \
    /app/logs

RUN chown -R 1000:1000 /app/server && \
    chown -R 1000:1000 /app/collector && \
    chown -R 1000:1000 /app/logs || true

RUN chmod -R 777 /app/server/storage && \
    chmod -R 777 /app/collector && \
    chmod -R 777 /app/logs || true

RUN mkdir -p /storage /data && \
    chown -R 1000:1000 /storage /data && \
    chmod -R 777 /storage /data || true

RUN ln -sf /storage /app/server/storage 2>/dev/null || true && \
    ln -sf /data /app/server/storage 2>/dev/null || true

ENV STORAGE_DIR=/app/server/storage \
    PERSIST_DATA=true \
    NODE_ENV=production \
    SERVER_PORT=3001 \
    FILE_UPLOAD_MAX_SIZE=100mb

USER 1000
EXPOSE 3001
CMD ["node", "server/index.js"]
