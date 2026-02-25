# Armadillo v3 — Practical Combo Tooling Matrix

## Selected v1 Combo
1. **naabu** — fast port discovery
2. **nmap** — deep service/version/script enumeration
3. **httpx** — web probe + fingerprint on discovered web services
4. **nuclei** — templated vulnerability checks

## Why this combo
- Fast enough for real operations
- Strong coverage without tool sprawl
- Clear stage boundaries for queue-based execution
- Easy to parallelize in worker fleet

## Recommended Run Order
```text
Target(s)
  -> naabu (quick ports)
  -> nmap (service/version/NSE as allowed)
  -> httpx (only web endpoints)
  -> nuclei (scoped templates/policies)
  -> normalize + enrich + score
  -> dashboard + exports
```

## Safe Defaults (v1)
- No unauthorised internet-wide scans
- Per-job concurrency caps
- Template allowlist for nuclei (curated, low-noise)
- Strict timeout and retry budgets
- Full audit trail for every job stage

## Stage Output Contract
- `naabu`: host + open ports
- `nmap`: host/port/service/version/cpe/scripts
- `httpx`: URL/status/title/tech/tls metadata
- `nuclei`: finding id/severity/template/asset/evidence

## v2 Expansion (optional)
- amass/subfinder (attack surface discovery)
- dnsx (resolution validation)
- OpenVAS for authenticated checks in controlled engagements
