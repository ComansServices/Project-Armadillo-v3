'use client';

import { useRouter } from 'next/navigation';
import { VulnRemediationEdit } from './vuln-remediation-edit';

export function RemediationCell({ 
  vulnId, 
  assignedTo, 
  dueDate, 
  remediationStatus 
}: { 
  vulnId: number; 
  assignedTo: string | null; 
  dueDate: string | null; 
  remediationStatus: string;
}) {
  const router = useRouter();
  
  return (
    <VulnRemediationEdit
      vulnId={vulnId}
      assignedTo={assignedTo}
      dueDate={dueDate}
      remediationStatus={remediationStatus}
      onUpdate={() => router.refresh()}
    />
  );
}
