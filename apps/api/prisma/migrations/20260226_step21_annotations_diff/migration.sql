-- Step 21 Phase 1: annotations support
ALTER TABLE "assets" ADD COLUMN IF NOT EXISTS "annotations" JSONB;
ALTER TABLE "xml_imports" ADD COLUMN IF NOT EXISTS "annotations" JSONB;
ALTER TABLE "scans" ADD COLUMN IF NOT EXISTS "annotations" JSONB;