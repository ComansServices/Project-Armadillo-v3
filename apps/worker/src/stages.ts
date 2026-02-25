import type { ScanStage, StageResult, ScanJobPayload } from '@armadillo/types/src/pipeline';

const stageOrder: ScanStage[] = ['naabu', 'nmap', 'httpx', 'nuclei'];

export function nextStage(current: ScanStage): ScanStage | null {
  const idx = stageOrder.indexOf(current);
  if (idx < 0 || idx === stageOrder.length - 1) return null;
  return stageOrder[idx + 1];
}

export async function runStage(job: ScanJobPayload): Promise<StageResult> {
  const startedAt = new Date().toISOString();

  // TODO: replace with real executors per stage
  // e.g. naabu exec -> artifact, nmap exec -> artifact, etc.
  await new Promise((r) => setTimeout(r, 300));

  const finishedAt = new Date().toISOString();
  return {
    scanId: job.scanId,
    stage: job.stage,
    ok: true,
    artifactRef: `artifact://${job.scanId}/${job.stage}/${Date.now()}`,
    summary: {
      targets: job.request.targets.length,
      note: 'scaffold stage completed'
    },
    startedAt,
    finishedAt
  };
}
