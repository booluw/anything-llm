FROM node:18-alpine

# Install build dependencies including yarn
RUN apk add --no-cache python3 make g++ yarn

WORKDIR /app

# Copy all source code
COPY . .

# Install dependencies using yarn setup (as per BARE_METAL.md)
RUN yarn setup

# Generate Prisma client for your changes
RUN cd server && npx prisma generate

# Clean up
RUN yarn cache clean

USER root

# Your storage permissions
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

# Use yarn prod:server to start (standard for AnythingLLM production)
CMD ["yarn", "prod:server"]
