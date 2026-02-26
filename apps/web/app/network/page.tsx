import Link from 'next/link';

type NetworkNode = {
  id: string;
  type: 'asset' | 'port' | 'service';
  label: string;
  meta?: Record<string, unknown>;
};

type NetworkLink = {
  source: string;
  target: string;
  kind: 'has-port' | 'has-service';
};

type NetworkResponse = {
  summary: { assets: number; nodes: number; links: number };
  nodes: NetworkNode[];
  links: NetworkLink[];
};

const baseUrl = process.env.API_BASE_URL ?? process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://localhost:4000';
const authHeaders = {
  'x-armadillo-user': process.env.WEB_ACTOR_ID ?? 'web-ui',
  'x-armadillo-role': process.env.WEB_ACTOR_ROLE ?? 'viewer'
};

async function getNetwork(filters: { importId?: string; subnet?: string; service?: string; port?: string }): Promise<NetworkResponse> {
  const qs = new URLSearchParams();
  if (filters.importId) qs.set('importId', filters.importId);
  if (filters.subnet) qs.set('subnet', filters.subnet);
  if (filters.service) qs.set('service', filters.service);
  if (filters.port) qs.set('port', filters.port);
  qs.set('limit', '400');

  const res = await fetch(`${baseUrl}/api/v1/network?${qs.toString()}`, {
    cache: 'no-store',
    headers: authHeaders
  });
  if (!res.ok) throw new Error(`Failed to fetch network (${res.status})`);
  return (await res.json()) as NetworkResponse;
}

export const dynamic = 'force-dynamic';
export const revalidate = 0;

