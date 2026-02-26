-- Add remediation tracking fields to asset_vulnerabilities
ALTER TABLE "asset_vulnerabilities"
ADD COLUMN IF NOT EXISTS "assignedTo" VARCHAR(255),
ADD COLUMN IF NOT EXISTS "dueDate" DATE,
ADD COLUMN IF NOT EXISTS "remediationStatus" VARCHAR(50) DEFAULT 'open';

-- Create index for common filter queries
CREATE INDEX IF NOT EXISTS "idx_vuln_assigned_to" ON "asset_vulnerabilities"("assignedTo");
CREATE INDEX IF NOT EXISTS "idx_vuln_remediation_status" ON "asset_vulnerabilities"("remediationStatus");
CREATE INDEX IF NOT EXISTS "idx_vuln_due_date" ON "asset_vulnerabilities"("dueDate");
