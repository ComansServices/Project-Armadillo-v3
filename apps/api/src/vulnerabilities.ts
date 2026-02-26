import { prisma } from './prisma';

type AssetLite = {
  id: string;
  importId: string;
  ports: number[];
  serviceTags: string[];
};

type FindingSeed = {
  cve: string;
  cpe?: string;
  severity: 'low' | 'medium' | 'high' | 'critical';
  cvss?: number;
  title: string;
  description: string;
};

function normalize(s: string) {
  return s.trim().toLowerCase();
}

function deriveCpeHints(asset: AssetLite): string[] {
  const hints = new Set<string>();
  const tags = new Set(asset.serviceTags.map(normalize));

  if (asset.ports.includes(22) || tags.has('ssh')) hints.add('cpe:2.3:a:openbsd:openssh:*');
  if (asset.ports.includes(443) || asset.ports.includes(8443) || tags.has('web')) {
    hints.add('cpe:2.3:a:nginx:nginx:*');
    hints.add('cpe:2.3:a:openssl:openssl:*');
  }
  if (asset.ports.includes(3389) || tags.has('rdp')) hints.add('cpe:2.3:o:microsoft:windows:*');

  return [...hints];
}

function cpeToFindings(cpe: string): FindingSeed[] {
  if (cpe.includes('openssh')) {
    return [
      {
        cve: 'CVE-2024-6387',
        cpe,
        severity: 'high',
        cvss: 8.1,
        title: 'OpenSSH regreSSHion',
        description: 'Potential unauthenticated remote code execution risk in vulnerable OpenSSH versions.'
      }
    ];
  }

  if (cpe.includes('nginx')) {
    return [
      {
        cve: 'CVE-2023-44487',
        cpe,
        severity: 'medium',
        cvss: 7.5,
        title: 'HTTP/2 Rapid Reset',
        description: 'HTTP/2 request reset behavior can be abused for denial-of-service if not mitigated.'
      }
    ];
  }

  if (cpe.includes('openssl')) {
    return [
      {
        cve: 'CVE-2023-5678',
        cpe,
        severity: 'medium',
        cvss: 6.5,
        title: 'OpenSSL implementation weakness',
        description: 'Placeholder advisory mapping for OpenSSL exposure requiring version-specific validation.'
      }
    ];
  }

  if (cpe.includes('windows')) {
    return [
      {
        cve: 'CVE-2019-0708',
        cpe,
        severity: 'critical',
        cvss: 9.8,
        title: 'BlueKeep (RDP)',
        description: 'Historic RDP RCE class issue; use for exposure triage and patch hygiene checks.'
      }
    ];
  }

  return [];
}

export async function enrichImportVulnerabilities(importId: string) {
  const assets = await prisma.asset.findMany({
    where: { importId },
    select: { id: true, importId: true, ports: true, serviceTags: true }
  });

  const rows = [] as Array<{
    assetId: string;
    importId: string;
    cve: string;
    cpe?: string;
    severity: string;
    cvss?: number;
    title: string;
    description: string;
  }>;

  for (const asset of assets) {
    for (const cpe of deriveCpeHints(asset)) {
      for (const finding of cpeToFindings(cpe)) {
        rows.push({
          assetId: asset.id,
          importId: asset.importId,
          cve: finding.cve,
          cpe: finding.cpe,
          severity: finding.severity,
          cvss: finding.cvss,
          title: finding.title,
          description: finding.description
        });
      }
    }
  }

  let created = 0;
  for (const row of rows) {
    const r = await prisma.assetVulnerability.upsert({
      where: { assetId_cve: { assetId: row.assetId, cve: row.cve } },
      create: { ...row },
      update: {
        cpe: row.cpe,
        severity: row.severity,
        cvss: row.cvss,
        title: row.title,
        description: row.description,
        importId: row.importId,
        detectedAt: new Date()
      }
    });
    if (r) created += 1;
  }

  return {
    importId,
    assetsScanned: assets.length,
    findingsWritten: created,
    distinctCves: [...new Set(rows.map((r) => r.cve))].length
  };
}

export async function listVulnerabilities(filters: {
  importId?: string;
  assetId?: string;
  severity?: string;
  limit?: number;
}) {
  return prisma.assetVulnerability.findMany({
    where: {
      importId: filters.importId,
      assetId: filters.assetId,
      severity: filters.severity ? normalize(filters.severity) : undefined
    },
    include: {
      asset: {
        select: {
          id: true,
          identityKey: true,
          ip: true,
          hostname: true
        }
      }
    },
    orderBy: [{ detectedAt: 'desc' }],
    take: Math.min(Math.max(filters.limit ?? 100, 1), 500)
  });
}
