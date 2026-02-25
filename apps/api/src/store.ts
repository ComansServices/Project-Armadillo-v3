export type ScanStatus = 'queued' | 'running' | 'completed' | 'failed';

export interface ScanRecord {
  id: string;
  projectId: string;
  requestedBy: string;
  status: ScanStatus;
  createdAt: string;
  updatedAt: string;
}

const scans = new Map<string, ScanRecord>();

export function createScan(record: ScanRecord) {
  scans.set(record.id, record);
  return record;
}

export function getScan(id: string) {
  return scans.get(id) ?? null;
}

export function updateScan(id: string, patch: Partial<ScanRecord>) {
  const current = scans.get(id);
  if (!current) return null;
  const next = { ...current, ...patch, updatedAt: new Date().toISOString() };
  scans.set(id, next);
  return next;
}
