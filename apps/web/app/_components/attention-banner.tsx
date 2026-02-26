'use client';

import { useEffect, useState } from 'react';

interface FailedScan {
  id: string;
  status: string;
  projectId: string;
  requestedBy: string;
  updatedAt: string;
}

interface TrendDay {
  date: string;
  completed: number;
  failed: number;
}

interface AttentionData {
  needsAttention: boolean;
  totalFailed: number;
  failedScans: FailedScan[];
  trend: TrendDay[];
}

function Sparkline({ trend }: { trend: TrendDay[] }) {
  const maxVal = Math.max(...trend.map(d => Math.max(d.completed, d.failed)), 1);
  const width = 120;
  const height = 30;
  const padding = 2;
  
  const points = trend.map((d, i) => {
    const x = padding + (i / (trend.length - 1 || 1)) * (width - 2 * padding);
    const y = height - padding - (d.completed / maxVal) * (height - 2 * padding);
    return `${x},${y}`;
  }).join(' ');

  const failPoints = trend.map((d, i) => {
    const x = padding + (i / (trend.length - 1 || 1)) * (width - 2 * padding);
    const y = height - padding - (d.failed / maxVal) * (height - 2 * padding);
    return `${x},${y}`;
  }).join(' ');

  return (
    <svg width={width} height={height} style={{ display: 'inline-block', verticalAlign: 'middle' }}>
      <polyline
        fill="none"
        stroke="#22c55e"
        strokeWidth="2"
        points={points}
      />
      <polyline
        fill="none"
        stroke="#ef4444"
        strokeWidth="2"
        points={failPoints}
      />
    </svg>
  );
}

export function AttentionBanner() {
  const [data, setData] = useState<AttentionData | null>(null);
  const [loading, setLoading] = useState(true);
  const [retrying, setRetrying] = useState<string | null>(null);

  useEffect(() => {
    fetch('/api/v1/scans/attention', { cache: 'no-store' })
      .then(r => r.json())
      .then(setData)
      .finally(() => setLoading(false));
  }, []);

  const handleRetry = async (scanId: string) => {
    setRetrying(scanId);
    try {
      const res = await fetch(`/api/v1/scans/${scanId}/retry`, { method: 'POST' });
      if (res.ok) {
        window.location.reload();
      } else {
        alert('Retry failed. Please try again.');
      }
    } finally {
      setRetrying(null);
    }
  };

  if (loading) return null;
  if (!data?.needsAttention) return null;

  const severity = data.totalFailed > 5 ? 'critical' : data.totalFailed > 1 ? 'warning' : 'info';
  const colors = {
    critical: { bg: '#fef2f2', border: '#ef4444', text: '#991b1b' },
    warning: { bg: '#fffbeb', border: '#f59e0b', text: '#92400e' },
    info: { bg: '#eff6ff', border: '#3b82f6', text: '#1e40af' }
  }[severity];

  return (
    <div style={{ 
      background: colors.bg, 
      border: `1px solid ${colors.border}`, 
      borderRadius: 10, 
      padding: 14,
      marginBottom: 16 
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, flexWrap: 'wrap' }}>
        <span style={{ fontSize: 24 }}>🔥</span>
        <div style={{ flex: 1 }}>
          <strong style={{ color: colors.text, fontSize: 16 }}>
            Attention: {data.totalFailed} scan{data.totalFailed > 1 ? 's' : ''} failed in the last 24 hours
          </strong>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 4 }}>
            <span style={{ fontSize: 13, color: '#666' }}>7-day trend:</span>
            <Sparkline trend={data.trend} />
          </div>
        </div>
        <div style={{ display: 'flex', gap: 8 }}>
          {data.failedScans.slice(0, 3).map(scan => (
            <button
              key={scan.id}
              onClick={() => handleRetry(scan.id)}
              disabled={retrying === scan.id}
              style={{ 
                padding: '6px 12px', 
                fontSize: 13,
                opacity: retrying === scan.id ? 0.6 : 1 
              }}
            >
              {retrying === scan.id ? 'Retrying...' : `Retry ${scan.id.slice(0, 8)}...`}
            </button>
          ))}
        </div>
      </div>
      
      {data.failedScans.length > 0 && (
        <details style={{ marginTop: 10 }}>
          <summary style={{ cursor: 'pointer', fontSize: 13, color: '#666' }}>
            View {data.failedScans.length} failed scan{data.failedScans.length > 1 ? 's' : ''}
          </summary>
          <div style={{ marginTop: 8, display: 'flex', flexDirection: 'column', gap: 6 }}>
            {data.failedScans.map(scan => (
              <div 
                key={scan.id} 
                style={{ 
                  display: 'flex', 
                  alignItems: 'center', 
                  gap: 12, 
                  fontSize: 13,
                  padding: '6px 8px',
                  background: 'rgba(255,255,255,0.5)',
                  borderRadius: 6
                }}
              >
                <code>{scan.id}</code>
                <span>{scan.projectId}</span>
                <span style={{ color: '#666' }}>{new Date(scan.updatedAt).toLocaleString()}</span>
                <button 
                  onClick={() => handleRetry(scan.id)}
                  disabled={retrying === scan.id}
                  style={{ marginLeft: 'auto', padding: '4px 10px', fontSize: 12 }}
                >
                  {retrying === scan.id ? '...' : 'Retry'}
                </button>
              </div>
            ))}
          </div>
        </details>
      )}
    </div>
  );
}
