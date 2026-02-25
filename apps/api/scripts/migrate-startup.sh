#!/usr/bin/env sh
set -eu

BASELINE_MIGRATION="20260225_step12_baseline"

if pnpm --filter @armadillo/api exec prisma migrate deploy; then
  exit 0
fi

echo "[migrate-startup] migrate deploy failed, checking for baseline-needed state..."

if pnpm --filter @armadillo/api exec prisma migrate resolve --applied "${BASELINE_MIGRATION}"; then
  echo "[migrate-startup] baseline marked as applied: ${BASELINE_MIGRATION}"
  pnpm --filter @armadillo/api exec prisma migrate deploy
  exit 0
fi

echo "[migrate-startup] migration bootstrap failed"
exit 1
