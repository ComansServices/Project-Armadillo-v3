#!/usr/bin/env python3
import sys
import time
import requests

BASE = 'http://localhost:4000'
VIEWER = {'x-armadillo-user': 'phase4-smoke', 'x-armadillo-role': 'viewer'}
STAFF = {'x-armadillo-user': 'phase4-smoke', 'x-armadillo-role': 'staff', 'content-type': 'application/json'}


def ok(name, cond, detail=''):
    print(f"{'✅' if cond else '❌'} {name} {detail}")
    return cond


def test_scan_flow():
    payload = {
        'projectId': 'proj-001',
        'requestedBy': 'phase4-smoke',
        'targets': [{'type': 'ip', 'value': '127.0.0.1'}],
        'config': {'profile': 'safe-default'}
    }
    r = requests.post(f'{BASE}/api/v1/scans', headers=STAFF, json=payload, timeout=20)
    if not ok('queue scan', r.status_code == 200, f'status={r.status_code}'):
        return False, None
    scan_id = r.json()['scanId']

    status = None
    for _ in range(30):
        s = requests.get(f'{BASE}/api/v1/scans/{scan_id}', headers=VIEWER, timeout=10).json()
        status = s.get('status')
        if status in ('completed', 'failed'):
            break
        time.sleep(1)
    return ok('scan lifecycle terminal', status in ('completed', 'failed'), f'status={status}'), scan_id


def test_rbac():
    r = requests.post(f'{BASE}/api/v1/assets/backfill-identity', headers=VIEWER, timeout=10)
    return ok('rbac viewer denied admin endpoint', r.status_code == 403, f'status={r.status_code}')


def test_report_archive(scan_id):
    requests.get(f'{BASE}/api/v1/reports/scans/{scan_id}.pdf?audience=ops&archive=1', headers=VIEWER, timeout=20)
    requests.get(f'{BASE}/api/v1/reports/scans/{scan_id}.pdf?audience=exec&archive=1', headers=VIEWER, timeout=20)
    r = requests.get(f'{BASE}/api/v1/reports', headers=VIEWER, timeout=20)
    if not ok('reports index reachable', r.status_code == 200, f'status={r.status_code}'):
        return False
    rows = r.json().get('reports', [])
    matches = [x for x in rows if x.get('kind') == 'scan' and x.get('refId') == scan_id]
    return ok('scan ops+exec archived', len(matches) >= 2, f'count={len(matches)}')


def main():
    try:
        h = requests.get(f'{BASE}/health', timeout=5)
    except Exception as e:
        print('❌ health request failed', e)
        return 1
    if not ok('health', h.status_code == 200):
        return 1

    pass_count = 0
    total = 0

    total += 1
    if test_rbac():
        pass_count += 1

    total += 1
    scan_ok, scan_id = test_scan_flow()
    if scan_ok:
        pass_count += 1

    total += 1
    if scan_id and test_report_archive(scan_id):
        pass_count += 1

    print(f'\nResult: {pass_count}/{total} checks passed')
    return 0 if pass_count == total else 2


if __name__ == '__main__':
    raise SystemExit(main())
