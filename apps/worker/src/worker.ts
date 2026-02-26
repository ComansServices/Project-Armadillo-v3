import { Queue, Worker } from 'bullmq';
import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import { SCAN_QUEUE_NAME } from '../../api/src/queue';
import { updateScan } from '../../api/src/store';
import type { ScanJobPayload } from '@armadillo/types/src/pipeline';
import { nextStage, runStage } from './stages';

const connection = {
  host: process.env.REDIS_HOST ?? '127.0.0.1',
  port: Number(process.env.REDIS_PORT ?? 6379)
};

const queue = new Queue(SCAN_QUEUE_NAME, { connection });
const apiBaseUrl = process.env.API_BASE_URL ?? 'http://api:4000';
const execFileAsync = promisify(execFile);
const teamsWebhookBin = process.env.TEAMS_WEBHOOK_BIN ?? `${process.env.HOME ?? ''}/.openclaw/skills/teams-webhook/teams-webhook`;
const teamsRecipient = process.env.TEAMS_RECIPIENT ?? 'Jason';

async function archiveScanReports(scanId: string) {
  for (const audience of ['ops', 'exec'] as const) {
    const url = `${apiBaseUrl}/api/v1/reports/scans/${scanId}.pdf?audience=${audience}&archive=1`;
    try {
      const res = await fetch(url, {
        headers: {
          'x-armadillo-user': 'worker-auto-report',
          'x-armadillo-role': 'viewer'
        }
      });
      if (!res.ok) {
        console.warn(`[worker] auto-report archive failed scanId=${scanId} audience=${audience} status=${res.status}`);
      }
    } catch (err) {
      const e = err as Error;
      console.warn(`[worker] auto-report archive error scanId=${scanId} audience=${audience} err=${e.message}`);
    }
  }
}

async function sendFailureAlert(scanId: string, message: string) {
  if (!teamsWebhookBin) return;
  const title = '🚨 Armadillo Scan Failure';
  const text = `scanId=${scanId}\nreason=${message.slice(0, 220)}\nscan=<http://localhost:3000/scans/${scanId}>`;
  try {
    await execFileAsync(teamsWebhookBin, [title, text, teamsRecipient]);
  } catch (err) {
    const e = err as Error;
    console.warn(`[worker] teams failure alert send failed scanId=${scanId} err=${e.message}`);
  }
}

const worker = new Worker<ScanJobPayload>(
  SCAN_QUEUE_NAME,
  async (job) => {
    const payload = job.data;

    await updateScan(
      payload.scanId,
      {
        status: 'running',
        request: payload.request
      },
      {
        status: 'running',
        stage: payload.stage,
        message: `Stage ${payload.stage} running`
      }
    );

    const result = await runStage(payload);

    console.log(`[worker] stage=${payload.stage} scanId=${payload.scanId} ok=${result.ok}`);

    if (!result.ok) {
      await updateScan(
        payload.scanId,
        {
          status: 'failed',
          request: payload.request
        },
        {
          status: 'failed',
          stage: payload.stage,
          message: result.error ?? `Stage ${payload.stage} failed`
        }
      );
      throw new Error(result.error ?? `Stage ${payload.stage} failed`);
    }

    const nxt = nextStage(payload.stage);
    if (nxt) {
      await queue.add('scan-stage', {
        scanId: payload.scanId,
        stage: nxt,
        request: payload.request,
        upstreamArtifactId: result.artifactRef
      });
    } else {
      await updateScan(
        payload.scanId,
        {
          status: 'completed',
          request: payload.request
        },
        {
          status: 'completed',
          stage: payload.stage,
          message: 'Pipeline completed'
        }
      );
      console.log(`[worker] pipeline complete scanId=${payload.scanId}`);
      await archiveScanReports(payload.scanId);
    }

    return result;
  },
  { connection, concurrency: Number(process.env.WORKER_CONCURRENCY ?? 4) }
);

worker.on('completed', (job) => console.log(`[worker] completed job=${job.id}`));
worker.on('failed', async (job, err) => {
  console.error(`[worker] failed job=${job?.id} err=${err.message}`);
  const scanId = job?.data?.scanId;
  if (scanId) {
    await updateScan(scanId, { status: 'failed' }, { status: 'failed', message: err.message });
    await sendFailureAlert(scanId, err.message);
  }
});

console.log('[worker] Armadillo pipeline worker running...');
