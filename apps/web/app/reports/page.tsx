import Link from 'next/link';
import { AppShell } from '../_components/app-shell';

type ReportItem = {
  kind: 'import' | 'scan';
  refId: string;
  audience: 'ops' | 'exec';
  requestedBy: string;
  createdAt: string;
  file: string;
};

const baseUrl = process.env.API_BASE_URL ?? process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://localhost:4000';
const authHeaders = {
  'x-armadillo-user': process.env.WEB_ACTOR_ID ?? 'web-ui',
  'x-armadillo-role': process.env.WEB_ACTOR_ROLE ?? 'viewer',
  ...(process.env.ARMADILLO_AUTH_TOKEN ? { 'x-armadillo-auth': process.env.ARMADILLO_AUTH_TOKEN } : {})
};

async function getReports(): Promise<ReportItem[]> {
  const res = await fetch(`${baseUrl}/api/v1/reports`, { cache: 'no-store', headers: authHeaders });
  if (!res.ok) throw new Error(`Failed to fetch reports (${res.status})`);
  const data = (await res.json()) as { reports: ReportItem[] };
  return data.reports ?? [];
}

export const dynamic = 'force-dynamic';
export const revalidate = 0;

export default async function ReportsPage() {
  const reports = await getReports();

  return (
    <AppShell
      title="Report Archive"
      purpose="Access generated operational and executive PDFs for distribution."
      whenToUse="Use this page after scan/import milestones when sharing formal outputs."
      firstAction="Choose the latest report row and open PDF in a new tab."
    >
      <p style={{ marginTop: 0 }}>Archived PDF reports generated with archive mode.</p>

      <div style={{ overflowX: 'auto', marginTop: 16 }}>
        <table style={{ borderCollapse: 'collapse', minWidth: 900, width: '100%' }}>
          <thead>
            <tr>
              {['Created', 'Kind', 'Audience', 'Reference', 'Requested By', 'Open'].map((h) => (
                <th key={h} style={{ textAlign: 'left', borderBottom: '1px solid #ddd', padding: '8px 10px' }}>
                  {h}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {reports.length === 0 ? (
              <tr>
                <td colSpan={6} style={{ padding: '12px 10px', color: '#666' }}>No archived reports yet.</td>
              </tr>
            ) : (
              reports.map((r) => {
                const url =
                  r.kind === 'import'
                    ? `${baseUrl}/api/v1/reports/imports/${r.refId}.pdf?audience=${r.audience}`
                    : `${baseUrl}/api/v1/reports/scans/${r.refId}.pdf?audience=${r.audience}`;

                return (
                  <tr key={r.file}>
                    <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>{new Date(r.createdAt).toLocaleString()}</td>
                    <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px', textTransform: 'uppercase' }}>{r.kind}</td>
                    <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px', textTransform: 'uppercase' }}>{r.audience}</td>
                    <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px', fontFamily: 'monospace' }}>{r.refId}</td>
                    <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>{r.requestedBy}</td>
                    <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>
                      <a href={url} target="_blank" rel="noreferrer">Open PDF</a>
                    </td>
                  </tr>
                );
              })
            )}
          </tbody>
        </table>
      </div>
    </AppShell>
  );
}
