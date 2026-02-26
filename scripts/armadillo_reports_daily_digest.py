#!/usr/bin/env python3
import json
import os
import subprocess
from datetime import datetime, timedelta, timezone
from pathlib import Path

ARCHIVE = Path('/Users/leo/.openclaw/workspace/Project-Armadillo-v3/apps/api/reports/archive')
TEAMS_BIN = os.environ.get('TEAMS_WEBHOOK_SKILL', str(Path.home() / '.openclaw/skills/teams-webhook/teams-webhook'))
RECIPIENT = os.environ.get('TEAMS_RECIPIENT', 'Jason')
TITLE = '🛡️ Armadillo Reports Daily Digest'


def as_dt(v: str):
    try:
        return datetime.fromisoformat(v.replace('Z', '+00:00'))
    except Exception:
        return None


def load_meta():
    if not ARCHIVE.exists():
        return []
    out = []
    for p in sorted(ARCHIVE.glob('*.json')):
        try:
            out.append(json.loads(p.read_text(encoding='utf-8')))
        except Exception:
            continue
    return out


def build_digest(rows):
    now = datetime.now(timezone.utc)
    cutoff = now - timedelta(hours=24)
    recent = [r for r in rows if (dt := as_dt(r.get('createdAt', ''))) and dt >= cutoff]

    if not recent:
        return 'No archived Armadillo reports in the last 24h.'

    by_kind = {'import': 0, 'scan': 0}
    by_aud = {'ops': 0, 'exec': 0}
    for r in recent:
      by_kind[r.get('kind','')] = by_kind.get(r.get('kind',''), 0) + 1
      by_aud[r.get('audience','')] = by_aud.get(r.get('audience',''), 0) + 1

    latest = recent[-1]
    lines = [
      f'Window: last 24h ({len(recent)} archived reports)',
      f"Kinds: import={by_kind.get('import',0)} scan={by_kind.get('scan',0)}",
      f"Audience split: ops={by_aud.get('ops',0)} exec={by_aud.get('exec',0)}",
      f"Latest: {latest.get('kind')} {latest.get('audience')} ref={latest.get('refId')} by={latest.get('requestedBy')}",
      'Archive index: <http://localhost:3000/reports>'
    ]
    return '\n'.join(lines)


def send(text):
    if Path(TEAMS_BIN).exists() and os.access(TEAMS_BIN, os.X_OK):
        proc = subprocess.run([TEAMS_BIN, TITLE, text, RECIPIENT], capture_output=True, text=True)
        print(proc.stdout.strip())
        if proc.returncode != 0:
            print(proc.stderr.strip())
        return proc.returncode
    print(text)
    return 0


if __name__ == '__main__':
    raise SystemExit(send(build_digest(load_meta())))
