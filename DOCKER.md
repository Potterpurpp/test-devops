# Docker Setup Guide

This document explains how to run the application using Docker with support for multiple environments.

## 📋 Table of Contents

- [Quick Start](#quick-start)
- [Architecture](#architecture)
- [Environments](#environments)
- [Usage](#usage)
- [Accessing Services](#accessing-services)
- [Troubleshooting](#troubleshooting)

## 🚀 Quick Start

### Development Environment

```bash
# Start all services in development mode
docker-compose -f docker-compose.yml -f docker-compose.dev.yml --env-file .env.development up

# Or use the shorthand
docker-compose --profile dev up
```

### Test Environment

```bash
# Run tests
docker-compose -f docker-compose.yml -f docker-compose.qa.yml --env-file .env.qa up --abort-on-container-exit

# Run tests and cleanup
docker-compose -f docker-compose.yml -f docker-compose.qa.yml --env-file .env.qa up --abort-on-container-exit && \
docker-compose -f docker-compose.yml -f docker-compose.qa.yml down
```

### Production Environment

```bash
# Start all services in production mode
docker-compose -f docker-compose.yml -f docker-compose.prod.yml --env-file .env.production up -d

# View logs
docker-compose logs -f
```

## 🏗 Architecture

```
┌─────────────────┐
│   Node.js App   │
│   (index.js)    │
└────────┬────────┘
         │ Sends metrics
         │ UDP 8125
         ▼
┌─────────────────┐
│     StatsD      │
│  (Aggregation)  │
└────────┬────────┘
         │ Forwards
         │ TCP 2003
         ▼
┌─────────────────┐
│    Graphite     │
│ (Storage + UI)  │
└─────────────────┘
```

### Services

1. **app**: Node.js application that sends metrics to StatsD
2. **statsd**: StatsD daemon for metrics aggregation (included in graphiteapp/graphite-statsd)
3. **graphite**: Metrics storage and visualization backend (included in graphiteapp/graphite-statsd)

## 🌍 Environments

### Development

**Features:**
- Hot reload (code changes reflect immediately)
- All ports exposed
- Debug logging enabled
- Volume mounting for live code updates

**Configuration:** `.env.development`

### Test

**Features:**
- Runs automated tests
- Minimal resource usage
- Exits after test completion
- No volume mounting

**Configuration:** `.env.qa`

### Production

**Features:**
- Optimized image size
- Non-root user for security
- Resource limits
- Auto-restart on failure
- Health checks

**Configuration:** `.env.production`

## 📖 Usage

### Build Images

```bash
# Build for specific environment
docker-compose build --build-arg BUILD_TARGET=development
docker-compose build --build-arg BUILD_TARGET=qa
docker-compose build --build-arg BUILD_TARGET=production

# Build without cache
docker-compose build --no-cache
```

### Start Services

```bash
# Development
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up

# Qa
docker-compose -f docker-compose.yml -f docker-compose.qa.yml up

# Production (detached mode)
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

### Stop Services

```bash
# Stop all services
docker-compose down

# Stop and remove volumes
docker-compose down -v

# Stop and remove images
docker-compose down --rmi all
```

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f app
docker-compose logs -f statsd

# Last 100 lines
docker-compose logs --tail=100 app
```

### Execute Commands in Container

```bash
# Open shell in app container
docker-compose exec app sh

# Run npm command
docker-compose exec app npm install <package-name>

# Check StatsD stats
docker-compose exec statsd nc localhost 8126
```

## 🌐 Accessing Services

### Graphite Web UI

Open your browser and navigate to:
```
http://localhost:8080
```

**Default Credentials:**
- Username: `root`
- Password: `root`

**Viewing Metrics:**
1. Go to http://localhost:8080
2. Click "Graphite" → "Dashboard"
3. Navigate to: `stats.timers.test.core.delay`

### StatsD Admin Interface

```bash
# Get StatsD stats via netcat
echo "stats" | nc localhost 8126

# Or using docker-compose
docker-compose exec statsd bash -c "echo stats | nc localhost 8126"
```

### Application Logs

```bash
# View application logs
docker-compose logs -f app
```

## 🔧 Environment Variables

### Application Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `NODE_ENV` | Node.js environment | `production` |
| `BUILD_TARGET` | Docker build target | `production` |
| `STATSD_HOST` | StatsD hostname | `statsd` |
| `STATSD_PORT` | StatsD port | `8125` |
| `LOG_LEVEL` | Logging level | `warn` |

### Graphite Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `GRAPHITE_WEB_PORT` | Graphite web UI port | `8080` |

## 📊 Metrics

The application sends the following metrics to StatsD:

- `test.core.delay`: Random timing metric (0-1000ms)

### Viewing Metrics in Graphite

1. Access Graphite UI: http://localhost:8080
2. Click "Graph" in the top menu
3. Browse metrics tree: `stats` → `timers` → `test` → `core` → `delay`
4. Select metrics to display:
   - `stats.timers.test.core.delay.mean`
   - `stats.timers.test.core.delay.upper`
   - `stats.timers.test.core.delay.count`

## 🐛 Troubleshooting

### App cannot connect to StatsD

**Problem:** Application shows connection errors

**Solution:**
```bash
# Check if statsd container is running
docker-compose ps

# Check network connectivity
docker-compose exec app ping statsd

# Verify StatsD is listening
docker-compose exec statsd netstat -an | grep 8125
```

### Graphite UI not accessible

**Problem:** Cannot access http://localhost:8080

**Solution:**
```bash
# Check if port is exposed
docker-compose ps statsd

# Check container logs
docker-compose logs statsd

# Restart services
docker-compose restart statsd
```

### No metrics appearing in Graphite

**Problem:** Metrics not visible in Graphite UI

**Solution:**
1. Wait 1-2 minutes for metrics to aggregate
2. Check if app is sending metrics:
   ```bash
   docker-compose logs app
   ```
3. Verify StatsD is receiving data:
   ```bash
   echo "stats" | nc localhost 8126
   ```
4. Check Graphite storage:
   ```bash
   docker-compose exec statsd ls -la /opt/graphite/storage/whisper
   ```

### Container keeps restarting

**Problem:** App container in restart loop

**Solution:**
```bash
# Check logs
docker-compose logs --tail=50 app

# Check if dependencies are installed
docker-compose exec app ls -la node_modules

# Rebuild image
docker-compose build --no-cache app
docker-compose up app
```

### Permission denied errors

**Problem:** Cannot write to mounted volumes

**Solution:**
```bash
# Check volume permissions
docker-compose exec app ls -la /app

# Fix ownership (if needed)
docker-compose exec -u root app chown -R nodejs:nodejs /app
```

## 🧹 Cleanup

### Remove all containers and volumes

```bash
# Stop and remove everything
docker-compose down -v

# Remove unused Docker resources
docker system prune -a --volumes
```

### Reset Graphite data

```bash
# Remove only Graphite data volume
docker-compose down
docker volume rm test-devops_statsd-data
docker-compose up -d
```

## 📚 Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [StatsD Documentation](https://github.com/statsd/statsd)
- [Graphite Documentation](https://graphite.readthedocs.io/)

## 🔐 Security Notes

### Development
- Uses root user for convenience
- All ports exposed
- Debug logging enabled

### Production
- Runs as non-root user (nodejs)
- Limited resource allocation
- Only necessary ports exposed
- Minimal logging

## 🚀 Performance Tips

1. **Use BuildKit** for faster builds:
   ```bash
   DOCKER_BUILDKIT=1 docker-compose build
   ```

2. **Cache dependencies** by copying package.json first

3. **Multi-stage builds** reduce final image size

4. **Resource limits** prevent container from consuming all resources

## 📝 Next Steps

1. Configure Graphite retention policies
2. Set up Grafana for better visualization
3. Add more metrics to the application
4. Implement alerting with Grafana/Prometheus
5. Set up log aggregation (ELK stack)
