import { createHmac, randomUUID, timingSafeEqual } from 'node:crypto';
import { mkdir, readdir, readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import Fastify, { FastifyReply, FastifyRequest } from 'fastify';
import { CronExpressionParser } from 'cron-parser';
import { scanQueue } from './queue';
import { createScan, getScan, listScans, listScanEvents } from './store';
import { createXmlImport, getImportQualityDigest, getXmlImport, listImportQualityTrend, listXmlImports } from './imports';
import { backfillAssetIdentityKeys, getAsset, listAssets } from './assets';
import { getSourcePolicy, listSourcePolicies, upsertSourcePolicy } from './policies';
import { prisma } from './prisma';
import { enrichImportVulnerabilities, listVulnerabilities } from './vulnerabilities';
import { buildBrandedReportPdf } from './report-pdf';
import type { ScanRequest, ScanJobPayload } from '@armadillo/types/src/pipeline';

const app = Fastify({ logger: true });

type UserRole = 'owner' | 'admin' | 'staff' | 'viewer';
const ROLE_ORDER: Record<UserRole, number> = {
  viewer: 1,
  staff: 2,
  admin: 3,
  owner: 4
};

type AuthActor = {
  actorId: string;
  role: UserRole;
  orgId: string;
  projects: string[];
  sessionId?: string;
  authType: 'session' | 'legacy';
};

type SessionClaims = {
  sub: string;
  role: UserRole;
  orgId?: string;
  projects?: string[];
  exp: number;
  iat?: number;
  sid?: string;
};

const authSecret = process.env.AUTH_SESSION_SECRET ?? '';
const allowLegacyHeaders = (process.env.AUTH_ALLOW_LEGACY_HEADERS ?? 'true').toLowerCase() === 'true';
const authFailThreshold = Math.min(Math.max(Number(process.env.AUTH_FAIL_THRESHOLD ?? 5), 1), 20);
const authLockMinutes = Math.min(Math.max(Number(process.env.AUTH_LOCK_MINUTES ?? 15), 1), 180);
const authFailures = new Map<string, { count: number; lockedUntil?: number }>();

function auditAuth(event: string, meta: Record<string, unknown>) {
  app.log.warn({ event, ...meta }, 'auth_audit');
}

function failAuth(key: string) {
  const now = Date.now();
  const curr = authFailures.get(key) ?? { count: 0 };
  curr.count += 1;
  if (curr.count >= authFailThreshold) {
    curr.lockedUntil = now + authLockMinutes * 60 * 1000;
  }
  authFailures.set(key, curr);
  return curr;
}

function clearAuthFail(key: string) {
  authFailures.delete(key);
}

function isLocked(key: string) {
  const row = authFailures.get(key);
  if (!row?.lockedUntil) return false;
  if (Date.now() > row.lockedUntil) {
    authFailures.delete(key);
    return false;
  }
  return true;
}

function parseSessionToken(token: string): SessionClaims | null {
  try {
    const [ver, payloadB64, sigHex] = token.trim().split('.');
    if (ver !== 'v1' || !payloadB64 || !sigHex || !authSecret) return null;

    const mac = createHmac('sha256', authSecret).update(`${ver}.${payloadB64}`).digest('hex');
    const a = Buffer.from(sigHex, 'hex');
    const b = Buffer.from(mac, 'hex');
    if (a.length !== b.length || !timingSafeEqual(a, b)) return null;

    const claims = JSON.parse(Buffer.from(payloadB64, 'base64url').toString('utf8')) as SessionClaims;
    if (!claims?.sub || !claims?.role || !claims?.exp) return null;
    if (!['owner', 'admin', 'staff', 'viewer'].includes(claims.role)) return null;
    if (Date.now() > claims.exp * 1000) return null;
    return claims;
  } catch {
    return null;
  }
}

function getActor(req: FastifyRequest) {
  const cached = (req as FastifyRequest & { authActor?: AuthActor }).authActor;
  if (cached) return cached;

  const actorId = String(req.headers['x-armadillo-user'] ?? 'anonymous');
  const rawRole = String(req.headers['x-armadillo-role'] ?? 'viewer').toLowerCase();
  const role: UserRole = ['owner', 'admin', 'staff', 'viewer'].includes(rawRole)
    ? (rawRole as UserRole)
    : 'viewer';
  return { actorId, role, orgId: 'legacy', projects: ['*'], authType: 'legacy' as const };
}

function ensureProjectScope(actor: AuthActor, projectId: string) {
  if (!projectId) return true;
  if (actor.projects.includes('*')) return true;
  return actor.projects.includes(projectId);
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

app.addHook('preHandler', async (req, reply) => {
  if (!req.url.startsWith('/api/v1/')) return;

  const ip = String(req.headers['x-forwarded-for'] ?? req.ip ?? 'unknown').split(',')[0].trim();
  const authHeader = String(req.headers['x-armadillo-auth'] ?? req.headers.authorization ?? '').trim();
  const token = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : authHeader;
  const lockKey = `${ip}:${token.slice(0, 24) || String(req.headers['x-armadillo-user'] ?? 'anon')}`;

  if (isLocked(lockKey)) {
    auditAuth('auth_locked', { ip, path: req.url });
    return reply.code(423).send({ error: 'auth_locked', message: 'Too many authentication failures' });
  }

  if (token) {
    const claims = parseSessionToken(token);
    if (!claims) {
      const fail = failAuth(lockKey);
      auditAuth('auth_failure', { ip, path: req.url, reason: 'invalid_or_expired_session', count: fail.count });
      return reply.code(401).send({ error: 'invalid_session' });
    }

    const actor: AuthActor = {
      actorId: claims.sub,
      role: claims.role,
      orgId: claims.orgId ?? 'default',
      projects: Array.isArray(claims.projects) && claims.projects.length ? claims.projects : ['*'],
      sessionId: claims.sid,
      authType: 'session'
    };
    (req as FastifyRequest & { authActor?: AuthActor }).authActor = actor;
    clearAuthFail(lockKey);
    return;
  }

  if (!allowLegacyHeaders) {
    const fail = failAuth(lockKey);
    auditAuth('auth_failure', { ip, path: req.url, reason: 'missing_session', count: fail.count });
    return reply.code(401).send({ error: 'missing_session' });
  }

  const actor = getActor(req);
  (req as FastifyRequest & { authActor?: AuthActor }).authActor = actor;
  auditAuth('auth_legacy_used', { ip, path: req.url, actorId: actor.actorId, role: actor.role });
});
type AnnotationPayload = { labels?: string[]; notes?: string };

function sanitizeAnnotations(input: AnnotationPayload) {
  const labels = Array.isArray(input.labels)
    ? [...new Set(input.labels.map((v) => String(v).trim()).filter(Boolean))].slice(0, 20)
    : [];
  const notes = typeof input.notes === 'string' ? input.notes.trim().slice(0, 4000) : '';
  return { labels, notes };
}

function mergeCounts(base: Record<string, number>, next: Record<string, number>) {
  const out: Record<string, number> = { ...base };
  for (const [k, v] of Object.entries(next)) out[k] = (out[k] ?? 0) + v;
  return out;
}

const reportArchiveDir = path.resolve(process.cwd(), 'apps/api/reports/archive');

async function archiveReport(params: {
  kind: 'import' | 'scan';
  refId: string;
  audience: 'ops' | 'exec';
  pdf: Buffer;
  requestedBy: string;
}) {
  await mkdir(reportArchiveDir, { recursive: true });
  const ts = new Date().toISOString().replace(/[:.]/g, '-');
  const base = `${params.kind}-${params.refId}-${params.audience}-${ts}`;
  const pdfName = `${base}.pdf`;
  const metaName = `${base}.json`;

  await writeFile(path.join(reportArchiveDir, pdfName), params.pdf);
  await writeFile(
    path.join(reportArchiveDir, metaName),
    JSON.stringify(
      {
        kind: params.kind,
        refId: params.refId,
        audience: params.audience,
        requestedBy: params.requestedBy,
        createdAt: new Date().toISOString(),
        file: pdfName
      },
      null,
      2
    )
  );

  return { pdfName, metaName };
}

function nextRunFromCron(cronExpr: string, timezone: string) {
  try {
    const interval = CronExpressionParser.parse(cronExpr, { tz: timezone });
    return interval.next().toDate();
  } catch {
    return null;
  }
}

let scheduleRunnerBusy = false;
async function runDueSchedules() {
  if (scheduleRunnerBusy) return { ran: 0 };
  scheduleRunnerBusy = true;
  try {
    const now = new Date();
    const due = await prisma.scanSchedule.findMany({ where: { enabled: true, nextRunAt: { lte: now } }, take: 20 });
    let ran = 0;

    for (const s of due) {
      const scanId = randomUUID();
      const request = {
        projectId: s.projectId,
        requestedBy: s.requestedBy,
        targets: (s.targets as Array<{ type: string; value: string }>) ?? [],
        config: (s.config as Record<string, unknown>) ?? { profile: 'safe-default' }
      };

      try {
        await createScan({ id: scanId, projectId: s.projectId, requestedBy: s.requestedBy, status: 'queued', request });
        await scanQueue.add('scan-stage', { scanId, stage: 'naabu', request } as ScanJobPayload, {
          attempts: 2,
          removeOnComplete: 100,
          removeOnFail: 100
        });

        await prisma.scanSchedule.update({
          where: { id: s.id },
          data: {
            lastRunAt: now,
            lastRunScanId: scanId,
            lastRunStatus: 'queued',
            lastRunMessage: 'Scheduled run queued',
            nextRunAt: nextRunFromCron(s.cronExpr, s.timezone)
          }
        });
        ran += 1;
      } catch (err) {
        const e = err as Error;
        await prisma.scanSchedule.update({
          where: { id: s.id },
          data: {
            lastRunAt: now,
            lastRunStatus: 'failed',
            lastRunMessage: e.message.slice(0, 240),
            nextRunAt: nextRunFromCron(s.cronExpr, s.timezone)
          }
        });
      }
    }

    return { ran };
  } finally {
    scheduleRunnerBusy = false;
  }
}

app.get('/health', async () => ({ ok: true, service: 'armadillo-api' }));

app.post('/api/v1/scans', async (req, reply) => {
  const actor = requireRole(req, reply, 'staff');
  if (!actor) return;

  const body = req.body as ScanRequest;

  if (!body?.projectId || !body?.requestedBy || !Array.isArray(body?.targets) || body.targets.length === 0) {
    return reply.code(400).send({ error: 'Invalid scan request payload' });
  }

  if (!ensureProjectScope(actor, body.projectId)) {
    return reply.code(403).send({ error: 'project_scope_denied', projectId: body.projectId });
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
  const scoped = actor.projects.includes('*') ? scans : scans.filter((s) => ensureProjectScope(actor, s.projectId));

  app.log.info({ actorId: actor.actorId, role: actor.role, count: scoped.length }, 'scan list viewed');

  return { scans: scoped };
});

app.get('/api/v1/scans/:scanId', async (req, reply) => {
  const actor = requireRole(req, reply, 'viewer');
  if (!actor) return;

  const { scanId } = req.params as { scanId: string };
  const scan = await getScan(scanId);
  if (!scan) {
    return reply.code(404).send({ error: 'Scan not found' });
  }
  if (!ensureProjectScope(actor, scan.projectId)) {
    return reply.code(403).send({ error: 'project_scope_denied', projectId: scan.projectId });
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
  if (!ensureProjectScope(actor, scan.projectId)) {
    return reply.code(403).send({ error: 'project_scope_denied', projectId: scan.projectId });
  }

  const events = await listScanEvents(scanId, 200);
  app.log.info({ actorId: actor.actorId, role: actor.role, scanId, count: events.length }, 'scan events viewed');
  return { events };
});

app.get('/api/v1/scan-schedules', async (req, reply) => {
  const actor = requireRole(req, reply, 'viewer');
  if (!actor) return;

  const rows = await prisma.scanSchedule.findMany({ orderBy: { createdAt: 'desc' }, take: 200 });
  const schedules = actor.projects.includes('*') ? rows : rows.filter((r) => ensureProjectScope(actor, r.projectId));
  return { schedules };
});

app.post('/api/v1/scan-schedules', async (req, reply) => {
  const actor = requireRole(req, reply, 'staff');
  if (!actor) return;

  const body = req.body as {
    name?: string;
    cronExpr?: string;
    timezone?: string;
    projectId?: string;
    requestedBy?: string;
    targets?: Array<{ type: string; value: string }>;
    config?: Record<string, unknown>;
  };

  if (!body?.name || !body?.cronExpr || !body?.projectId || !body?.requestedBy || !Array.isArray(body?.targets) || body.targets.length === 0) {
    return reply.code(400).send({ error: 'invalid_schedule_payload' });
  }

  if (!ensureProjectScope(actor, body.projectId.trim())) {
    return reply.code(403).send({ error: 'project_scope_denied', projectId: body.projectId.trim() });
  }

  const timezone = (body.timezone || 'Australia/Melbourne').trim();
  const cronExpr = body.cronExpr.trim();
  const created = await prisma.scanSchedule.create({
    data: {
      id: randomUUID(),
      name: body.name.trim(),
      enabled: true,
      cronExpr,
      timezone,
      projectId: body.projectId.trim(),
      requestedBy: body.requestedBy.trim(),
      targets: body.targets,
      config: body.config ?? {},
      nextRunAt: nextRunFromCron(cronExpr, timezone),
      lastRunAt: null
    }
  });

  return created;
});

app.post('/api/v1/scan-schedules/:scheduleId/toggle', async (req, reply) => {
  const actor = requireRole(req, reply, 'staff');
  if (!actor) return;
  const { scheduleId } = req.params as { scheduleId: string };

  const row = await prisma.scanSchedule.findUnique({ where: { id: scheduleId } });
  if (!row) return reply.code(404).send({ error: 'Schedule not found' });
  if (!ensureProjectScope(actor, row.projectId)) {
    return reply.code(403).send({ error: 'project_scope_denied', projectId: row.projectId });
  }

  const nextEnabled = !row.enabled;
  const updated = await prisma.scanSchedule.update({
    where: { id: scheduleId },
    data: {
      enabled: nextEnabled,
      nextRunAt: nextEnabled ? nextRunFromCron(row.cronExpr, row.timezone) : null
    }
  });
  return updated;
});

app.post('/api/v1/scan-schedules/run-due', async (req, reply) => {
  const actor = requireRole(req, reply, 'admin');
  if (!actor) return;
  const result = await runDueSchedules();
  return result;
});

app.post('/api/v1/imports/xml', async (req, reply) => {
  const actor = requireRole(req, reply, 'staff');
  if (!actor) return;

  const body = req.body as { xml?: string; source?: string; qualityMode?: 'lenient' | 'strict' };
  if (!body?.xml || typeof body.xml !== 'string' || body.xml.trim().length === 0) {
    return reply.code(400).send({ error: 'xml payload is required' });
  }
  if (!body?.source || typeof body.source !== 'string' || body.source.trim().length === 0) {
    return reply.code(400).send({ error: 'source is required' });
  }

  const source = body.source.trim();
  const policy = await getSourcePolicy(source);
  if (!policy || !policy.enabled) {
    return reply.code(403).send({ error: 'source_not_allowed', source });
  }

  const requestedMode = body.qualityMode;
  const effectiveMode = requestedMode ?? (policy.defaultQualityMode as 'lenient' | 'strict');

  if (
    requestedMode === 'lenient' &&
    policy.defaultQualityMode === 'strict' &&
    !policy.allowBypassToLenient &&
    actor.role !== 'admin' &&
    actor.role !== 'owner'
  ) {
    return reply.code(403).send({
      error: 'lenient_bypass_not_allowed',
      source,
      policyDefault: policy.defaultQualityMode
    });
  }

  try {
    const created = await createXmlImport({
      xml: body.xml,
      source,
      requestedBy: actor.actorId,
      qualityMode: effectiveMode
    });

    app.log.info({ actorId: actor.actorId, importId: created.id, rootNode: created.rootNode }, 'xml import created');

    return {
      importId: created.id,
      qualityMode: created.qualityMode,
      qualityStatus: created.qualityStatus,
      alertTriggered: created.alertTriggered,
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
    const e = err as Error & { code?: string; details?: object };
    if (e.code === 'STRICT_QUALITY_GATE_FAILED') {
      return reply.code(422).send({ error: 'strict_quality_gate_failed', details: e.details });
    }
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
      qualityMode: i.qualityMode,
      qualityStatus: i.qualityStatus,
      alertTriggered: i.alertTriggered,
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
    'qualityMode',
    'qualityStatus',
    'alertTriggered',
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
        i.qualityMode,
        i.qualityStatus,
        i.alertTriggered,
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

app.get('/api/v1/imports/:importId/reject-artifact', async (req, reply) => {
  const actor = requireRole(req, reply, 'viewer');
  if (!actor) return;

  const { importId } = req.params as { importId: string };
  const data = await getXmlImport(importId);
  if (!data) {
    return reply.code(404).send({ error: 'Import not found' });
  }

  return {
    importId: data.id,
    qualityStatus: data.qualityStatus,
    rejectArtifact: data.rejectArtifact ?? { rejected: [], rejectedCount: 0 }
  };
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

app.get('/api/v1/import-policies', async (req, reply) => {
  const actor = requireRole(req, reply, 'viewer');
  if (!actor) return;

  const rows = await listSourcePolicies();
  return { policies: rows };
});

app.post('/api/v1/import-policies', async (req, reply) => {
  const actor = requireRole(req, reply, 'admin');
  if (!actor) return;

  const body = req.body as {
    source?: string;
    enabled?: boolean;
    defaultQualityMode?: 'lenient' | 'strict';
    allowBypassToLenient?: boolean;
  };

  if (!body?.source || typeof body.source !== 'string' || body.source.trim().length === 0) {
    return reply.code(400).send({ error: 'source is required' });
  }

  const saved = await upsertSourcePolicy({
    source: body.source.trim(),
    enabled: body.enabled,
    defaultQualityMode: body.defaultQualityMode,
    allowBypassToLenient: body.allowBypassToLenient
  });

  return saved;
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

app.get('/api/v1/imports/:importId/annotations', async (req, reply) => {
  const actor = requireRole(req, reply, 'viewer');
  if (!actor) return;
  const { importId } = req.params as { importId: string };
  const row = await prisma.xmlImport.findUnique({ where: { id: importId }, select: { annotations: true } });
  if (!row) return reply.code(404).send({ error: 'Import not found' });
  return { importId, annotations: row.annotations ?? { labels: [], notes: '' } };
});

app.post('/api/v1/imports/:importId/annotations', async (req, reply) => {
  const actor = requireRole(req, reply, 'staff');
  if (!actor) return;
  const { importId } = req.params as { importId: string };
  const payload = sanitizeAnnotations((req.body ?? {}) as AnnotationPayload);
  const updated = await prisma.xmlImport.update({ where: { id: importId }, data: { annotations: payload } }).catch(() => null);
  if (!updated) return reply.code(404).send({ error: 'Import not found' });
  return { importId, annotations: updated.annotations };
});

app.get('/api/v1/assets/:assetId/annotations', async (req, reply) => {
  const actor = requireRole(req, reply, 'viewer');
  if (!actor) return;
  const { assetId } = req.params as { assetId: string };
  const row = await prisma.asset.findUnique({ where: { id: assetId }, select: { annotations: true } });
  if (!row) return reply.code(404).send({ error: 'Asset not found' });
  return { assetId, annotations: row.annotations ?? { labels: [], notes: '' } };
});

app.post('/api/v1/assets/:assetId/annotations', async (req, reply) => {
  const actor = requireRole(req, reply, 'staff');
  if (!actor) return;
  const { assetId } = req.params as { assetId: string };
  const payload = sanitizeAnnotations((req.body ?? {}) as AnnotationPayload);
  const updated = await prisma.asset.update({ where: { id: assetId }, data: { annotations: payload } }).catch(() => null);
  if (!updated) return reply.code(404).send({ error: 'Asset not found' });
  return { assetId, annotations: updated.annotations };
});

app.get('/api/v1/scans/:scanId/diff', async (req, reply) => {
  const actor = requireRole(req, reply, 'viewer');
  if (!actor) return;
  const { scanId } = req.params as { scanId: string };
  const { againstScanId, format } = req.query as { againstScanId?: string; format?: string };
  if (!againstScanId) return reply.code(400).send({ error: 'againstScanId is required' });

  const [a, b] = await Promise.all([
    prisma.scanEvent.findMany({ where: { scanId }, select: { stage: true, status: true } }),
    prisma.scanEvent.findMany({ where: { scanId: againstScanId }, select: { stage: true, status: true } })
  ]);

  const toBucket = (rows: Array<{ stage: string | null; status: string | null }>) => {
    let out: Record<string, number> = {};
    for (const r of rows) {
      const key = `${r.stage ?? '-'}:${r.status ?? '-'}`;
      out = mergeCounts(out, { [key]: 1 });
    }
    return out;
  };

  const left = toBucket(a);
  const right = toBucket(b);
  const keys = [...new Set([...Object.keys(left), ...Object.keys(right)])];
  const deltas = keys
    .map((k) => ({ key: k, current: left[k] ?? 0, baseline: right[k] ?? 0, delta: (left[k] ?? 0) - (right[k] ?? 0) }))
    .filter((r) => r.delta !== 0)
    .sort((x, y) => Math.abs(y.delta) - Math.abs(x.delta));

  if (format === 'csv') {
    const header = 'bucket,current,baseline,delta';
    const rows = deltas.map((d) => `"${d.key.replaceAll('"', '""')}",${d.current},${d.baseline},${d.delta}`);
    reply.header('content-type', 'text/csv; charset=utf-8');
    reply.header('content-disposition', `attachment; filename="scan-diff-${scanId}-vs-${againstScanId}.csv"`);
    return [header, ...rows].join('\n');
  }

  return {
    scanId,
    againstScanId,
    summary: { currentEvents: a.length, baselineEvents: b.length, changedBuckets: deltas.length },
    deltas
  };
});

app.get('/api/v1/imports/:importId/diff', async (req, reply) => {
  const actor = requireRole(req, reply, 'viewer');
  if (!actor) return;
  const { importId } = req.params as { importId: string };
  const { againstImportId, format } = req.query as { againstImportId?: string; format?: string };
  if (!againstImportId) return reply.code(400).send({ error: 'againstImportId is required' });

  const [current, baseline] = await Promise.all([
    prisma.asset.findMany({ where: { importId }, select: { identityKey: true, ports: true, serviceTags: true } }),
    prisma.asset.findMany({ where: { importId: againstImportId }, select: { identityKey: true, ports: true, serviceTags: true } })
  ]);

  const currMap = new Map(current.map((a) => [a.identityKey, a]));
  const baseMap = new Map(baseline.map((a) => [a.identityKey, a]));

  const added: string[] = [];
  const removed: string[] = [];
  const changed: string[] = [];

  for (const key of currMap.keys()) {
    if (!baseMap.has(key)) {
      added.push(key);
      continue;
    }
    const c = currMap.get(key)!;
    const b = baseMap.get(key)!;
    const portsChanged = JSON.stringify([...c.ports].sort((x, y) => x - y)) !== JSON.stringify([...b.ports].sort((x, y) => x - y));
    const tagsChanged = JSON.stringify([...c.serviceTags].sort()) !== JSON.stringify([...b.serviceTags].sort());
    if (portsChanged || tagsChanged) changed.push(key);
  }

  for (const key of baseMap.keys()) {
    if (!currMap.has(key)) removed.push(key);
  }

  if (format === 'csv') {
    const esc = (v: string) => `"${v.replaceAll('"', '""')}"`;
    const rows = [
      ...added.map((k) => `${esc('added')},${esc(k)}`),
      ...removed.map((k) => `${esc('removed')},${esc(k)}`),
      ...changed.map((k) => `${esc('changed')},${esc(k)}`)
    ];
    reply.header('content-type', 'text/csv; charset=utf-8');
    reply.header('content-disposition', `attachment; filename="import-diff-${importId}-vs-${againstImportId}.csv"`);
    return ['category,identityKey', ...rows].join('\n');
  }

  return {
    importId,
    againstImportId,
    summary: {
      currentAssets: current.length,
      baselineAssets: baseline.length,
      added: added.length,
      removed: removed.length,
      changed: changed.length
    },
    samples: {
      added: added.slice(0, 20),
      removed: removed.slice(0, 20),
      changed: changed.slice(0, 20)
    }
  };
});

app.post('/api/v1/imports/:importId/vuln-enrich', async (req, reply) => {
  const actor = requireRole(req, reply, 'staff');
  if (!actor) return;
  const { importId } = req.params as { importId: string };
  const exists = await prisma.xmlImport.findUnique({ where: { id: importId }, select: { id: true } });
  if (!exists) return reply.code(404).send({ error: 'Import not found' });
  const result = await enrichImportVulnerabilities(importId);

  for (const audience of ['ops', 'exec'] as const) {
    const pdf = await buildBrandedReportPdf({
      title: 'Armadillo Import Report',
      subtitle: `Import ${importId}`,
      audience,
      generatedFor: audience === 'exec' ? 'Jason Comeau (CEO)' : `Ops Team (${actor.actorId})`,
      dateRange: 'Post-enrichment snapshot',
      confidentiality: 'INTERNAL CONFIDENTIAL',
      preparedBy: 'Leo • Comans Services',
      dashboardUrl: `http://localhost:3000/imports/${importId}`,
      sections: [
        { heading: 'Auto-Generated Trigger', lines: ['Generated automatically after vulnerability enrichment completion.'] },
        { heading: 'Enrichment Summary', lines: [`assetsScanned=${result.assetsScanned}`, `findingsWritten=${result.findingsWritten}`, `distinctCves=${result.distinctCves}`] }
      ]
    });
    await archiveReport({ kind: 'import', refId: importId, audience, pdf, requestedBy: actor.actorId });
  }

  return result;
});

app.get('/api/v1/vulns', async (req, reply) => {
  const actor = requireRole(req, reply, 'viewer');
  if (!actor) return;
  const { importId, assetId, severity, limit, format } = req.query as {
    importId?: string;
    assetId?: string;
    severity?: string;
    limit?: string;
    format?: string;
  };
  const rows = await listVulnerabilities({
    importId,
    assetId,
    severity,
    limit: Number(limit ?? 100)
  });

  if (format === 'csv') {
    const esc = (v: unknown) => `"${String(v ?? '').replaceAll('"', '""')}"`;
    const header = [
      'detectedAt',
      'severity',
      'cve',
      'cvss',
      'cpe',
      'source',
      'assetId',
      'identityKey',
      'ip',
      'hostname',
      'importId',
      'title',
      'description',
      'exploitRefs'
    ];
    const lines = [header.join(',')];
    for (const r of rows) {
      lines.push(
        [
          r.detectedAt.toISOString(),
          r.severity,
          r.cve,
          r.cvss ?? '',
          r.cpe ?? '',
          r.source ?? '',
          r.asset.id,
          r.asset.identityKey,
          r.asset.ip ?? '',
          r.asset.hostname ?? '',
          r.importId,
          r.title ?? '',
          r.description ?? '',
          Array.isArray((r as { exploitRefs?: Array<{ source: string; id: string }> }).exploitRefs)
            ? ((r as { exploitRefs?: Array<{ source: string; id: string }> }).exploitRefs ?? [])
                .map((e) => `${e.source}:${e.id}`)
                .join(' | ')
            : ''
        ]
          .map(esc)
          .join(',')
      );
    }
    reply.header('content-type', 'text/csv; charset=utf-8');
    reply.header('content-disposition', 'attachment; filename="armadillo-vulns.csv"');
    return lines.join('\n');
  }

  return { findings: rows };
});

app.get('/api/v1/assets/:assetId/vulns', async (req, reply) => {
  const actor = requireRole(req, reply, 'viewer');
  if (!actor) return;
  const { assetId } = req.params as { assetId: string };
  const rows = await listVulnerabilities({ assetId, limit: 200 });
  return { findings: rows };
});

app.get('/api/v1/network', async (req, reply) => {
  const actor = requireRole(req, reply, 'viewer');
  if (!actor) return;

  const { importId, limit, subnet, service, port } = req.query as {
    importId?: string;
    limit?: string;
    subnet?: string;
    service?: string;
    port?: string;
  };
  const take = Math.min(Math.max(Number(limit ?? 300), 1), 1000);

  const parsedPort = port ? Number(port) : undefined;
  const assets = await prisma.asset.findMany({
    where: {
      ...(importId ? { importId } : {}),
      ...(service ? { serviceTags: { has: service } } : {}),
      ...(Number.isFinite(parsedPort) ? { ports: { has: parsedPort as number } } : {})
    },
    orderBy: { createdAt: 'desc' },
    take,
    select: {
      id: true,
      identityKey: true,
      importId: true,
      ip: true,
      hostname: true,
      ports: true,
      serviceTags: true
    }
  });

  const subnetFiltered = subnet
    ? assets.filter((a) => {
        const ip = a.ip ?? '';
        return ip.startsWith(subnet);
      })
    : assets;

  const nodes: Array<{ id: string; type: 'asset' | 'port' | 'service'; label: string; meta?: Record<string, unknown> }> = [];
  const links: Array<{ source: string; target: string; kind: 'has-port' | 'has-service' }> = [];

  const seenNodes = new Set<string>();
  const addNode = (id: string, type: 'asset' | 'port' | 'service', label: string, meta?: Record<string, unknown>) => {
    if (seenNodes.has(id)) return;
    seenNodes.add(id);
    nodes.push({ id, type, label, meta });
  };

  for (const a of subnetFiltered) {
    const assetNodeId = `asset:${a.id}`;
    addNode(assetNodeId, 'asset', a.identityKey, {
      importId: a.importId,
      ip: a.ip,
      hostname: a.hostname,
      ports: a.ports,
      serviceTags: a.serviceTags
    });

    for (const p of a.ports.slice(0, 25)) {
      const portNodeId = `port:${p}`;
      addNode(portNodeId, 'port', `port ${p}`);
      links.push({ source: assetNodeId, target: portNodeId, kind: 'has-port' });
    }

    for (const s of a.serviceTags.slice(0, 20)) {
      const serviceNodeId = `service:${s}`;
      addNode(serviceNodeId, 'service', s);
      links.push({ source: assetNodeId, target: serviceNodeId, kind: 'has-service' });
    }
  }

  return {
    summary: {
      assets: subnetFiltered.length,
      nodes: nodes.length,
      links: links.length
    },
    nodes,
    links
  };
});

app.get('/api/v1/dashboard/summary', async (req, reply) => {
  const actor = requireRole(req, reply, 'viewer');
  if (!actor) return;

  const { days, format, importId } = req.query as { days?: string; format?: string; importId?: string };
  const windowDays = Math.min(Math.max(Number(days ?? 14), 1), 90);
  const since = new Date(Date.now() - windowDays * 24 * 60 * 60 * 1000);

  const assetWhere = importId ? { importId } : undefined;
  const vulnWhere = {
    detectedAt: { gte: since },
    ...(importId ? { importId } : {})
  };

  const [assetCount, importCount, scanCount, vulnRows, assets] = await Promise.all([
    prisma.asset.count({ where: assetWhere }),
    prisma.xmlImport.count({ where: importId ? { id: importId } : undefined }),
    prisma.scan.count(),
    prisma.assetVulnerability.findMany({ where: vulnWhere, select: { severity: true, detectedAt: true } }),
    prisma.asset.findMany({ where: assetWhere, take: 1500, select: { ports: true, serviceTags: true, os: true } })
  ]);

  const sev = { critical: 0, high: 0, medium: 0, low: 0 };
  for (const r of vulnRows) {
    const s = String(r.severity || '').toLowerCase();
    if (s in sev) (sev as Record<string, number>)[s] += 1;
  }

  const serviceCounts: Record<string, number> = {};
  const portCounts: Record<string, number> = {};
  const osCounts: Record<string, number> = {};

  for (const a of assets) {
    for (const s of a.serviceTags.slice(0, 20)) serviceCounts[s] = (serviceCounts[s] ?? 0) + 1;
    for (const p of a.ports.slice(0, 40)) {
      const k = String(p);
      portCounts[k] = (portCounts[k] ?? 0) + 1;
    }
    const os = (a.os || 'unknown').trim().toLowerCase();
    osCounts[os] = (osCounts[os] ?? 0) + 1;
  }

  const top = (obj: Record<string, number>, n = 8) =>
    Object.entries(obj)
      .sort((a, b) => b[1] - a[1])
      .slice(0, n)
      .map(([label, count]) => ({ label, count }));

  const dayBuckets: Record<string, number> = {};
  for (let i = windowDays - 1; i >= 0; i -= 1) {
    const d = new Date(Date.now() - i * 24 * 60 * 60 * 1000).toISOString().slice(0, 10);
    dayBuckets[d] = 0;
  }
  for (const r of vulnRows) {
    const k = r.detectedAt.toISOString().slice(0, 10);
    if (k in dayBuckets) dayBuckets[k] += 1;
  }

  const summary = {
    totals: {
      assets: assetCount,
      imports: importCount,
      scans: scanCount,
      vulnsWindow: vulnRows.length
    },
    severity: sev,
    topServices: top(serviceCounts),
    topPorts: top(portCounts),
    topOs: top(osCounts),
    trend: Object.entries(dayBuckets).map(([date, count]) => ({ date, count })),
    windowDays,
    importId: importId ?? null
  };

  if (format === 'csv') {
    const rows = [
      'section,label,count',
      ...Object.entries(summary.totals).map(([k, v]) => `totals,${k},${v}`),
      ...Object.entries(summary.severity).map(([k, v]) => `severity,${k},${v}`),
      ...summary.topServices.map((r) => `topServices,${r.label},${r.count}`),
      ...summary.topPorts.map((r) => `topPorts,${r.label},${r.count}`),
      ...summary.topOs.map((r) => `topOs,${r.label},${r.count}`),
      ...summary.trend.map((r) => `trend,${r.date},${r.count}`)
    ];
    reply.header('content-type', 'text/csv; charset=utf-8');
    reply.header('content-disposition', 'attachment; filename="armadillo-dashboard-summary.csv"');
    return rows.join('\n');
  }

  return summary;
});

app.get('/api/v1/reports', async (req, reply) => {
  const actor = requireRole(req, reply, 'viewer');
  if (!actor) return;
  await mkdir(reportArchiveDir, { recursive: true });
  const files = await readdir(reportArchiveDir);
  const metaFiles = files.filter((f) => f.endsWith('.json')).sort().reverse().slice(0, 200);

  const reports = [] as Array<Record<string, unknown>>;
  for (const file of metaFiles) {
    try {
      const raw = await readFile(path.join(reportArchiveDir, file), 'utf8');
      reports.push(JSON.parse(raw));
    } catch {
      // ignore bad metadata
    }
  }

  return { reports };
});

app.get('/api/v1/reports/imports/:importId.pdf', async (req, reply) => {
  const actor = requireRole(req, reply, 'viewer');
  if (!actor) return;
  const { importId } = req.params as { importId: string };
  const { againstImportId, audience, archive } = req.query as { againstImportId?: string; audience?: string; archive?: string };
  const reportAudience: 'ops' | 'exec' = audience === 'exec' ? 'exec' : 'ops';

  const importRow = await prisma.xmlImport.findUnique({ where: { id: importId } });
  if (!importRow) return reply.code(404).send({ error: 'Import not found' });

  const findings = await listVulnerabilities({ importId, limit: reportAudience === 'exec' ? 20 : 50 });
  const sev = findings.reduce<Record<string, number>>((acc, f) => {
    const key = String(f.severity || 'unknown').toLowerCase();
    acc[key] = (acc[key] ?? 0) + 1;
    return acc;
  }, {});

  let diffSummary = 'No baseline selected';
  if (againstImportId) {
    const [current, baseline] = await Promise.all([
      prisma.asset.findMany({ where: { importId }, select: { identityKey: true, ports: true, serviceTags: true } }),
      prisma.asset.findMany({ where: { importId: againstImportId }, select: { identityKey: true, ports: true, serviceTags: true } })
    ]);
    const currMap = new Map(current.map((a) => [a.identityKey, a]));
    const baseMap = new Map(baseline.map((a) => [a.identityKey, a]));
    let added = 0;
    let removed = 0;
    let changed = 0;
    for (const key of currMap.keys()) {
      if (!baseMap.has(key)) {
        added += 1;
        continue;
      }
      const c = currMap.get(key)!;
      const b = baseMap.get(key)!;
      const portsChanged = JSON.stringify([...c.ports].sort((x, y) => x - y)) !== JSON.stringify([...b.ports].sort((x, y) => x - y));
      const tagsChanged = JSON.stringify([...c.serviceTags].sort()) !== JSON.stringify([...b.serviceTags].sort());
      if (portsChanged || tagsChanged) changed += 1;
    }
    for (const key of baseMap.keys()) if (!currMap.has(key)) removed += 1;
    diffSummary = `Diff vs ${againstImportId}: added=${added}, removed=${removed}, changed=${changed}`;
  }

  const topFindings = findings
    .slice(0, reportAudience === 'exec' ? 8 : 15)
    .map((f) => {
      const refs = Array.isArray((f as { exploitRefs?: Array<{ source: string; id: string }> }).exploitRefs)
        ? ((f as { exploitRefs?: Array<{ source: string; id: string }> }).exploitRefs ?? [])
            .slice(0, 2)
            .map((e) => `${e.source}:${e.id}`)
            .join(', ')
        : '';
      const tail = refs ? ` | exploits: ${refs}` : '';
      return `[${String(f.severity).toUpperCase()}] ${f.cve} ${f.asset.identityKey} ${f.title ?? ''}${tail}`.trim();
    });

  const pdf = await buildBrandedReportPdf({
    title: 'Armadillo Import Report',
    subtitle: `Import ${importRow.id}`,
    audience: reportAudience,
    generatedFor: reportAudience === 'exec' ? 'Jason Comeau (CEO)' : `Ops Team (${importRow.requestedBy})`,
    dateRange: againstImportId ? `${againstImportId} → ${importId}` : 'Single import snapshot',
    confidentiality: 'INTERNAL CONFIDENTIAL',
    metricCards: [
      { label: 'Critical', value: String(sev.critical ?? 0), tone: 'critical' },
      { label: 'High', value: String(sev.high ?? 0), tone: 'high' },
      { label: 'Medium', value: String(sev.medium ?? 0), tone: 'medium' },
      { label: 'Low', value: String(sev.low ?? 0), tone: 'low' }
    ],
    signoff: { name: 'Jason Comeau', role: 'CEO, Comans Services' },
    preparedBy: 'Leo • Comans Services',
    dashboardUrl: `http://localhost:3000/imports/${importId}`,
    sections: [
      {
        heading: 'Import Overview',
        lines: [
          `Source: ${importRow.source ?? '-'}`,
          `RequestedBy: ${importRow.requestedBy}`,
          `Quality Mode: ${importRow.qualityMode}`,
          `Quality Status: ${importRow.qualityStatus}`,
          `Asset Counts: items=${importRow.itemCount}, normalized=${importRow.normalizedAssetCount}, skipped=${importRow.skippedAssetCount}, invalid=${importRow.invalidAssetCount}`
        ]
      },
      {
        heading: 'Change Summary',
        lines: [diffSummary]
      },
      {
        heading: 'Vulnerability Summary',
        lines: [
          `Findings considered: ${findings.length}`,
          `Severity split: critical=${sev.critical ?? 0}, high=${sev.high ?? 0}, medium=${sev.medium ?? 0}, low=${sev.low ?? 0}`
        ]
      },
      {
        heading: reportAudience === 'exec' ? 'Key Findings' : 'Top Findings',
        lines: topFindings.length ? topFindings : ['No findings for selected import.']
      }
    ]
  });

  if (archive === '1' || archive === 'true') {
    await archiveReport({ kind: 'import', refId: importId, audience: reportAudience, pdf, requestedBy: actor.actorId });
  }

  reply.header('content-type', 'application/pdf');
  reply.header('content-disposition', `attachment; filename="armadillo-import-report-${importId}-${reportAudience}.pdf"`);
  return reply.send(pdf);
});

app.get('/api/v1/reports/scans/:scanId.pdf', async (req, reply) => {
  const actor = requireRole(req, reply, 'viewer');
  if (!actor) return;
  const { scanId } = req.params as { scanId: string };
  const { againstScanId, audience, archive } = req.query as { againstScanId?: string; audience?: string; archive?: string };
  const reportAudience: 'ops' | 'exec' = audience === 'exec' ? 'exec' : 'ops';

  const scan = await prisma.scan.findUnique({ where: { id: scanId } });
  if (!scan) return reply.code(404).send({ error: 'Scan not found' });

  const events = await prisma.scanEvent.findMany({ where: { scanId }, orderBy: { createdAt: 'asc' }, take: 80 });

  let diffSummary = 'No baseline selected';
  if (againstScanId) {
    const [a, b] = await Promise.all([
      prisma.scanEvent.findMany({ where: { scanId }, select: { stage: true, status: true } }),
      prisma.scanEvent.findMany({ where: { scanId: againstScanId }, select: { stage: true, status: true } })
    ]);

    const toBucket = (rows: Array<{ stage: string | null; status: string | null }>) => {
      let out: Record<string, number> = {};
      for (const r of rows) {
        const key = `${r.stage ?? '-'}:${r.status ?? '-'}`;
        out = mergeCounts(out, { [key]: 1 });
      }
      return out;
    };

    const left = toBucket(a);
    const right = toBucket(b);
    const keys = [...new Set([...Object.keys(left), ...Object.keys(right)])];
    const changedBuckets = keys.filter((k) => (left[k] ?? 0) !== (right[k] ?? 0)).length;
    diffSummary = `Diff vs ${againstScanId}: currentEvents=${a.length}, baselineEvents=${b.length}, changedBuckets=${changedBuckets}`;
  }

  const vulnRows = await prisma.assetVulnerability.findMany({ take: 200 });

  const sev = vulnRows.reduce<Record<string, number>>((acc, r) => {
    const k = String(r.severity || 'unknown').toLowerCase();
    acc[k] = (acc[k] ?? 0) + 1;
    return acc;
  }, {});

  const timelineLines = events
    .slice(0, reportAudience === 'exec' ? 8 : 20)
    .map((e) => `${e.createdAt.toISOString()} | ${e.stage ?? '-'} | ${e.status ?? '-'} | ${e.message ?? '-'}`);

  const pdf = await buildBrandedReportPdf({
    title: 'Armadillo Scan Report',
    subtitle: `Scan ${scan.id}`,
    audience: reportAudience,
    generatedFor: reportAudience === 'exec' ? 'Jason Comeau (CEO)' : `Ops Team (${scan.requestedBy})`,
    dateRange: againstScanId ? `${againstScanId} → ${scanId}` : 'Single scan snapshot',
    confidentiality: 'INTERNAL CONFIDENTIAL',
    metricCards: [
      { label: 'Critical', value: String(sev.critical ?? 0), tone: 'critical' },
      { label: 'High', value: String(sev.high ?? 0), tone: 'high' },
      { label: 'Medium', value: String(sev.medium ?? 0), tone: 'medium' },
      { label: 'Low', value: String(sev.low ?? 0), tone: 'low' }
    ],
    signoff: { name: 'Jason Comeau', role: 'CEO, Comans Services' },
    preparedBy: 'Leo • Comans Services',
    dashboardUrl: `http://localhost:3000/scans/${scanId}`,
    sections: [
      {
        heading: 'Scan Overview',
        lines: [
          `Project: ${scan.projectId}`,
          `RequestedBy: ${scan.requestedBy}`,
          `Status: ${scan.status}`,
          `Created: ${scan.createdAt.toISOString()}`,
          `Updated: ${scan.updatedAt.toISOString()}`
        ]
      },
      {
        heading: 'Change Summary',
        lines: [diffSummary]
      },
      {
        heading: 'Execution Timeline Snapshot',
        lines: timelineLines.length ? timelineLines : ['No timeline events captured.']
      },
      {
        heading: 'Vulnerability Context',
        lines: [
          `Global vulnerability snapshot: critical=${sev.critical ?? 0}, high=${sev.high ?? 0}, medium=${sev.medium ?? 0}, low=${sev.low ?? 0}`
        ]
      }
    ]
  });

  if (archive === '1' || archive === 'true') {
    await archiveReport({ kind: 'scan', refId: scanId, audience: reportAudience, pdf, requestedBy: actor.actorId });
  }

  reply.header('content-type', 'application/pdf');
  reply.header('content-disposition', `attachment; filename="armadillo-scan-report-${scanId}-${reportAudience}.pdf"`);
  return reply.send(pdf);
});

app.listen({ host: '0.0.0.0', port: 4000 }).then(() => {
  console.log('API listening on http://localhost:4000');
  runDueSchedules().catch(() => {});
  setInterval(() => {
    runDueSchedules().catch(() => {});
  }, 60_000);
});
