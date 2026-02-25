import { randomUUID } from 'node:crypto';
import Fastify, { FastifyReply, FastifyRequest } from 'fastify';
import { scanQueue } from './queue';
import { createScan, getScan, listScans, listScanEvents } from './store';
import { createXmlImport, getImportQualityDigest, getXmlImport, listImportQualityTrend, listXmlImports } from './imports';
import { backfillAssetIdentityKeys, getAsset, listAssets } from './assets';
import type { ScanRequest, ScanJobPayload } from '@armadillo/types/src/pipeline';

const app = Fastify({ logger: true });

type UserRole = 'owner' | 'admin' | 'staff' | 'viewer';
const ROLE_ORDER: Record<UserRole, number> = {
  viewer: 1,
  staff: 2,
  admin: 3,
  owner: 4
};

function getActor(req: FastifyRequest) {
  const actorId = String(req.headers['x-armadillo-user'] ?? 'anonymous');
  const rawRole = String(req.headers['x-armadillo-role'] ?? 'viewer').toLowerCase();
  const role: UserRole = ['owner', 'admin', 'staff', 'viewer'].includes(rawRole)
    ? (rawRole as UserRole)
    : 'viewer';
  return { actorId, role };
}

function requireRole(req: FastifyRequest, reply: FastifyReply, minimumRole: UserRole) {
  const actor = getActor(req);
  if (ROLE_ORDER[actor.role] < ROLE_ORDER[minimumRole]) {
    reply.code(403).send({
      error: 'insufficient_role',
      requiredRole: minimumRole,
      actorRole: actor.role
    });
    return null;
  }
  return actor;
}

app.get('/health', async () => ({ ok: true, service: 'armadillo-api' }));

app.post('/api/v1/scans', async (req, reply) => {
  const actor = requireRole(req, reply, 'staff');
  if (!actor) return;

  const body = req.body as ScanRequest;

  if (!body?.projectId || !body?.requestedBy || !Array.isArray(body?.targets) || body.targets.length === 0) {
    return reply.code(400).send({ error: 'Invalid scan request payload' });
  }

  const scanId = randomUUID();
  await createScan({
    id: scanId,
    projectId: body.projectId,
    requestedBy: body.requestedBy,
    status: 'queued',
    request: body
  });

  const firstJob: ScanJobPayload = {
    scanId,
    stage: 'naabu',
    request: body
  };

  await scanQueue.add('scan-stage', firstJob, {
    attempts: 2,
    removeOnComplete: 100,
    removeOnFail: 100
  });

  app.log.info({ actorId: actor.actorId, role: actor.role, scanId }, 'scan queued');

  return { scanId, status: 'queued' };
});

app.get('/api/v1/scans', async (req, reply) => {
  const actor = requireRole(req, reply, 'viewer');
  if (!actor) return;

  const { limit } = req.query as { limit?: string };
  const parsedLimit = Math.min(Math.max(Number(limit ?? 25), 1), 100);
  const scans = await listScans(Number.isNaN(parsedLimit) ? 25 : parsedLimit);

  app.log.info({ actorId: actor.actorId, role: actor.role, count: scans.length }, 'scan list viewed');

  return { scans };
});

app.get('/api/v1/scans/:scanId', async (req, reply) => {
  const actor = requireRole(req, reply, 'viewer');
  if (!actor) return;

  const { scanId } = req.params as { scanId: string };
  const scan = await getScan(scanId);
  if (!scan) {
    return reply.code(404).send({ error: 'Scan not found' });
  }

  app.log.info({ actorId: actor.actorId, role: actor.role, scanId }, 'scan viewed');
  return scan;
});

app.get('/api/v1/scans/:scanId/events', async (req, reply) => {
  const actor = requireRole(req, reply, 'viewer');
  if (!actor) return;

  const { scanId } = req.params as { scanId: string };
  const scan = await getScan(scanId);
  if (!scan) {
    return reply.code(404).send({ error: 'Scan not found' });
  }

  const events = await listScanEvents(scanId, 200);
  app.log.info({ actorId: actor.actorId, role: actor.role, scanId, count: events.length }, 'scan events viewed');
  return { events };
});

app.post('/api/v1/imports/xml', async (req, reply) => {
  const actor = requireRole(req, reply, 'staff');
  if (!actor) return;

  const body = req.body as { xml?: string; source?: string };
  if (!body?.xml || typeof body.xml !== 'string' || body.xml.trim().length === 0) {
    return reply.code(400).send({ error: 'xml payload is required' });
  }

  try {
    const created = await createXmlImport({
      xml: body.xml,
      source: body.source,
      requestedBy: actor.actorId
    });

    app.log.info({ actorId: actor.actorId, importId: created.id, rootNode: created.rootNode }, 'xml import created');

    return {
      importId: created.id,
      rootNode: created.rootNode,
      itemCount: created.itemCount,
      normalizedAssetCount: created.normalizedAssetCount,
      createdAssetCount: created.createdAssetCount,
      updatedAssetCount: created.updatedAssetCount,
      skippedAssetCount: created.skippedAssetCount,
      invalidAssetCount: created.invalidAssetCount,
      qualitySummary: created.qualitySummary,
      createdAt: created.createdAt
    };
  } catch (err) {
    req.log.error({ err }, 'xml parse/import failed');
    return reply.code(400).send({ error: 'invalid_xml_or_import_failed' });
  }
});

