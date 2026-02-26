import { revalidatePath } from 'next/cache';
import Link from 'next/link';
import { ActionButtons, AppShell } from '../_components/app-shell';
import { redirect } from 'next/navigation';

type XmlImportRecord = {
  id: string;
  source: string | null;
  requestedBy: string;
  rootNode: string | null;
  itemCount: number;
  qualityMode: 'lenient' | 'strict';
  qualityStatus: 'pass' | 'warn' | 'fail';
  alertTriggered: boolean;
  normalizedAssetCount: number;
  skippedAssetCount: number;
  invalidAssetCount: number;
  createdAt: string;
};

type ImportTrendPoint = {
  id: string;
  createdAt: string;
  qualityStatus: 'pass' | 'warn' | 'fail';
  normalizedAssetCount: number;
  skippedAssetCount: number;
  invalidAssetCount: number;
};

type ImportPolicy = {
  source: string;
  enabled: boolean;
  defaultQualityMode: 'lenient' | 'strict';
  allowBypassToLenient: boolean;
};

const baseUrl = process.env.API_BASE_URL ?? process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://localhost:4000';
const publicApiBaseUrl = process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://localhost:4000';

const authHeaders = {
  'x-armadillo-user': process.env.WEB_ACTOR_ID ?? 'web-ui',
  'x-armadillo-role': process.env.WEB_ACTOR_ROLE ?? 'viewer',
  ...(process.env.ARMADILLO_AUTH_TOKEN ? { 'x-armadillo-auth': process.env.ARMADILLO_AUTH_TOKEN } : {})
};

const adminHeaders = {
  'x-armadillo-user': process.env.WEB_ADMIN_ACTOR_ID ?? process.env.WEB_ACTOR_ID ?? 'web-admin',
  'x-armadillo-role': process.env.WEB_ADMIN_ACTOR_ROLE ?? 'admin',
  ...(process.env.ARMADILLO_AUTH_TOKEN ? { 'x-armadillo-auth': process.env.ARMADILLO_AUTH_TOKEN } : {})
};

async function getImports(): Promise<XmlImportRecord[]> {
  const res = await fetch(`${baseUrl}/api/v1/imports?limit=50`, { cache: 'no-store', headers: authHeaders });
  if (!res.ok) throw new Error(`Failed to fetch imports (${res.status})`);
  const data = (await res.json()) as { imports: XmlImportRecord[] };
  return data.imports ?? [];
}

async function getTrend(): Promise<ImportTrendPoint[]> {
  const res = await fetch(`${baseUrl}/api/v1/imports/quality-trend?limit=10`, { cache: 'no-store', headers: authHeaders });
  if (!res.ok) throw new Error(`Failed to fetch trend (${res.status})`);
  const data = (await res.json()) as { trend: ImportTrendPoint[] };
  return data.trend ?? [];
}

async function getPolicies(): Promise<ImportPolicy[]> {
  const res = await fetch(`${baseUrl}/api/v1/import-policies`, { cache: 'no-store', headers: authHeaders });
  if (!res.ok) return [];
  const data = (await res.json()) as { policies: ImportPolicy[] };
  return data.policies ?? [];
}

async function savePolicyAction(formData: FormData) {
  'use server';
  const source = String(formData.get('source') ?? '').trim();
  const defaultQualityMode = String(formData.get('defaultQualityMode') ?? 'strict') as 'lenient' | 'strict';
  const enabled = String(formData.get('enabled') ?? 'false') === 'true';
  const allowBypassToLenient = String(formData.get('allowBypassToLenient') ?? 'false') === 'true';
  if (!source) return;

  const res = await fetch(`${baseUrl}/api/v1/import-policies`, {
    method: 'POST',
    headers: { ...adminHeaders, 'content-type': 'application/json' },
    body: JSON.stringify({ source, enabled, defaultQualityMode, allowBypassToLenient })
  });

  revalidatePath('/imports');
  if (!res.ok) redirect(`/imports?policyError=${res.status}`);
  redirect('/imports?policySaved=1');
}

export const dynamic = 'force-dynamic';
export const revalidate = 0;

