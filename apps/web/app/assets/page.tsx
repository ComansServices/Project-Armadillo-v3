import Link from 'next/link';

type AssetRecord = {
  id: string;
  identityKey: string;
  importId: string;
  ip: string | null;
  hostname: string | null;
  os: string | null;
  ports: number[];
  serviceTags: string[];
  sourceType: string;
  seenCount: number;
  firstSeenAt: string;
  lastSeenAt: string;
  createdAt: string;
};

type AssetFilters = {
  ip?: string;
  hostname?: string;
  tag?: string;
  source?: string;
};

const baseUrl =
  process.env.API_BASE_URL ?? process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://localhost:4000';

const authHeaders = {
  'x-armadillo-user': process.env.WEB_ACTOR_ID ?? 'web-ui',
  'x-armadillo-role': process.env.WEB_ACTOR_ROLE ?? 'viewer',
  ...(process.env.ARMADILLO_AUTH_TOKEN ? { 'x-armadillo-auth': process.env.ARMADILLO_AUTH_TOKEN } : {})
};

async function getAssets(filters: AssetFilters): Promise<AssetRecord[]> {
  const qs = new URLSearchParams();
  qs.set('limit', '100');
  if (filters.ip) qs.set('ip', filters.ip);
  if (filters.hostname) qs.set('hostname', filters.hostname);
  if (filters.tag) qs.set('tag', filters.tag);
  if (filters.source) qs.set('source', filters.source);

  const res = await fetch(`${baseUrl}/api/v1/assets?${qs.toString()}`, {
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

export default async function AssetsPage({
  searchParams
}: {
  searchParams: { ip?: string; hostname?: string; tag?: string; source?: string };
}) {
  const filters: AssetFilters = {
    ip: searchParams.ip?.trim() || undefined,
    hostname: searchParams.hostname?.trim() || undefined,
    tag: searchParams.tag?.trim() || undefined,
    source: searchParams.source?.trim() || undefined
  };

  const assets = await getAssets(filters);

  return (
    <main style={{ padding: 24, fontFamily: 'system-ui' }}>
      <p style={{ marginBottom: 12 }}>
        <Link href="/imports">← Back to imports</Link>
      </p>
      <p style={{ marginTop: 0 }}>
        <Link href="/vulns">View vulnerability findings →</Link>
      </p>
      <h1 style={{ marginBottom: 8 }}>Normalized Assets</h1>
      <p style={{ marginTop: 0 }}>Assets extracted from XML imports (manual refresh).</p>

      <form method="get" style={{ display: 'grid', gap: 8, gridTemplateColumns: 'repeat(4, minmax(0,1fr))' }}>
        <input name="ip" placeholder="Filter IP (e.g. 10.0.0)" defaultValue={filters.ip ?? ''} />
        <input name="hostname" placeholder="Filter hostname" defaultValue={filters.hostname ?? ''} />
        <input name="tag" placeholder="Filter tag (e.g. web)" defaultValue={filters.tag ?? ''} />
        <input name="source" placeholder="Filter source (e.g. xml)" defaultValue={filters.source ?? ''} />
        <div style={{ gridColumn: '1 / -1', display: 'flex', gap: 8 }}>
          <button type="submit">Apply filters</button>
          <Link href="/assets">Reset</Link>
        </div>
      </form>


      <div style={{ overflowX: 'auto', marginTop: 16 }}>
        <table style={{ borderCollapse: 'collapse', minWidth: 1100, width: '100%' }}>
          <thead>
            <tr>
              {['Asset ID', 'Identity Key', 'IP', 'Hostname', 'Ports', 'Tags', 'Seen', 'Last Seen', 'Import ID'].map(
                (h) => (
                  <th key={h} style={{ textAlign: 'left', borderBottom: '1px solid #ddd', padding: '8px 10px' }}>
                    {h}
                  </th>
                )
              )}
            </tr>
          </thead>
          <tbody>
            {assets.length === 0 ? (
              <tr>
                <td colSpan={9} style={{ padding: '12px 10px', color: '#666' }}>
                  No assets matched current filters.
                </td>
              </tr>
            ) : (
              assets.map((a) => (
                <tr key={a.id}>
                  <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px', fontFamily: 'monospace' }}>
                    <Link href={`/assets/${a.id}`}>{a.id}</Link>
                  </td>
                  <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px', fontFamily: 'monospace' }}>
                    {a.identityKey}
                  </td>
                  <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>{a.ip ?? '-'}</td>
                  <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>{a.hostname ?? '-'}</td>
                  <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>
                    {a.ports?.length ? a.ports.join(', ') : '-'}
                  </td>
                  <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>
                    {a.serviceTags?.length ? a.serviceTags.join(', ') : '-'}
                  </td>
                  <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>{a.seenCount}</td>
                  <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>
                    {new Date(a.lastSeenAt).toLocaleString()}
                  </td>
                  <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px', fontFamily: 'monospace' }}>
                    <Link href={`/imports/${a.importId}`}>{a.importId}</Link>
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