app.get('/api/v1/imports', async (req, reply) => {
  const actor = requireRole(req, reply, 'viewer');
  if (!actor) return;

  const { limit } = req.query as { limit?: string };
  const parsedLimit = Math.min(Math.max(Number(limit ?? 25), 1), 100);
  const imports = await listXmlImports(Number.isNaN(parsedLimit) ? 25 : parsedLimit);

  return {
    imports: imports.map((i) => ({
      id: i.id,
      source: i.source,
      requestedBy: i.requestedBy,
      rootNode: i.rootNode,
      itemCount: i.itemCount,
      normalizedAssetCount: i.normalizedAssetCount,
      skippedAssetCount: i.skippedAssetCount,
      invalidAssetCount: i.invalidAssetCount,
      createdAt: i.createdAt
    }))
  };
});

app.get('/api/v1/imports/quality-trend', async (req, reply) => {
  const actor = requireRole(req, reply, 'viewer');
  if (!actor) return;

  const { limit } = req.query as { limit?: string };
  const parsedLimit = Math.min(Math.max(Number(limit ?? 14), 1), 90);
  const rows = await listImportQualityTrend(Number.isNaN(parsedLimit) ? 14 : parsedLimit);
  return { trend: rows };
});

app.get('/api/v1/imports/quality-digest', async (req, reply) => {
  const actor = requireRole(req, reply, 'viewer');
  if (!actor) return;

  const digest = await getImportQualityDigest();
  return digest;
});

app.get('/api/v1/imports.csv', async (req, reply) => {
  const actor = requireRole(req, reply, 'viewer');
  if (!actor) return;

  const { limit } = req.query as { limit?: string };
  const parsedLimit = Math.min(Math.max(Number(limit ?? 200), 1), 1000);
  const imports = await listXmlImports(Number.isNaN(parsedLimit) ? 200 : parsedLimit);

  const header = [
    'id',
    'source',
    'requestedBy',
    'rootNode',
    'itemCount',
    'normalizedAssetCount',
    'skippedAssetCount',
    'invalidAssetCount',
    'createdAt'
  ];

  const esc = (v: unknown) => `"${String(v ?? '').replaceAll('"', '""')}"`;
  const lines = [header.join(',')];

  for (const i of imports) {
    lines.push(
      [
        i.id,
        i.source,
        i.requestedBy,
        i.rootNode,
        i.itemCount,
        i.normalizedAssetCount,
        i.skippedAssetCount,
        i.invalidAssetCount,
        i.createdAt.toISOString()
      ]
        .map(esc)
        .join(',')
    );
  }

  reply.header('content-type', 'text/csv; charset=utf-8');
  reply.header('content-disposition', 'attachment; filename="armadillo-imports.csv"');
  return lines.join('\n');
});

app.get('/api/v1/imports/:importId', async (req, reply) => {
  const actor = requireRole(req, reply, 'viewer');
  if (!actor) return;

  const { importId } = req.params as { importId: string };
  const data = await getXmlImport(importId);
  if (!data) {
    return reply.code(404).send({ error: 'Import not found' });
  }

  return data;
});

app.get('/api/v1/assets', async (req, reply) => {
  const actor = requireRole(req, reply, 'viewer');
  if (!actor) return;

  const { limit, ip, hostname, tag, source } = req.query as {
    limit?: string;
    ip?: string;
    hostname?: string;
    tag?: string;
    source?: string;
  };
  const parsedLimit = Math.min(Math.max(Number(limit ?? 50), 1), 200);
  const assets = await listAssets(Number.isNaN(parsedLimit) ? 50 : parsedLimit, {
    ip,
    hostname,
    tag,
    source
  });

  return {
    assets: assets.map((a) => ({
      id: a.id,
      identityKey: a.identityKey,
      importId: a.importId,
      ip: a.ip,
      hostname: a.hostname,
      os: a.os,
      ports: a.ports,
      serviceTags: a.serviceTags,
      sourceType: a.sourceType,
      seenCount: a.seenCount,
      firstSeenAt: a.firstSeenAt,
      lastSeenAt: a.lastSeenAt,
      createdAt: a.createdAt
    }))
  };
});

app.get('/api/v1/assets/:assetId', async (req, reply) => {
  const actor = requireRole(req, reply, 'viewer');
  if (!actor) return;

  const { assetId } = req.params as { assetId: string };
  const asset = await getAsset(assetId);
  if (!asset) {
    return reply.code(404).send({ error: 'Asset not found' });
  }

  return asset;
});

app.post('/api/v1/assets/backfill-identity', async (req, reply) => {
  const actor = requireRole(req, reply, 'admin');
  if (!actor) return;

  const result = await backfillAssetIdentityKeys();
  app.log.info({ actorId: actor.actorId, ...result }, 'asset identity backfill complete');
  return result;
});

app.listen({ host: '0.0.0.0', port: 4000 }).then(() => {
  console.log('API listening on http://localhost:4000');
});
