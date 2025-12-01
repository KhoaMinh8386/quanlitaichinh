/**
 * MerchantExtractor - Utility class to extract merchant names from transaction descriptions
 * Validates: Requirements 22.1
 */
export class MerchantExtractor {
  /**
   * Extract merchant name from transaction description
   * Handles common transaction description formats
   */
  static extractMerchant(description: string): string | null {
    if (!description || description.trim().length === 0) {
      return null;
    }

    const normalized = description.trim();

    // Pattern 1: "MERCHANT NAME - LOCATION" or "MERCHANT NAME-LOCATION"
    // Example: "STARBUCKS - NEW YORK" or "STARBUCKS-NEW YORK"
    const dashPattern = /^([A-Z0-9\s&'.]+?)\s*-\s*/i;
    const dashMatch = normalized.match(dashPattern);
    if (dashMatch) {
      return this.cleanMerchantName(dashMatch[1]);
    }

    // Pattern 2: "POS MERCHANT NAME" or "ATM MERCHANT NAME"
    // Example: "POS WALMART SUPERCENTER" or "ATM CHASE BANK"
    const posAtmPattern = /^(?:POS|ATM)\s+(.+?)(?:\s+\d|$)/i;
    const posAtmMatch = normalized.match(posAtmPattern);
    if (posAtmMatch) {
      return this.cleanMerchantName(posAtmMatch[1]);
    }

    // Pattern 3: "MERCHANT NAME *LOCATION" or "MERCHANT NAME * LOCATION"
    // Example: "AMAZON.COM *SEATTLE WA" or "UBER * TRIP"
    const asteriskPattern = /^(.+?)\s*\*\s*/i;
    const asteriskMatch = normalized.match(asteriskPattern);
    if (asteriskMatch) {
      return this.cleanMerchantName(asteriskMatch[1]);
    }

    // Pattern 4: "MERCHANT NAME #REFERENCE" or "MERCHANT NAME # REFERENCE"
    // Example: "NETFLIX #12345" or "SPOTIFY # SUBSCRIPTION"
    const hashPattern = /^(.+?)\s*#\s*/i;
    const hashMatch = normalized.match(hashPattern);
    if (hashMatch) {
      return this.cleanMerchantName(hashMatch[1]);
    }

    // Pattern 5: "MERCHANT NAME CITY STATE" (extract first 2-3 words)
    // Example: "TARGET STORE NEW YORK NY"
    const wordsPattern = /^([A-Z][A-Z0-9\s&'.]{2,}?)(?:\s+[A-Z]{2,}){2,}/i;
    const wordsMatch = normalized.match(wordsPattern);
    if (wordsMatch) {
      return this.cleanMerchantName(wordsMatch[1]);
    }

    // Pattern 6: "MERCHANT.COM" or "WWW.MERCHANT.COM"
    // Example: "AMAZON.COM" or "WWW.PAYPAL.COM"
    const domainPattern = /^(?:WWW\.)?([A-Z0-9]+)\.(?:COM|NET|ORG)/i;
    const domainMatch = normalized.match(domainPattern);
    if (domainMatch) {
      return this.cleanMerchantName(domainMatch[1]);
    }

    // Pattern 7: "MERCHANT NAME YYYYMMDD" (date at end)
    // Example: "SHELL GAS STATION 20231115"
    const datePattern = /^(.+?)\s+\d{8}$/i;
    const dateMatch = normalized.match(datePattern);
    if (dateMatch) {
      return this.cleanMerchantName(dateMatch[1]);
    }

    // Pattern 8: "MERCHANT NAME CARD XXXX" (card number at end)
    // Example: "WALMART CARD 1234"
    const cardPattern = /^(.+?)\s+(?:CARD|XXXX)\s*\d+$/i;
    const cardMatch = normalized.match(cardPattern);
    if (cardMatch) {
      return this.cleanMerchantName(cardMatch[1]);
    }

    // Pattern 9: Extract first meaningful part (up to first number or special char)
    // Example: "MCDONALDS 123 MAIN ST" -> "MCDONALDS"
    const firstPartPattern = /^([A-Z][A-Z\s&'.]{2,}?)(?:\s+\d|\s+[^A-Z\s])/i;
    const firstPartMatch = normalized.match(firstPartPattern);
    if (firstPartMatch) {
      return this.cleanMerchantName(firstPartMatch[1]);
    }

    // Pattern 10: If all else fails, take first 3 words if they look like a merchant name
    const words = normalized.split(/\s+/);
    if (words.length >= 1 && words[0].length >= 3) {
      const merchantCandidate = words.slice(0, Math.min(3, words.length)).join(' ');
      if (this.looksLikeMerchantName(merchantCandidate)) {
        return this.cleanMerchantName(merchantCandidate);
      }
    }

    return null;
  }

  /**
   * Clean and normalize merchant name
   */
  private static cleanMerchantName(name: string): string {
    return name
      .trim()
      .replace(/\s+/g, ' ') // Normalize whitespace
      .replace(/[^A-Z0-9\s&'.]/gi, '') // Remove special chars except &, ', .
      .toUpperCase();
  }

  /**
   * Check if a string looks like a merchant name
   */
  private static looksLikeMerchantName(text: string): boolean {
    // Must be at least 3 characters
    if (text.length < 3) {
      return false;
    }

    // Should not be all numbers
    if (/^\d+$/.test(text)) {
      return false;
    }

    // Should not be common transaction words
    const commonWords = [
      'PAYMENT',
      'TRANSFER',
      'WITHDRAWAL',
      'DEPOSIT',
      'TRANSACTION',
      'PURCHASE',
      'DEBIT',
      'CREDIT',
      'FEE',
      'CHARGE',
    ];

    const upperText = text.toUpperCase();
    if (commonWords.some((word) => upperText === word)) {
      return false;
    }

    return true;
  }

  /**
   * Test the extractor with various patterns
   */
  static test(): void {
    const testCases = [
      'STARBUCKS - NEW YORK',
      'STARBUCKS-NEW YORK',
      'POS WALMART SUPERCENTER 123',
      'ATM CHASE BANK',
      'AMAZON.COM *SEATTLE WA',
      'UBER * TRIP',
      'NETFLIX #12345',
      'SPOTIFY # SUBSCRIPTION',
      'TARGET STORE NEW YORK NY',
      'AMAZON.COM',
      'WWW.PAYPAL.COM',
      'SHELL GAS STATION 20231115',
      'WALMART CARD 1234',
      'MCDONALDS 123 MAIN ST',
      'APPLE STORE PURCHASE',
      'GOOGLE PLAY APPS',
    ];

    console.log('Merchant Extraction Test Results:');
    console.log('='.repeat(50));
    testCases.forEach((testCase) => {
      const merchant = this.extractMerchant(testCase);
      console.log(`Input:  "${testCase}"`);
      console.log(`Output: "${merchant}"`);
      console.log('-'.repeat(50));
    });
  }
}
