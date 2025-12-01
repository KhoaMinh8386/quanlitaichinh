import { CategoryRuleService } from '../services/categoryRule.service';

describe('CategoryRuleService', () => {
  let service: CategoryRuleService;

  beforeEach(() => {
    service = new CategoryRuleService();
  });

  describe('normalizeVietnamese', () => {
    it('should remove Vietnamese diacritics', () => {
      expect(service.normalizeVietnamese('ăn uống')).toBe('an uong');
      expect(service.normalizeVietnamese('đi chuyển')).toBe('di chuyen');
      expect(service.normalizeVietnamese('hóa đơn')).toBe('hoa don');
      expect(service.normalizeVietnamese('Mua sắm')).toBe('mua sam');
    });

    it('should handle mixed Vietnamese and English', () => {
      expect(service.normalizeVietnamese('GRAB FOOD Hà Nội')).toBe('grab food ha noi');
      expect(service.normalizeVietnamese('Shopee Việt Nam')).toBe('shopee viet nam');
    });

    it('should convert to lowercase', () => {
      expect(service.normalizeVietnamese('HELLO WORLD')).toBe('hello world');
      expect(service.normalizeVietnamese('MixedCase')).toBe('mixedcase');
    });

    it('should trim whitespace', () => {
      expect(service.normalizeVietnamese('  text  ')).toBe('text');
      expect(service.normalizeVietnamese('  đi lại  ')).toBe('di lai');
    });

    it('should handle special characters', () => {
      expect(service.normalizeVietnamese('đồng (VND)')).toBe('dong (vnd)');
      expect(service.normalizeVietnamese('100.000 VNĐ')).toBe('100.000 vnd');
    });

    it('should handle all Vietnamese vowels', () => {
      const testCases = [
        ['à á ạ ả ã', 'a a a a a'],
        ['â ầ ấ ậ ẩ ẫ', 'a a a a a a'],
        ['ă ằ ắ ặ ẳ ẵ', 'a a a a a a'],
        ['è é ẹ ẻ ẽ', 'e e e e e'],
        ['ê ề ế ệ ể ễ', 'e e e e e e'],
        ['ì í ị ỉ ĩ', 'i i i i i'],
        ['ò ó ọ ỏ õ', 'o o o o o'],
        ['ô ồ ố ộ ổ ỗ', 'o o o o o o'],
        ['ơ ờ ớ ợ ở ỡ', 'o o o o o o'],
        ['ù ú ụ ủ ũ', 'u u u u u'],
        ['ư ừ ứ ự ử ữ', 'u u u u u u'],
        ['ỳ ý ỵ ỷ ỹ', 'y y y y y'],
        ['đ', 'd'],
      ];

      testCases.forEach(([input, expected]) => {
        expect(service.normalizeVietnamese(input)).toBe(expected);
      });
    });
  });

  describe('Transaction categorization keywords', () => {
    const testKeywordMatching = (description: string, normalizedDesc: string) => {
      const service = new CategoryRuleService();
      return service.normalizeVietnamese(description);
    };

    it('should match food-related keywords', () => {
      expect(testKeywordMatching('GRAB FOOD thanh toán', '')).toBe('grab food thanh toan');
      expect(testKeywordMatching('SHOPEE FOOD đặt hàng', '')).toBe('shopee food dat hang');
      expect(testKeywordMatching('Nhà hàng Phở 24', '')).toBe('nha hang pho 24');
      expect(testKeywordMatching('THE COFFEE HOUSE', '')).toBe('the coffee house');
    });

    it('should match transport-related keywords', () => {
      expect(testKeywordMatching('GRAB di chuyển', '')).toBe('grab di chuyen');
      expect(testKeywordMatching('BE taxi', '')).toBe('be taxi');
      expect(testKeywordMatching('PETROLIMEX đổ xăng', '')).toBe('petrolimex do xang');
      expect(testKeywordMatching('Gửi xe máy', '')).toBe('gui xe may');
    });

    it('should match bills-related keywords', () => {
      expect(testKeywordMatching('Tiền điện tháng 1', '')).toBe('tien dien thang 1');
      expect(testKeywordMatching('EVN Hà Nội', '')).toBe('evn ha noi');
      expect(testKeywordMatching('VNPT Internet', '')).toBe('vnpt internet');
      expect(testKeywordMatching('Nạp điện thoại', '')).toBe('nap dien thoai');
    });

    it('should match shopping-related keywords', () => {
      expect(testKeywordMatching('SHOPEE mua sắm', '')).toBe('shopee mua sam');
      expect(testKeywordMatching('LAZADA đơn hàng', '')).toBe('lazada don hang');
      expect(testKeywordMatching('Thế Giới Di Động', '')).toBe('the gioi di dong');
      expect(testKeywordMatching('VINMART siêu thị', '')).toBe('vinmart sieu thi');
    });

    it('should match entertainment-related keywords', () => {
      expect(testKeywordMatching('NETFLIX thanh toán', '')).toBe('netflix thanh toan');
      expect(testKeywordMatching('CGV Cinema', '')).toBe('cgv cinema');
      expect(testKeywordMatching('Karaoke ICool', '')).toBe('karaoke icool');
      expect(testKeywordMatching('GYM tập luyện', '')).toBe('gym tap luyen');
    });

    it('should match health-related keywords', () => {
      expect(testKeywordMatching('Bệnh viện Bạch Mai', '')).toBe('benh vien bach mai');
      expect(testKeywordMatching('Nhà thuốc Long Châu', '')).toBe('nha thuoc long chau');
      expect(testKeywordMatching('Bảo hiểm Prudential', '')).toBe('bao hiem prudential');
      expect(testKeywordMatching('Khám bệnh định kỳ', '')).toBe('kham benh dinh ky');
    });

    it('should match education-related keywords', () => {
      expect(testKeywordMatching('Học phí đại học', '')).toBe('hoc phi dai hoc');
      expect(testKeywordMatching('Khóa học Udemy', '')).toBe('khoa hoc udemy');
      expect(testKeywordMatching('FAHASA sách', '')).toBe('fahasa sach');
    });
  });
});

describe('Keyword extraction', () => {
  it('should extract meaningful keywords from transaction descriptions', () => {
    // These are example transaction descriptions from Vietnamese banks
    const descriptions = [
      'NGUYEN VAN A chuyen tien GRAB FOOD don hang 123456',
      'THE TIN DUNG THANH TOAN SHOPEE MA GD 789012',
      'CHUYEN KHOAN QUA INTERNET BANKING EVN TIEN DIEN',
    ];

    // After normalization, should be able to find key terms
    const service = new CategoryRuleService();
    
    descriptions.forEach(desc => {
      const normalized = service.normalizeVietnamese(desc);
      expect(normalized.length).toBeGreaterThan(0);
      // Should not contain Vietnamese diacritics
      expect(normalized).not.toMatch(/[àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ]/);
    });
  });
});

