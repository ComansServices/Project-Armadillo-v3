-- Step 22: CVE/CPE enrichment foundation
CREATE TABLE IF NOT EXISTS "asset_vulnerabilities" (
  "id" SERIAL PRIMARY KEY,
  "assetId" TEXT NOT NULL,
  "importId" TEXT NOT NULL,
  "cve" TEXT NOT NULL,
  "cpe" TEXT,
  "severity" TEXT NOT NULL,
  "cvss" DOUBLE PRECISION,
  "title" TEXT,
  "description" TEXT,
  "source" TEXT NOT NULL DEFAULT 'builtin-enricher',
  "detectedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "asset_vulnerabilities_assetId_fkey"
    FOREIGN KEY ("assetId") REFERENCES "assets"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "asset_vulnerabilities_importId_fkey"
    FOREIGN KEY ("importId") REFERENCES "xml_imports"("id") ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE UNIQUE INDEX IF NOT EXISTS "asset_vulnerabilities_assetId_cve_key"
  ON "asset_vulnerabilities"("assetId", "cve");
CREATE INDEX IF NOT EXISTS "asset_vulnerabilities_importId_severity_idx"
  ON "asset_vulnerabilities"("importId", "severity");
CREATE INDEX IF NOT EXISTS "asset_vulnerabilities_cve_idx"
  ON "asset_vulnerabilities"("cve");