import { ReactNode } from 'react';

interface AssetBadgeProps {
  badge: 'new' | 'new_this_week' | 'changed' | null;
  tooltip?: string;
}

export function AssetBadge({ badge, tooltip }: AssetBadgeProps): ReactNode {
  if (!badge) return null;

  const config = {
    new: { 
      label: 'NEW', 
      bg: '#dcfce7', 
      color: '#166534',
      border: '#86efac'
    },
    new_this_week: { 
      label: 'THIS WEEK', 
      bg: '#e0e7ff', 
      color: '#3730a3',
      border: '#a5b4fc'
    },
    changed: { 
      label: 'CHANGED', 
      bg: '#fef3c7', 
      color: '#92400e',
      border: '#fcd34d'
    }
  }[badge];

  return (
    <span
      title={tooltip}
      style={{
        display: 'inline-flex',
        alignItems: 'center',
        gap: 4,
        padding: '2px 8px',
        borderRadius: 999,
        background: config.bg,
        color: config.color,
        border: `1px solid ${config.border}`,
        fontSize: 10,
        fontWeight: 700,
        textTransform: 'uppercase',
        letterSpacing: '0.02em',
        whiteSpace: 'nowrap'
      }}
    >
      {badge === 'new' && '●'}
      {badge === 'changed' && '◆'}
      {config.label}
    </span>
  );
}
