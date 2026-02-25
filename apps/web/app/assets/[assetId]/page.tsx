import Link from 'next/link';

type AssetDetail = {
  id: string;
  importId: string;
  ip: string | null;
  hostname: string | null;
  raw: unknown;
  createdAt: string;
};

const baseUrl =
  process.env.API_BASE_URL ?? process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://localhost:4000';

const authHeaders = {
  'x-armadillo-user': process.env.WEB_ACTOR_ID ?? 'web-ui',
  'x-armadillo-role': process.env.WEB_ACTOR_ROLE ?? 'viewer'
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

export const dynamic = 'force-dynamic';
export const revalidate = 0;

export default async function AssetDetailPage({ params }: { params: { assetId: string } }) {
  const data = await getAsset(params.assetId);

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
        <strong>IP:</strong> {data.ip ?? '-'} &nbsp; | &nbsp;
        <strong>Hostname:</strong> {data.hostname ?? '-'}
      </div>

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
