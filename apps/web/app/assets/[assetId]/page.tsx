import { revalidatePath } from 'next/cache';
import Link from 'next/link';
import { redirect } from 'next/navigation';
import CommandShortcuts from './command-shortcuts';

type AssetDetail = {
  id: string;
  identityKey: string;
  importId: string;
  ip: string | null;
  hostname: string | null;
  seenCount: number;
  firstSeenAt: string;
  lastSeenAt: string;
  annotations?: { labels?: string[]; notes?: string } | null;
  raw: unknown;
  createdAt: string;
};

const baseUrl = process.env.API_BASE_URL ?? process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://localhost:4000';

const authHeaders = {
  'x-armadillo-user': process.env.WEB_ACTOR_ID ?? 'web-ui',
  'x-armadillo-role': process.env.WEB_ACTOR_ROLE ?? 'viewer',
  ...(process.env.ARMADILLO_AUTH_TOKEN ? { 'x-armadillo-auth': process.env.ARMADILLO_AUTH_TOKEN } : {})
};

const editHeaders = {
  'x-armadillo-user': process.env.WEB_ADMIN_ACTOR_ID ?? process.env.WEB_ACTOR_ID ?? 'web-admin',
  'x-armadillo-role': process.env.WEB_ADMIN_ACTOR_ROLE ?? process.env.WEB_ACTOR_ROLE ?? 'viewer',
  ...(process.env.ARMADILLO_AUTH_TOKEN ? { 'x-armadillo-auth': process.env.ARMADILLO_AUTH_TOKEN } : {})
};

async function getAsset(assetId: string): Promise<AssetDetail> {
  const res = await fetch(`${baseUrl}/api/v1/assets/${assetId}`, {
    cache: 'no-store',
    headers: authHeaders
  });

  if (!res.ok) {
    throw new Error(`Failed to fetch asset (${res.status})`);
  }

  return res.json();
}

async function saveAssetAnnotationsAction(formData: FormData) {
  'use server';
  const assetId = String(formData.get('assetId') ?? '').trim();
  if (!assetId) return;

  const labels = String(formData.get('labels') ?? '')
    .split(',')
    .map((v) => v.trim())
    .filter(Boolean);
  const notes = String(formData.get('notes') ?? '').trim();

  const res = await fetch(`${baseUrl}/api/v1/assets/${assetId}/annotations`, {
    method: 'POST',
    headers: {
      ...editHeaders,
      'content-type': 'application/json'
    },
    body: JSON.stringify({ labels, notes })
  });

  revalidatePath(`/assets/${assetId}`);
  if (!res.ok) redirect(`/assets/${assetId}?saveError=${res.status}`);
  redirect(`/assets/${assetId}?saved=1`);
}

export const dynamic = 'force-dynamic';
export const revalidate = 0;

export default async function AssetDetailPage({
  params,
  searchParams
}: {
  params: { assetId: string };
  searchParams?: Promise<Record<string, string | string[] | undefined>>;
}) {
  const qp = searchParams ? await searchParams : undefined;
  const saved = qp?.saved === '1';
  const saveError = typeof qp?.saveError === 'string' ? qp.saveError : null;
  const canEdit = ['owner', 'admin', 'staff'].includes(
    (process.env.WEB_ADMIN_ACTOR_ROLE ?? process.env.WEB_ACTOR_ROLE ?? 'viewer').toLowerCase()
  );
  const data = await getAsset(params.assetId);
  const labels = (data.annotations?.labels ?? []).join(', ');
  const notes = data.annotations?.notes ?? '';

  const rawTarget = data.ip || data.hostname || '';
  const safeTarget = /^[a-zA-Z0-9.:-]+$/.test(rawTarget) ? rawTarget : '';
  const commandDisabledReason = safeTarget ? '' : 'No safe host/IP target available for command generation.';
  const shortcuts = [
    {
      title: 'HTTP headers (curl)',
      command: `curl -I --max-time 10 http://${safeTarget}`,
      note: 'Fast liveness/header check over HTTP.'
    },
    {
      title: 'HTTPS headers (curl)',
      command: `curl -k -I --max-time 10 https://${safeTarget}`,
      note: 'TLS endpoint probe (certificate validation bypass for diagnostics).'
    },
    {
      title: 'Port 22 probe (netcat)',
      command: `nc -vz ${safeTarget} 22`,
      note: 'Quick SSH port reachability test.'
    },
    {
      title: 'Port 80 probe (telnet style)',
      command: `telnet ${safeTarget} 80`,
      note: 'Legacy plain-port connectivity check.'
    },
    {
      title: 'Web baseline scan (nikto)',
      command: `nikto -h http://${safeTarget}`,
      note: 'Basic web misconfig scan starter command.'
    }
  ];

  return (
    <main style={{ padding: 24, fontFamily: 'system-ui' }}>
      <p style={{ marginBottom: 12 }}>
        <Link href="/assets">← Back to assets</Link>
      </p>
      <h1 style={{ marginBottom: 6 }}>Asset Detail</h1>
      <p style={{ marginTop: 0, color: '#444' }}>{data.id}</p>
      <p style={{ marginTop: 0 }}>
        <Link href={`/imports/${data.importId}`}>View source import →</Link>
      </p>

      <div style={{ marginTop: 12, marginBottom: 20 }}>
        <strong>Identity:</strong> {data.identityKey} &nbsp; | &nbsp;
        <strong>IP:</strong> {data.ip ?? '-'} &nbsp; | &nbsp;
        <strong>Hostname:</strong> {data.hostname ?? '-'} &nbsp; | &nbsp;
        <strong>Seen:</strong> {data.seenCount} &nbsp; | &nbsp;
        <strong>Last Seen:</strong> {new Date(data.lastSeenAt).toLocaleString()}
      </div>

      <h2 style={{ marginBottom: 8 }}>Annotations</h2>
      {saved ? <p style={{ color: '#0b7d29' }}>Annotations saved.</p> : null}
      {saveError ? <p style={{ color: '#a61b1b' }}>Annotation save failed (HTTP {saveError}).</p> : null}
      {!canEdit ? <p style={{ color: '#666' }}>Annotations are read-only for current web actor role.</p> : null}
      <form action={canEdit ? saveAssetAnnotationsAction : undefined} style={{ display: 'grid', gap: 8, marginBottom: 16, maxWidth: 900 }}>
        <input type="hidden" name="assetId" value={data.id} />
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

      <CommandShortcuts target={safeTarget} commands={shortcuts} disabledReason={commandDisabledReason || undefined} />

      <h2 style={{ marginBottom: 8 }}>Raw Asset Node</h2>
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
        {JSON.stringify(data.raw, null, 2)}
      </pre>
    </main>
  );
}
