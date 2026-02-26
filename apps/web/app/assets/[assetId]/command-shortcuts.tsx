'use client';

import { useMemo, useState } from 'react';

type CommandShortcut = {
  title: string;
  command: string;
  note: string;
};

function isSafeCommand(command: string): boolean {
  const blockedTokens = ['&&', '||', ';', '|', '>', '<', '`', '$(', 'rm ', 'sudo '];
  return !blockedTokens.some((t) => command.includes(t));
}

export default function CommandShortcuts({
  target,
  commands,
  disabledReason
}: {
  target: string;
  commands: CommandShortcut[];
  disabledReason?: string;
}) {
  const [copied, setCopied] = useState<string>('');

  const safeCommands = useMemo(() => commands.filter((c) => isSafeCommand(c.command)), [commands]);

  async function copy(text: string, key: string) {
    try {
      await navigator.clipboard.writeText(text);
      setCopied(key);
      setTimeout(() => setCopied(''), 1200);
    } catch {
      setCopied('copy-failed');
      setTimeout(() => setCopied(''), 1200);
    }
  }

  return (
    <section style={{ marginBottom: 18 }}>
      <h2 style={{ marginBottom: 8 }}>Host action shortcuts</h2>
      <p style={{ marginTop: 0, color: '#475569' }}>
        Practical operator commands for <code>{target || 'unavailable target'}</code>. Templates are read-only probes.
      </p>
      {disabledReason ? <p style={{ color: '#a61b1b' }}>{disabledReason}</p> : null}

      <div style={{ display: 'grid', gap: 10 }}>
        {safeCommands.map((c, i) => (
          <div key={`${c.title}-${i}`} style={{ border: '1px solid #dbe2ea', borderRadius: 10, padding: 10, background: '#fff' }}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 10 }}>
              <strong>{c.title}</strong>
              <button type="button" onClick={() => copy(c.command, c.title)} disabled={!!disabledReason}>
                {copied === c.title ? 'Copied' : 'Copy'}
              </button>
            </div>
            <pre style={{ margin: '8px 0', background: '#0f172a', color: '#e2e8f0', padding: 10, borderRadius: 8, overflowX: 'auto' }}>
              {c.command}
            </pre>
            <p style={{ margin: 0, fontSize: 12, color: '#475569' }}>{c.note}</p>
          </div>
        ))}
      </div>
      {copied === 'copy-failed' ? <p style={{ color: '#a61b1b' }}>Copy failed on this browser. Long-press select the command instead.</p> : null}
    </section>
  );
}
