import { Prisma } from '@prisma/client';
import { prisma } from './prisma';

function deriveIdentityKey(ip: string | null, hostname: string | null): string | null {
  if (ip && ip.trim().length > 0) return `ip:${ip.trim()}`;
  if (hostname && hostname.trim().length > 0) return `host:${hostname.trim().toLowerCase()}`;
  return null;
}

export type ListAssetFilters = {
  ip?: string;
  hostname?: string;
  tag?: string;
  source?: string;
};

export async function listAssets(limit = 50, filters: ListAssetFilters = {}) {
  return prisma.asset.findMany({
    where: {
      ip: filters.ip ? { contains: filters.ip, mode: 'insensitive' } : undefined,
      hostname: filters.hostname ? { contains: filters.hostname, mode: 'insensitive' } : undefined,
      sourceType: filters.source ? { equals: filters.source, mode: 'insensitive' } : undefined,
      serviceTags: filters.tag ? { has: filters.tag } : undefined
    },
    orderBy: { createdAt: 'desc' },
    take: limit
  });
}

export async function getAsset(id: string) {
  return prisma.asset.findUnique({ where: { id } });
}

type LegacyAssetRow = {
  id: string;
  import_id: string;
  ip: string | null;
  hostname: string | null;
  raw: Prisma.JsonValue;
  seen_count: number;
  first_seen_at: Date;
  last_seen_at: Date;
};

export async function backfillAssetIdentityKeys() {
  const rows = await prisma.$queryRaw<LegacyAssetRow[]>`
    SELECT
      id,
      "importId" AS import_id,
      ip,
      hostname,
      raw,
      "seenCount" AS seen_count,
      "firstSeenAt" AS first_seen_at,
      "lastSeenAt" AS last_seen_at
    FROM assets
    WHERE "identityKey" IS NULL
    ORDER BY "createdAt" ASC
  `;

  let updated = 0;
  let merged = 0;
  let skipped = 0;

  for (const row of rows) {
    const identityKey = deriveIdentityKey(row.ip, row.hostname);
    if (!identityKey) {
      skipped += 1;
      continue;
    }

    try {
      await prisma.asset.update({
        where: { id: row.id },
        data: { identityKey }
      });
      updated += 1;
    } catch (err) {
      if (err instanceof Prisma.PrismaClientKnownRequestError && err.code === 'P2002') {
        const target = await prisma.asset.findUnique({ where: { identityKey } });
        if (target) {
          await prisma.$transaction([
            prisma.asset.update({
              where: { id: target.id },
              data: {
                seenCount: { increment: row.seen_count },
                firstSeenAt: row.first_seen_at < target.firstSeenAt ? row.first_seen_at : target.firstSeenAt,
                lastSeenAt: row.last_seen_at > target.lastSeenAt ? row.last_seen_at : target.lastSeenAt,
                importId: row.import_id,
                raw: row.raw,
                ip: target.ip ?? row.ip,
                hostname: target.hostname ?? row.hostname
              }
            }),
            prisma.asset.delete({ where: { id: row.id } })
          ]);
          merged += 1;
          continue;
        }
      }
      throw err;
    }
  }

  const remainingNullRows = await prisma.$queryRaw<Array<{ count: bigint }>>`
    SELECT COUNT(*)::bigint AS count FROM assets WHERE "identityKey" IS NULL
  `;

  const remainingNull = Number(remainingNullRows[0]?.count ?? 0);
  return { scanned: rows.length, updated, merged, skipped, remainingNull };
}
