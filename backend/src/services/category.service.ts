import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export class CategoryService {
  async getCategories(userId: string) {
    const categories = await prisma.category.findMany({
      where: {
        OR: [{ userId }, { isDefault: true }],
      },
      orderBy: [{ priority: 'desc' }, { name: 'asc' }],
    });

    return categories;
  }

  async getCategoriesByType(userId: string, type: 'income' | 'expense') {
    const categories = await prisma.category.findMany({
      where: {
        type,
        OR: [{ userId }, { isDefault: true }],
      },
      orderBy: [{ priority: 'desc' }, { name: 'asc' }],
    });

    return categories;
  }
}
