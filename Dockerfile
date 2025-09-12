# Use Node.js as base image (AnythingLLM is a Node.js app)
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Copy your source code
COPY . .

# Install dependencies and build the application
RUN npm install --legacy-peer-deps
RUN npm run build

# Switch to root to create directories and set permissions
USER root

# Create storage directories with proper permissions
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

# Set ownership to UID 1000 (Railway's default user)
RUN chown -R 1000:1000 /app/server && \
    chown -R 1000:1000 /app/collector && \
    chown -R 1000:1000 /app/logs || true

# Set full permissions for the storage directories
RUN chmod -R 777 /app/server/storage && \
    chmod -R 777 /app/collector && \
    chmod -R 777 /app/logs || true

# Handle potential Railway volume mount paths
RUN mkdir -p /storage /data && \
    chown -R 1000:1000 /storage /data && \
    chmod -R 777 /storage /data || true

# Create symbolic links for various mount possibilities
RUN ln -sf /storage /app/server/storage 2>/dev/null || true && \
    ln -sf /data /app/server/storage 2>/dev/null || true

# Set environment variables
ENV STORAGE_DIR=/app/server/storage \
    PERSIST_DATA=true \
    NODE_ENV=production \
    SERVER_PORT=3001 \
    FILE_UPLOAD_MAX_SIZE=100mb

# Switch to UID 1000 (Railway's expected user)
USER 1000

EXPOSE 3001

# Start the application
CMD ["node", "/app/server/index.js"]
