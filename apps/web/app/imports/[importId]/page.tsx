import { revalidatePath } from 'next/cache';
import Link from 'next/link';
import { redirect } from 'next/navigation';

type ImportOption = { id: string; createdAt: string; source: string | null; requestedBy: string };

type XmlImportDetail = {
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
  annotations?: { labels?: string[]; notes?: string } | null;
  qualitySummary: {
    parsedObjects: number;
    normalizedAssetCount: number;
    skippedAssetCount: number;
    invalidAssetCount: number;
    reasonBuckets: Record<string, number>;
  } | null;
  rejectArtifact: {
    rejected: Array<{ reason: string; node: unknown }>;
    rejectedCount: number;
  } | null;
  payload: unknown;
  createdAt: string;
};

const baseUrl = process.env.API_BASE_URL ?? process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://localhost:4000';
const publicApiBaseUrl = process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://localhost:4000';

const authHeaders = {
  'x-armadillo-user': process.env.WEB_ACTOR_ID ?? 'web-ui',
  'x-armadillo-role': process.env.WEB_ACTOR_ROLE ?? 'viewer'
};

const editHeaders = {
  'x-armadillo-user': process.env.WEB_ADMIN_ACTOR_ID ?? process.env.WEB_ACTOR_ID ?? 'web-admin',
  'x-armadillo-role': process.env.WEB_ADMIN_ACTOR_ROLE ?? process.env.WEB_ACTOR_ROLE ?? 'viewer'
};

async function getImport(importId: string): Promise<XmlImportDetail> {
  const res = await fetch(`${baseUrl}/api/v1/imports/${importId}`, {
    cache: 'no-store',
    headers: authHeaders
  });

  if (!res.ok) {
    throw new Error(`Failed to fetch import (${res.status})`);
  }

  return res.json();
}

async function getImportDiff(importId: string, againstImportId: string) {
  const res = await fetch(`${baseUrl}/api/v1/imports/${importId}/diff?againstImportId=${againstImportId}`, {
    cache: 'no-store',
    headers: authHeaders
  });
  if (!res.ok) return null;
  return res.json();
}

async function getRecentImports(): Promise<ImportOption[]> {
  const res = await fetch(`${baseUrl}/api/v1/imports?limit=50`, {
    cache: 'no-store',
    headers: authHeaders
  });
  if (!res.ok) return [];
  const data = (await res.json()) as { imports?: ImportOption[] };
  return data.imports ?? [];
}

async function saveImportAnnotationsAction(formData: FormData) {
  'use server';
  const importId = String(formData.get('importId') ?? '').trim();
  if (!importId) return;

  const labels = String(formData.get('labels') ?? '')
    .split(',')
    .map((v) => v.trim())
    .filter(Boolean);
  const notes = String(formData.get('notes') ?? '').trim();

  const res = await fetch(`${baseUrl}/api/v1/imports/${importId}/annotations`, {
    method: 'POST',
    headers: {
      ...editHeaders,
      'content-type': 'application/json'
    },
    body: JSON.stringify({ labels, notes })
  });

  revalidatePath(`/imports/${importId}`);
  if (!res.ok) redirect(`/imports/${importId}?saveError=${res.status}`);
  redirect(`/imports/${importId}?saved=1`);
}

export const dynamic = 'force-dynamic';
export const revalidate = 0;

