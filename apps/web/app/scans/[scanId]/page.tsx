import Link from 'next/link';

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

const baseUrl =
  process.env.API_BASE_URL ?? process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://localhost:4000';

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

export const dynamic = 'force-dynamic';
export const revalidate = 0;

export default async function ScanDetailPage({ params }: { params: { scanId: string } }) {
  const [scan, events] = await Promise.all([getScan(params.scanId), getEvents(params.scanId)]);

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

      <h2 style={{ marginBottom: 8 }}>Timeline</h2>
      <meta httpEquiv="refresh" content="5" />
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
