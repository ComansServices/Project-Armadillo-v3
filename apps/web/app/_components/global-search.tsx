'use client';

import { useEffect, useState, useCallback } from 'react';
import Link from 'next/link';

interface SearchResult {
  type: 'vulnerability' | 'asset' | 'scan' | 'import';
  id: string;
  title: string;
  subtitle: string;
  url: string;
}

export function GlobalSearch() {
  const [isOpen, setIsOpen] = useState(false);
  const [query, setQuery] = useState('');
  const [results, setResults] = useState<SearchResult[]>([]);
  const [loading, setLoading] = useState(false);
  const [selectedIndex, setSelectedIndex] = useState(0);

  // Handle Cmd+K / Ctrl+K
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key === 'k') {
        e.preventDefault();
        setIsOpen(true);
      }
      if (e.key === 'Escape') {
        setIsOpen(false);
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, []);

  // Search API call
  useEffect(() => {
    if (!isOpen || query.length < 2) {
      setResults([]);
      return;
    }

    setLoading(true);
    const timeout = setTimeout(() => {
      fetch(`/api/v1/search?q=${encodeURIComponent(query)}&limit=20`)
        .then(r => r.json())
        .then(data => setResults(data.results || []))
        .catch(() => setResults([]))
        .finally(() => setLoading(false));
    }, 150);

    return () => clearTimeout(timeout);
  }, [query, isOpen]);

  // Reset selection when results change
  useEffect(() => {
    setSelectedIndex(0);
  }, [results.length]);

  // Keyboard navigation
  const handleKeyDown = useCallback((e: React.KeyboardEvent) => {
    if (e.key === 'ArrowDown') {
      e.preventDefault();
      setSelectedIndex(i => Math.min(i + 1, results.length - 1));
    } else if (e.key === 'ArrowUp') {
      e.preventDefault();
      setSelectedIndex(i => Math.max(i - 1, 0));
    } else if (e.key === 'Enter') {
      e.preventDefault();
      const result = results[selectedIndex];
      if (result) {
        window.location.href = result.url;
      }
    }
  }, [results, selectedIndex]);

  if (!isOpen) {
    return (
      <button
        onClick={() => setIsOpen(true)}
        style={{
          position: 'fixed',
          bottom: 20,
          right: 20,
          width: 44,
          height: 44,
          borderRadius: 999,
          background: '#0f172a',
          color: '#fff',
          border: 'none',
          cursor: 'pointer',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          fontSize: 18,
          boxShadow: '0 4px 12px rgba(0,0,0,0.15)',
          zIndex: 100
        }}
        title="Search (Cmd+K)"
      >
        🔍
      </button>
    );
  }

  const typeIcons: Record<string, string> = {
    vulnerability: '🛡️',
    asset: '🖥️',
    scan: '🔍',
    import: '📥'
  };

  return (
    <div
      style={{
        position: 'fixed',
        inset: 0,
        background: 'rgba(0,0,0,0.5)',
        display: 'flex',
        alignItems: 'flex-start',
        justifyContent: 'center',
        paddingTop: '15vh',
        zIndex: 1000
      }}
      onClick={() => setIsOpen(false)}
    >
      <div
        style={{
          background: '#fff',
          borderRadius: 12,
          width: 'min(600px, 90vw)',
          maxHeight: '60vh',
          display: 'flex',
          flexDirection: 'column',
          boxShadow: '0 20px 50px rgba(0,0,0,0.3)'
        }}
        onClick={e => e.stopPropagation()}
      >
        <div style={{ padding: '12px 16px', borderBottom: '1px solid #e2e8f0' }}>
          <input
            autoFocus
            value={query}
            onChange={e => setQuery(e.target.value)}
            onKeyDown={handleKeyDown}
            placeholder="Search CVEs, IPs, hostnames, scans, imports..."
            style={{
              width: '100%',
              border: 'none',
              padding: 8,
              fontSize: 16,
              outline: 'none'
            }}
          />
        </div>

        <div style={{ overflow: 'auto', flex: 1 }}>
          {query.length < 2 ? (
            <div style={{ padding: 20, color: '#666', textAlign: 'center' }}>
              Type at least 2 characters to search
            </div>
          ) : loading ? (
            <div style={{ padding: 20, color: '#666', textAlign: 'center' }}>
              Searching...
            </div>
          ) : results.length === 0 ? (
            <div style={{ padding: 20, color: '#666', textAlign: 'center' }}>
              No results found for &quot;{query}&quot;
            </div>
          ) : (
            <div style={{ padding: 8 }}>
              {results.map((result, index) => (
                <Link
                  key={`${result.type}-${result.id}`}
                  href={result.url}
                  onClick={() => setIsOpen(false)}
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: 12,
                    padding: '10px 12px',
                    borderRadius: 8,
                    textDecoration: 'none',
                    color: 'inherit',
                    background: index === selectedIndex ? '#f1f5f9' : 'transparent'
                  }}
                  onMouseEnter={() => setSelectedIndex(index)}
                >
                  <span style={{ fontSize: 20 }}>{typeIcons[result.type]}</span>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ fontWeight: 600, fontSize: 14 }}>
                      {result.title}
                    </div>
                    <div style={{ fontSize: 12, color: '#666', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                      {result.subtitle}
                    </div>
                  </div>
                  <span style={{ fontSize: 11, color: '#999', textTransform: 'capitalize' }}>
                    {result.type}
                  </span>
                </Link>
              ))}
            </div>
          )}
        </div>

        <div
          style={{
            padding: '8px 16px',
            borderTop: '1px solid #e2e8f0',
            fontSize: 12,
            color: '#666',
            display: 'flex',
            gap: 16
          }}
        >
          <span>↑↓ to navigate</span>
          <span>↵ to select</span>
          <span>ESC to close</span>
        </div>
      </div>
    </div>
  );
}
