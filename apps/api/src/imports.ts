import { randomUUID } from 'node:crypto';
import { XMLParser } from 'fast-xml-parser';
import { prisma } from './prisma';

export interface XmlImportInput {
  xml: string;
  requestedBy: string;
  source?: string;
}

type AssetCandidate = {
  identityKey: string;
  ip?: string;
  hostname?: string;
  os?: string;
  ports: number[];
  serviceTags: string[];
  sourceType: string;
  raw: object;
};

type NormalizationStats = {
  parsedObjects: number;
  normalizedAssetCount: number;
  skippedAssetCount: number;
  invalidAssetCount: number;
  reasonBuckets: Record<string, number>;
};

const parser = new XMLParser({
  ignoreAttributes: false,
  attributeNamePrefix: '@_',
  allowBooleanAttributes: true
});

function estimateItemCount(parsed: unknown): number {
  if (!parsed || typeof parsed !== 'object') return 0;
  const root = Object.values(parsed as Record<string, unknown>)[0];
  if (!root || typeof root !== 'object') return 0;

  let total = 0;
  for (const v of Object.values(root as Record<string, unknown>)) {
    if (Array.isArray(v)) total += v.length;
  }
  return total;
}

function collectObjects(node: unknown, out: object[] = []): object[] {
  if (!node || typeof node !== 'object') return out;

  if (Array.isArray(node)) {
    for (const entry of node) collectObjects(entry, out);
    return out;
  }

  out.push(node as object);
  for (const value of Object.values(node as Record<string, unknown>)) {
    collectObjects(value, out);
  }
  return out;
}

function toStringArray(v: unknown): string[] {
  if (Array.isArray(v)) return v.flatMap((x) => (typeof x === 'string' ? [x.trim()] : [])).filter(Boolean);
  if (typeof v === 'string' && v.trim().length > 0) return [v.trim()];
  return [];
}

function toNumberArray(v: unknown): number[] {
  if (Array.isArray(v)) {
    return v
      .map((x) => Number(x))
      .filter((x) => Number.isFinite(x) && x > 0 && x <= 65535)
      .map((x) => Math.trunc(x));
  }
  if (typeof v === 'string') {
    return v
      .split(',')
      .map((x) => Number(x.trim()))
      .filter((x) => Number.isFinite(x) && x > 0 && x <= 65535)
      .map((x) => Math.trunc(x));
  }
  if (typeof v === 'number' && Number.isFinite(v) && v > 0 && v <= 65535) return [Math.trunc(v)];
  return [];
}

function normalizeAssetCandidates(parsed: Record<string, unknown>): { assets: AssetCandidate[]; stats: NormalizationStats } {
  const objects = collectObjects(parsed);
  const dedup = new Map<string, AssetCandidate>();
  const reasonBuckets: Record<string, number> = {};

  let skipped = 0;
  let invalid = 0;

  for (const obj of objects) {
    const record = obj as Record<string, unknown>;
    const ip = typeof record.ip === 'string' ? record.ip.trim() : undefined;
    const hostname = typeof record.hostname === 'string' ? record.hostname.trim() : undefined;

    if (!ip && !hostname) {
      skipped += 1;
      reasonBuckets['missing_identity'] = (reasonBuckets['missing_identity'] ?? 0) + 1;
      continue;
    }

    const ports = toNumberArray(record.ports ?? record.port);
    const serviceTags = toStringArray(record.serviceTags ?? record.tags ?? record.service);
    const os = typeof record.os === 'string' ? record.os.trim() : undefined;

    if ((record.port !== undefined || record.ports !== undefined) && ports.length === 0) {
      invalid += 1;
      reasonBuckets['invalid_ports'] = (reasonBuckets['invalid_ports'] ?? 0) + 1;
    }

    const identityKey = ip && ip.length > 0 ? `ip:${ip}` : `host:${(hostname ?? '').toLowerCase()}`;
    if (!dedup.has(identityKey)) {
      dedup.set(identityKey, {
        identityKey,
        ip: ip && ip.length > 0 ? ip : undefined,
        hostname: hostname && hostname.length > 0 ? hostname : undefined,
        os: os && os.length > 0 ? os : undefined,
        ports: [...new Set(ports)],
        serviceTags: [...new Set(serviceTags)],
        sourceType: 'xml',
        raw: record
      });
    }
  }

  return {
    assets: [...dedup.values()],
    stats: {
      parsedObjects: objects.length,
      normalizedAssetCount: dedup.size,
      skippedAssetCount: skipped,
      invalidAssetCount: invalid,
      reasonBuckets
    }
  };
}

export async function createXmlImport(input: XmlImportInput) {
  const parsed = parser.parse(input.xml) as Record<string, unknown>;
  const rootNode = Object.keys(parsed)[0] ?? null;
  const itemCount = estimateItemCount(parsed);
  const { assets, stats } = normalizeAssetCandidates(parsed);
  const importId = randomUUID();

  const created = await prisma.$transaction(async (tx) => {
    const saved = await tx.xmlImport.create({
      data: {
        id: importId,
        source: input.source ?? null,
        requestedBy: input.requestedBy,
        rootNode,
        itemCount,
        normalizedAssetCount: stats.normalizedAssetCount,
        skippedAssetCount: stats.skippedAssetCount,
        invalidAssetCount: stats.invalidAssetCount,
        qualitySummary: stats,
        payload: parsed as object
      }
    });

    let createdAssets = 0;
    let updatedAssets = 0;

    for (const a of assets) {
      const exists = await tx.asset.findUnique({ where: { identityKey: a.identityKey } });

      await tx.asset.upsert({
        where: { identityKey: a.identityKey },
        create: {
          id: randomUUID(),
          identityKey: a.identityKey,
          importId,
          ip: a.ip ?? null,
          hostname: a.hostname ?? null,
          os: a.os ?? null,
          ports: a.ports,
          serviceTags: a.serviceTags,
          sourceType: a.sourceType,
          raw: a.raw,
          seenCount: 1
        },
        update: {
          importId,
          ip: a.ip ?? exists?.ip ?? null,
          hostname: a.hostname ?? exists?.hostname ?? null,
          os: a.os ?? exists?.os ?? null,
          ports: a.ports.length > 0 ? a.ports : exists?.ports ?? [],
          serviceTags: a.serviceTags.length > 0 ? a.serviceTags : exists?.serviceTags ?? [],
          sourceType: a.sourceType,
          raw: a.raw,
          seenCount: { increment: 1 },
          lastSeenAt: new Date()
        }
      });

      if (exists) updatedAssets += 1;
      else createdAssets += 1;
    }

    return {
      ...saved,
      normalizedAssetCount: assets.length,
      createdAssetCount: createdAssets,
      updatedAssetCount: updatedAssets,
      skippedAssetCount: stats.skippedAssetCount,
      invalidAssetCount: stats.invalidAssetCount,
      qualitySummary: stats
    };
  });

  return created;
}

export async function listXmlImports(limit = 25) {
  return prisma.xmlImport.findMany({
    orderBy: { createdAt: 'desc' },
    take: limit
  });
}

export async function getXmlImport(id: string) {
  return prisma.xmlImport.findUnique({ where: { id } });
}

export async function listImportQualityTrend(limit = 14) {
  return prisma.xmlImport.findMany({
    orderBy: { createdAt: 'desc' },
    take: limit,
    select: {
      id: true,
      createdAt: true,
      normalizedAssetCount: true,
      skippedAssetCount: true,
      invalidAssetCount: true
    }
  });
}
