# RUNBOOK.md — Armadillo v3 Operations Runbook

> Commands, test flows, debugging procedures, and rollback steps.

---

## Quick Reference — Make Commands

```bash
make up            # Start full stack (postgres, redis, api, worker, web, minio)
make down          # Stop all containers
make logs          # Tail all container logs
make test          # Run smoke tests (health + queue verification)
make ps            # Container status
make bootstrap     # First-time setup: migrations + seed data
make clean         # Remove volumes + containers (DESTRUCTIVE)
```

---

## Development Workflow

### Starting a New Task

```bash
# 1. Pull latest
git checkout main && git pull origin main

# 2. Create branch
git checkout -b sprint-{N}/{story-id}-short-desc
# Example: git checkout -b sprint-0/INFRA-01-user-rbac

# 3. Start stack
make up

# 4. Verify healthy
make ps          # All containers "Up"
make test        # Health checks pass

# 5. Do work...

# 6. Pre-commit checks
pnpm build       # TypeScript strict mode — must pass
make test        # Smoke tests — must pass

# 7. Commit and push
git add -A
git commit -m "[STORY-ID] descriptive message"
git push origin HEAD
```

### Database Migrations

```bash
# Create a new migration
cd apps/api
npx prisma migrate dev --name descriptive-name

# Apply migrations (startup)
pnpm --filter @armadillo/api prisma:migrate:startup

# Reset database (DESTRUCTIVE — dev only)
npx prisma migrate reset

# View current migration status
npx prisma migrate status

# Generate Prisma client after schema change
npx prisma generate
```

**NEVER edit committed migration SQL files.** Create a new migration instead.

### Seeding Demo Data

```bash
# Run seed script
cd apps/api
npx prisma db seed

# Demo dataset: 480 assets, 720 vulns across multiple projects
```

---

## Testing

### Playwright E2E

```bash
# Run full suite
pnpm exec playwright test

# Run specific test file
pnpm exec playwright test e2e/phase7.spec.ts

# Run with UI
pnpm exec playwright test --ui

# Run headed (see the browser)
pnpm exec playwright test --headed

# Generate test report
pnpm exec playwright show-report
```

### Smoke Tests

```bash
# Full smoke test (health + queue + basic endpoints)
make test

# Manual health check
curl http://localhost:4000/api/v1/health

# Check queue status
curl http://localhost:4000/api/v1/queue/status

# Check API with auth headers (dev mode)
curl -H "x-armadillo-user: admin@test.com" \
     -H "x-armadillo-role: owner" \
     http://localhost:4000/api/v1/dashboard/summary
```

### Sprint Validation

After completing a sprint:

1. Run full Playwright suite: `pnpm exec playwright test`
2. Run smoke tests: `make test`
3. Run TypeScript build: `pnpm build`
4. Visual test with OpenClaw browser (primary) or Agent Browser (backup)
5. Write validation report: `docs/sprint-{N}-validation.md`

---

## Debugging

### Container Logs

```bash
# All containers
make logs

# Specific container
docker compose logs -f api
docker compose logs -f worker
docker compose logs -f web
docker compose logs -f postgres
docker compose logs -f redis
docker compose logs -f minio
```

### Common Issues

**API won't start: "Cannot connect to database"**
```bash
# Check postgres is running
docker compose ps postgres
# Check connection string
docker compose exec api env | grep DATABASE_URL
# Check postgres logs
docker compose logs postgres
```

**Worker jobs stuck in queue**
```bash
# Check Redis connection
docker compose exec redis redis-cli PING
# Check BullMQ queue length
curl http://localhost:4000/api/v1/queue/status
# Check worker logs
docker compose logs -f worker
```

**Prisma migration fails**
```bash
# Check migration status
cd apps/api && npx prisma migrate status
# If drift detected, reset (dev only!)
npx prisma migrate reset
# If production, manually resolve the drift
```

**MinIO not accessible**
```bash
# Check MinIO health
curl http://localhost:9000/minio/health/live
# Access console
open http://localhost:9001
# Default credentials from docker-compose.yml env vars
```

**OpenRouter LLM not responding**
```bash
# Verify env vars
docker compose exec api env | grep LLM_
# Test directly
curl -H "Authorization: Bearer $LLM_API_KEY" \
     -H "Content-Type: application/json" \
     -d '{"model":"anthropic/claude-sonnet-4","messages":[{"role":"user","content":"ping"}],"max_tokens":10}' \
     https://openrouter.ai/api/v1/chat/completions
```

