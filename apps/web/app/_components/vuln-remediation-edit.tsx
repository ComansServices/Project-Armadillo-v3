'use client';

import { useState } from 'react';

interface VulnRemediationEditProps {
  vulnId: number;
  assignedTo?: string | null;
  dueDate?: string | null;
  remediationStatus?: string;
  onUpdate?: () => void;
}

const statusOptions = [
  { value: 'open', label: 'Open', color: '#dc2626' },
  { value: 'in_progress', label: 'In Progress', color: '#d97706' },
  { value: 'on_hold', label: 'On Hold', color: '#6b7280' },
  { value: 'resolved', label: 'Resolved', color: '#16a34a' }
];

export function VulnRemediationEdit({ 
  vulnId, 
  assignedTo: initialAssignedTo, 
  dueDate: initialDueDate,
  remediationStatus: initialStatus = 'open',
  onUpdate 
}: VulnRemediationEditProps) {
  const [assignedTo, setAssignedTo] = useState(initialAssignedTo || '');
  const [dueDate, setDueDate] = useState(initialDueDate || '');
  const [status, setStatus] = useState(initialStatus);
  const [isEditing, setIsEditing] = useState(false);
  const [saving, setSaving] = useState(false);

  const handleSave = async () => {
    setSaving(true);
    try {
      const res = await fetch(`/api/v1/vulns/${vulnId}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          assignedTo: assignedTo || null,
          dueDate: dueDate || null,
          remediationStatus: status
        })
      });
      if (res.ok) {
        setIsEditing(false);
        onUpdate?.();
      } else {
        alert('Failed to save. Please try again.');
      }
    } finally {
      setSaving(false);
    }
  };

  const currentStatus = statusOptions.find(s => s.value === status);

  if (!isEditing) {
    return (
      <div 
        onClick={() => setIsEditing(true)}
        style={{ 
          cursor: 'pointer',
          display: 'flex',
          flexDirection: 'column',
          gap: 2,
          fontSize: 12
        }}
        title="Click to edit"
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
          <span 
            style={{ 
              width: 8, 
              height: 8, 
              borderRadius: '50%', 
              background: currentStatus?.color || '#666' 
            }} 
          />
          <span style={{ fontWeight: 500 }}>{currentStatus?.label || status}</span>
        </div>
        {assignedTo && <span style={{ color: '#666' }}>@{assignedTo}</span>}
        {dueDate && (
          <span style={{ 
            color: new Date(dueDate) < new Date() && status !== 'resolved' ? '#dc2626' : '#666',
            fontSize: 11
          }}>
            Due: {new Date(dueDate).toLocaleDateString()}
          </span>
        )}
      </div>
    );
  }

  return (
    <div 
      style={{ 
        display: 'flex', 
        flexDirection: 'column', 
        gap: 6,
        minWidth: 140
      }}
      onClick={e => e.stopPropagation()}
    >
      <select
        value={status}
        onChange={e => setStatus(e.target.value)}
        style={{ fontSize: 12, padding: '4px 8px' }}
        disabled={saving}
      >
        {statusOptions.map(s => (
          <option key={s.value} value={s.value}>{s.label}</option>
        ))}
      </select>
      <input
        type="text"
        value={assignedTo}
        onChange={e => setAssignedTo(e.target.value)}
        placeholder="Assignee"
        style={{ fontSize: 12, padding: '4px 8px' }}
        disabled={saving}
      />
      <input
        type="date"
        value={dueDate}
        onChange={e => setDueDate(e.target.value)}
        style={{ fontSize: 12, padding: '4px 8px' }}
        disabled={saving}
      />
      <div style={{ display: 'flex', gap: 4 }}>
        <button 
          onClick={handleSave}
          disabled={saving}
          style={{ flex: 1, fontSize: 11, padding: '4px 8px' }}
        >
          {saving ? '...' : 'Save'}
        </button>
        <button 
          onClick={() => {
            setAssignedTo(initialAssignedTo || '');
            setDueDate(initialDueDate || '');
            setStatus(initialStatus);
            setIsEditing(false);
          }}
          disabled={saving}
          style={{ fontSize: 11, padding: '4px 8px', background: '#6b7280' }}
        >
          Cancel
        </button>
      </div>
    </div>
  );
}

// Bulk edit component for selecting multiple vulns
interface BulkVulnEditProps {
  selectedIds: number[];
  onComplete?: () => void;
  onClear?: () => void;
}

export function BulkVulnEdit({ selectedIds, onComplete, onClear }: BulkVulnEditProps) {
  const [assignedTo, setAssignedTo] = useState('');
  const [dueDate, setDueDate] = useState('');
  const [status, setStatus] = useState('');
  const [saving, setSaving] = useState(false);

  if (selectedIds.length === 0) return null;

  const handleBulkUpdate = async () => {
    setSaving(true);
    try {
      const updates: any = {};
      if (assignedTo) updates.assignedTo = assignedTo;
      if (dueDate) updates.dueDate = dueDate;
      if (status) updates.remediationStatus = status;

      const res = await fetch('/api/v1/vulns/bulk-update', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ ids: selectedIds, ...updates })
      });

      if (res.ok) {
        onComplete?.();
        onClear?.();
      } else {
        alert('Bulk update failed. Please try again.');
      }
    } finally {
      setSaving(false);
    }
  };

  return (
    <div style={{
      position: 'fixed',
      bottom: 20,
      left: '50%',
      transform: 'translateX(-50%)',
      background: '#0f172a',
      color: '#fff',
      padding: '12px 16px',
      borderRadius: 10,
      display: 'flex',
      alignItems: 'center',
      gap: 12,
      boxShadow: '0 4px 20px rgba(0,0,0,0.3)',
      zIndex: 100
    }}>
      <span style={{ fontSize: 14, fontWeight: 500 }}>
        {selectedIds.length} selected
      </span>
      <select
        value={status}
        onChange={e => setStatus(e.target.value)}
        style={{ fontSize: 13, padding: '4px 8px' }}
      >
        <option value="">Status...</option>
        {statusOptions.map(s => (
          <option key={s.value} value={s.value}>{s.label}</option>
        ))}
      </select>
      <input
        type="text"
        value={assignedTo}
        onChange={e => setAssignedTo(e.target.value)}
        placeholder="Assignee"
        style={{ fontSize: 13, padding: '4px 8px', width: 100 }}
      />
      <input
        type="date"
        value={dueDate}
        onChange={e => setDueDate(e.target.value)}
        style={{ fontSize: 13, padding: '4px 8px' }}
      />
      <button 
        onClick={handleBulkUpdate}
        disabled={saving || (!assignedTo && !dueDate && !status)}
        style={{ fontSize: 13, padding: '6px 12px' }}
      >
        {saving ? '...' : 'Apply'}
      </button>
      <button 
        onClick={onClear}
        style={{ fontSize: 13, padding: '6px 12px', background: '#374151' }}
      >
        Clear
      </button>
    </div>
  );
}
