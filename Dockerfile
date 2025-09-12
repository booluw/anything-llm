# Use the official AnythingLLM image as base
FROM mintplexlabs/anythingllm:latest

# Railway runs as non-root user with UID 1000
# We need to create a user with proper permissions
USER root

# Create the storage directory structure that AnythingLLM expects
# These are the typical directories AnythingLLM needs write access to
RUN mkdir -p /app/server/storage \
    /app/server/storage/documents \
    /app/server/storage/vector-cache \
    /app/server/storage/lancedb \
    /app/server/storage/outputs \
    /app/server/storage/uploads \
    /app/server/storage/workspaces \
    /app/server/storage/chats \
    /app/collector/hotdir \
    /app/collector/outputs

# Create a non-root user that matches Railway's expected UID (1000)
# This is crucial for Railway compatibility
RUN groupadd -g 1000 anythingllm && \
    useradd -r -u 1000 -g anythingllm anythingllm

# Set ownership of all necessary directories to the new user
RUN chown -R anythingllm:anythingllm /app/server/storage && \
    chown -R anythingllm:anythingllm /app/collector && \
    chown -R anythingllm:anythingllm /app

# Give full permissions to storage directories
# 755 for directories, ensuring read/write/execute for owner
RUN chmod -R 755 /app/server/storage && \
    chmod -R 755 /app/collector

# Set environment variables for AnythingLLM
# Adjust the storage path to use Railway's volume mount point
ENV STORAGE_DIR=/app/server/storage \
    PERSIST_DATA=true \
    NODE_ENV=production

# If Railway mounts volume at a different path (like /storage), 
# create symbolic links
RUN ln -sf /storage /app/server/storage || true

# Switch to the non-root user
USER anythingllm

# Set working directory
WORKDIR /app

# The entrypoint should already be set in the base image
# But if needed, you can override it:
# ENTRYPOINT ["node", "/app/server/index.js"]

# Expose the default AnythingLLM port
EXPOSE 3001
