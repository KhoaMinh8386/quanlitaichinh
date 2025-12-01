import fc from 'fast-check';
import { MerchantExtractor } from '../utils/merchantExtractor';
import { it } from 'node:test';
import { describe } from 'node:test';
import { it } from 'node:test';
import { it } from 'node:test';
import { it } from 'node:test';
import { it } from 'node:test';
import { it } from 'node:test';
import { it } from 'node:test';
import { it } from 'node:test';
import { it } from 'node:test';
import { it } from 'node:test';
import { it } from 'node:test';
import { describe } from 'node:test';
import { describe } from 'node:test';

/**
 * Property-Based Tests for Merchant Extraction
 * Feature: advanced-financial-management, Property 67: Merchant pattern extraction
 * Validates: Requirements 22.1
 */
describe('MerchantExtractor Property-Based Tests', () => {
  /**
   * Property 67: Merchant pattern extraction
   * For any manual categorization, if a merchant name can be extracted from description,
   * it should be stored as a pattern.
   */
  describe('Property 67: Merchant pattern extraction', () => {
    it('should extract merchant from dash-separated descriptions', () => {
      fc.assert(
        fc.property(
          fc.string({ minLength: 3, maxLength: 30 }).filter(s => /^[A-Z0-9\s&'.]+$/i.test(s.trim())),
          fc.string({ minLength: 3, maxLength: 20 }).filter(s => /^[A-Z0-9\s]+$/i.test(s.trim())),
          (merchantName, location) => {
            const description = `${merchantName} - ${location}`;
            const extracted = MerchantExtractor.extractMerchant(description);
            
            expect(extracted).not.toBeNull();
            expect(extracted).toBeTruthy();
            // The extracted merchant should be a cleaned version of the merchant name
            expect(extracted?.toUpperCase()).toContain(merchantName.trim().split(/\s+/)[0].toUpperCase());
          }
        ),
        { numRuns: 100 }
      );
    });

    it('should extract merchant from POS/ATM prefixed descriptions', () => {
      fc.assert(
        fc.property(
          fc.constantFrom('POS', 'ATM'),
          fc.string({ minLength: 3, maxLength: 30 }).filter(s => /^[A-Z0-9\s&'.]+$/i.test(s.trim())),
          (prefix, merchantName) => {
            const description = `${prefix} ${merchantName} 123`;
            const extracted = MerchantExtractor.extractMerchant(description);
            
            expect(extracted).not.toBeNull();
            expect(extracted).toBeTruthy();
            // Should extract the merchant name without the prefix
            expect(extracted).not.toContain(prefix);
          }
        ),
        { numRuns: 100 }
      );
    });

    it('should extract merchant from asterisk-separated descriptions', () => {
      fc.assert(
        fc.property(
          fc.string({ minLength: 3, maxLength: 30 }).filter(s => /^[A-Z0-9\s&'.]+$/i.test(s.trim())),
          fc.string({ minLength: 3, maxLength: 20 }).filter(s => /^[A-Z0-9\s]+$/i.test(s.trim())),
          (merchantName, location) => {
            const description = `${merchantName} * ${location}`;
            const extracted = MerchantExtractor.extractMerchant(description);
            
            expect(extracted).not.toBeNull();
            expect(extracted).toBeTruthy();
            // The extracted merchant should be a cleaned version of the merchant name
            expect(extracted?.toUpperCase()).toContain(merchantName.trim().split(/\s+/)[0].toUpperCase());
          }
        ),
        { numRuns: 100 }
      );
    });

    it('should extract merchant from hash-separated descriptions', () => {
      fc.assert(
        fc.property(
          fc.string({ minLength: 3, maxLength: 30 }).filter(s => /^[A-Z0-9\s&'.]+$/i.test(s.trim())),
          fc.integer({ min: 1000, max: 99999 }),
          (merchantName, reference) => {
            const description = `${merchantName} #${reference}`;
            const extracted = MerchantExtractor.extractMerchant(description);
            
            expect(extracted).not.toBeNull();
            expect(extracted).toBeTruthy();
            // Should not contain the reference number
            expect(extracted).not.toContain(reference.toString());
          }
        ),
        { numRuns: 100 }
      );
    });

    it('should extract merchant from domain-style descriptions', () => {
      fc.assert(
        fc.property(
          fc.string({ minLength: 3, maxLength: 20 }).filter(s => /^[A-Z0-9]+$/i.test(s)),
          fc.constantFrom('COM', 'NET', 'ORG'),
          (merchantName, tld) => {
            const description = `${merchantName}.${tld}`;
            const extracted = MerchantExtractor.extractMerchant(description);
            
            expect(extracted).not.toBeNull();
            expect(extracted).toBeTruthy();
            expect(extracted?.toUpperCase()).toBe(merchantName.toUpperCase());
          }
        ),
        { numRuns: 100 }
      );
    });

    it('should extract merchant from descriptions with dates', () => {
      fc.assert(
        fc.property(
          fc.string({ minLength: 3, maxLength: 30 }).filter(s => /^[A-Z0-9\s&'.]+$/i.test(s.trim())),
          fc.integer({ min: 20200101, max: 20251231 }),
          (merchantName, date) => {
            const description = `${merchantName} ${date}`;
            const extracted = MerchantExtractor.extractMerchant(description);
            
            expect(extracted).not.toBeNull();
            expect(extracted).toBeTruthy();
            // Should not contain the date
            expect(extracted).not.toContain(date.toString());
          }
        ),
        { numRuns: 100 }
      );
    });

    it('should return null for empty or whitespace-only descriptions', () => {
      fc.assert(
        fc.property(
          fc.constantFrom('', '   ', '\t', '\n', '  \t  '),
          (emptyString) => {
            const extracted = MerchantExtractor.extractMerchant(emptyString);
            expect(extracted).toBeNull();
          }
        ),
        { numRuns: 100 }
      );
    });

    it('should return uppercase cleaned merchant names', () => {
      fc.assert(
        fc.property(
          fc.string({ minLength: 3, maxLength: 30 }).filter(s => /^[A-Z0-9\s&'.]+$/i.test(s.trim())),
          (merchantName) => {
            const description = `${merchantName} - LOCATION`;
            const extracted = MerchantExtractor.extractMerchant(description);
            
            if (extracted) {
              // Should be uppercase
              expect(extracted).toBe(extracted.toUpperCase());
              // Should not have multiple consecutive spaces
              expect(extracted).not.toMatch(/\s{2,}/);
              // Should not have leading/trailing spaces
              expect(extracted).toBe(extracted.trim());
            }
          }
        ),
        { numRuns: 100 }
      );
    });

    it('should handle various merchant name formats consistently', () => {
      fc.assert(
        fc.property(
          fc.string({ minLength: 3, maxLength: 20 }).filter(s => /^[A-Z0-9\s&'.]+$/i.test(s.trim())),
          (merchantName) => {
            const formats = [
              `${merchantName} - LOCATION`,
              `POS ${merchantName} 123`,
              `${merchantName} * INFO`,
              `${merchantName} #12345`,
            ];
            
            const results = formats.map(desc => MerchantExtractor.extractMerchant(desc));
            
            // All formats should extract something
            results.forEach(result => {
              expect(result).not.toBeNull();
            });
            
            // All results should contain the first word of the merchant name
            const firstWord = merchantName.trim().split(/\s+/)[0].toUpperCase();
            results.forEach(result => {
              if (result && firstWord.length >= 3) {
                expect(result).toContain(firstWord);
              }
            });
          }
        ),
        { numRuns: 100 }
      );
    });

    it('should not extract common transaction words as merchants', () => {
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

      commonWords.forEach(word => {
        const extracted = MerchantExtractor.extractMerchant(word);
        // These should either be null or not be the word itself
        if (extracted) {
          expect(extracted).not.toBe(word);
        }
      });
    });
  });

  // Additional unit tests for specific known patterns
  describe('Known pattern tests', () => {
    it('should extract from real-world examples', () => {
      const testCases = [
        { input: 'STARBUCKS - NEW YORK', expected: 'STARBUCKS' },
        { input: 'POS WALMART SUPERCENTER 123', expected: 'WALMART SUPERCENTER' },
        { input: 'AMAZON.COM *SEATTLE WA', expected: 'AMAZON.COM' },
        { input: 'NETFLIX #12345', expected: 'NETFLIX' },
        { input: 'AMAZON.COM', expected: 'AMAZON' },
        { input: 'WWW.PAYPAL.COM', expected: 'PAYPAL' },
        { input: 'SHELL GAS STATION 20231115', expected: 'SHELL' }, // Extracts first word before date
        { input: 'WALMART CARD 1234', expected: 'WALMART' },
      ];

      testCases.forEach(({ input, expected }) => {
        const result = MerchantExtractor.extractMerchant(input);
        expect(result).not.toBeNull();
        expect(result).toContain(expected);
      });
    });
  });
});
