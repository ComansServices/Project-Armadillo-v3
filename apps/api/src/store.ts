import type { ScanRequest } from '@armadillo/types/src/pipeline';
import { prisma } from './prisma';

export type ScanStatus = 'queued' | 'running' | 'completed' | 'failed';

export interface ScanRecord {
  id: string;
  projectId: string;
  requestedBy: string;
  status: ScanStatus;
  request?: ScanRequest;
  createdAt: string;
  updatedAt: string;
}

interface CreateScanInput {
  id: string;
  projectId: string;
  requestedBy: string;
  status?: ScanStatus;
  request?: ScanRequest;
}

function toScanRecord(scan: {
  id: string;
  projectId: string;
  requestedBy: string;
  status: string;
  request: unknown;
  createdAt: Date;
  updatedAt: Date;
}): ScanRecord {
  return {
    id: scan.id,
    projectId: scan.projectId,
    requestedBy: scan.requestedBy,
    status: scan.status as ScanStatus,
    request: (scan.request ?? undefined) as ScanRequest | undefined,
    createdAt: scan.createdAt.toISOString(),
    updatedAt: scan.updatedAt.toISOString()
  };
}

export async function createScan(input: CreateScanInput) {
  const created = await prisma.scan.create({
    data: {
      id: input.id,
      projectId: input.projectId,
      requestedBy: input.requestedBy,
      status: input.status ?? 'queued',
      request: (input.request as unknown as object) ?? undefined
    }
  });

  await prisma.scanEvent.create({
    data: {
      scanId: created.id,
      status: created.status,
      message: 'Scan created'
    }
  });

  return toScanRecord(created);
}

export async function getScan(id: string) {
  const scan = await prisma.scan.findUnique({ where: { id } });
  return scan ? toScanRecord(scan) : null;
}

export async function listScans(limit = 25) {
  const scans = await prisma.scan.findMany({
    orderBy: { createdAt: 'desc' },
    take: limit
  });

  return scans.map(toScanRecord);
}

export async function updateScan(id: string, patch: Partial<ScanRecord>) {
  const existing = await prisma.scan.findUnique({ where: { id }, select: { id: true } });
  if (!existing) return null;

  const updated = await prisma.scan.update({
    where: { id },
    data: {
      projectId: patch.projectId,
      requestedBy: patch.requestedBy,
      status: patch.status,
      request: (patch.request as unknown as object) ?? undefined
    }
  });

  await prisma.scanEvent.create({
    data: {
      scanId: updated.id,
      status: updated.status,
      message: 'Scan updated',
      metadata: (patch as unknown as object) ?? undefined
    }
  });

  return toScanRecord(updated);
}
