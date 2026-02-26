import Link from 'next/link';
import { AppShell } from '../_components/app-shell';
import { AssetBadge } from '../_components/asset-badge';

type AssetBadge = { badge: 'new' | 'new_this_week' | 'changed' | null; tooltip?: string };

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
  badge?: AssetBadge;
};

type AssetFilters = { ip?: string; hostname?: string; tag?: string; source?: string };

const baseUrl = process.env.API_BASE_URL ?? process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://localhost:4000';

const authHeaders = {
  'x-armadillo-user': process.env.WEB_ACTOR_ID ?? 'web-ui',
  'x-armadillo-role': process.env.WEB_ACTOR_ROLE ?? 'viewer',
  ...(process.env.ARMADILLO_AUTH_TOKEN ? { 'x-armadillo-auth': process.env.ARMADILLO_AUTH_TOKEN } : {})
};

async function getAssets(filters: AssetFilters): Promise<AssetRecord[]> {
  const qs = new URLSearchParams();
  qs.set('limit', '100');
  qs.set('badges', 'true');
  if (filters.ip) qs.set('ip', filters.ip);
  if (filters.hostname) qs.set('hostname', filters.hostname);
  if (filters.tag) qs.set('tag', filters.tag);
  if (filters.source) qs.set('source', filters.source);

  const res = await fetch(`${baseUrl}/api/v1/assets?${qs.toString()}`, { cache: 'no-store', headers: authHeaders });
  if (!res.ok) throw new Error(`Failed to fetch assets (${res.status})`);
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
    <AppShell
      title="Assets"
      purpose="Inspect normalized host assets and pivot into vulnerability and network triage."
      whenToUse="Use this page after imports to review discovered infrastructure quickly."
      firstAction="Apply a filter (IP, hostname, tag), then open a target asset detail."
    >
      <form method="get" style={{ display: 'grid', gap: 8, gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))' }}>
        <input name="ip" placeholder="Filter IP (e.g. 10.0.0)" defaultValue={filters.ip ?? ''} />
        <input name="hostname" placeholder="Filter hostname" defaultValue={filters.hostname ?? ''} />
        <input name="tag" placeholder="Filter tag (e.g. web)" defaultValue={filters.tag ?? ''} />
        <input name="source" placeholder="Filter source (e.g. xml)" defaultValue={filters.source ?? ''} />
        <div style={{ gridColumn: '1 / -1', display: 'flex', gap: 8, flexWrap: 'wrap' }}>
          <button type="submit">Apply filters</button>
          <Link href="/assets">Reset</Link>
          <Link href="/vulns">Open vulnerabilities</Link>
          <Link href="/network">Open network</Link>
        </div>
      </form>

      <div className="desktop-table" style={{ overflowX: 'auto', marginTop: 16 }}>
        <table style={{ borderCollapse: 'collapse', minWidth: 1100, width: '100%' }}>
          <thead>
            <tr>
              {['Asset', 'Identity Key', 'IP', 'Hostname', 'Ports', 'Tags', 'Seen', 'Last Seen', 'Import', 'Status', 'Actions'].map((h) => (
                <th key={h} style={{ textAlign: 'left', borderBottom: '1px solid #ddd', padding: '8px 10px' }}>{h}</th>
              ))}
            </tr>
          </thead>
          <tbody>
            {assets.length === 0 ? (
              <tr><td colSpan={11} style={{ padding: '12px 10px', color: '#666' }}>No assets matched current filters.</td></tr>
            ) : assets.map((a) => (
              <tr key={a.id}>
                <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px', fontFamily: 'monospace' }}>{a.id}</td>
                <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px', fontFamily: 'monospace' }}>{a.identityKey}</td>
                <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>{a.ip ?? '-'}</td>
                <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>{a.hostname ?? '-'}</td>
                <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>{a.ports?.length ? a.ports.join(', ') : '-'}</td>
                <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>{a.serviceTags?.length ? a.serviceTags.join(', ') : '-'}</td>
                <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>{a.seenCount}</td>
                <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>{new Date(a.lastSeenAt).toLocaleString()}</td>
                <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px', fontFamily: 'monospace' }}>{a.importId}</td>
                <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>
                  {a.badge && <AssetBadge badge={a.badge.badge} tooltip={a.badge.tooltip} />}
                </td>
                <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>
                  <Link href={`/assets/${a.id}`}>Open</Link>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div className="mobile-cards" style={{ display: 'none', gap: 8, marginTop: 12 }}>
        {assets.length === 0 ? <p style={{ color: '#666' }}>No assets matched current filters.</p> : assets.map((a) => (
          <article key={`card-${a.id}`} style={{ border: '1px solid #ddd', borderRadius: 10, padding: 10, background: '#fff' }}>
            <p style={{ margin: '0 0 4px 0', fontFamily: 'monospace', fontSize: 12 }}>{a.identityKey}</p>
            <p style={{ margin: '0 0 4px 0' }}><strong>IP:</strong> {a.ip ?? '-'}</p>
            <p style={{ margin: '0 0 4px 0' }}><strong>Ports:</strong> {a.ports?.length ? a.ports.join(', ') : '-'}</p>
            <p style={{ margin: '0 0 8px 0' }}><strong>Tags:</strong> {a.serviceTags?.length ? a.serviceTags.join(', ') : '-'}</p>
            <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap' }}>
              <Link href={`/assets/${a.id}`}>Open asset</Link>
              <Link href={`/vulns?importId=${encodeURIComponent(a.importId)}`}>View import vulns</Link>
            </div>
          </article>
        ))}
      </div>

      <style>{`
        @media (max-width: 980px) {
          .desktop-table { display: none; }
          .mobile-cards { display: grid !important; }
        }
      `}</style>
    </AppShell>
  );
}
