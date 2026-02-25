import { randomUUID } from 'node:crypto';
import Fastify from 'fastify';
import { scanQueue } from './queue';
import { createScan, getScan, listScans } from './store';
import type { ScanRequest, ScanJobPayload } from '@armadillo/types/src/pipeline';

const app = Fastify({ logger: true });

app.get('/health', async () => ({ ok: true, service: 'armadillo-api' }));

app.post('/api/v1/scans', async (req, reply) => {
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

  return { scanId, status: 'queued' };
});

app.get('/api/v1/scans', async (req) => {
  const { limit } = req.query as { limit?: string };
  const parsedLimit = Math.min(Math.max(Number(limit ?? 25), 1), 100);
  const scans = await listScans(Number.isNaN(parsedLimit) ? 25 : parsedLimit);
  return { scans };
});

app.get('/api/v1/scans/:scanId', async (req, reply) => {
  const { scanId } = req.params as { scanId: string };
  const scan = await getScan(scanId);
  if (!scan) {
    return reply.code(404).send({ error: 'Scan not found' });
  }
  return scan;
});

app.listen({ host: '0.0.0.0', port: 4000 }).then(() => {
  console.log('API listening on http://localhost:4000');
});
