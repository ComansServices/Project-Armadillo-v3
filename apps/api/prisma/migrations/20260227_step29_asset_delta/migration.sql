-- Add delta tracking for asset change detection
ALTER TABLE "assets"
ADD COLUMN IF NOT EXISTS "deltaSinceLast" JSONB;

-- Add index for filtering new assets
CREATE INDEX IF NOT EXISTS "idx_assets_first_seen" ON "assets"("firstSeenAt");
