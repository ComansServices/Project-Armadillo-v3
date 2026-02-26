import Link from 'next/link';
import { ReactNode } from 'react';

const navItems = [
  { href: '/', label: 'Overview' },
  { href: '/schedules', label: 'Schedules' },
  { href: '/imports', label: 'Imports' },
  { href: '/assets', label: 'Assets' },
  { href: '/vulns', label: 'Vulnerabilities' },
  { href: '/network', label: 'Network' },
  { href: '/reports', label: 'Reports' },
  { href: '/dashboard', label: 'Dashboard' }
];

export function ActionButtons({ actions }: { actions: Array<{ href: string; label: string; primary?: boolean }> }) {
  return (
    <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', margin: '10px 0 14px 0' }}>
      {actions.map((a) => (
        <Link
          key={`${a.href}-${a.label}`}
          href={a.href}
          style={{
            textDecoration: 'none',
            borderRadius: 8,
            padding: '8px 12px',
            border: a.primary ? '1px solid #1d4ed8' : '1px solid #cbd5e1',
            background: a.primary ? '#2563eb' : '#fff',
            color: a.primary ? '#fff' : '#0f172a',
            fontWeight: 600,
            fontSize: 14
          }}
        >
          {a.label}
        </Link>
      ))}
    </div>
  );
}

export function AppShell({
  title,
  purpose,
  whenToUse,
  firstAction,
  children
}: {
  title: string;
  purpose: string;
  whenToUse: string;
  firstAction: string;
  children: ReactNode;
}) {
  return (
    <main style={{ padding: 24, fontFamily: 'system-ui' }}>
      <nav style={{ display: 'flex', gap: 8, flexWrap: 'wrap', marginBottom: 12 }}>
        {navItems.map((n) => (
          <Link
            key={n.href}
            href={n.href}
            style={{
              textDecoration: 'none',
              border: '1px solid #cbd5e1',
              background: '#f8fafc',
              borderRadius: 999,
              padding: '6px 11px',
              color: '#0f172a',
              fontSize: 13,
              fontWeight: 600
            }}
          >
            {n.label}
          </Link>
        ))}
      </nav>

      <h1 style={{ marginBottom: 8 }}>{title}</h1>
      <div style={{ border: '1px solid #e2e8f0', background: '#f8fafc', borderRadius: 10, padding: 12, marginBottom: 14 }}>
        <p style={{ margin: '0 0 4px 0' }}><strong>Purpose:</strong> {purpose}</p>
        <p style={{ margin: '0 0 4px 0' }}><strong>When to use:</strong> {whenToUse}</p>
        <p style={{ margin: 0 }}><strong>Start here:</strong> {firstAction}</p>
      </div>

      {children}
    </main>
  );
}
