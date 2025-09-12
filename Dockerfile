FROM node:18

# Install pnpm globally
RUN npm install -g pnpm

WORKDIR /app

# Copy everything
COPY . .

# Install all workspace dependencies
RUN pnpm install

# Build the server app (NestJS)
RUN pnpm --filter server build

# ✅ Run from the apps/server directory
WORKDIR /app/apps/server

# ✅ Run as root to allow writing to volumes
USER root

# Expose the port
EXPOSE 3001

# Start the backend server
CMD ["node", "dist/main.js"]
