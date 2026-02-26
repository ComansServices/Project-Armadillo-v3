-- Step 24 / Phase 4: performance hardening indexes
CREATE INDEX IF NOT EXISTS "scans_createdAt_idx"
  ON "scans"("createdAt");

CREATE INDEX IF NOT EXISTS "scans_updatedAt_idx"
  ON "scans"("updatedAt");

CREATE INDEX IF NOT EXISTS "xml_imports_source_createdAt_idx"
  ON "xml_imports"("source", "createdAt");

CREATE INDEX IF NOT EXISTS "asset_vulnerabilities_importId_detectedAt_idx"
  ON "asset_vulnerabilities"("importId", "detectedAt");

CREATE INDEX IF NOT EXISTS "asset_vulnerabilities_severity_detectedAt_idx"
  ON "asset_vulnerabilities"("severity", "detectedAt");

CREATE INDEX IF NOT EXISTS "asset_vulnerabilities_detectedAt_idx"
  ON "asset_vulnerabilities"("detectedAt");
