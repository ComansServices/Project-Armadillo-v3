import Link from 'next/link';

type XmlImportDetail = {
  id: string;
  source: string | null;
  requestedBy: string;
  rootNode: string | null;
  itemCount: number;
  payload: unknown;
  createdAt: string;
};

const baseUrl =
  process.env.API_BASE_URL ?? process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://localhost:4000';

const authHeaders = {
  'x-armadillo-user': process.env.WEB_ACTOR_ID ?? 'web-ui',
  'x-armadillo-role': process.env.WEB_ACTOR_ROLE ?? 'viewer'
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

export const dynamic = 'force-dynamic';
export const revalidate = 0;

export default async function ImportDetailPage({ params }: { params: { importId: string } }) {
  const data = await getImport(params.importId);

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
