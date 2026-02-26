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
  'x-armadillo-role': process.env.WEB_ACTOR_ROLE ?? 'viewer',
  ...(process.env.ARMADILLO_AUTH_TOKEN ? { 'x-armadillo-auth': process.env.ARMADILLO_AUTH_TOKEN } : {})
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
  const layout = typeof params?.layout === 'string' ? params.layout : 'service';
  const selectedNode = typeof params?.node === 'string' ? params.node : '';

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

  const assetNodes = assets.slice(0, 18);
  const serviceNodesForGraph = serviceNodes.slice(0, 10);
  const assetPos = new Map<string, { x: number; y: number }>();
  const servicePos = new Map<string, { x: number; y: number }>();

  assetNodes.forEach((a, i) => {
    const row = Math.floor(i / 6);
    const col = i % 6;
    assetPos.set(a.id, { x: 130 + col * 140, y: 90 + row * 95 });
  });

  serviceNodesForGraph.forEach((s, i) => {
    servicePos.set(s.id, { x: 70 + i * 120, y: 28 });
  });

  const graphLinks = data.links
    .filter((l) => l.kind === 'has-service' && assetPos.has(l.source) && servicePos.has(l.target))
    .slice(0, 80);

  const selected = data.nodes.find((n) => n.id === selectedNode);
  const selectedMeta = (selected?.meta ?? {}) as Record<string, unknown>;

  const subnetGroups = assets.reduce<Record<string, typeof assets>>((acc, a) => {
    const ip = typeof a.meta?.ip === 'string' ? (a.meta.ip as string) : 'unknown';
    const lane = ip === 'unknown' ? 'unknown' : ip.split('.').slice(0, 3).join('.') + '.x';
    (acc[lane] ||= []).push(a);
    return acc;
  }, {} as Record<string, typeof assets>);

  return (
    <main style={{ padding: 24, fontFamily: 'system-ui' }}>
      <p style={{ marginBottom: 12 }}>
        <Link href="/">← Back to scans</Link>
      </p>
      <h1 style={{ marginBottom: 8 }}>Network Topology</h1>
      <p style={{ marginTop: 0 }}>Phase 5 Item 2: asset-to-port/service relationship view.</p>

      <form method="get" style={{ display: 'flex', gap: 8, alignItems: 'center', marginBottom: 14, flexWrap: 'wrap' }}>
        <input type="hidden" name="layout" value={layout} />
        <input name="importId" placeholder="Filter import ID" defaultValue={importId} style={{ minWidth: 220, width: 'min(100%, 320px)' }} />
        <input name="subnet" placeholder="Subnet prefix (e.g. 10.0.0.)" defaultValue={subnet} style={{ minWidth: 180, width: 'min(100%, 260px)' }} />
        <input name="service" placeholder="Service tag (e.g. ssh)" defaultValue={service} style={{ minWidth: 180, width: 'min(100%, 260px)' }} />
        <input name="port" placeholder="Port (e.g. 22)" defaultValue={port} style={{ width: 120 }} />
        <button type="submit">Apply</button>
        <Link href="/network">Reset</Link>
      </form>

      <div style={{ display: 'flex', gap: 8, marginBottom: 12 }}>
        <Link href={`/network?layout=service&importId=${encodeURIComponent(importId)}&subnet=${encodeURIComponent(subnet)}&service=${encodeURIComponent(service)}&port=${encodeURIComponent(port)}`}>Service-centric layout</Link>
        <span>·</span>
        <Link href={`/network?layout=subnet&importId=${encodeURIComponent(importId)}&subnet=${encodeURIComponent(subnet)}&service=${encodeURIComponent(service)}&port=${encodeURIComponent(port)}`}>Subnet lanes layout</Link>
      </div>

      <div style={{ display: 'flex', gap: 12, marginBottom: 16, flexWrap: 'wrap' }}>
        <div style={{ border: '1px solid #ddd', borderRadius: 8, padding: 10, minWidth: 130 }}><strong>Assets</strong><div>{data.summary.assets}</div></div>
        <div style={{ border: '1px solid #ddd', borderRadius: 8, padding: 10, minWidth: 130 }}><strong>Ports</strong><div>{portNodes.length}</div></div>
        <div style={{ border: '1px solid #ddd', borderRadius: 8, padding: 10, minWidth: 130 }}><strong>Services</strong><div>{serviceNodes.length}</div></div>
        <div style={{ border: '1px solid #ddd', borderRadius: 8, padding: 10, minWidth: 130 }}><strong>Links</strong><div>{data.summary.links}</div></div>
      </div>

      <h2 style={{ marginBottom: 8 }}>{layout === 'subnet' ? 'Subnet lanes view' : 'Service-centric topology'}</h2>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: 12, marginBottom: 16 }}>
        <div style={{ border: '1px solid #cbd5e1', borderRadius: 10, padding: 8, overflowX: 'auto', background: 'linear-gradient(180deg, #f8fafc 0%, #f1f5f9 100%)' }}>
          {layout === 'subnet' ? (
            <div style={{ display: 'grid', gap: 10 }}>
              {Object.entries(subnetGroups).map(([lane, laneAssets]) => (
                <div key={lane} style={{ border: '1px solid #e5e7eb', borderRadius: 8, padding: 10, background: '#fff' }}>
                  <strong>{lane}</strong>
                  <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', marginTop: 8 }}>
                    {laneAssets.map((a) => (
                      <Link key={a.id} href={`/network?layout=${layout}&importId=${encodeURIComponent(importId)}&subnet=${encodeURIComponent(subnet)}&service=${encodeURIComponent(service)}&port=${encodeURIComponent(port)}&node=${encodeURIComponent(a.id)}`} style={{ border: '1px solid #d1d5db', borderRadius: 999, padding: '4px 10px', fontSize: 12 }}>
                        {a.label}
                      </Link>
                    ))}
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <svg width="100%" height={390} viewBox="0 0 920 390" preserveAspectRatio="xMinYMin meet" role="img" aria-label="Network topology mini map">
              <rect x="0" y="0" width="920" height="390" fill="#f8fafc" />

              {graphLinks.map((l, idx) => {
                const a = assetPos.get(l.source)!;
                const s = servicePos.get(l.target)!;
                return <line key={`${l.source}-${l.target}-${idx}`} x1={s.x} y1={s.y + 12} x2={a.x} y2={a.y - 10} stroke="#94a3b8" strokeOpacity={0.55} strokeWidth={1.4} />;
              })}

              {serviceNodesForGraph.map((s) => {
                const p = servicePos.get(s.id)!;
                return (
                  <g key={s.id}>
                    <circle cx={p.x} cy={p.y} r={12} fill="#6d28d9" />
                    <text x={p.x} y={p.y + 4} textAnchor="middle" fontSize="9" fill="#fff">S</text>
                    <text x={p.x} y={p.y + 26} textAnchor="middle" fontSize="9" fill="#334155">{s.label}</text>
                  </g>
                );
              })}

              {assetNodes.map((a) => {
                const p = assetPos.get(a.id)!;
                const short = a.label.length > 18 ? `${a.label.slice(0, 18)}…` : a.label;
                return (
                  <g key={a.id}>
                    <rect x={p.x - 45} y={p.y - 16} width={90} height={32} rx={8} fill="#0284c7" />
                    <text x={p.x} y={p.y + 4} textAnchor="middle" fontSize="9" fill="#fff">A</text>
                    <text x={p.x} y={p.y + 30} textAnchor="middle" fontSize="8.5" fill="#0f172a">{short}</text>
                  </g>
                );
              })}
            </svg>
          )}

          {layout !== 'subnet' ? (
            <div style={{ marginTop: 8, display: 'flex', gap: 8, flexWrap: 'wrap' }}>
              {assetNodes.map((a) => (
                <Link
                  key={a.id}
                  href={`/network?layout=${layout}&importId=${encodeURIComponent(importId)}&subnet=${encodeURIComponent(subnet)}&service=${encodeURIComponent(service)}&port=${encodeURIComponent(port)}&node=${encodeURIComponent(a.id)}`}
                  style={{
                    border: selectedNode === a.id ? '1px solid #0ea5e9' : '1px solid #cbd5e1',
                    background: selectedNode === a.id ? '#e0f2fe' : '#ffffff',
                    borderRadius: 999,
                    padding: '4px 10px',
                    fontSize: 12
                  }}
                >
                  {a.label}
                </Link>
              ))}
            </div>
          ) : null}
        </div>

        <aside style={{ border: '1px solid #cbd5e1', borderRadius: 10, padding: 12, background: '#ffffff', boxShadow: '0 1px 2px rgba(15,23,42,0.05)' }}>
          <h3 style={{ marginTop: 0, marginBottom: 8 }}>Entity panel</h3>
          {!selected ? (
            <p style={{ color: '#666' }}>Select a node using <code>?node=...</code> or click an asset chip in subnet mode.</p>
          ) : (
            <div style={{ fontSize: 13 }}>
              <p><strong>ID:</strong> {selected.id}</p>
              <p><strong>Type:</strong> {selected.type}</p>
              <p><strong>Label:</strong> {selected.label}</p>
              <p><strong>Import:</strong> {String(selectedMeta.importId ?? '-')}</p>
              <p><strong>IP:</strong> {String(selectedMeta.ip ?? '-')}</p>
              <p><strong>Hostname:</strong> {String(selectedMeta.hostname ?? '-')}</p>
              <p><strong>Ports:</strong> {Array.isArray(selectedMeta.ports) ? selectedMeta.ports.join(', ') : '-'}</p>
              <p><strong>Services:</strong> {Array.isArray(selectedMeta.serviceTags) ? selectedMeta.serviceTags.join(', ') : '-'}</p>
            </div>
          )}
        </aside>
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
