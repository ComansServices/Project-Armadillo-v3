import { revalidatePath } from 'next/cache';
import Link from 'next/link';
import { redirect } from 'next/navigation';

type ScanSchedule = {
  id: string;
  name: string;
  enabled: boolean;
  cronExpr: string;
  timezone: string;
  projectId: string;
  requestedBy: string;
  createdAt: string;
};

const baseUrl = process.env.API_BASE_URL ?? process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://localhost:4000';
const authHeaders = {
  'x-armadillo-user': process.env.WEB_ACTOR_ID ?? 'web-ui',
  'x-armadillo-role': process.env.WEB_ACTOR_ROLE ?? 'viewer'
};

async function getSchedules(): Promise<ScanSchedule[]> {
  const res = await fetch(`${baseUrl}/api/v1/scan-schedules`, { cache: 'no-store', headers: authHeaders });
  if (!res.ok) throw new Error(`Failed to fetch schedules (${res.status})`);
  const data = (await res.json()) as { schedules: ScanSchedule[] };
  return data.schedules ?? [];
}

async function createScheduleAction(formData: FormData) {
  'use server';
  const payload = {
    name: String(formData.get('name') ?? '').trim(),
    cronExpr: String(formData.get('cronExpr') ?? '').trim(),
    timezone: String(formData.get('timezone') ?? 'Australia/Melbourne').trim(),
    projectId: String(formData.get('projectId') ?? '').trim(),
    requestedBy: String(formData.get('requestedBy') ?? '').trim(),
    targets: [{ type: 'ip', value: String(formData.get('target') ?? '127.0.0.1').trim() }],
    config: { profile: 'safe-default' }
  };

  const res = await fetch(`${baseUrl}/api/v1/scan-schedules`, {
    method: 'POST',
    headers: { ...authHeaders, 'content-type': 'application/json' },
    body: JSON.stringify(payload)
  });

  revalidatePath('/schedules');
  if (!res.ok) redirect(`/schedules?error=${res.status}`);
  redirect('/schedules?saved=1');
}

async function toggleScheduleAction(formData: FormData) {
  'use server';
  const id = String(formData.get('id') ?? '');
  if (!id) return;
  await fetch(`${baseUrl}/api/v1/scan-schedules/${id}/toggle`, {
    method: 'POST',
    headers: authHeaders
  });
  revalidatePath('/schedules');
  redirect('/schedules');
}

export const dynamic = 'force-dynamic';
export const revalidate = 0;

export default async function SchedulesPage({ searchParams }: { searchParams?: Promise<Record<string, string | string[] | undefined>> }) {
  const params = searchParams ? await searchParams : undefined;
  const saved = params?.saved === '1';
  const error = typeof params?.error === 'string' ? params.error : null;
  const schedules = await getSchedules();

  return (
    <main style={{ padding: 24, fontFamily: 'system-ui' }}>
      <p style={{ marginBottom: 12 }}><Link href="/">← Back to scans</Link></p>
      <h1 style={{ marginBottom: 8 }}>Scan Schedules</h1>
      <p style={{ marginTop: 0 }}>Phase 1 parity: create and toggle recurring scan schedules.</p>
      {saved ? <p style={{ color: '#0b7d29' }}>Schedule saved.</p> : null}
      {error ? <p style={{ color: '#a61b1b' }}>Save failed (HTTP {error}).</p> : null}

      <form action={createScheduleAction} style={{ display: 'grid', gap: 8, maxWidth: 720, marginBottom: 20 }}>
        <input name="name" placeholder="Schedule name" required />
        <input name="cronExpr" placeholder="Cron expr (e.g. 0 2 * * *)" required />
        <input name="timezone" defaultValue="Australia/Melbourne" required />
        <input name="projectId" defaultValue="proj-001" required />
        <input name="requestedBy" defaultValue="web-ui" required />
        <input name="target" defaultValue="127.0.0.1" required />
        <button type="submit">Create schedule</button>
      </form>

      <div style={{ overflowX: 'auto' }}>
        <table style={{ borderCollapse: 'collapse', minWidth: 900, width: '100%' }}>
          <thead>
            <tr>{['Name', 'Cron', 'TZ', 'Project', 'RequestedBy', 'Enabled', 'Action'].map((h) => <th key={h} style={{ textAlign: 'left', borderBottom: '1px solid #ddd', padding: '8px 10px' }}>{h}</th>)}</tr>
          </thead>
          <tbody>
            {schedules.length === 0 ? (
              <tr><td colSpan={7} style={{ padding: '12px 10px', color: '#666' }}>No schedules yet.</td></tr>
            ) : schedules.map((s) => (
              <tr key={s.id}>
                <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>{s.name}</td>
                <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px', fontFamily: 'monospace' }}>{s.cronExpr}</td>
                <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>{s.timezone}</td>
                <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>{s.projectId}</td>
                <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>{s.requestedBy}</td>
                <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>{s.enabled ? 'yes' : 'no'}</td>
                <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>
                  <form action={toggleScheduleAction}>
                    <input type="hidden" name="id" value={s.id} />
                    <button type="submit">{s.enabled ? 'Disable' : 'Enable'}</button>
                  </form>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </main>
  );
}
