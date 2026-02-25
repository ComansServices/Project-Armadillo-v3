import { Prisma } from '@prisma/client';
import { prisma } from './prisma';

function deriveIdentityKey(ip: string | null, hostname: string | null): string | null {
  if (ip && ip.trim().length > 0) return `ip:${ip.trim()}`;
  if (hostname && hostname.trim().length > 0) return `host:${hostname.trim().toLowerCase()}`;
  return null;
}

export async function listAssets(limit = 50) {
  return prisma.asset.findMany({
    orderBy: { createdAt: 'desc' },
    take: limit
  });
}

export async function getAsset(id: string) {
  return prisma.asset.findUnique({ where: { id } });
}

export async function backfillAssetIdentityKeys() {
  const rows = await prisma.asset.findMany({
    where: { identityKey: null },
    orderBy: { createdAt: 'asc' }
  });

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
        // Duplicate identity (existing canonical row already assigned).
        const target = await prisma.asset.findUnique({ where: { identityKey } });
        if (target) {
          await prisma.$transaction([
            prisma.asset.update({
              where: { id: target.id },
              data: {
                seenCount: { increment: row.seenCount },
                firstSeenAt: row.firstSeenAt < target.firstSeenAt ? row.firstSeenAt : target.firstSeenAt,
                lastSeenAt: row.lastSeenAt > target.lastSeenAt ? row.lastSeenAt : target.lastSeenAt,
                importId: row.importId,
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

  const remainingNull = await prisma.asset.count({ where: { identityKey: null } });
  return { scanned: rows.length, updated, merged, skipped, remainingNull };
}
