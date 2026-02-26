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

const baseUrl =
  process.env.API_BASE_URL ?? process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://localhost:4000';

const authHeaders = {
  'x-armadillo-user': process.env.WEB_ACTOR_ID ?? 'web-ui',
  'x-armadillo-role': process.env.WEB_ACTOR_ROLE ?? 'viewer',
  ...(process.env.ARMADILLO_AUTH_TOKEN ? { 'x-armadillo-auth': process.env.ARMADILLO_AUTH_TOKEN } : {})
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
    <AppShell
      title="Armadillo v3 Overview"
      purpose="Track scan activity and jump quickly into operational workflows."
      whenToUse="Use this as your command centre before moving into imports, vulnerabilities, or reports."
      firstAction="Review the latest scan statuses, then use a quick action button."
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
    </AppShell>
  );
}
