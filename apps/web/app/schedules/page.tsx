import { revalidatePath } from 'next/cache';
import { AppShell } from '../_components/app-shell';
import { redirect } from 'next/navigation';

type ScanSchedule = {
  id: string;
  name: string;
  enabled: boolean;
  cronExpr: string;
  timezone: string;
  projectId: string;
  requestedBy: string;
  nextRunAt: string | null;
  lastRunAt: string | null;
  lastRunStatus: string | null;
  lastRunMessage: string | null;
  createdAt: string;
};

const baseUrl = process.env.API_BASE_URL ?? process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://localhost:4000';
const authHeaders = {
  'x-armadillo-user': process.env.WEB_ACTOR_ID ?? 'web-ui',
  'x-armadillo-role': process.env.WEB_ACTOR_ROLE ?? 'viewer',
  ...(process.env.ARMADILLO_AUTH_TOKEN ? { 'x-armadillo-auth': process.env.ARMADILLO_AUTH_TOKEN } : {})
};

const writeHeaders = {
  'x-armadillo-user': process.env.WEB_ADMIN_ACTOR_ID ?? process.env.WEB_ACTOR_ID ?? 'web-ui',
  'x-armadillo-role': process.env.WEB_ADMIN_ACTOR_ROLE ?? process.env.WEB_ACTOR_ROLE ?? 'viewer',
  ...(process.env.ARMADILLO_AUTH_TOKEN ? { 'x-armadillo-auth': process.env.ARMADILLO_AUTH_TOKEN } : {})
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
    headers: { ...writeHeaders, 'content-type': 'application/json' },
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
  await fetch(`${baseUrl}/api/v1/scan-schedules/${id}/toggle`, { method: 'POST', headers: writeHeaders });
  revalidatePath('/schedules');
  redirect('/schedules');
}

async function runDueAction() {
  'use server';
  await fetch(`${baseUrl}/api/v1/scan-schedules/run-due`, { method: 'POST', headers: writeHeaders });
  revalidatePath('/schedules');
  redirect('/schedules?ran=1');
}

export const dynamic = 'force-dynamic';
export const revalidate = 0;

export default async function SchedulesPage({ searchParams }: { searchParams?: Promise<Record<string, string | string[] | undefined>> }) {
  const params = searchParams ? await searchParams : undefined;
  const saved = params?.saved === '1';
  const ran = params?.ran === '1';
  const error = typeof params?.error === 'string' ? params.error : null;
  const canEditSchedules = ['staff', 'admin', 'owner'].includes(
    (process.env.WEB_ADMIN_ACTOR_ROLE ?? process.env.WEB_ACTOR_ROLE ?? 'viewer').toLowerCase()
  );
  const schedules = await getSchedules();

  return (
    <AppShell
      title="Scan Schedules"
      purpose="Automate recurring scan execution windows with visibility on run outcomes."
      whenToUse="Use this page when setting routine scanning cadence for projects."
      firstAction="Create a schedule, then monitor next run and latest run status columns."
    >
      {saved ? <p style={{ color: '#0b7d29' }}>Schedule saved.</p> : null}
      {ran ? <p style={{ color: '#0b7d29' }}>Due schedules processed.</p> : null}
      {error ? <p style={{ color: '#a61b1b' }}>Save failed (HTTP {error}).</p> : null}
      {!canEditSchedules ? <p style={{ color: '#666' }}>Schedule editor is read-only for current web actor role.</p> : null}

      <form action={canEditSchedules ? createScheduleAction : undefined} style={{ display: 'grid', gap: 8, maxWidth: 760, marginBottom: 12, gridTemplateColumns: 'repeat(auto-fit,minmax(180px,1fr))' }}>
        <input name="name" placeholder="Schedule name" required disabled={!canEditSchedules} />
        <input name="cronExpr" placeholder="Cron expr (e.g. 0 * * * *)" required disabled={!canEditSchedules} />
        <input name="timezone" defaultValue="Australia/Melbourne" required disabled={!canEditSchedules} />
        <input name="projectId" defaultValue="proj-001" required disabled={!canEditSchedules} />
        <input name="requestedBy" defaultValue="web-ui" required disabled={!canEditSchedules} />
        <input name="target" defaultValue="127.0.0.1" required disabled={!canEditSchedules} />
        <div style={{ gridColumn: '1 / -1', display: 'flex', gap: 8 }}>
          <button type="submit" disabled={!canEditSchedules}>Create schedule</button>
          <button formAction={canEditSchedules ? runDueAction : undefined} type="submit" disabled={!canEditSchedules}>Run due now</button>
        </div>
      </form>

      <div className="desktop-table" style={{ overflowX: 'auto' }}>
        <table style={{ borderCollapse: 'collapse', minWidth: 900, width: '100%' }}>
          <thead>
            <tr>{['Name', 'Cron', 'Project', 'Next Run', 'Last Run', 'Last Status', 'Enabled', 'Action'].map((h) => <th key={h} style={{ textAlign: 'left', borderBottom: '1px solid #ddd', padding: '8px 10px' }}>{h}</th>)}</tr>
          </thead>
          <tbody>
            {schedules.length === 0 ? (
              <tr><td colSpan={8} style={{ padding: '12px 10px', color: '#666' }}>No schedules yet.</td></tr>
            ) : schedules.map((s) => (
              <tr key={s.id}>
                <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>{s.name}</td>
                <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px', fontFamily: 'monospace' }}>{s.cronExpr}</td>
                <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>{s.projectId}</td>
                <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>{s.nextRunAt ? new Date(s.nextRunAt).toLocaleString() : '-'}</td>
                <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>{s.lastRunAt ? new Date(s.lastRunAt).toLocaleString() : '-'}</td>
                <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }} title={s.lastRunMessage ?? ''}>{s.lastRunStatus ?? '-'}</td>
                <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>{s.enabled ? 'yes' : 'no'}</td>
                <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>
                  <form action={canEditSchedules ? toggleScheduleAction : undefined}>
                    <input type="hidden" name="id" value={s.id} />
                    <button type="submit" disabled={!canEditSchedules}>{s.enabled ? 'Disable' : 'Enable'}</button>
                  </form>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div className="mobile-cards" style={{ display: 'none', gap: 8 }}>
        {schedules.length === 0 ? <p style={{ color: '#666' }}>No schedules yet.</p> : schedules.map((s) => (
          <article key={`m-${s.id}`} style={{ border: '1px solid #ddd', borderRadius: 10, padding: 10, background: '#fff' }}>
            <p style={{ margin: '0 0 6px 0' }}><strong>{s.name}</strong></p>
            <p style={{ margin: '0 0 4px 0', fontFamily: 'monospace' }}>{s.cronExpr}</p>
            <p style={{ margin: '0 0 4px 0' }}><strong>Project:</strong> {s.projectId}</p>
            <p style={{ margin: '0 0 4px 0' }}><strong>Next:</strong> {s.nextRunAt ? new Date(s.nextRunAt).toLocaleString() : '-'}</p>
            <p style={{ margin: '0 0 8px 0' }}><strong>Status:</strong> {s.lastRunStatus ?? '-'} ({s.enabled ? 'enabled' : 'disabled'})</p>
            <form action={canEditSchedules ? toggleScheduleAction : undefined}>
              <input type="hidden" name="id" value={s.id} />
              <button type="submit" disabled={!canEditSchedules}>{s.enabled ? 'Disable' : 'Enable'}</button>
            </form>
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
