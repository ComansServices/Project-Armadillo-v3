#!/usr/bin/env python3
import json
import os

path = os.path.expanduser('~/.docker/config.json')
os.makedirs(os.path.dirname(path), exist_ok=True)

try:
    with open(path) as f:
        cfg = json.load(f)
except Exception:
    cfg = {}

want = '/opt/homebrew/lib/docker/cli-plugins'
extra = cfg.get('cliPluginsExtraDirs', [])
if want not in extra:
    extra.append(want)
cfg['cliPluginsExtraDirs'] = extra

with open(path, 'w') as f:
    json.dump(cfg, f, indent=2)

print(f'Updated {path}')
