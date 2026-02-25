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
  raw: object;
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

function normalizeAssetCandidates(parsed: Record<string, unknown>): AssetCandidate[] {
  const objects = collectObjects(parsed);
  const dedup = new Map<string, AssetCandidate>();

  for (const obj of objects) {
    const record = obj as Record<string, unknown>;
    const ip = typeof record.ip === 'string' ? record.ip.trim() : undefined;
    const hostname = typeof record.hostname === 'string' ? record.hostname.trim() : undefined;

    if (!ip && !hostname) continue;

    const identityKey = ip && ip.length > 0 ? `ip:${ip}` : `host:${(hostname ?? '').toLowerCase()}`;
    if (!dedup.has(identityKey)) {
      dedup.set(identityKey, {
        identityKey,
        ip: ip && ip.length > 0 ? ip : undefined,
        hostname: hostname && hostname.length > 0 ? hostname : undefined,
        raw: record
      });
    }
  }

  return [...dedup.values()];
}

export async function createXmlImport(input: XmlImportInput) {
  const parsed = parser.parse(input.xml) as Record<string, unknown>;
  const rootNode = Object.keys(parsed)[0] ?? null;
  const itemCount = estimateItemCount(parsed);
  const assets = normalizeAssetCandidates(parsed);
  const importId = randomUUID();

  const created = await prisma.$transaction(async (tx) => {
    const saved = await tx.xmlImport.create({
      data: {
        id: importId,
        source: input.source ?? null,
        requestedBy: input.requestedBy,
        rootNode,
        itemCount,
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
          raw: a.raw,
          seenCount: 1
        },
        update: {
          importId,
          ip: a.ip ?? exists?.ip ?? null,
          hostname: a.hostname ?? exists?.hostname ?? null,
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
      updatedAssetCount: updatedAssets
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
