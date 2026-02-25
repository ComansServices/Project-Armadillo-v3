-- CreateEnum
CREATE TYPE "ScanStatus" AS ENUM ('queued', 'running', 'completed', 'failed');

-- CreateTable
CREATE TABLE "scans" (
    "id" TEXT NOT NULL,
    "projectId" TEXT NOT NULL,
    "requestedBy" TEXT NOT NULL,
    "status" "ScanStatus" NOT NULL DEFAULT 'queued',
    "request" JSONB,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "scans_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "scan_events" (
    "id" SERIAL NOT NULL,
    "scanId" TEXT NOT NULL,
    "status" "ScanStatus",
    "stage" TEXT,
    "message" TEXT,
    "metadata" JSONB,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "scan_events_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "xml_imports" (
    "id" TEXT NOT NULL,
    "source" TEXT,
    "requestedBy" TEXT NOT NULL,
    "rootNode" TEXT,
    "itemCount" INTEGER NOT NULL DEFAULT 0,
    "payload" JSONB NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "xml_imports_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "assets" (
    "id" TEXT NOT NULL,
    "identityKey" TEXT NOT NULL,
    "importId" TEXT NOT NULL,
    "ip" TEXT,
    "hostname" TEXT,
    "raw" JSONB NOT NULL,
    "seenCount" INTEGER NOT NULL DEFAULT 1,
    "firstSeenAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "lastSeenAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "assets_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "scans_projectId_idx" ON "scans"("projectId");

-- CreateIndex
CREATE INDEX "scans_status_idx" ON "scans"("status");

-- CreateIndex
CREATE INDEX "scan_events_scanId_createdAt_idx" ON "scan_events"("scanId", "createdAt");

-- CreateIndex
CREATE INDEX "xml_imports_createdAt_idx" ON "xml_imports"("createdAt");

-- CreateIndex
CREATE UNIQUE INDEX "assets_identityKey_key" ON "assets"("identityKey");

-- CreateIndex
CREATE INDEX "assets_importId_createdAt_idx" ON "assets"("importId", "createdAt");

-- CreateIndex
CREATE INDEX "assets_ip_idx" ON "assets"("ip");

-- CreateIndex
CREATE INDEX "assets_hostname_idx" ON "assets"("hostname");

-- AddForeignKey
ALTER TABLE "scan_events" ADD CONSTRAINT "scan_events_scanId_fkey" FOREIGN KEY ("scanId") REFERENCES "scans"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "assets" ADD CONSTRAINT "assets_importId_fkey" FOREIGN KEY ("importId") REFERENCES "xml_imports"("id") ON DELETE CASCADE ON UPDATE CASCADE;
