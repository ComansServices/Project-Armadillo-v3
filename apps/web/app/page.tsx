import Link from 'next/link';

type ScanRecord = {
  id: string;
  projectId: string;
  requestedBy: string;
  status: 'queued' | 'running' | 'completed' | 'failed';
  createdAt: string;
  updatedAt: string;
};

const baseUrl =
  process.env.API_BASE_URL ?? process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://localhost:4000';

const authHeaders = {
  'x-armadillo-user': process.env.WEB_ACTOR_ID ?? 'web-ui',
  'x-armadillo-role': process.env.WEB_ACTOR_ROLE ?? 'viewer'
};

async function getScans(): Promise<ScanRecord[]> {
  const res = await fetch(`${baseUrl}/api/v1/scans?limit=30`, {
    cache: 'no-store',
    headers: authHeaders
  });

  if (!res.ok) {
    throw new Error(`Failed to fetch scans (${res.status})`);
  }

  const data = (await res.json()) as { scans: ScanRecord[] };
  return data.scans ?? [];
}

export const dynamic = 'force-dynamic';
export const revalidate = 0;

export default async function HomePage() {
  const scans = await getScans();

  return (
    <main style={{ padding: 24, fontFamily: 'system-ui' }}>
      <h1 style={{ marginBottom: 8 }}>Armadillo v3</h1>
      <p style={{ marginTop: 0 }}>Live scan queue/status view (auto-refresh every 5s).</p>
      <p style={{ marginTop: 0 }}>
        <Link href="/imports">View XML imports →</Link>
      </p>

      <meta httpEquiv="refresh" content="5" />

      <div style={{ overflowX: 'auto', marginTop: 16 }}>
        <table style={{ borderCollapse: 'collapse', minWidth: 900, width: '100%' }}>
          <thead>
            <tr>
              {['Scan ID', 'Project', 'Requested By', 'Status', 'Created', 'Updated'].map((h) => (
                <th
                  key={h}
                  style={{ textAlign: 'left', borderBottom: '1px solid #ddd', padding: '8px 10px' }}
                >
                  {h}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {scans.length === 0 ? (
              <tr>
                <td colSpan={6} style={{ padding: '12px 10px', color: '#666' }}>
                  No scans yet. Queue one via API and this list will populate.
                </td>
              </tr>
            ) : (
              scans.map((s) => (
                <tr key={s.id}>
                  <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px', fontFamily: 'monospace' }}>
                    <Link href={`/scans/${s.id}`}>{s.id}</Link>
                  </td>
                  <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>{s.projectId}</td>
                  <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>{s.requestedBy}</td>
                  <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px', textTransform: 'uppercase' }}>
                    {s.status}
                  </td>
                  <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>
                    {new Date(s.createdAt).toLocaleString()}
                  </td>
                  <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>
                    {new Date(s.updatedAt).toLocaleString()}
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </main>
  );
}
