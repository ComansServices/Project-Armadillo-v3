import Link from 'next/link';
import { AppShell } from '../_components/app-shell';

type Summary = {
  totals: { assets: number; imports: number; scans: number; vulnsWindow: number };
  severity: { critical: number; high: number; medium: number; low: number };
  topServices: Array<{ label: string; count: number }>;
  topPorts: Array<{ label: string; count: number }>;
  topOs: Array<{ label: string; count: number }>;
  trend: Array<{ date: string; count: number }>;
  windowDays: number;
  importId: string | null;
};

const baseUrl = process.env.API_BASE_URL ?? process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://localhost:4000';
const publicApiBaseUrl = process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://localhost:4000';
const authHeaders = {
  'x-armadillo-user': process.env.WEB_ACTOR_ID ?? 'web-ui',
  'x-armadillo-role': process.env.WEB_ACTOR_ROLE ?? 'viewer',
  ...(process.env.ARMADILLO_AUTH_TOKEN ? { 'x-armadillo-auth': process.env.ARMADILLO_AUTH_TOKEN } : {})
};

async function getSummary(days: number, importId?: string): Promise<Summary> {
  const qs = new URLSearchParams();
  qs.set('days', String(days));
  if (importId) qs.set('importId', importId);
  const res = await fetch(`${baseUrl}/api/v1/dashboard/summary?${qs.toString()}`, { cache: 'no-store', headers: authHeaders });
  if (!res.ok) throw new Error(`Failed to fetch dashboard summary (${res.status})`);
  return (await res.json()) as Summary;
}

function MiniBars({ title, rows, color }: { title: string; rows: Array<{ label: string; count: number }>; color: string }) {
  const max = Math.max(1, ...rows.map((r) => r.count));
  return (
    <section style={{ border: '1px solid #ddd', borderRadius: 10, padding: 12, background: '#fff' }}>
      <h3 style={{ margin: '0 0 8px 0' }}>{title}</h3>
      <svg width="100%" height={Math.max(90, rows.length * 24 + 20)} viewBox={`0 0 420 ${Math.max(90, rows.length * 24 + 20)}`} preserveAspectRatio="xMinYMin meet">
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

function TrendSparkline({ rows }: { rows: Array<{ date: string; count: number }> }) {
  const max = Math.max(1, ...rows.map((r) => r.count));
  const width = 680;
  const height = 120;
  const xStep = rows.length > 1 ? (width - 30) / (rows.length - 1) : 0;

  const points = rows
    .map((r, i) => {
      const x = 15 + i * xStep;
      const y = 95 - (r.count / max) * 75;
      return `${x},${y}`;
    })
    .join(' ');

  return (
    <section style={{ border: '1px solid #ddd', borderRadius: 10, padding: 12, background: '#fff', marginBottom: 12 }}>
      <h3 style={{ margin: '0 0 8px 0' }}>Vulnerability trend</h3>
      <svg width="100%" height={height} viewBox={`0 0 ${width} ${height}`} preserveAspectRatio="xMinYMin meet">
        <line x1={10} y1={95} x2={width - 10} y2={95} stroke="#cbd5e1" />
        <polyline fill="none" stroke="#2563eb" strokeWidth={2.2} points={points} />
        {rows.map((r, i) => {
          const x = 15 + i * xStep;
          const y = 95 - (r.count / max) * 75;
          return <circle key={`${r.date}-${i}`} cx={x} cy={y} r={2.8} fill="#1d4ed8" />;
        })}
      </svg>
      <p style={{ marginTop: 6, color: '#475569', fontSize: 12 }}>Window: last {rows.length} day(s)</p>
    </section>
  );
}

export const dynamic = 'force-dynamic';
export const revalidate = 0;

export default async function DashboardPage({ searchParams }: { searchParams?: Promise<Record<string, string | string[] | undefined>> }) {
  const params = searchParams ? await searchParams : undefined;
  const days = Number(typeof params?.days === 'string' ? params.days : '14') || 14;
  const importId = typeof params?.importId === 'string' ? params.importId : '';
  const safeDays = Math.min(Math.max(days, 1), 90);

  const data = await getSummary(safeDays, importId || undefined);

  return (
    <AppShell
      title="Dashboard"
      purpose="Monitor high-level security and scan trends at a glance."
      whenToUse="Use this page when you need rapid KPI context before deep triage."
      firstAction="Set your date window and optional import scope, then review severity and trend cards."
    >
      <form method="get" style={{ display: 'flex', gap: 8, alignItems: 'center', marginBottom: 16, flexWrap: 'wrap' }}>
        <label>Window days</label>
        <input name="days" defaultValue={String(safeDays)} style={{ width: 90 }} />
        <input name="importId" placeholder="Filter import ID (optional)" defaultValue={importId} style={{ minWidth: 220, width: 'min(100%, 320px)' }} />
        <button type="submit">Apply</button>
        <a href={`${publicApiBaseUrl}/api/v1/dashboard/summary?days=${safeDays}${importId ? `&importId=${encodeURIComponent(importId)}` : ''}`} target="_blank" rel="noreferrer">Export JSON</a>
        <a href={`${publicApiBaseUrl}/api/v1/dashboard/summary?days=${safeDays}${importId ? `&importId=${encodeURIComponent(importId)}` : ''}&format=csv`} target="_blank" rel="noreferrer">Export CSV</a>
      </form>

      <TrendSparkline rows={data.trend} />
      {data.importId ? <p style={{ marginTop: 0, color: '#334155' }}>Scoped to import: <code>{data.importId}</code></p> : null}

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

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: 12 }}>
        <MiniBars title="Top services" rows={data.topServices} color="#2563eb" />
        <MiniBars title="Top ports" rows={data.topPorts} color="#0f766e" />
        <MiniBars title="Top OS" rows={data.topOs} color="#7c3aed" />
      </div>
    </AppShell>
  );
}
