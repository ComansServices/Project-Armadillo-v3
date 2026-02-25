export type ScanStage = 'naabu' | 'nmap' | 'httpx' | 'nuclei';

export interface ScanTarget {
  value: string; // CIDR, IP, hostname, or domain
  type?: 'cidr' | 'ip' | 'host' | 'domain';
}

export interface ScanPipelineConfig {
  profile: 'safe-default' | 'deep-internal';
  maxConcurrency?: number;
  timeoutSeconds?: number;
  allowNucleiTemplates?: string[];
}

export interface ScanRequest {
  projectId: string;
  requestedBy: string;
  targets: ScanTarget[];
  config: ScanPipelineConfig;
}

export interface ScanJobPayload {
  scanId: string;
  stage: ScanStage;
  request: ScanRequest;
  upstreamArtifactId?: string;
}

export interface StageResult {
  scanId: string;
  stage: ScanStage;
  ok: boolean;
  artifactRef?: string;
  summary?: Record<string, unknown>;
  error?: string;
  startedAt: string;
  finishedAt: string;
}
