# Multi-stage Dockerfile with support for development, test, and production environments

# ============================================
# Base Stage - Common dependencies
# ============================================
FROM node:22-alpine AS base

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# ============================================
# Development Stage
# ============================================
FROM base AS development

# Set NODE_ENV
ENV NODE_ENV=development

# Install all dependencies (including devDependencies)
RUN npm install

# Copy application code
COPY . .

# Expose port (if needed in future)
EXPOSE 3000

# Command to run in development mode with auto-reload
CMD ["npm", "run", "dev"]

# ============================================
# QA Stage
# ============================================
FROM base AS qa

# Set NODE_ENV
ENV NODE_ENV=test

# Install all dependencies (for running tests)
RUN npm install

# Copy application code
COPY . .

# Run tests
CMD ["npm", "test"]

# ============================================
# Builder Stage - Install production dependencies only
# ============================================
FROM base AS builder

# Set NODE_ENV to production
ENV NODE_ENV=production

# Install only production dependencies
RUN npm ci --only=production

# Copy application code
COPY . .

# ============================================
# Production Stage - Minimal image
# ============================================
FROM node:22-alpine AS production

# Set NODE_ENV
ENV NODE_ENV=production

# Create non-root user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Set working directory
WORKDIR /app

# Copy production dependencies from builder
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules

# Copy application code
COPY --chown=nodejs:nodejs package*.json ./
COPY --chown=nodejs:nodejs index.js ./

# Switch to non-root user
USER nodejs

# Health check (optional)
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD node -e "console.log('healthy')" || exit 1

# Expose port (if needed)
EXPOSE 3000

# Start the application
CMD ["node", "index.js"]
