FROM node:18

WORKDIR /app

# Install pnpm globally (AnythingLLM uses pnpm)
RUN npm install -g pnpm

# Copy package files to install dependencies
COPY package.json pnpm-lock.yaml ./

# Install all dependencies
RUN pnpm install

# Copy the full codebase
COPY . .

# Build the server (TypeScript -> JavaScript)
RUN pnpm --filter server build

# Change working directory to the server app
WORKDIR /app/apps/server

# Fix permissions on storage folder for Railway volumes
RUN mkdir -p storage && chmod -R 777 storage

# Expose the port
EXPOSE 3001

# Start the server
CMD ["node", "dist/main.js"]
