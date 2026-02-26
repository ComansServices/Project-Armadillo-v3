import Link from 'next/link';
import { ActionButtons, AppShell } from './_components/app-shell';

type ScanRecord = {
  id: string;
  projectId: string;
  requestedBy: string;
  status: 'queued' | 'running' | 'completed' | 'failed';
  createdAt: string;
  updatedAt: string;
};

const baseUrl = process.env.API_BASE_URL ?? process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://localhost:4000';

const authHeaders = {
  'x-armadillo-user': process.env.WEB_ACTOR_ID ?? 'web-ui',
  'x-armadillo-role': process.env.WEB_ACTOR_ROLE ?? 'viewer',
  ...(process.env.ARMADILLO_AUTH_TOKEN ? { 'x-armadillo-auth': process.env.ARMADILLO_AUTH_TOKEN } : {})
};

async function getScans(status?: string): Promise<ScanRecord[]> {
  const qs = new URLSearchParams({ limit: '40' });
  const res = await fetch(`${baseUrl}/api/v1/scans?${qs.toString()}`, {
    cache: 'no-store',
    headers: authHeaders
  });
  if (!res.ok) throw new Error(`Failed to fetch scans (${res.status})`);

  const data = (await res.json()) as { scans: ScanRecord[] };
  const rows = data.scans ?? [];
  if (!status || status === 'all') return rows;
  return rows.filter((r) => r.status === status);
}

export const dynamic = 'force-dynamic';
export const revalidate = 0;

export default async function HomePage({
  searchParams
}: {
  searchParams?: Promise<Record<string, string | string[] | undefined>>;
}) {
  const params = searchParams ? await searchParams : undefined;
  const status = typeof params?.status === 'string' ? params.status : 'all';
  const scans = await getScans(status);

  const counts = scans.reduce(
    (acc, s) => {
      acc[s.status] += 1;
      return acc;
    },
    { queued: 0, running: 0, completed: 0, failed: 0 }
  );

  return (
    <AppShell
      title="Armadillo v3 Overview"
      purpose="Track scan activity and jump quickly into operational workflows."
      whenToUse="Use this as your command centre before moving into imports, vulnerabilities, or reports."
      firstAction="Use a status filter, then open a scan or jump via quick actions."
    >
      <ActionButtons
        actions={[
          { href: '/imports', label: 'Open Imports', primary: true },
          { href: '/assets', label: 'Open Assets' },
          { href: '/vulns', label: 'Open Vulnerabilities' },
          { href: '/reports', label: 'Open Reports' },
          { href: '/schedules', label: 'Open Schedules' }
        ]}
      />

      <form method="get" style={{ display: 'flex', gap: 8, alignItems: 'center', flexWrap: 'wrap', marginBottom: 12 }}>
        <label>Status</label>
        <select name="status" defaultValue={status}>
          <option value="all">all</option>
          <option value="queued">queued</option>
          <option value="running">running</option>
          <option value="completed">completed</option>
          <option value="failed">failed</option>
        </select>
        <button type="submit">Apply</button>
        <Link href="/">Reset</Link>
      </form>

      <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', marginBottom: 14 }}>
        <div style={{ border: '1px solid #ddd', borderRadius: 8, padding: 10, minWidth: 110 }}><strong>Queued</strong><div>{counts.queued}</div></div>
        <div style={{ border: '1px solid #ddd', borderRadius: 8, padding: 10, minWidth: 110 }}><strong>Running</strong><div>{counts.running}</div></div>
        <div style={{ border: '1px solid #ddd', borderRadius: 8, padding: 10, minWidth: 110 }}><strong>Completed</strong><div>{counts.completed}</div></div>
        <div style={{ border: '1px solid #ddd', borderRadius: 8, padding: 10, minWidth: 110 }}><strong>Failed</strong><div>{counts.failed}</div></div>
      </div>

      <div className="desktop-table" style={{ overflowX: 'auto', marginTop: 10 }}>
        <table style={{ borderCollapse: 'collapse', minWidth: 900, width: '100%' }}>
          <thead>
            <tr>
              {['Scan ID', 'Project', 'Requested By', 'Status', 'Created', 'Open'].map((h) => (
                <th key={h} style={{ textAlign: 'left', borderBottom: '1px solid #ddd', padding: '8px 10px' }}>{h}</th>
              ))}
            </tr>
          </thead>
          <tbody>
            {scans.length === 0 ? (
              <tr><td colSpan={6} style={{ padding: '12px 10px', color: '#666' }}>No scans matched this filter.</td></tr>
            ) : scans.map((s) => (
              <tr key={s.id}>
                <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px', fontFamily: 'monospace' }}>{s.id}</td>
                <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>{s.projectId}</td>
                <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>{s.requestedBy}</td>
                <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px', textTransform: 'uppercase' }}>{s.status}</td>
                <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>{new Date(s.createdAt).toLocaleString()}</td>
                <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}><Link href={`/scans/${s.id}`}>Open</Link></td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div className="mobile-cards" style={{ display: 'none', gap: 8 }}>
        {scans.length === 0 ? <p style={{ color: '#666' }}>No scans matched this filter.</p> : scans.map((s) => (
          <article key={`card-${s.id}`} style={{ border: '1px solid #ddd', borderRadius: 10, padding: 10, background: '#fff' }}>
            <p style={{ margin: '0 0 6px 0', fontFamily: 'monospace', fontSize: 12 }}>{s.id}</p>
            <p style={{ margin: '0 0 6px 0' }}><strong>Status:</strong> {s.status.toUpperCase()}</p>
            <p style={{ margin: '0 0 6px 0' }}><strong>Project:</strong> {s.projectId}</p>
            <p style={{ margin: '0 0 8px 0', color: '#475569' }}>{new Date(s.createdAt).toLocaleString()}</p>
            <Link href={`/scans/${s.id}`}>Open scan</Link>
          </article>
        ))}
      </div>

      <style>{`
        @media (max-width: 860px) {
          .desktop-table { display: none; }
          .mobile-cards { display: grid !important; }
        }
      `}</style>
    </AppShell>
  );
}
