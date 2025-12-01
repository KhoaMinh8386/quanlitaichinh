import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcrypt';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

const prisma = new PrismaClient();

async function main() {
  console.log('Starting database seeding...');

  // Seed default categories
  console.log('Seeding default categories...');
  
  const expenseCategories = [
    { name: 'Food', viSlug: 'an-uong', icon: 'restaurant', color: '#FF6B6B', priority: 1 },
    { name: 'Transport', viSlug: 'di-chuyen', icon: 'directions_car', color: '#4ECDC4', priority: 2 },
    { name: 'Bills', viSlug: 'hoa-don', icon: 'receipt', color: '#FFE66D', priority: 3 },
    { name: 'Entertainment', viSlug: 'giai-tri', icon: 'movie', color: '#A8E6CF', priority: 4 },
    { name: 'Shopping', viSlug: 'mua-sam', icon: 'shopping_bag', color: '#FF8B94', priority: 5 },
    { name: 'Health', viSlug: 'suc-khoe', icon: 'local_hospital', color: '#C7CEEA', priority: 6 },
    { name: 'Education', viSlug: 'giao-duc', icon: 'school', color: '#B4A7D6', priority: 7 },
    { name: 'Travel', viSlug: 'du-lich', icon: 'flight', color: '#FFD3B6', priority: 8 },
    { name: 'Personal Care', viSlug: 'cham-soc-ca-nhan', icon: 'spa', color: '#FFAAA5', priority: 9 },
    { name: 'Gifts & Donations', viSlug: 'qua-tang', icon: 'card_giftcard', color: '#FF8C94', priority: 10 },
    { name: 'Insurance', viSlug: 'bao-hiem', icon: 'shield', color: '#A8DADC', priority: 11 },
    { name: 'Debt & Credit', viSlug: 'no-tin-dung', icon: 'credit_card', color: '#E63946', priority: 12 },
    { name: 'Other', viSlug: 'khac', icon: 'category', color: '#95A5A6', priority: 99 },
    { name: 'Uncategorized', viSlug: 'chua-phan-loai', icon: 'help_outline', color: '#BDC3C7', priority: 100 },
  ];

  const incomeCategories = [
    { name: 'Salary', viSlug: 'luong', icon: 'payments', color: '#2ECC71', priority: 1 },
    { name: 'Business Income', viSlug: 'kinh-doanh', icon: 'business', color: '#27AE60', priority: 2 },
    { name: 'Investment Returns', viSlug: 'dau-tu', icon: 'trending_up', color: '#16A085', priority: 3 },
    { name: 'Freelance', viSlug: 'tu-do', icon: 'laptop', color: '#1ABC9C', priority: 4 },
    { name: 'Rental Income', viSlug: 'cho-thue', icon: 'home', color: '#3498DB', priority: 5 },
    { name: 'Gifts Received', viSlug: 'qua-nhan', icon: 'redeem', color: '#9B59B6', priority: 6 },
    { name: 'Refunds', viSlug: 'hoan-tien', icon: 'replay', color: '#34495E', priority: 7 },
    { name: 'Other Income', viSlug: 'thu-khac', icon: 'attach_money', color: '#95A5A6', priority: 99 },
  ];

  // Create expense categories
  const createdExpenseCategories: any[] = [];
  for (const category of expenseCategories) {
    const existing = await prisma.category.findFirst({
      where: { name: category.name, isDefault: true, type: 'expense' }
    });
    
    if (!existing) {
      const created = await prisma.category.create({
        data: {
          ...category,
          type: 'expense',
          isDefault: true,
        },
      });
      createdExpenseCategories.push(created);
    } else {
      createdExpenseCategories.push(existing);
    }
  }

  // Create income categories
  for (const category of incomeCategories) {
    const existing = await prisma.category.findFirst({
      where: { name: category.name, isDefault: true, type: 'income' }
    });
    
    if (!existing) {
      await prisma.category.create({
        data: {
          ...category,
          type: 'income',
          isDefault: true,
        },
      });
    }
  }

  console.log('Default categories seeded successfully');

  // Seed category rules for Vietnamese transactions
  console.log('Seeding category rules...');
  
  const categoryRules: { categoryName: string; rules: { keyword: string; priority: number }[] }[] = [
    {
      categoryName: 'Food',
      rules: [
        { keyword: 'GRAB FOOD', priority: 1 },
        { keyword: 'GRABFOOD', priority: 1 },
        { keyword: 'SHOPEE FOOD', priority: 1 },
        { keyword: 'SHOPEEFOOD', priority: 1 },
        { keyword: 'NOW.VN', priority: 1 },
        { keyword: 'BAEMIN', priority: 1 },
        { keyword: 'GOFOOD', priority: 1 },
        { keyword: 'HIGHLAND', priority: 2 },
        { keyword: 'STARBUCKS', priority: 2 },
        { keyword: 'PHUC LONG', priority: 2 },
        { keyword: 'THE COFFEE HOUSE', priority: 2 },
        { keyword: 'CAFE', priority: 3 },
        { keyword: 'NHA HANG', priority: 3 },
        { keyword: 'QUAN AN', priority: 3 },
      ],
    },
    {
      categoryName: 'Transport',
      rules: [
        { keyword: 'GRAB', priority: 1 },
        { keyword: 'GOJEK', priority: 1 },
        { keyword: 'BE', priority: 1 },
        { keyword: 'XANH SM', priority: 1 },
        { keyword: 'TAXI', priority: 2 },
        { keyword: 'PETROLIMEX', priority: 2 },
        { keyword: 'XANG DAU', priority: 2 },
        { keyword: 'VIETJET', priority: 2 },
        { keyword: 'VIETNAM AIRLINES', priority: 2 },
        { keyword: 'BAMBOO AIRWAYS', priority: 2 },
        { keyword: 'GUI XE', priority: 3 },
        { keyword: 'PARKING', priority: 3 },
      ],
    },
    {
      categoryName: 'Bills',
      rules: [
        { keyword: 'TIEN DIEN', priority: 1 },
        { keyword: 'EVN', priority: 1 },
        { keyword: 'DIEN LUC', priority: 1 },
        { keyword: 'TIEN NUOC', priority: 1 },
        { keyword: 'CAP NUOC', priority: 1 },
        { keyword: 'INTERNET', priority: 1 },
        { keyword: 'VNPT', priority: 1 },
        { keyword: 'FPT', priority: 1 },
        { keyword: 'VIETTEL', priority: 1 },
        { keyword: 'MOBIFONE', priority: 1 },
        { keyword: 'NAP DIEN THOAI', priority: 2 },
      ],
    },
    {
      categoryName: 'Shopping',
      rules: [
        { keyword: 'SHOPEE', priority: 1 },
        { keyword: 'LAZADA', priority: 1 },
        { keyword: 'TIKI', priority: 1 },
        { keyword: 'SENDO', priority: 1 },
        { keyword: 'THEGIOIDIDONG', priority: 1 },
        { keyword: 'DIEN MAY XANH', priority: 1 },
        { keyword: 'BACH HOA XANH', priority: 1 },
        { keyword: 'VINMART', priority: 2 },
        { keyword: 'COOPMART', priority: 2 },
        { keyword: 'BIG C', priority: 2 },
        { keyword: 'LOTTE', priority: 2 },
        { keyword: 'AEON', priority: 2 },
      ],
    },
    {
      categoryName: 'Entertainment',
      rules: [
        { keyword: 'NETFLIX', priority: 1 },
        { keyword: 'SPOTIFY', priority: 1 },
        { keyword: 'YOUTUBE', priority: 1 },
        { keyword: 'CGV', priority: 1 },
        { keyword: 'LOTTE CINEMA', priority: 1 },
        { keyword: 'GALAXY', priority: 2 },
        { keyword: 'GAME', priority: 2 },
        { keyword: 'KARAOKE', priority: 2 },
        { keyword: 'GYM', priority: 2 },
        { keyword: 'FITNESS', priority: 2 },
        { keyword: 'SPA', priority: 2 },
      ],
    },
    {
      categoryName: 'Health',
      rules: [
        { keyword: 'BENH VIEN', priority: 1 },
        { keyword: 'HOSPITAL', priority: 1 },
        { keyword: 'PHONG KHAM', priority: 1 },
        { keyword: 'NHA THUOC', priority: 1 },
        { keyword: 'PHARMACY', priority: 1 },
        { keyword: 'PRUDENTIAL', priority: 1 },
        { keyword: 'MANULIFE', priority: 1 },
        { keyword: 'AIA', priority: 1 },
        { keyword: 'BAO HIEM', priority: 2 },
      ],
    },
    {
      categoryName: 'Education',
      rules: [
        { keyword: 'HOC PHI', priority: 1 },
        { keyword: 'TUITION', priority: 1 },
        { keyword: 'DAI HOC', priority: 1 },
        { keyword: 'UNIVERSITY', priority: 1 },
        { keyword: 'UDEMY', priority: 1 },
        { keyword: 'COURSERA', priority: 1 },
        { keyword: 'FAHASA', priority: 2 },
        { keyword: 'SACH', priority: 3 },
      ],
    },
  ];

  // Helper function to remove Vietnamese diacritics
  const normalizeVietnamese = (text: string): string => {
    const vietnameseMap: { [key: string]: string } = {
      'à': 'a', 'á': 'a', 'ạ': 'a', 'ả': 'a', 'ã': 'a',
      'â': 'a', 'ầ': 'a', 'ấ': 'a', 'ậ': 'a', 'ẩ': 'a', 'ẫ': 'a',
      'ă': 'a', 'ằ': 'a', 'ắ': 'a', 'ặ': 'a', 'ẳ': 'a', 'ẵ': 'a',
      'è': 'e', 'é': 'e', 'ẹ': 'e', 'ẻ': 'e', 'ẽ': 'e',
      'ê': 'e', 'ề': 'e', 'ế': 'e', 'ệ': 'e', 'ể': 'e', 'ễ': 'e',
      'ì': 'i', 'í': 'i', 'ị': 'i', 'ỉ': 'i', 'ĩ': 'i',
      'ò': 'o', 'ó': 'o', 'ọ': 'o', 'ỏ': 'o', 'õ': 'o',
      'ô': 'o', 'ồ': 'o', 'ố': 'o', 'ộ': 'o', 'ổ': 'o', 'ỗ': 'o',
      'ơ': 'o', 'ờ': 'o', 'ớ': 'o', 'ợ': 'o', 'ở': 'o', 'ỡ': 'o',
      'ù': 'u', 'ú': 'u', 'ụ': 'u', 'ủ': 'u', 'ũ': 'u',
      'ư': 'u', 'ừ': 'u', 'ứ': 'u', 'ự': 'u', 'ử': 'u', 'ữ': 'u',
      'ỳ': 'y', 'ý': 'y', 'ỵ': 'y', 'ỷ': 'y', 'ỹ': 'y',
      'đ': 'd',
    };
    return text.split('').map(char => vietnameseMap[char.toLowerCase()] || char.toLowerCase()).join('').trim();
  };

  for (const categoryRule of categoryRules) {
    const category = createdExpenseCategories.find(c => c.name === categoryRule.categoryName);
    if (!category) continue;

    for (const rule of categoryRule.rules) {
      const existing = await prisma.categoryRule.findFirst({
        where: {
          keyword: rule.keyword,
          categoryId: category.id,
        },
      });

      if (!existing) {
        await prisma.categoryRule.create({
          data: {
            categoryId: category.id,
            keyword: rule.keyword,
            keywordNormalized: normalizeVietnamese(rule.keyword),
            priority: rule.priority,
            isActive: true,
          },
        });
      }
    }
  }

  console.log('Category rules seeded successfully');

  // Seed sample bank providers
  console.log('Seeding sample bank providers...');

  const bankProviders = [
    {
      name: 'MB Bank',
      code: 'MBBANK',
      authType: 'sepay',
      apiBaseUrl: 'https://my.sepay.vn/userapi',
    },
    {
      name: 'Vietcombank',
      code: 'VCB',
      authType: 'sepay',
      apiBaseUrl: 'https://my.sepay.vn/userapi',
    },
    {
      name: 'Techcombank',
      code: 'TCB',
      authType: 'sepay',
      apiBaseUrl: 'https://my.sepay.vn/userapi',
    },
    {
      name: 'BIDV',
      code: 'BIDV',
      authType: 'sepay',
      apiBaseUrl: 'https://my.sepay.vn/userapi',
    },
    {
      name: 'VPBank',
      code: 'VPB',
      authType: 'sepay',
      apiBaseUrl: 'https://my.sepay.vn/userapi',
    },
    {
      name: 'ACB',
      code: 'ACB',
      authType: 'sepay',
      apiBaseUrl: 'https://my.sepay.vn/userapi',
    },
    {
      name: 'TPBank',
      code: 'TPB',
      authType: 'sepay',
      apiBaseUrl: 'https://my.sepay.vn/userapi',
    },
    {
      name: 'Manual Entry',
      code: 'MANUAL',
      authType: 'none',
      apiBaseUrl: 'none',
    },
  ];

  for (const provider of bankProviders) {
    await prisma.bankProvider.upsert({
      where: { code: provider.code },
      update: provider,
      create: provider,
    });
  }

  console.log('Sample bank providers seeded successfully');

  // Create demo user account
  console.log('Creating demo user account...');

  const demoEmail = 'demo@example.com';
  const demoPassword = 'Demo123456!';
  const passwordHash = await bcrypt.hash(demoPassword, 12);

  const demoUser = await prisma.user.upsert({
    where: { email: demoEmail },
    update: {},
    create: {
      email: demoEmail,
      passwordHash: passwordHash,
      fullName: 'Demo User',
      settings: {
        currency: 'VND',
        language: 'vi',
        notifications: true,
        darkMode: false,
      },
    },
  });

  console.log('Demo user created successfully');
  console.log(`Email: ${demoEmail}`);
  console.log(`Password: ${demoPassword}`);
  console.log(`User ID: ${demoUser.id}`);

  // Create demo bank account
  console.log('Creating demo bank account...');

  const mbBankProvider = await prisma.bankProvider.findFirst({
    where: { code: 'MBBANK' },
  });

  if (mbBankProvider) {
    const demoConnection = await prisma.bankConnection.upsert({
      where: { id: '00000000-0000-0000-0000-000000000001' },
      update: {},
      create: {
        id: '00000000-0000-0000-0000-000000000001',
        userId: demoUser.id,
        bankProviderId: mbBankProvider.id,
        accessToken: 'demo_token',
        refreshToken: 'demo_refresh',
        tokenExpiresAt: new Date('2099-12-31'),
        status: 'active',
      },
    });

    const demoBankAccount = await prisma.bankAccount.upsert({
      where: { id: '00000000-0000-0000-0000-000000000002' },
      update: {},
      create: {
        id: '00000000-0000-0000-0000-000000000002',
        userId: demoUser.id,
        connectionId: demoConnection.id,
        bankName: 'MB Bank',
        accountAlias: 'Tài khoản chính',
        accountNumberMask: '******6789',
        accountType: 'checking',
        currency: 'VND',
        balance: 15000000,
        status: 'active',
      },
    });

    console.log('Demo bank account created successfully');

    // Create sample transactions for demo
    console.log('Creating sample transactions...');

    const foodCategory = createdExpenseCategories.find(c => c.name === 'Food');
    const transportCategory = createdExpenseCategories.find(c => c.name === 'Transport');
    const billsCategory = createdExpenseCategories.find(c => c.name === 'Bills');
    const shoppingCategory = createdExpenseCategories.find(c => c.name === 'Shopping');
    const entertainmentCategory = createdExpenseCategories.find(c => c.name === 'Entertainment');
    const salaryCategory = await prisma.category.findFirst({ where: { name: 'Salary', isDefault: true } });

    const sampleTransactions = [
      // Income
      {
        userId: demoUser.id,
        bankAccountId: demoBankAccount.id,
        externalTxnId: 'DEMO_SALARY_001',
        amount: 15000000,
        type: 'income',
        rawDescription: 'LUONG THANG 11/2024',
        normalizedDescription: 'Lương tháng 11/2024',
        postedAt: new Date('2024-11-05'),
        categoryId: salaryCategory?.id,
        classificationSource: 'AUTO',
      },
      // Expenses
      {
        userId: demoUser.id,
        bankAccountId: demoBankAccount.id,
        externalTxnId: 'DEMO_GRAB_001',
        amount: 75000,
        type: 'expense',
        rawDescription: 'GRAB FOOD DON HANG GF123456',
        normalizedDescription: 'Grab Food đơn hàng',
        postedAt: new Date('2024-11-10'),
        categoryId: foodCategory?.id,
        classificationSource: 'AUTO',
      },
      {
        userId: demoUser.id,
        bankAccountId: demoBankAccount.id,
        externalTxnId: 'DEMO_GRAB_002',
        amount: 45000,
        type: 'expense',
        rawDescription: 'GRAB DI CHUYEN',
        normalizedDescription: 'Grab di chuyển',
        postedAt: new Date('2024-11-11'),
        categoryId: transportCategory?.id,
        classificationSource: 'AUTO',
      },
      {
        userId: demoUser.id,
        bankAccountId: demoBankAccount.id,
        externalTxnId: 'DEMO_EVN_001',
        amount: 350000,
        type: 'expense',
        rawDescription: 'THANH TOAN TIEN DIEN EVN',
        normalizedDescription: 'Thanh toán tiền điện EVN',
        postedAt: new Date('2024-11-15'),
        categoryId: billsCategory?.id,
        classificationSource: 'AUTO',
      },
      {
        userId: demoUser.id,
        bankAccountId: demoBankAccount.id,
        externalTxnId: 'DEMO_SHOPEE_001',
        amount: 500000,
        type: 'expense',
        rawDescription: 'SHOPEE DH789012',
        normalizedDescription: 'Shopee mua sắm',
        postedAt: new Date('2024-11-18'),
        categoryId: shoppingCategory?.id,
        classificationSource: 'AUTO',
      },
      {
        userId: demoUser.id,
        bankAccountId: demoBankAccount.id,
        externalTxnId: 'DEMO_NETFLIX_001',
        amount: 260000,
        type: 'expense',
        rawDescription: 'NETFLIX SUBSCRIPTION',
        normalizedDescription: 'Netflix subscription',
        postedAt: new Date('2024-11-20'),
        categoryId: entertainmentCategory?.id,
        classificationSource: 'AUTO',
      },
      {
        userId: demoUser.id,
        bankAccountId: demoBankAccount.id,
        externalTxnId: 'DEMO_COFFEE_001',
        amount: 85000,
        type: 'expense',
        rawDescription: 'THE COFFEE HOUSE',
        normalizedDescription: 'The Coffee House',
        postedAt: new Date('2024-11-22'),
        categoryId: foodCategory?.id,
        classificationSource: 'AUTO',
      },
      {
        userId: demoUser.id,
        bankAccountId: demoBankAccount.id,
        externalTxnId: 'DEMO_PETRO_001',
        amount: 200000,
        type: 'expense',
        rawDescription: 'PETROLIMEX DO XANG',
        normalizedDescription: 'Đổ xăng Petrolimex',
        postedAt: new Date('2024-11-25'),
        categoryId: transportCategory?.id,
        classificationSource: 'AUTO',
      },
    ];

    for (const txn of sampleTransactions) {
      const existing = await prisma.transaction.findFirst({
        where: { externalTxnId: txn.externalTxnId, userId: demoUser.id },
      });

      if (!existing) {
        await prisma.transaction.create({ data: txn });
      }
    }

    console.log('Sample transactions created successfully');

    // Create sample budgets
    console.log('Creating sample budgets...');

    const currentMonth = new Date().getMonth() + 1;
    const currentYear = new Date().getFullYear();

    const sampleBudgets = [
      { categoryId: foodCategory?.id, amountLimit: 3000000 },
      { categoryId: transportCategory?.id, amountLimit: 1500000 },
      { categoryId: entertainmentCategory?.id, amountLimit: 1000000 },
      { categoryId: shoppingCategory?.id, amountLimit: 2000000 },
    ];

    for (const budget of sampleBudgets) {
      if (!budget.categoryId) continue;

      const existing = await prisma.budget.findFirst({
        where: {
          userId: demoUser.id,
          categoryId: budget.categoryId,
          month: currentMonth,
          year: currentYear,
        },
      });

      if (!existing) {
        await prisma.budget.create({
          data: {
            userId: demoUser.id,
            categoryId: budget.categoryId,
            month: currentMonth,
            year: currentYear,
            amountLimit: budget.amountLimit,
          },
        });
      }
    }

    console.log('Sample budgets created successfully');
  }

  console.log('\nDatabase seeding completed successfully!');
}

main()
  .catch((e) => {
    console.error('Error seeding database:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
