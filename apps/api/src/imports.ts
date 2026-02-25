import { randomUUID } from 'node:crypto';
import { XMLParser } from 'fast-xml-parser';
import { prisma } from './prisma';

export interface XmlImportInput {
  xml: string;
  requestedBy: string;
  source?: string;
}

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

export async function createXmlImport(input: XmlImportInput) {
  const parsed = parser.parse(input.xml) as Record<string, unknown>;
  const rootNode = Object.keys(parsed)[0] ?? null;
  const itemCount = estimateItemCount(parsed);

  return prisma.xmlImport.create({
    data: {
      id: randomUUID(),
      source: input.source ?? null,
      requestedBy: input.requestedBy,
      rootNode,
      itemCount,
      payload: parsed as object
    }
  });
}

export async function listXmlImports(limit = 25) {
  return prisma.xmlImport.findMany({
    orderBy: { createdAt: 'desc' },
    take: limit
  });
}
