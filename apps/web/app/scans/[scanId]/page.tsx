import Link from 'next/link';

type ScanOption = {
  id: string;
  projectId: string;
  requestedBy: string;
  status: 'queued' | 'running' | 'completed' | 'failed';
  createdAt: string;
};

type ScanRecord = {
  id: string;
  projectId: string;
  requestedBy: string;
  status: 'queued' | 'running' | 'completed' | 'failed';
  createdAt: string;
  updatedAt: string;
};

type ScanEvent = {
  id: number;
  scanId: string;
  status: string | null;
  stage: string | null;
  message: string | null;
  metadata: unknown;
  createdAt: string;
};

const baseUrl = process.env.API_BASE_URL ?? process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://localhost:4000';
const publicApiBaseUrl = process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://localhost:4000';

const authHeaders = {
  'x-armadillo-user': process.env.WEB_ACTOR_ID ?? 'web-ui',
  'x-armadillo-role': process.env.WEB_ACTOR_ROLE ?? 'viewer'
};

async function getScan(scanId: string): Promise<ScanRecord> {
  const res = await fetch(`${baseUrl}/api/v1/scans/${scanId}`, { cache: 'no-store', headers: authHeaders });
  if (!res.ok) throw new Error(`Scan fetch failed (${res.status})`);
  return res.json();
}

async function getEvents(scanId: string): Promise<ScanEvent[]> {
  const res = await fetch(`${baseUrl}/api/v1/scans/${scanId}/events`, {
    cache: 'no-store',
    headers: authHeaders
  });
  if (!res.ok) throw new Error(`Events fetch failed (${res.status})`);
  const data = (await res.json()) as { events: ScanEvent[] };
  return data.events ?? [];
}

async function getScanDiff(scanId: string, againstScanId: string) {
  const res = await fetch(`${baseUrl}/api/v1/scans/${scanId}/diff?againstScanId=${againstScanId}`, {
    cache: 'no-store',
    headers: authHeaders
  });
  if (!res.ok) return null;
  return res.json();
}

async function getRecentScans(): Promise<ScanOption[]> {
  const res = await fetch(`${baseUrl}/api/v1/scans?limit=50`, { cache: 'no-store', headers: authHeaders });
  if (!res.ok) return [];
  const data = (await res.json()) as { scans?: ScanOption[] };
  return data.scans ?? [];
}

export const dynamic = 'force-dynamic';
export const revalidate = 0;