export default async function NetworkPage({ searchParams }: { searchParams?: Promise<Record<string, string | string[] | undefined>> }) {
  const params = searchParams ? await searchParams : undefined;
  const importId = typeof params?.importId === 'string' ? params.importId : '';
  const subnet = typeof params?.subnet === 'string' ? params.subnet : '';
  const service = typeof params?.service === 'string' ? params.service : '';
  const port = typeof params?.port === 'string' ? params.port : '';

  const data = await getNetwork({
    importId: importId || undefined,
    subnet: subnet || undefined,
    service: service || undefined,
    port: port || undefined
  });

  const assets = data.nodes.filter((n) => n.type === 'asset');
  const portNodes = data.nodes.filter((n) => n.type === 'port');
  const serviceNodes = data.nodes.filter((n) => n.type === 'service');

  const serviceLinkCounts = data.links
    .filter((l) => l.target.startsWith('service:'))
    .reduce<Record<string, number>>((acc, l) => {
      const key = l.target.replace('service:', '');
      acc[key] = (acc[key] ?? 0) + 1;
      return acc;
    }, {});

  return (
    <main style={{ padding: 24, fontFamily: 'system-ui' }}>
      <p style={{ marginBottom: 12 }}>
        <Link href="/">← Back to scans</Link>
      </p>
      <h1 style={{ marginBottom: 8 }}>Network Topology</h1>
      <p style={{ marginTop: 0 }}>Phase 5 Item 2: asset-to-port/service relationship view.</p>

      <form method="get" style={{ display: 'flex', gap: 8, alignItems: 'center', marginBottom: 14, flexWrap: 'wrap' }}>
        <input name="importId" placeholder="Filter import ID" defaultValue={importId} style={{ minWidth: 320 }} />
        <input name="subnet" placeholder="Subnet prefix (e.g. 10.0.0.)" defaultValue={subnet} style={{ minWidth: 220 }} />
        <input name="service" placeholder="Service tag (e.g. ssh)" defaultValue={service} style={{ minWidth: 220 }} />
        <input name="port" placeholder="Port (e.g. 22)" defaultValue={port} style={{ width: 120 }} />
        <button type="submit">Apply</button>
        <Link href="/network">Reset</Link>
      </form>

      <div style={{ display: 'flex', gap: 12, marginBottom: 16, flexWrap: 'wrap' }}>
        <div style={{ border: '1px solid #ddd', borderRadius: 8, padding: 10, minWidth: 130 }}><strong>Assets</strong><div>{data.summary.assets}</div></div>
        <div style={{ border: '1px solid #ddd', borderRadius: 8, padding: 10, minWidth: 130 }}><strong>Ports</strong><div>{portNodes.length}</div></div>
        <div style={{ border: '1px solid #ddd', borderRadius: 8, padding: 10, minWidth: 130 }}><strong>Services</strong><div>{serviceNodes.length}</div></div>
        <div style={{ border: '1px solid #ddd', borderRadius: 8, padding: 10, minWidth: 130 }}><strong>Links</strong><div>{data.summary.links}</div></div>
      </div>

      <h2 style={{ marginBottom: 8 }}>Service groups</h2>
      <div style={{ overflowX: 'auto', marginBottom: 16 }}>
        <table style={{ borderCollapse: 'collapse', minWidth: 560, width: '100%' }}>
          <thead>
            <tr>{['Service', 'Connected assets'].map((h) => <th key={h} style={{ textAlign: 'left', borderBottom: '1px solid #ddd', padding: '8px 10px' }}>{h}</th>)}</tr>
          </thead>
          <tbody>
            {Object.keys(serviceLinkCounts).length === 0 ? (
              <tr><td colSpan={2} style={{ padding: '12px 10px', color: '#666' }}>No service groups in current filter set.</td></tr>
            ) : Object.entries(serviceLinkCounts)
                .sort((a, b) => b[1] - a[1])
                .slice(0, 50)
                .map(([svc, count]) => (
                  <tr key={svc}>
                    <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>{svc}</td>
                    <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>{count}</td>
                  </tr>
                ))}
          </tbody>
        </table>
      </div>

      <h2 style={{ marginBottom: 8 }}>Topology edges</h2>
      <div style={{ overflowX: 'auto', marginBottom: 16 }}>
        <table style={{ borderCollapse: 'collapse', minWidth: 1000, width: '100%' }}>
          <thead>
            <tr>{['Asset', 'Kind', 'Target'].map((h) => <th key={h} style={{ textAlign: 'left', borderBottom: '1px solid #ddd', padding: '8px 10px' }}>{h}</th>)}</tr>
          </thead>
          <tbody>
            {data.links.length === 0 ? (
              <tr><td colSpan={3} style={{ padding: '12px 10px', color: '#666' }}>No edges for current filters.</td></tr>
            ) : data.links.slice(0, 500).map((l, idx) => (
              <tr key={`${l.source}-${l.target}-${idx}`}>
                <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px', fontFamily: 'monospace' }}>{l.source}</td>
                <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>{l.kind}</td>
                <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px', fontFamily: 'monospace' }}>{l.target}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <h2 style={{ marginBottom: 8 }}>Assets</h2>
      <div style={{ overflowX: 'auto' }}>
        <table style={{ borderCollapse: 'collapse', minWidth: 1100, width: '100%' }}>
          <thead>
            <tr>{['Identity', 'Import', 'IP', 'Hostname', 'Ports', 'Services'].map((h) => <th key={h} style={{ textAlign: 'left', borderBottom: '1px solid #ddd', padding: '8px 10px' }}>{h}</th>)}</tr>
          </thead>
          <tbody>
            {assets.length === 0 ? (
              <tr><td colSpan={6} style={{ padding: '12px 10px', color: '#666' }}>No assets for current filters.</td></tr>
            ) : assets.slice(0, 300).map((a) => {
              const meta = a.meta ?? {};
              const ports = Array.isArray(meta.ports) ? meta.ports.join(', ') : '-';
              const tags = Array.isArray(meta.serviceTags) ? meta.serviceTags.join(', ') : '-';
              const importRef = typeof meta.importId === 'string' ? meta.importId : '-';
              const ip = typeof meta.ip === 'string' ? meta.ip : '-';
              const hostname = typeof meta.hostname === 'string' ? meta.hostname : '-';
              const assetId = a.id.replace('asset:', '');

              return (
                <tr key={a.id}>
                  <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}><Link href={`/assets/${assetId}`}>{a.label}</Link></td>
                  <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px', fontFamily: 'monospace' }}>{importRef}</td>
                  <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>{ip}</td>
                  <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>{hostname}</td>
                  <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>{ports || '-'}</td>
                  <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>{tags || '-'}</td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </main>
  );
}
