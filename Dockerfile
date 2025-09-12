# Use Node base image
FROM node:18

# Set working directory
WORKDIR /app

# Copy package files and install dependencies
COPY package*.json ./
RUN npm install

# Copy the rest of the app
COPY . .

# Set environment variables
ENV NODE_ENV=production
ENV PORT=3001

# ✅ Run as root to avoid EACCES issues with volumes
USER root

# Create models directory as a precaution (optional)
RUN mkdir -p /app/data/models/context-windows

# Expose port
EXPOSE 3001

# Start the app
CMD ["npm", "run", "start"]
