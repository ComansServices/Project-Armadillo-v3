import Link from 'next/link';

type Summary = {
  totals: { assets: number; imports: number; scans: number; vulnsWindow: number };
  severity: { critical: number; high: number; medium: number; low: number };
  topServices: Array<{ label: string; count: number }>;
  topPorts: Array<{ label: string; count: number }>;
  topOs: Array<{ label: string; count: number }>;
  windowDays: number;
};

const baseUrl = process.env.API_BASE_URL ?? process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://localhost:4000';
const publicApiBaseUrl = process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://localhost:4000';
const authHeaders = {
  'x-armadillo-user': process.env.WEB_ACTOR_ID ?? 'web-ui',
  'x-armadillo-role': process.env.WEB_ACTOR_ROLE ?? 'viewer'
};

async function getSummary(days: number): Promise<Summary> {
  const res = await fetch(`${baseUrl}/api/v1/dashboard/summary?days=${days}`, { cache: 'no-store', headers: authHeaders });
  if (!res.ok) throw new Error(`Failed to fetch dashboard summary (${res.status})`);
  return (await res.json()) as Summary;
}

function MiniBars({ title, rows, color }: { title: string; rows: Array<{ label: string; count: number }>; color: string }) {
  const max = Math.max(1, ...rows.map((r) => r.count));
  return (
    <section style={{ border: '1px solid #ddd', borderRadius: 10, padding: 12, background: '#fff' }}>
      <h3 style={{ margin: '0 0 8px 0' }}>{title}</h3>
      <svg width={420} height={Math.max(90, rows.length * 24 + 20)} viewBox={`0 0 420 ${Math.max(90, rows.length * 24 + 20)}`}>
        {rows.map((r, i) => {
          const y = 20 + i * 24;
          const w = (r.count / max) * 240;
          return (
            <g key={`${title}-${r.label}-${i}`}>
              <text x={0} y={y + 11} fontSize={10} fill="#334155">{r.label}</text>
              <rect x={150} y={y} width={w} height={14} rx={4} fill={color} />
              <text x={150 + w + 6} y={y + 11} fontSize={10} fill="#111827">{r.count}</text>
            </g>
          );
        })}
      </svg>
    </section>
  );
}

export const dynamic = 'force-dynamic';
export const revalidate = 0;

export default async function DashboardPage({ searchParams }: { searchParams?: Promise<Record<string, string | string[] | undefined>> }) {
  const params = searchParams ? await searchParams : undefined;
  const days = Number(typeof params?.days === 'string' ? params.days : '14') || 14;
  const safeDays = Math.min(Math.max(days, 1), 90);

  const data = await getSummary(safeDays);

  return (
    <main style={{ padding: 24, fontFamily: 'system-ui' }}>
      <p style={{ marginBottom: 12 }}><Link href="/">← Back to scans</Link></p>
      <h1 style={{ marginBottom: 8 }}>Dashboard parity</h1>
      <p style={{ marginTop: 0 }}>Item 3: stats + charts + export snapshot.</p>

      <form method="get" style={{ display: 'flex', gap: 8, alignItems: 'center', marginBottom: 16 }}>
        <label>Window days</label>
        <input name="days" defaultValue={String(safeDays)} style={{ width: 90 }} />
        <button type="submit">Apply</button>
        <a href={`${publicApiBaseUrl}/api/v1/dashboard/summary?days=${safeDays}`} target="_blank" rel="noreferrer">Export JSON</a>
        <a href={`${publicApiBaseUrl}/api/v1/dashboard/summary?days=${safeDays}&format=csv`} target="_blank" rel="noreferrer">Export CSV</a>
      </form>

      <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap', marginBottom: 16 }}>
        <div style={{ border: '1px solid #ddd', borderRadius: 8, padding: 10, minWidth: 130 }}><strong>Assets</strong><div>{data.totals.assets}</div></div>
        <div style={{ border: '1px solid #ddd', borderRadius: 8, padding: 10, minWidth: 130 }}><strong>Imports</strong><div>{data.totals.imports}</div></div>
        <div style={{ border: '1px solid #ddd', borderRadius: 8, padding: 10, minWidth: 130 }}><strong>Scans</strong><div>{data.totals.scans}</div></div>
        <div style={{ border: '1px solid #ddd', borderRadius: 8, padding: 10, minWidth: 160 }}><strong>Vulns ({data.windowDays}d)</strong><div>{data.totals.vulnsWindow}</div></div>
      </div>

      <section style={{ border: '1px solid #ddd', borderRadius: 10, padding: 12, marginBottom: 16, background: '#fff' }}>
        <h3 style={{ margin: '0 0 10px 0' }}>Severity split</h3>
        <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
          <div style={{ background: '#7f1d1d', color: '#fff', borderRadius: 8, padding: '8px 12px' }}>Critical: {data.severity.critical}</div>
          <div style={{ background: '#991b1b', color: '#fff', borderRadius: 8, padding: '8px 12px' }}>High: {data.severity.high}</div>
          <div style={{ background: '#92400e', color: '#fff', borderRadius: 8, padding: '8px 12px' }}>Medium: {data.severity.medium}</div>
          <div style={{ background: '#1f2937', color: '#fff', borderRadius: 8, padding: '8px 12px' }}>Low: {data.severity.low}</div>
        </div>
      </section>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(430px, 1fr))', gap: 12 }}>
        <MiniBars title="Top services" rows={data.topServices} color="#2563eb" />
        <MiniBars title="Top ports" rows={data.topPorts} color="#0f766e" />
        <MiniBars title="Top OS" rows={data.topOs} color="#7c3aed" />
      </div>
    </main>
  );
}
