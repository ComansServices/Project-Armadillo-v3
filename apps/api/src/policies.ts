import { prisma } from './prisma';

export async function getSourcePolicy(source: string) {
  return prisma.importSourcePolicy.findUnique({ where: { source } });
}

export async function listSourcePolicies() {
  return prisma.importSourcePolicy.findMany({ orderBy: { source: 'asc' } });
}

export async function upsertSourcePolicy(input: {
  source: string;
  enabled?: boolean;
  defaultQualityMode?: 'lenient' | 'strict';
  allowBypassToLenient?: boolean;
}) {
  return prisma.importSourcePolicy.upsert({
    where: { source: input.source },
    create: {
      source: input.source,
      enabled: input.enabled ?? true,
      defaultQualityMode: input.defaultQualityMode ?? 'strict',
      allowBypassToLenient: input.allowBypassToLenient ?? false
    },
    update: {
      enabled: input.enabled,
      defaultQualityMode: input.defaultQualityMode,
      allowBypassToLenient: input.allowBypassToLenient
    }
  });
}
