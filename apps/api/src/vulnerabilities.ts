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

type ExploitRef = {
  source: string;
  id: string;
  url: string;
  confidence: 'high' | 'medium' | 'low';
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

const exploitCatalog: Record<string, ExploitRef[]> = {
  'CVE-2024-6387': [
    {
      source: 'nvd',
      id: 'CVE-2024-6387',
      url: 'https://nvd.nist.gov/vuln/detail/CVE-2024-6387',
      confidence: 'high'
    },
    {
      source: 'cisa-kev',
      id: 'CVE-2024-6387',
      url: 'https://www.cisa.gov/known-exploited-vulnerabilities-catalog',
      confidence: 'medium'
    }
  ],
  'CVE-2023-44487': [
    {
      source: 'nvd',
      id: 'CVE-2023-44487',
      url: 'https://nvd.nist.gov/vuln/detail/CVE-2023-44487',
      confidence: 'high'
    }
  ],
  'CVE-2019-0708': [
    {
      source: 'nvd',
      id: 'CVE-2019-0708',
      url: 'https://nvd.nist.gov/vuln/detail/CVE-2019-0708',
      confidence: 'high'
    },
    {
      source: 'exploit-db',
      id: '47014',
      url: 'https://www.exploit-db.com/exploits/47014',
      confidence: 'medium'
    }
  ]
};

const exploitCache = new Map<string, ExploitRef[]>();

async function lookupExploitRefs(cve: string): Promise<ExploitRef[]> {
  const key = cve.toUpperCase();
  if (exploitCache.has(key)) return exploitCache.get(key)!;

  const enabled = (process.env.EXPLOIT_ENRICH_ENABLED ?? 'true').toLowerCase() !== 'false';
  if (!enabled) return [];

  const timeoutMs = Math.min(Math.max(Number(process.env.EXPLOIT_ENRICH_TIMEOUT_MS ?? 800), 100), 3000);
  const retries = Math.min(Math.max(Number(process.env.EXPLOIT_ENRICH_RETRIES ?? 1), 0), 3);

  const task = async () => exploitCatalog[key] ?? [];

  let attempt = 0;
  let last: ExploitRef[] = [];
  while (attempt <= retries) {
    attempt += 1;
    try {
      const refs = await Promise.race([
        task(),
        new Promise<ExploitRef[]>((resolve) => setTimeout(() => resolve([]), timeoutMs))
      ]);
      last = refs;
      break;
    } catch {
      if (attempt > retries) break;
    }
  }

  exploitCache.set(key, last);
  return last;
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
    const exploitRefs = await lookupExploitRefs(row.cve);
    const r = await prisma.assetVulnerability.upsert({
      where: { assetId_cve: { assetId: row.assetId, cve: row.cve } },
      create: { ...row, exploitRefs },
      update: {
        cpe: row.cpe,
        severity: row.severity,
        cvss: row.cvss,
        title: row.title,
        description: row.description,
        importId: row.importId,
        exploitRefs,
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
  assignedTo?: string;
  remediationStatus?: string;
  dueBefore?: string;
  dueAfter?: string;
  hasExploit?: boolean;
  limit?: number;
}) {
  const where: any = {
    importId: filters.importId,
    assetId: filters.assetId,
    severity: filters.severity ? normalize(filters.severity) : undefined,
    assignedTo: filters.assignedTo,
    remediationStatus: filters.remediationStatus,
  };

  if (filters.dueBefore || filters.dueAfter) {
    where.dueDate = {};
    if (filters.dueBefore) where.dueDate.lte = new Date(filters.dueBefore);
    if (filters.dueAfter) where.dueDate.gte = new Date(filters.dueAfter);
  }

  const rows = await prisma.assetVulnerability.findMany({
    where,
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

  const includeExploits = (process.env.EXPLOIT_ENRICH_ENABLED ?? 'true').toLowerCase() !== 'false';
  
  let enriched = await Promise.all(
    rows.map(async (r) => {
      const existing = Array.isArray(r.exploitRefs as unknown[]) ? (r.exploitRefs as unknown[] as ExploitRef[]) : [];
      const exploitRefs = existing.length > 0 ? existing : (includeExploits ? await lookupExploitRefs(r.cve) : []);
      const hasExploit = exploitRefs.length > 0;
      return {
        ...r,
        exploitRefs,
        hasExploit,
        exploitConfidence: hasExploit ? Math.max(...exploitRefs.map(e => e.confidence === 'high' ? 3 : e.confidence === 'medium' ? 2 : 1)) : 0
      };
    })
  );

  // Filter by hasExploit if specified
  if (filters.hasExploit !== undefined) {
    enriched = enriched.filter(r => r.hasExploit === filters.hasExploit);
  }

  // Sort: exploitable first, then by confidence
  enriched.sort((a, b) => {
    if (a.hasExploit && !b.hasExploit) return -1;
    if (!a.hasExploit && b.hasExploit) return 1;
    return b.exploitConfidence - a.exploitConfidence;
  });

  return enriched;
}

export async function getBlastRadius(cve: string) {
  const vulns = await prisma.assetVulnerability.findMany({
    where: { cve },
    include: {
      asset: {
        select: {
          id: true,
          identityKey: true,
          ip: true,
          hostname: true,
          serviceTags: true,
          ports: true
        }
      }
    }
  });

  const affectedAssets = vulns.map(v => v.asset);
  const uniqueAssets = [...new Map(affectedAssets.map(a => [a.id, a])).values()];
  
  // Calculate severity breakdown
  const severityCount = vulns.reduce((acc, v) => {
    acc[v.severity] = (acc[v.severity] || 0) + 1;
    return acc;
  }, {} as Record<string, number>);

  // Calculate service breakdown
  const serviceBreakdown = uniqueAssets.reduce((acc, asset) => {
    for (const tag of asset.serviceTags) {
      acc[tag] = (acc[tag] || 0) + 1;
    }
    return acc;
  }, {} as Record<string, number>);

  return {
    cve,
    totalInstances: vulns.length,
    affectedAssetCount: uniqueAssets.length,
    severityBreakdown: severityCount,
    serviceBreakdown,
    assets: uniqueAssets.map(a => ({
      id: a.id,
      identityKey: a.identityKey,
      ip: a.ip,
      hostname: a.hostname
    }))
  };
}

export async function getExploitabilityStats(importId?: string) {
  const where = importId ? { importId } : {};
  
  const allVulns = await prisma.assetVulnerability.findMany({
    where,
    select: { cve: true, exploitRefs: true, severity: true }
  });

  const withExploit = allVulns.filter(v => {
    const refs = Array.isArray(v.exploitRefs) ? v.exploitRefs : [];
    return refs.length > 0;
  });

  const withoutExploit = allVulns.filter(v => {
    const refs = Array.isArray(v.exploitRefs) ? v.exploitRefs : [];
    return refs.length === 0;
  });

  return {
    total: allVulns.length,
    withExploit: withExploit.length,
    withoutExploit: withoutExploit.length,
    bySeverity: {
      exploitable: withExploit.reduce((acc, v) => {
        acc[v.severity] = (acc[v.severity] || 0) + 1;
        return acc;
      }, {} as Record<string, number>),
      theoretical: withoutExploit.reduce((acc, v) => {
        acc[v.severity] = (acc[v.severity] || 0) + 1;
        return acc;
      }, {} as Record<string, number>)
    }
  };
}

export async function updateVulnerability(
  id: number,
  updates: {
    assignedTo?: string | null;
    dueDate?: string | null;
    remediationStatus?: 'open' | 'in_progress' | 'on_hold' | 'resolved';
  }
) {
  const data: any = {};
  if (updates.assignedTo !== undefined) data.assignedTo = updates.assignedTo;
  if (updates.dueDate !== undefined) data.dueDate = updates.dueDate ? new Date(updates.dueDate) : null;
  if (updates.remediationStatus !== undefined) data.remediationStatus = updates.remediationStatus;

  const updated = await prisma.assetVulnerability.update({
    where: { id },
    data,
    include: {
      asset: {
        select: {
          id: true,
          identityKey: true,
          ip: true,
          hostname: true
        }
      }
    }
  });

  return updated;
}

export async function bulkUpdateVulnerabilities(
  ids: number[],
  updates: {
    assignedTo?: string | null;
    dueDate?: string | null;
    remediationStatus?: 'open' | 'in_progress' | 'on_hold' | 'resolved';
  }
) {
  const data: any = {};
  if (updates.assignedTo !== undefined) data.assignedTo = updates.assignedTo;
  if (updates.dueDate !== undefined) data.dueDate = updates.dueDate ? new Date(updates.dueDate) : null;
  if (updates.remediationStatus !== undefined) data.remediationStatus = updates.remediationStatus;

  const result = await prisma.assetVulnerability.updateMany({
    where: { id: { in: ids } },
    data
  });

  return { updated: result.count };
}
