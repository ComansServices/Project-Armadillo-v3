import { mkdirSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { backfillAssetIdentityKeys } from '../assets';
import { prisma } from '../prisma';

async function run() {
  const backfill = await backfillAssetIdentityKeys();

  const nullRows = await prisma.$queryRaw<Array<{ count: bigint }>>`
    SELECT COUNT(*)::bigint AS count FROM assets WHERE "identityKey" IS NULL
  `;
  const nullIdentityCount = Number(nullRows[0]?.count ?? 0);
  const duplicateGroups = await prisma.$queryRaw<Array<{ identity_key: string }>>`
    SELECT "identityKey" AS identity_key
    FROM assets
    WHERE "identityKey" IS NOT NULL
    GROUP BY "identityKey"
    HAVING COUNT(*) > 1
  `;

  const report = {
    ts: new Date().toISOString(),
    backfill,
    nullIdentityCount,
    duplicateIdentityGroupCount: duplicateGroups.length,
    duplicateIdentityKeys: duplicateGroups.map((g) => g.identity_key)
  };

  const outPath = resolve(process.cwd(), 'prisma', 'reports', 'asset-identity-enforcement.json');
  mkdirSync(dirname(outPath), { recursive: true });
  writeFileSync(outPath, JSON.stringify(report, null, 2));

  // eslint-disable-next-line no-console
  console.log(`[assets:enforce-identity] report=${outPath}`);
  // eslint-disable-next-line no-console
  console.log(JSON.stringify(report));

  if (nullIdentityCount > 0) {
    throw new Error(`asset identity enforcement failed: ${nullIdentityCount} rows still missing identityKey`);
  }

  if (duplicateGroups.length > 0) {
    throw new Error(`asset identity enforcement failed: ${duplicateGroups.length} duplicate identity groups remain`);
  }
}

run()
  .catch((err) => {
    // eslint-disable-next-line no-console
    console.error('[assets:enforce-identity] failed', err);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
