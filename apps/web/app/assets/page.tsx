import Link from 'next/link';

type AssetRecord = {
  id: string;
  importId: string;
  ip: string | null;
  hostname: string | null;
  createdAt: string;
};

const baseUrl =
  process.env.API_BASE_URL ?? process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://localhost:4000';

const authHeaders = {
  'x-armadillo-user': process.env.WEB_ACTOR_ID ?? 'web-ui',
  'x-armadillo-role': process.env.WEB_ACTOR_ROLE ?? 'viewer'
};

async function getAssets(): Promise<AssetRecord[]> {
  const res = await fetch(`${baseUrl}/api/v1/assets?limit=100`, {
    cache: 'no-store',
    headers: authHeaders
  });

  if (!res.ok) {
    throw new Error(`Failed to fetch assets (${res.status})`);
  }

  const data = (await res.json()) as { assets: AssetRecord[] };
  return data.assets ?? [];
}

export const dynamic = 'force-dynamic';
export const revalidate = 0;

export default async function AssetsPage() {
  const assets = await getAssets();

  return (
    <main style={{ padding: 24, fontFamily: 'system-ui' }}>
      <p style={{ marginBottom: 12 }}>
        <Link href="/imports">← Back to imports</Link>
      </p>
      <h1 style={{ marginBottom: 8 }}>Normalized Assets</h1>
      <p style={{ marginTop: 0 }}>Assets extracted from XML imports (auto-refresh every 5s).</p>

      <meta httpEquiv="refresh" content="5" />

      <div style={{ overflowX: 'auto', marginTop: 16 }}>
        <table style={{ borderCollapse: 'collapse', minWidth: 900, width: '100%' }}>
          <thead>
            <tr>
              {['Asset ID', 'IP', 'Hostname', 'Import ID', 'Created'].map((h) => (
                <th key={h} style={{ textAlign: 'left', borderBottom: '1px solid #ddd', padding: '8px 10px' }}>
                  {h}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {assets.length === 0 ? (
              <tr>
                <td colSpan={5} style={{ padding: '12px 10px', color: '#666' }}>No normalized assets yet.</td>
              </tr>
            ) : (
              assets.map((a) => (
                <tr key={a.id}>
                  <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px', fontFamily: 'monospace' }}>
                    <Link href={`/assets/${a.id}`}>{a.id}</Link>
                  </td>
                  <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>{a.ip ?? '-'}</td>
                  <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>{a.hostname ?? '-'}</td>
                  <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px', fontFamily: 'monospace' }}>
                    <Link href={`/imports/${a.importId}`}>{a.importId}</Link>
                  </td>
                  <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>
                    {new Date(a.createdAt).toLocaleString()}
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
