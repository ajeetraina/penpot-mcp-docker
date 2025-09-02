# 🐳 PenPot MCP Server - Dockerized

A containerized version of the [PenPot MCP Server](https://github.com/montevive/penpot-mcp) that enables AI-powered design workflow automation through Docker containers.

## 🚀 Features

- **Containerized Deployment**: Easy deployment using Docker and Docker Compose
- **Multi-Architecture Support**: Works on AMD64 and ARM64 architectures
- **Production Ready**: Optimized for production with health checks and monitoring
- **Auto-restart**: Container automatically restarts on failures
- **Volume Persistence**: Optional persistent storage for cache and data
- **Redis Integration**: Optional Redis service for improved caching
- **Security Focused**: Runs with non-root user for enhanced security

## 📋 Prerequisites

- Docker Engine 20.10+
- Docker Compose 2.0+
- Penpot account ([Sign up free](https://penpot.app/))

## 🛠️ Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/ajeetraina/penpot-mcp-docker.git
cd penpot-mcp-docker
```

### 2. Configure Environment Variables

```bash
# Copy the example environment file
cp .env.example .env

# Edit the .env file with your Penpot credentials
nano .env
```

**Required Configuration:**
```env
PENPOT_USERNAME=your_penpot_username
PENPOT_PASSWORD=your_penpot_password
PENPOT_API_URL=https://design.penpot.app/api
```

### 3. Deploy with Docker Compose

```bash
# Build and start the services
docker-compose up -d

# View logs
docker-compose logs -f penpot-mcp

# Check service status
docker-compose ps
```

### 4. Verify Installation

```bash
# Check if the service is healthy
curl http://localhost:5000/health

# Test MCP server functionality
docker-compose exec penpot-mcp penpot-client
```

## 🏗️ Alternative Deployment Methods

### Method 1: Docker Run (Simple)

```bash
# Build the image
docker build -t penpot-mcp:latest .

# Run the container
docker run -d \
  --name penpot-mcp-server \
  --restart unless-stopped \
  -p 5000:5000 \
  -e PENPOT_USERNAME=your_username \
  -e PENPOT_PASSWORD=your_password \
  -e PENPOT_API_URL=https://design.penpot.app/api \
  penpot-mcp:latest
```

### Method 2: Using Pre-built Image (Coming Soon)

```bash
# Pull and run from Docker Hub (when available)
docker run -d \
  --name penpot-mcp-server \
  --restart unless-stopped \
  -p 5000:5000 \
  --env-file .env \
  ajeetraina/penpot-mcp:latest
```

## ⚙️ Configuration

### Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `PENPOT_USERNAME` | Your Penpot username | - | ✅ |
| `PENPOT_PASSWORD` | Your Penpot password | - | ✅ |
| `PENPOT_API_URL` | Penpot API endpoint | `https://design.penpot.app/api` | ✅ |
| `PORT` | Server port | `5000` | ❌ |
| `DEBUG` | Enable debug mode | `false` | ❌ |
| `LOG_LEVEL` | Logging level | `INFO` | ❌ |
| `MAX_CACHE_SIZE` | Maximum cached files | `100` | ❌ |
| `CACHE_EXPIRATION` | Cache expiration (seconds) | `3600` | ❌ |

### Volumes

- `penpot_cache:/app/.cache` - Persistent cache storage
- `redis_data:/data` - Redis data persistence (if using Redis)

### Health Checks

The container includes built-in health checks that monitor:
- Server responsiveness on port 5000
- API connectivity to Penpot
- Service availability every 30 seconds

## 🔧 Development

### Building Locally

```bash
# Clone the original source
git clone https://github.com/montevive/penpot-mcp.git source/

# Build with custom tag
docker build -t penpot-mcp:dev .

# Run in development mode
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up
```

### Debugging

```bash
# Access container shell
docker-compose exec penpot-mcp bash

# View detailed logs
docker-compose logs -f --tail=100 penpot-mcp

# Test API connection
docker-compose exec penpot-mcp python -c "import requests; print(requests.get('http://localhost:5000/health').json())"
```

## 🔍 Monitoring and Maintenance

### Service Management

```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# Restart specific service
docker-compose restart penpot-mcp

# View resource usage
docker stats penpot-mcp-server
```

### Logs and Debugging

```bash
# Follow logs in real-time
docker-compose logs -f penpot-mcp

# Export logs to file
docker-compose logs penpot-mcp > penpot-mcp.log

# Check container health
docker inspect --format='{{.State.Health.Status}}' penpot-mcp-server
```

### Updates

```bash
# Pull latest changes
git pull origin main

# Rebuild and restart
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

## 🔌 Integration with AI Tools

### Claude Desktop Configuration

Add to your Claude Desktop config:

```json
{
  "mcpServers": {
    "penpot": {
      "command": "docker",
      "args": ["exec", "penpot-mcp-server", "penpot-mcp"],
      "env": {
        "PENPOT_API_URL": "https://design.penpot.app/api",
        "PENPOT_USERNAME": "your_username",
        "PENPOT_PASSWORD": "your_password"
      }
    }
  }
}
```

### Cursor IDE Integration

Configure Cursor with the containerized MCP server:

```json
{
  "mcpServers": {
    "penpot": {
      "command": "docker",
      "args": ["exec", "penpot-mcp-server", "penpot-mcp"]
    }
  }
}
```

## 🚨 Troubleshooting

### Common Issues

**Container won't start:**
```bash
# Check logs for errors
docker-compose logs penpot-mcp

# Verify environment variables
docker-compose exec penpot-mcp env | grep PENPOT
```

**Connection refused:**
```bash
# Check if port is available
netstat -tlnp | grep 5000

# Test internal connectivity
docker-compose exec penpot-mcp curl localhost:5000/health
```

**Authentication errors:**
```bash
# Verify credentials
docker-compose exec penpot-mcp python -m penpot_mcp.api.penpot_api --debug list-projects
```

### Performance Tuning

For production deployments:

```yaml
# Add to docker-compose.yml
services:
  penpot-mcp:
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 2G
        reservations:
          cpus: '0.5'
          memory: 512M
```

## 📚 API Documentation

Once running, the MCP server provides these endpoints:

- `GET /health` - Health check endpoint
- `GET /server://info` - Server status and information
- `GET /penpot://schema` - Penpot API schema as JSON
- `GET /penpot://tree-schema` - Penpot object tree schema

Available MCP tools:
- `list_projects` - List all Penpot projects
- `get_project_files` - Get files for a specific project
- `get_file` - Retrieve a Penpot file by ID
- `export_object` - Export a Penpot object as an image
- `get_object_tree` - Get object tree structure
- `search_object` - Search for objects within a file

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with Docker
5. Submit a pull request

](https://github.com/ajeetraina) | Docker Captain & ARM Innovator
