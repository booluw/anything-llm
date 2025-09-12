# Use Node.js 18 as base image
FROM node:18

# Set working directory inside the container
WORKDIR /app

# Install pnpm globally (AnythingLLM uses pnpm)
RUN npm install -g pnpm

# Copy package.json only (no pnpm-lock.yaml to avoid errors)
COPY package.json ./

# Install dependencies
RUN pnpm install

# Copy the entire app source code
COPY . .

# Build the server app (TypeScript -> JavaScript)
RUN pnpm --filter server build

# Set working directory to the server app
WORKDIR /app/apps/server

# Ensure storage folder exists and set permissions for Railway volumes
RUN mkdir -p storage && chmod -R 777 storage

# Expose the port AnythingLLM backend listens on
EXPOSE 3001

# Start the server
CMD ["node", "dist/main.js"]