export default async function ImportsPage({
  searchParams
}: {
  searchParams?: Promise<Record<string, string | string[] | undefined>>;
}) {
  const params = searchParams ? await searchParams : undefined;
  const policySaved = params?.policySaved === '1';
  const policyError = typeof params?.policyError === 'string' ? params.policyError : null;
  const canEditPolicies = ['admin', 'owner'].includes(
    (process.env.WEB_ADMIN_ACTOR_ROLE ?? process.env.WEB_ACTOR_ROLE ?? 'viewer').toLowerCase()
  );

  const [imports, trend, policies] = await Promise.all([getImports(), getTrend(), getPolicies()]);

  return (
    <AppShell
      title="XML Imports"
      purpose="Ingest and quality-check source XML payloads before downstream analysis."
      whenToUse="Use this page when onboarding new scan data or checking source policy enforcement."
      firstAction="Review quality status, then open assets or vulnerability triage for the target import."
    >
      <ActionButtons
        actions={[
          { href: '/assets', label: 'Open Assets', primary: true },
          { href: '/vulns', label: 'Open Vulnerabilities' },
          { href: `${publicApiBaseUrl}/api/v1/imports.csv?limit=500`, label: 'Export CSV' }
        ]}
      />

      <h2 style={{ marginTop: 20, marginBottom: 8 }}>Import Source Policies</h2>
      {policySaved ? <p style={{ marginTop: 0, color: '#0b7d29' }}>Policy saved successfully.</p> : null}
      {policyError ? <p style={{ marginTop: 0, color: '#a61b1b' }}>Policy save failed (HTTP {policyError}).</p> : null}
      {!canEditPolicies ? <p style={{ marginTop: 0, color: '#666' }}>Policy editor is read-only for current web actor role.</p> : null}

      <div style={{ marginBottom: 18, display: 'grid', gap: 8 }}>
        {policies.length === 0 ? (
          <p style={{ color: '#666', margin: 0 }}>No policies visible (viewer mode or none configured).</p>
        ) : (
          policies.map((p) => (
            <form key={p.source} action={canEditPolicies ? savePolicyAction : undefined} style={{ display: 'flex', gap: 8, alignItems: 'center', border: '1px solid #eee', borderRadius: 8, padding: 10, flexWrap: 'wrap' }}>
              <input name="source" value={p.source} readOnly style={{ minWidth: 140 }} />
              <select name="enabled" defaultValue={String(p.enabled)} disabled={!canEditPolicies}><option value="true">enabled</option><option value="false">disabled</option></select>
              <select name="defaultQualityMode" defaultValue={p.defaultQualityMode} disabled={!canEditPolicies}><option value="strict">strict</option><option value="lenient">lenient</option></select>
              <select name="allowBypassToLenient" defaultValue={String(p.allowBypassToLenient)} disabled={!canEditPolicies}><option value="false">bypass blocked</option><option value="true">bypass allowed</option></select>
              <button type="submit" disabled={!canEditPolicies}>Save</button>
            </form>
          ))
        )}
      </div>

      <h2 style={{ marginTop: 20, marginBottom: 8 }}>Quality Trend (last 10 imports)</h2>
      <div style={{ overflowX: 'auto', marginBottom: 18 }}>
        <table style={{ borderCollapse: 'collapse', minWidth: 700, width: '100%' }}>
          <thead><tr>{['When', 'Status', 'Normalized', 'Skipped', 'Invalid'].map((h) => <th key={h} style={{ textAlign: 'left', borderBottom: '1px solid #ddd', padding: '8px 10px' }}>{h}</th>)}</tr></thead>
          <tbody>
            {trend.length === 0 ? <tr><td colSpan={5} style={{ padding: '12px 10px', color: '#666' }}>No trend points yet.</td></tr> : trend.map((t) => (
              <tr key={t.id}>
                <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>{new Date(t.createdAt).toLocaleString()}</td>
                <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px', textTransform: 'uppercase' }}>{t.qualityStatus}</td>
                <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>{t.normalizedAssetCount}</td>
                <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>{t.skippedAssetCount}</td>
                <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>{t.invalidAssetCount}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div className="desktop-table" style={{ overflowX: 'auto', marginTop: 10 }}>
        <table style={{ borderCollapse: 'collapse', minWidth: 1100, width: '100%' }}>
          <thead><tr>{['Import ID', 'Source', 'Status', 'Normalized', 'Skipped', 'Invalid', 'Created', 'Actions'].map((h) => <th key={h} style={{ textAlign: 'left', borderBottom: '1px solid #ddd', padding: '8px 10px' }}>{h}</th>)}</tr></thead>
          <tbody>
            {imports.length === 0 ? <tr><td colSpan={8} style={{ padding: '12px 10px', color: '#666' }}>No imports yet.</td></tr> : imports.map((i) => (
              <tr key={i.id}>
                <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px', fontFamily: 'monospace' }}>{i.id}</td>
                <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>{i.source ?? '-'}</td>
                <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px', textTransform: 'uppercase' }}>{i.qualityStatus}{i.alertTriggered ? ' ⚠️' : ''}</td>
                <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>{i.normalizedAssetCount}</td>
                <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>{i.skippedAssetCount}</td>
                <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>{i.invalidAssetCount}</td>
                <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>{new Date(i.createdAt).toLocaleString()}</td>
                <td style={{ borderBottom: '1px solid #f0f0f0', padding: '8px 10px' }}>
                  <Link href={`/imports/${i.id}`}>Open</Link>
                  {' · '}
                  <Link href={`/vulns?importId=${encodeURIComponent(i.id)}`}>Vulns</Link>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div className="mobile-cards" style={{ display: 'none', gap: 8, marginTop: 10 }}>
        {imports.length === 0 ? <p style={{ color: '#666' }}>No imports yet.</p> : imports.map((i) => (
          <article key={`card-${i.id}`} style={{ border: '1px solid #ddd', borderRadius: 10, padding: 10, background: '#fff' }}>
            <p style={{ margin: '0 0 5px 0', fontFamily: 'monospace', fontSize: 12 }}>{i.id}</p>
            <p style={{ margin: '0 0 5px 0' }}><strong>Status:</strong> {i.qualityStatus.toUpperCase()}{i.alertTriggered ? ' ⚠️' : ''}</p>
            <p style={{ margin: '0 0 5px 0' }}><strong>Source:</strong> {i.source ?? '-'}</p>
            <p style={{ margin: '0 0 8px 0' }}><strong>Normalized/Skipped/Invalid:</strong> {i.normalizedAssetCount}/{i.skippedAssetCount}/{i.invalidAssetCount}</p>
            <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap' }}>
              <Link href={`/imports/${i.id}`}>Open import</Link>
              <Link href={`/vulns?importId=${encodeURIComponent(i.id)}`}>Open vulns</Link>
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
