# Phase 5 Item 6 — Production Auth Hardening

## What was implemented

- Signed session auth for API routes (`/api/v1/*`) using `x-armadillo-auth` or `Authorization: Bearer`.
- Token format: `v1.<base64url(json-claims)>.<hex-hmac>`.
- HMAC SHA-256 verification using `AUTH_SESSION_SECRET`.
- Expiry enforced via `exp` claim.
- Legacy header auth (`x-armadillo-user`, `x-armadillo-role`) retained only behind feature flag.

## Claims model (provider-ready)

```json
{
  "sub": "user-id",
  "role": "viewer|staff|admin|owner",
  "orgId": "org-identifier",
  "projects": ["proj-001", "proj-002", "*"],
  "exp": 1772090000,
  "iat": 1772086400,
  "sid": "session-id"
}
```

This shape is compatible with OIDC/SAML mapping at the identity provider boundary.

## Scope enforcement

Project scope checks now apply at auth boundary for:
- create scan
- list scans (results filtered)
- get scan details
- get scan events
- schedule list/create/toggle

`run-due` schedule executor now requires `admin`.

## Auth audit + lockout

- Failed auth attempts are audited via structured log event `auth_audit`.
- Lockout policy after repeated failures:
  - threshold: `AUTH_FAIL_THRESHOLD` (default 5)
  - lock duration: `AUTH_LOCK_MINUTES` (default 15)
- Locked callers receive HTTP `423 auth_locked`.

## Environment controls

- `AUTH_SESSION_SECRET` (required for signed sessions)
- `AUTH_ALLOW_LEGACY_HEADERS` (default `true`, must be `false` in prod)
- `AUTH_FAIL_THRESHOLD` (default `5`)
- `AUTH_LOCK_MINUTES` (default `15`)

## Production setting (required)

Set:

```bash
AUTH_ALLOW_LEGACY_HEADERS=false
```

This removes header-scaffold auth from production path.
