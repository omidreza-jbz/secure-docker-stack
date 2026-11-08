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
---

## Deployment Modes

### 1. Local Development (Docker Compose)
Used for single-node local development and rapid testing:

```bash
# Start the local environment
docker compose up -d

# Verify services
docker compose ps
```

### 2. High-Availability Cluster (Docker Swarm)
Used for production staging, providing zero-downtime rolling updates, replica management, and load balancing:

```bash
# Deploy or update the stack
docker stack deploy -c docker-compose-swarm.yml secure_stack

# Verify cluster services
docker service ls

# Inspect replica distribution across nodes
docker stack ps secure_stack
```
## Automated Database Backups & Retention

The repository includes a production-grade Bash backup script (`scripts/db-backup.sh`) with strict execution controls (`set -euo pipefail`):

* **Stream Compression:** Uses containerized `pg_dump` piped directly to host-level `gzip` without uncompressed intermediate disk writes.
* **Integrity Validation:** Verifies non-zero byte dump size prior to successful return.
* **Automated Housekeeping:** Rotates and removes dump files older than 7 days using timestamp-based file pattern matching.
* **Scheduled Execution:** Configured via Crontab (see `crontab.example`).


## Operations & Monitoring Scripts

This repository includes automated maintenance and health-check tooling located in `scripts/`:

### 1. Cluster Health & Network Audit (`cluster-audit.sh`)

Automated verification script for Swarm cluster state, replica scaling, and Ingress responsiveness.

* **Node Inspection:** Evaluates all cluster nodes for `Ready` status and `Active` availability.
* **Service Replica Audit:** Dynamically compares current replicas against desired counts (e.g. `3/3`).
* **Ingress Probe:** Sends an HTTPS probe to the entry point (`curl -k`) and validates HTTP status codes (`200`, `301`, `302`).
* **Structured Logging:** Writes clean, sanitized log entries (without terminal ANSI color codes) to `/var/log/cluster-audit.log`.
* **Exit Codes:** Returns `0` if all components are healthy, or `1` if any failure or degradation is detected.

#### Usage:
```bash
chmod +x scripts/cluster-audit.sh
sudo ./scripts/cluster-audit.sh
```

###Log Format Sample:
```text
[2026-11-08 13:52:50] [OK] The Node omid is: Ready (Availability:Active)
[2026-11-08 13:52:50] [OK] Service: secure_stack_backend Running Perfectly; Replicas: 3/3
[2026-11-08 13:52:50] [OK] Nginx Ingress is Responding (HTTP 200)
```
