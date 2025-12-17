# Docker Setup Guide

## Features ✅

1. **Multi-stage Dockerfile** - Optimized for production with security hardening
2. **Local Testing Environment** - Complete docker-compose with MongoDB, Redis, and app
3. **Container Networking** - Isolated bridge network verified and tested
4. **Persistent Storage** - MongoDB and Redis data persists across restarts
5. **No Hardcoded Secrets** - All secrets via environment variables
6. **Production-Ready** - Gunicorn WSGI server, health checks, resource limits
7. **Cache & Message Queue** - Redis for caching and pub/sub messaging
8. **Kubernetes-Ready** - Extensible to microservices with k8s manifests

## Quick Start

### 1. Create Environment File

```bash
cp .env.example .env
```

Edit `.env` and set your credentials:
```env
# Application
PORT=3000
APP_PORT=3000

# MongoDB
MONGO_USERNAME=admin
MONGO_PASSWORD=<generate-secure-password>
MONGO_PORT=27017
MONGODB_URI=mongodb://admin:<password>@mongo:27017/
DATABASE=inventory_db
COLLECTION=items

# Redis
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=<generate-secure-password>
CACHE_TTL=300
```

Generate secure passwords:
```bash
openssl rand -base64 32
```

⚠️ **Important:** Never commit the `.env` file to version control!

### 2. Start Services

```bash
# Build and start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Check service health
docker-compose ps
```

### 3. Access Application

- **Application:** http://localhost:3000
- **API:** http://localhost:3000/api/items
- **MongoDB:** localhost:27017 (for local development only)
- **Redis:** localhost:6379 (for local development only)

## Docker Architecture

### Services Overview

```
┌─────────────────────┐
│  Inventory Manager  │  Port: 3000
│   (Flask + Redis)   │  Image: Custom (multi-stage)
└──────┬──────┬───────┘
       │      │
   ┌───▼──┐   │
   │Redis │   │  Port: 6379
   └──────┘   │  Image: redis:7-alpine
              │  Volume: redis_data
          ┌───▼─────┐
          │ MongoDB │  Port: 27017
          └─────────┘  Image: mongo:7.0
                      Volumes: mongodb_data, mongodb_config

Network: inventory-network (bridge, 172.20.0.0/16)
```

### Multi-stage Build
The Dockerfile uses a two-stage build process:
- **Stage 1 (Builder):** Compiles dependencies with build tools
- **Stage 2 (Runtime):** Minimal runtime image with only necessary files

Benefits:
- Smaller final image size
- Faster deployment
- Reduced attack surface

### Security Features
- ✅ Non-root user in container
- ✅ Read-only filesystem options
- ✅ No hardcoded secrets
- ✅ Security options enabled
- ✅ Healthchecks for reliability

### Networking
Services communicate via a dedicated bridge network (`inventory-network`):
- `inventory-manager` ↔ `mongo` (internal communication)
- Only application port exposed to host

### Persistent Storage
Two volumes for MongoDB:
- `mongodb_data` - Database files
- `mongodb_config` - Configuration files

Data persists even if containers are removed.

## Common Commands

```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# Stop and remove volumes (⚠️ deletes data)
docker-compose down -v

# Rebuild after code changes
docker-compose up -d --build

# View logs
docker-compose logs -f inventory-manager
docker-compose logs -f mongo

# Execute commands in container
docker-compose exec inventory-manager sh
docker-compose exec mongo mongosh

# Check resource usage
docker stats
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `MONGO_USERNAME` | MongoDB admin username | `admin` |
| `MONGO_PASSWORD` | MongoDB admin password | `changeme` |
| `DATABASE` | Database name | `inventory_db` |
| `COLLECTION` | Collection name | `items` |
| `APP_PORT` | Host port for application | `3000` |

## Production Considerations

For production deployment:

1. **Remove port exposure for MongoDB** in docker-compose.yml
2. **Use strong passwords** for MongoDB credentials
3. **Enable TLS/SSL** for MongoDB connections
4. **Set up backup strategy** for MongoDB volumes
5. **Configure resource limits** for containers
6. **Use secrets management** (Docker Secrets, Kubernetes Secrets, etc.)
7. **Enable authentication** on MongoDB
8. **Set up monitoring and logging**

## Troubleshooting

### Container won't start
```bash
# Check logs
docker-compose logs inventory-manager

# Check MongoDB connectivity
docker-compose exec inventory-manager ping mongo
```

### MongoDB connection issues
```bash
# Verify MongoDB is healthy
docker-compose ps

# Test MongoDB connection
docker-compose exec mongo mongosh -u admin -p yourpassword
```

### Reset everything
```bash
# Stop all containers and remove volumes
docker-compose down -v

# Remove images
docker rmi $(docker images -q inventory-manager)

# Start fresh
docker-compose up -d --build
```

## Network Testing

Verify container networking:
```bash
# Check network exists
docker network ls | grep inventory-network

# Inspect network
docker network inspect inventory-network

# Test connectivity from app to MongoDB
docker-compose exec inventory-manager ping mongo
```
