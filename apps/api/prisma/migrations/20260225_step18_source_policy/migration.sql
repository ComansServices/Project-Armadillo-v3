-- CreateTable
CREATE TABLE "import_source_policies" (
  "source" TEXT NOT NULL,
  "enabled" BOOLEAN NOT NULL DEFAULT true,
  "defaultQualityMode" TEXT NOT NULL DEFAULT 'strict',
  "allowBypassToLenient" BOOLEAN NOT NULL DEFAULT false,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "import_source_policies_pkey" PRIMARY KEY ("source")
);

-- Seed defaults
INSERT INTO "import_source_policies" ("source", "defaultQualityMode", "allowBypassToLenient") VALUES
('smoke-test', 'lenient', true),
('manual', 'strict', false)
ON CONFLICT ("source") DO NOTHING;
