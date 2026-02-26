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

export function getAssetBadge(asset: {
  firstSeenAt: Date;
  lastSeenAt: Date;
  deltaSinceLast: Prisma.JsonValue | null;
}): { badge: 'new' | 'new_this_week' | 'changed' | null; tooltip?: string } {
  const now = new Date();
  const oneDayAgo = new Date(now.getTime() - 24 * 60 * 60 * 1000);
  const oneWeekAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);

  // Check for changes first (most specific)
  const delta = asset.deltaSinceLast as {
    addedPorts?: number[];
    removedPorts?: number[];
    addedServices?: string[];
    removedServices?: string[];
  } | null;

  if (delta && (delta.addedPorts?.length || delta.removedPorts?.length || delta.addedServices?.length || delta.removedServices?.length)) {
    const changes: string[] = [];
    if (delta.addedPorts?.length) changes.push(`+${delta.addedPorts.length} ports`);
    if (delta.removedPorts?.length) changes.push(`-${delta.removedPorts.length} ports`);
    if (delta.addedServices?.length) changes.push(`+${delta.addedServices.length} services`);
    if (delta.removedServices?.length) changes.push(`-${delta.removedServices.length} services`);
    return { badge: 'changed', tooltip: changes.join(', ') };
  }

  // Check if new (first seen today)
  if (asset.firstSeenAt >= oneDayAgo) {
    return { badge: 'new', tooltip: `First seen today` };
  }

  // Check if new this week
  if (asset.firstSeenAt >= oneWeekAgo) {
    return { badge: 'new_this_week', tooltip: `First seen this week` };
  }

  return { badge: null };
}

export async function listAssetsWithBadges(limit = 50, filters: ListAssetFilters = {}) {
  const assets = await prisma.asset.findMany({
    where: {
      ip: filters.ip ? { contains: filters.ip, mode: 'insensitive' } : undefined,
      hostname: filters.hostname ? { contains: filters.hostname, mode: 'insensitive' } : undefined,
      sourceType: filters.source ? { equals: filters.source, mode: 'insensitive' } : undefined,
      serviceTags: filters.tag ? { has: filters.tag } : undefined
    },
    orderBy: { createdAt: 'desc' },
    take: limit
  });

  return assets.map(asset => ({
    ...asset,
    badge: getAssetBadge(asset)
  }));
}

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
