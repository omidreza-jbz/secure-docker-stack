# Secure Multi-Tier Docker Stack

A production-ready multi-tier containerized stack built with Docker Compose.

## Architecture
- **Proxy Layer:** Nginx reverse proxy managing external HTTP/HTTPS traffic.
- **Application Layer:** Backend service bridging proxy and database networks.
- **Database Layer:** PostgreSQL 16 Alpine fully isolated inside an internal network.

## Features
- Network isolation using dedicated Docker bridge networks (`frontend-net` and `backend-net` with `internal: true`).
- Healthcheck orchestration ensuring backend only connects once PostgreSQL is ready.
- Persistent volume management for database integrity.
- Secrets separation using environment variables.

## Getting Started
```bash
cp .env.example .env
# Edit .env with your credentials
docker compose up -d
```
