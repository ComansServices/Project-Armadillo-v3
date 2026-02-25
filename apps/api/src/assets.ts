import { prisma } from './prisma';

export async function listAssets(limit = 50) {
  return prisma.asset.findMany({
    orderBy: { createdAt: 'desc' },
    take: limit
  });
}

export async function getAsset(id: string) {
  return prisma.asset.findUnique({ where: { id } });
}
