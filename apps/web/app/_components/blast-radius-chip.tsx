'use client';

import { useEffect, useState } from 'react';

interface BlastRadiusData {
  cve: string;
  totalInstances: number;
  affectedAssetCount: number;
  severityBreakdown: Record<string, number>;
  serviceBreakdown: Record<string, number>;
  assets: Array<{
    id: string;
    identityKey: string;
    ip: string | null;
    hostname: string | null;
  }>;
}

export function BlastRadiusChip({ cve }: { cve: string }) {
  const [data, setData] = useState<BlastRadiusData | null>(null);
  const [loading, setLoading] = useState(false);
  const [showDetails, setShowDetails] = useState(false);

  useEffect(() => {
    setLoading(true);
    fetch(`/api/v1/vulns/${encodeURIComponent(cve)}/blast-radius`)
      .then(r => r.json())
      .then(setData)
      .catch(() => setData(null))
      .finally(() => setLoading(false));
  }, [cve]);

  if (loading) {
    return (
      <span style={{
        display: 'inline-flex',
        alignItems: 'center',
        padding: '1px 6px',
        borderRadius: 999,
        background: '#e5e7eb',
        color: '#6b7280',
        fontSize: 10,
        fontWeight: 500
      }}>
        Loading...
      </span>
    );
  }

  if (!data || data.affectedAssetCount === 0) {
    return (
      <span style={{
        display: 'inline-flex',
        alignItems: 'center',
        padding: '1px 6px',
        borderRadius: 999,
        background: '#f3f4f6',
        color: '#9ca3af',
        fontSize: 10,
        fontWeight: 500
      }}>
        1 host
      </span>
    );
  }

  const severityColor = data.severityBreakdown.critical ? '#dc2626' : 
                       data.severityBreakdown.high ? '#ea580c' : 
                       data.severityBreakdown.medium ? '#ca8a04' : '#6b7280';

  return (
    <div style={{ display: 'inline-flex', flexDirection: 'column', gap: 4 }}>
      <button
        onClick={() => setShowDetails(!showDetails)}
        style={{
          display: 'inline-flex',
          alignItems: 'center',
          padding: '2px 8px',
          borderRadius: 999,
          background: severityColor + '15',
          color: severityColor,
          border: `1px solid ${severityColor}40`,
          fontSize: 11,
          fontWeight: 600,
          cursor: 'pointer',
          gap: 4
        }}
        title={`Affects ${data.affectedAssetCount} unique host${data.affectedAssetCount !== 1 ? 's' : ''}`}
      >
        🎯 {data.affectedAssetCount} host{data.affectedAssetCount !== 1 ? 's' : ''}
      </button>
      
      {showDetails && (
        <div style={{
          position: 'absolute',
          zIndex: 100,
          marginTop: 24,
          padding: 12,
          background: '#fff',
          borderRadius: 8,
          border: '1px solid #e5e7eb',
          boxShadow: '0 4px 12px rgba(0,0,0,0.15)',
          minWidth: 240,
          maxWidth: 320
        }}>
          <div style={{ fontWeight: 600, marginBottom: 8, color: '#111827' }}>
            {cve} Impact
          </div>
          <div style={{ fontSize: 12, color: '#6b7280', marginBottom: 8 }}>
            {data.totalInstances} total instance{data.totalInstances !== 1 ? 's' : ''} across {data.affectedAssetCount} host{data.affectedAssetCount !== 1 ? 's' : ''}
          </div>
          
          {Object.entries(data.severityBreakdown).length > 0 && (
            <div style={{ marginBottom: 8 }}>
              <div style={{ fontSize: 11, fontWeight: 600, color: '#374151', marginBottom: 4 }}>Severity breakdown:</div>
              <div style={{ display: 'flex', flexWrap: 'wrap', gap: 4 }}>
                {Object.entries(data.severityBreakdown).map(([sev, count]) => (
                  <span key={sev} style={{
                    padding: '2px 6px',
                    borderRadius: 4,
                    fontSize: 10,
                    textTransform: 'uppercase',
                    background: sev === 'critical' ? '#fef2f2' : sev === 'high' ? '#fff7ed' : sev === 'medium' ? '#fefce8' : '#f3f4f6',
                    color: sev === 'critical' ? '#dc2626' : sev === 'high' ? '#ea580c' : sev === 'medium' ? '#ca8a04' : '#6b7280'
                  }}>
                    {sev}: {count}
                  </span>
                ))}
              </div>
            </div>
          )}
          
          {Object.entries(data.serviceBreakdown).length > 0 && (
            <div>
              <div style={{ fontSize: 11, fontWeight: 600, color: '#374151', marginBottom: 4 }}>Services affected:</div>
              <div style={{ display: 'flex', flexWrap: 'wrap', gap: 4 }}>
                {Object.entries(data.serviceBreakdown).slice(0, 5).map(([svc, count]) => (
                  <span key={svc} style={{
                    padding: '2px 6px',
                    borderRadius: 4,
                    fontSize: 10,
                    background: '#dbeafe',
                    color: '#1d4ed8'
                  }}>
                    {svc}: {count}
                  </span>
                ))}
              </div>
            </div>
          )}
          
          <button
            onClick={() => setShowDetails(false)}
            style={{
              marginTop: 8,
              padding: '4px 8px',
              fontSize: 11,
              background: '#f3f4f6',
              border: '1px solid #d1d5db',
              borderRadius: 4,
              cursor: 'pointer'
            }}
          >
            Close
          </button>
        </div>
      )}
    </div>
  );
}
