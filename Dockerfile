## Multi-stage Dockerfile for Node app (works for dev/test/prod via `NODE_ENV` and env vars)

FROM node:18-alpine AS build
WORKDIR /app

# Install dependencies (only production deps by default)
COPY package.json package-lock.json* ./
RUN npm ci --only=production || npm install --only=production

# Copy source
COPY index.js ./

# Final runtime image
FROM node:18-alpine
WORKDIR /app

# Create non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

COPY --from=build /app /app

ENV NODE_ENV=production
ENV METRICS_HOST=statsd
ENV METRICS_PORT=8125

USER appuser
CMD ["node", "index.js"]