**EPSS/KEV sync failing**
```bash
# Check worker logs for sync jobs
docker compose logs worker | grep -i epss
docker compose logs worker | grep -i kev
# Test EPSS endpoint directly
curl -s "https://api.first.org/data/v1/epss?cve=CVE-2024-0001" | jq
# Test KEV endpoint
curl -s "https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.json" | jq '.count'
```

### Database Inspection

```bash
# Connect to PostgreSQL
docker compose exec postgres psql -U armadillo -d armadillo

# Useful queries
SELECT count(*) FROM assets;
SELECT count(*) FROM asset_vulnerabilities;
SELECT count(*) FROM scans WHERE status = 'failed';
SELECT count(*) FROM epss_cache;
SELECT count(*) FROM cisa_kev_entries;

# Check RLS policies
SELECT tablename, policyname, cmd FROM pg_policies ORDER BY tablename;

# Check table sizes
SELECT relname, pg_size_pretty(pg_total_relation_size(relid)) 
FROM pg_catalog.pg_statio_user_tables ORDER BY pg_total_relation_size(relid) DESC;
```

---

## Rollback Procedures

### Revert a Bad Migration

```bash
# Option 1: Revert specific commit (if just pushed)
git revert HEAD
npx prisma migrate reset  # Dev only

# Option 2: Create a compensating migration
cd apps/api
npx prisma migrate dev --name revert-bad-change
# Manually write SQL to undo the bad migration
```

### Revert a Bad Deployment

```bash
# 1. Identify last good commit
git log --oneline -10

# 2. Reset to it
git checkout <good-commit-hash>

# 3. Rebuild and restart
pnpm build
make down && make up

# 4. Re-apply migrations if needed
cd apps/api && npx prisma migrate deploy
```

### Emergency: Database Restore

```bash
# If you have a backup:
docker compose exec -T postgres pg_restore -U armadillo -d armadillo < backup.dump

# If no backup, reset to seed data (LAST RESORT):
cd apps/api && npx prisma migrate reset
```

### Emergency: Clear BullMQ Queue

```bash
# Connect to Redis and flush job queue
docker compose exec redis redis-cli
> KEYS bull:*
> DEL bull:armadillo:wait bull:armadillo:active bull:armadillo:delayed
```

---

## Environment Variables

### Required (Startup Fails Without These)

| Variable | Example | Purpose |
|---|---|---|
| `DATABASE_URL` | `postgresql://armadillo:pass@postgres:5432/armadillo` | PostgreSQL connection |
| `REDIS_URL` | `redis://redis:6379` | Redis/BullMQ connection |

### Required for Features

| Variable | Example | Purpose |
|---|---|---|
| `LLM_API_KEY` | `sk-or-v1-xxx` | OpenRouter API key (AI features) |
| `LLM_BASE_URL` | `https://openrouter.ai/api/v1` | LLM endpoint |
| `LLM_MODEL` | `anthropic/claude-sonnet-4` | Default model |
| `S3_ENDPOINT` | `http://minio:9000` | MinIO endpoint |
| `S3_ACCESS_KEY` | `minioadmin` | MinIO access key |
| `S3_SECRET_KEY` | `minioadmin` | MinIO secret key |
| `CREDENTIAL_ENCRYPTION_KEY` | `32-byte-hex-string` | AES-256-GCM for ScanCredential |
| `SMTP_HOST` | `smtp.example.com` | Email server |
| `SMTP_USER` | `notifications@example.com` | SMTP username |
| `SMTP_PASS` | `xxx` | SMTP password |

### Auth Configuration

| Variable | Default | Purpose |
|---|---|---|
| `AUTH_ALLOW_LEGACY_HEADERS` | `false` | Enable dev header auth (dev only!) |
| `AUTH_FAIL_THRESHOLD` | `5` | Failed login attempts before lockout |
| `AUTH_LOCK_MINUTES` | `15` | Lockout duration |

---

## Health Monitoring

### Endpoints

| Endpoint | Expected | Meaning |
|---|---|---|
| `GET /api/v1/health` | `200 { status: "ok" }` | API is up |
| `GET /api/v1/queue/status` | `200 { ... }` | Queue connectivity + job counts |
| `GET http://minio:9000/minio/health/live` | `200` | MinIO is up |

### Key Metrics to Watch

- Scan queue depth (should trend toward 0)
- Failed scan count (should be <5% of total)
- EPSS/KEV sync freshness (should update daily)
- API response time (should be <500ms p95)
- Worker concurrency utilisation (4 slots)
- PostgreSQL connection pool (default 10)
- Redis memory usage

---

*Comans Services Pty Ltd • ABN 46 615 007 862 • Melbourne, Australia*
