FROM node:18-alpine

WORKDIR /app

# Copy source code
COPY . .

# Install dependencies for all components
RUN npm install --legacy-peer-deps && \
    cd server && npm install --legacy-peer-deps && \
    cd ../collector && npm install --legacy-peer-deps && \
    cd ../frontend && npm install --legacy-peer-deps

# Build frontend
RUN cd frontend && npm run build

# Generate Prisma client (this is likely what you need for your Prisma changes)
RUN cd server && npx prisma generate

# Switch to root for permissions
USER root

# Create storage directories with proper permissions
# Using -p flag to prevent errors if they exist
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

# CRITICAL: Set ownership to UID 1000 (Railway's default user)
# Using UID directly avoids user/group creation issues
RUN chown -R 1000:1000 /app/server && \
    chown -R 1000:1000 /app/collector && \
    chown -R 1000:1000 /app/logs || true

# Set full permissions for the storage directories
RUN chmod -R 777 /app/server/storage && \
    chmod -R 777 /app/collector && \
    chmod -R 777 /app/logs || true

# Handle potential Railway volume mount paths
# Railway might mount at /storage or /data
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

CMD ["node", "server/index.js"]
