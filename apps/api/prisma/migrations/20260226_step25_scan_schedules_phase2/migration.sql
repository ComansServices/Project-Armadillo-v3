-- Step 25 Phase 2: schedule execution tracking fields
ALTER TABLE "scan_schedules"
  ADD COLUMN IF NOT EXISTS "lastRunScanId" TEXT,
  ADD COLUMN IF NOT EXISTS "lastRunStatus" TEXT,
  ADD COLUMN IF NOT EXISTS "lastRunMessage" TEXT;