export default async function ScanDetailPage({
  params,
  searchParams
}: {
  params: { scanId: string };
  searchParams?: Promise<Record<string, string | string[] | undefined>>;
}) {
  const qp = searchParams ? await searchParams : undefined;
  const againstScanId = typeof qp?.againstScanId === 'string' ? qp.againstScanId : '';

  const [scan, events, scanOptions] = await Promise.all([
    getScan(params.scanId),
    getEvents(params.scanId),
    getRecentScans()
  ]);
  const baselineOptions = scanOptions.filter((opt) => opt.id !== params.scanId);
  const latestBaseline = baselineOptions[0]?.id;
  const effectiveAgainstScanId = againstScanId || latestBaseline || '';
  const diff = effectiveAgainstScanId ? await getScanDiff(params.scanId, effectiveAgainstScanId) : null;

  return (
    <main style={{ padding: 24, fontFamily: 'system-ui' }}>
      <p style={{ marginBottom: 12 }}>
        <Link href="/">← Back to scans</Link>
      </p>
      <h1 style={{ marginBottom: 6 }}>Scan Detail</h1>
      <p style={{ marginTop: 0, color: '#444' }}>{scan.id}</p>
      <p style={{ marginTop: 0 }}>
        <Link href="/imports">View XML imports →</Link>
      </p>

      <div style={{ marginTop: 12, marginBottom: 20 }}>
        <strong>Status:</strong> {scan.status.toUpperCase()} &nbsp; | &nbsp;
        <strong>Project:</strong> {scan.projectId} &nbsp; | &nbsp;
        <strong>Requested By:</strong> {scan.requestedBy}
      </div>

      <p style={{ marginTop: 0, display: 'flex', gap: 12, flexWrap: 'wrap' }}>
        <a
          href={`${publicApiBaseUrl}/api/v1/reports/scans/${scan.id}.pdf${effectiveAgainstScanId ? `?againstScanId=${effectiveAgainstScanId}&audience=ops&archive=1` : '?audience=ops&archive=1'}`}
          target="_blank"
          rel="noreferrer"
        >
          Download Ops scan PDF report →
        </a>
        <a
          href={`${publicApiBaseUrl}/api/v1/reports/scans/${scan.id}.pdf${effectiveAgainstScanId ? `?againstScanId=${effectiveAgainstScanId}&audience=exec&archive=1` : '?audience=exec&archive=1'}`}
          target="_blank"
          rel="noreferrer"
        >
          Download Exec scan PDF report →
        </a>
      </p>

      <h2 style={{ marginBottom: 8 }}>Scan Diff</h2>
      <form method="get" style={{ display: 'flex', gap: 8, marginBottom: 12, alignItems: 'center', flexWrap: 'wrap' }}>
        <select name="againstScanId" defaultValue={effectiveAgainstScanId} style={{ minWidth: 520 }}>
          <option value="">Select baseline scan…</option>
          {baselineOptions.map((opt) => (
            <option key={opt.id} value={opt.id}>
              {new Date(opt.createdAt).toLocaleString()} · {opt.projectId} · {opt.requestedBy} · {opt.id}
            </option>
          ))}
        </select>
        <button type="submit">Compare</button>
        {latestBaseline ? <a href={`/scans/${scan.id}?againstScanId=${latestBaseline}`}>Compare latest previous</a> : null}
        {effectiveAgainstScanId ? (
          <>
            <a href={`${publicApiBaseUrl}/api/v1/scans/${scan.id}/diff?againstScanId=${effectiveAgainstScanId}`}>Export JSON</a>
            <a href={`${publicApiBaseUrl}/api/v1/scans/${scan.id}/diff?againstScanId=${effectiveAgainstScanId}&format=csv`}>Export CSV</a>
          </>
        ) : null}
      </form>
      {diff ? (
        <div style={{ border: '1px solid #ddd', borderRadius: 8, padding: 12, marginBottom: 16, background: '#fafafa' }}>
          <p style={{ marginTop: 0 }}>
            <strong>Current/Baseline Events:</strong> {diff.summary.currentEvents}/{diff.summary.baselineEvents} &nbsp; | &nbsp;
            <strong>Changed Buckets:</strong> {diff.summary.changedBuckets}
          </p>
          {(diff.deltas ?? []).length === 0 ? (
            <p style={{ marginBottom: 0, color: '#666' }}>No stage/status bucket differences detected.</p>
          ) : (
            <ul style={{ marginBottom: 0 }}>
              {(diff.deltas ?? []).slice(0, 10).map((d: { key: string; delta: number }) => (
                <li key={d.key}>
                  {d.key}: {d.delta > 0 ? '+' : ''}
                  {d.delta}
                </li>
              ))}
            </ul>
          )}
        </div>
      ) : null}

      <h2 style={{ marginBottom: 8 }}>Timeline</h2>
      <div style={{ overflowX: 'auto' }}>
        <table style={{ borderCollapse: 'collapse', minWidth: 900, width: '100%' }}>
          <thead>
            <tr>
              {['Time', 'Stage', 'Status', 'Message'].map((h) => (
                <th key={h} style={{ textAlign: 'left', borderBottom: '1px solid #ddd', padding: '8px 10px' }}>
                  {h}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {events.length === 0 ? (
              <tr>
                <td colSpan={4} style={{ padding: '12px 10px', color: '#666' }}>
                  No events yet.
                </td>
              </tr>
            ) : (
              events.map((e) => (
                <tr key={e.id}>
                  <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>
                    {new Date(e.createdAt).toLocaleString()}
                  </td>
                  <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>{e.stage ?? '-'}</td>
                  <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>{e.status ?? '-'}</td>
                  <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>{e.message ?? '-'}</td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </main>
  );
}
