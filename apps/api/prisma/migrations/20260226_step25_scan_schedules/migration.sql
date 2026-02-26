-- Step 25: scan schedule model (UI parity foundation)
CREATE TABLE IF NOT EXISTS "scan_schedules" (
  "id" TEXT NOT NULL,
  "name" TEXT NOT NULL,
  "enabled" BOOLEAN NOT NULL DEFAULT true,
  "cronExpr" TEXT NOT NULL,
  "timezone" TEXT NOT NULL DEFAULT 'Australia/Melbourne',
  "projectId" TEXT NOT NULL,
  "requestedBy" TEXT NOT NULL,
  "targets" JSONB NOT NULL,
  "config" JSONB,
  "nextRunAt" TIMESTAMP(3),
  "lastRunAt" TIMESTAMP(3),
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "scan_schedules_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "scan_schedules_enabled_nextRunAt_idx"
  ON "scan_schedules"("enabled", "nextRunAt");

CREATE INDEX IF NOT EXISTS "scan_schedules_projectId_createdAt_idx"
  ON "scan_schedules"("projectId", "createdAt");