export default async function ImportDetailPage({
  params,
  searchParams
}: {
  params: { importId: string };
  searchParams?: Promise<Record<string, string | string[] | undefined>>;
}) {
  const qp = searchParams ? await searchParams : undefined;
  const againstImportId = typeof qp?.againstImportId === 'string' ? qp.againstImportId : '';
  const saved = qp?.saved === '1';
  const saveError = typeof qp?.saveError === 'string' ? qp.saveError : null;
  const canEdit = ['owner', 'admin', 'staff'].includes(
    (process.env.WEB_ADMIN_ACTOR_ROLE ?? process.env.WEB_ACTOR_ROLE ?? 'viewer').toLowerCase()
  );

  const [data, importOptions] = await Promise.all([getImport(params.importId), getRecentImports()]);
  const baselineOptions = importOptions.filter((opt) => opt.id !== data.id);
  const latestBaseline = baselineOptions[0]?.id;
  const effectiveAgainstImportId = againstImportId || latestBaseline || '';
  const diff = effectiveAgainstImportId ? await getImportDiff(params.importId, effectiveAgainstImportId) : null;
  const labels = (data.annotations?.labels ?? []).join(', ');
  const notes = data.annotations?.notes ?? '';

  return (
    <main style={{ padding: 24, fontFamily: 'system-ui' }}>
      <p style={{ marginBottom: 12 }}>
        <Link href="/imports">← Back to imports</Link>
      </p>
      <h1 style={{ marginBottom: 6 }}>Import Detail</h1>
      <p style={{ marginTop: 0, color: '#444' }}>{data.id}</p>

      <div style={{ marginTop: 12, marginBottom: 20 }}>
        <strong>Source:</strong> {data.source ?? '-'} &nbsp; | &nbsp;
        <strong>Requested By:</strong> {data.requestedBy} &nbsp; | &nbsp;
        <strong>Root Node:</strong> {data.rootNode ?? '-'} &nbsp; | &nbsp;
        <strong>Items:</strong> {data.itemCount}
      </div>

      <h2 style={{ marginBottom: 8 }}>Annotations</h2>
      {saved ? <p style={{ color: '#0b7d29' }}>Annotations saved.</p> : null}
      {saveError ? <p style={{ color: '#a61b1b' }}>Annotation save failed (HTTP {saveError}).</p> : null}
      {!canEdit ? <p style={{ color: '#666' }}>Annotations are read-only for current web actor role.</p> : null}
      <form action={canEdit ? saveImportAnnotationsAction : undefined} style={{ display: 'grid', gap: 8, marginBottom: 16, maxWidth: 900 }}>
        <input type="hidden" name="importId" value={data.id} />
        <label>
          Labels (comma separated)
          <input name="labels" defaultValue={labels} style={{ width: '100%' }} disabled={!canEdit} />
        </label>
        <label>
          Notes
          <textarea name="notes" defaultValue={notes} rows={4} style={{ width: '100%' }} disabled={!canEdit} />
        </label>
        <div>
          <button type="submit" disabled={!canEdit}>Save annotations</button>
        </div>
      </form>

      <h2 style={{ marginBottom: 8 }}>Import Diff</h2>
      <form method="get" style={{ display: 'flex', gap: 8, marginBottom: 12, alignItems: 'center', flexWrap: 'wrap' }}>
        <select name="againstImportId" defaultValue={effectiveAgainstImportId} style={{ minWidth: 520 }}>
          <option value="">Select baseline import…</option>
          {baselineOptions.map((opt) => (
            <option key={opt.id} value={opt.id}>
              {new Date(opt.createdAt).toLocaleString()} · {opt.source ?? '-'} · {opt.requestedBy} · {opt.id}
            </option>
          ))}
        </select>
        <button type="submit">Compare</button>
        {latestBaseline ? <a href={`/imports/${data.id}?againstImportId=${latestBaseline}`}>Compare latest previous</a> : null}
        {effectiveAgainstImportId ? (
          <>
            <a href={`${publicApiBaseUrl}/api/v1/imports/${data.id}/diff?againstImportId=${effectiveAgainstImportId}`}>Export JSON</a>
            <a href={`${publicApiBaseUrl}/api/v1/imports/${data.id}/diff?againstImportId=${effectiveAgainstImportId}&format=csv`}>Export CSV</a>
          </>
        ) : null}
      </form>
      {diff ? (
        <div style={{ border: '1px solid #ddd', borderRadius: 8, padding: 12, marginBottom: 16, background: '#fafafa' }}>
          <p style={{ marginTop: 0 }}>
            <strong>Current/Baseline:</strong> {diff.summary.currentAssets}/{diff.summary.baselineAssets} &nbsp; | &nbsp;
            <strong>Added:</strong> {diff.summary.added} &nbsp; | &nbsp;
            <strong>Removed:</strong> {diff.summary.removed} &nbsp; | &nbsp;
            <strong>Changed:</strong> {diff.summary.changed}
          </p>
          <p style={{ marginBottom: 6 }}>
            <strong>Sample added:</strong> {(diff.samples.added ?? []).slice(0, 5).join(', ') || '-'}
          </p>
          <p style={{ margin: '0 0 6px 0' }}>
            <strong>Sample removed:</strong> {(diff.samples.removed ?? []).slice(0, 5).join(', ') || '-'}
          </p>
          <p style={{ marginBottom: 0 }}>
            <strong>Sample changed:</strong> {(diff.samples.changed ?? []).slice(0, 5).join(', ') || '-'}
          </p>
        </div>
      ) : null}

      <h2 style={{ marginBottom: 8 }}>Import Quality Summary</h2>
      <div
        style={{
          border: '1px solid #ddd',
          borderRadius: 8,
          padding: 12,
          marginBottom: 16,
          background: '#fafafa'
        }}
      >
        <p style={{ margin: '4px 0' }}>
          <strong>Mode:</strong> {data.qualityMode.toUpperCase()} &nbsp; | &nbsp;
          <strong>Status:</strong> {data.qualityStatus.toUpperCase()} {data.alertTriggered ? '⚠️' : ''} &nbsp; | &nbsp;
          <strong>Normalized:</strong> {data.normalizedAssetCount} &nbsp; | &nbsp;
          <strong>Skipped:</strong> {data.skippedAssetCount} &nbsp; | &nbsp;
          <strong>Invalid:</strong> {data.invalidAssetCount}
        </p>
        {data.qualitySummary?.reasonBuckets && Object.keys(data.qualitySummary.reasonBuckets).length > 0 ? (
          <ul style={{ margin: '8px 0 0 18px' }}>
            {Object.entries(data.qualitySummary.reasonBuckets).map(([k, v]) => (
              <li key={k}>
                {k}: {v}
              </li>
            ))}
          </ul>
        ) : (
          <p style={{ margin: '8px 0 0 0', color: '#666' }}>No quality issues detected.</p>
        )}
      </div>

      {data.rejectArtifact?.rejectedCount ? (
        <>
          <h2 style={{ marginBottom: 8 }}>Reject Artifact (sample)</h2>
          <pre
            style={{
              background: '#1a0f0f',
              color: '#ffdede',
              padding: 14,
              borderRadius: 8,
              overflowX: 'auto',
              fontSize: 12,
              lineHeight: 1.4,
              marginBottom: 16
            }}
          >
            {JSON.stringify(data.rejectArtifact, null, 2)}
          </pre>
        </>
      ) : null}

      <h2 style={{ marginBottom: 8 }}>Parsed Payload</h2>
      <pre
        style={{
          background: '#111',
          color: '#f4f4f4',
          padding: 14,
          borderRadius: 8,
          overflowX: 'auto',
          fontSize: 12,
          lineHeight: 1.4
        }}
      >
        {JSON.stringify(data.payload, null, 2)}
      </pre>
    </main>
  );
}
