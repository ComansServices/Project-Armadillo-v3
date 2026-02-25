import { Queue } from 'bullmq';

const connection = {
  host: process.env.REDIS_HOST ?? '127.0.0.1',
  port: Number(process.env.REDIS_PORT ?? 6379)
};

export const SCAN_QUEUE_NAME = 'scan-pipeline';
export const scanQueue = new Queue(SCAN_QUEUE_NAME, { connection });
