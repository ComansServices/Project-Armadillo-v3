-- AlterTable
ALTER TABLE "xml_imports"
  ADD COLUMN "qualityMode" TEXT NOT NULL DEFAULT 'lenient',
  ADD COLUMN "qualityStatus" TEXT NOT NULL DEFAULT 'pass',
  ADD COLUMN "alertTriggered" BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN "rejectArtifact" JSONB;
