FROM node:18

WORKDIR /app

# Install pnpm globally (AnythingLLM uses pnpm)
RUN npm install -g pnpm

# Copy package.json only (no pnpm-lock.yaml to avoid errors)
COPY package.json ./

# Install dependencies
RUN pnpm install

# Copy source code
COPY . .

# Build the server app (TypeScript -> JavaScript)
RUN pnpm --filter server build

# Generate Prisma client
RUN cd server && npx prisma generate

# Set working directory to the server app
WORKDIR /app/apps/server

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
    FILE_UPLOAD_MAX_SIZE=1000mb

USER 1000
EXPOSE 3001
CMD ["node", "index.js"]
