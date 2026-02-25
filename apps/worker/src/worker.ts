import { Queue, Worker } from 'bullmq';
import { SCAN_QUEUE_NAME } from '../../api/src/queue';
import type { ScanJobPayload } from '@armadillo/types/src/pipeline';
import { nextStage, runStage } from './stages';

const connection = {
  host: process.env.REDIS_HOST ?? '127.0.0.1',
  port: Number(process.env.REDIS_PORT ?? 6379)
};

const queue = new Queue(SCAN_QUEUE_NAME, { connection });

const worker = new Worker<ScanJobPayload>(
  SCAN_QUEUE_NAME,
  async (job) => {
    const payload = job.data;
    const result = await runStage(payload);

    console.log(`[worker] stage=${payload.stage} scanId=${payload.scanId} ok=${result.ok}`);

    if (!result.ok) {
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
      console.log(`[worker] pipeline complete scanId=${payload.scanId}`);
    }

    return result;
  },
  { connection, concurrency: Number(process.env.WORKER_CONCURRENCY ?? 4) }
);

worker.on('completed', (job) => console.log(`[worker] completed job=${job.id}`));
worker.on('failed', (job, err) => console.error(`[worker] failed job=${job?.id} err=${err.message}`));

console.log('[worker] Armadillo pipeline worker running...');
