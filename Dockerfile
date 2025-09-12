# Use Node.js 18 as base image
FROM node:18

# Set working directory inside the container
WORKDIR /app

# Install pnpm globally
RUN npm install -g pnpm

# Copy package.json and pnpm-lock.yaml if it exists
COPY package*.json pnpm-lock.yaml* ./

# Install dependencies
RUN pnpm install

# Copy the entire app source code
COPY . .

# Build the application
RUN pnpm build

# Create storage directory with proper permissions
RUN mkdir -p /app/server/storage && chmod -R 777 /app/server/storage

# Set working directory to server
WORKDIR /app/server

# Expose the port AnythingLLM backend listens on
EXPOSE 3001

# Start the server using pnpm (recommended approach)
CMD ["pnpm", "start"]
