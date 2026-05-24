import {
  calculatePrimaryMarketPrice,
  calculateSecondaryMarketPrice,
  calculateTertiaryMarketPrice,
  applySafetyLock,
} from "../../shared/pricingEngine";

describe("PricingEngine", () => {
  describe("applySafetyLock", () => {
    it("should return the calculated price if within 5% variation", () => {
      const result = applySafetyLock(1020, 1000, 0.05);
      expect(result).toBe(1020);
    });

    it("should cap the price at +5% if calculated variation is higher", () => {
      const result = applySafetyLock(1100, 1000, 0.05);
      expect(result).toBe(1050); // 1000 * 1.05
    });

    it("should floor the price at -5% if calculated variation is lower", () => {
      const result = applySafetyLock(900, 1000, 0.05);
      expect(result).toBe(950); // 1000 * 0.95
    });
  });

  describe("calculatePrimaryMarketPrice", () => {
    it("should increase price based on purchase quantity", () => {
      // Q=100.000, Total=1.000.000, K=0.1
      // Factor = (100k / 1M) * 0.1 = 0.1 * 0.1 = 0.01 (1%)
      // New Price = 1000 * 1.01 = 1010
      const result = calculatePrimaryMarketPrice(1000, 100000, 1000000, 0.1);
      expect(result).toBe(1010);
    });

    it("should be capped by safety lock on large purchases", () => {
      // Q=800.000, Total=1.000.000, K=0.1
      // Factor = 0.8 * 0.1 = 0.08 (8%)
      // Calc Price = 1000 * 1.08 = 1080
      // Safety Lock = 1050 (+5%)
      const result = calculatePrimaryMarketPrice(1000, 800000, 1000000, 0.1);
      expect(result).toBe(1050);
    });
  });

  describe("calculateSecondaryMarketPrice", () => {
    it("should adjust price based on offer price and quantity", () => {
      // Current=1000, Offer=1200, Q=100.000, Total=1.000.000, K=0.5
      // PriceDiffFactor = (1200-1000)/1000 = 0.2
      // QFactor = 100k/1M = 0.1
      // Factor = 0.2 * 0.1 * 0.5 = 0.01 (1%)
      // New Price = 1000 * 1.01 = 1010
      const result = calculateSecondaryMarketPrice(
        1000,
        1200,
        100000,
        1000000,
        0.5,
      );
      expect(result).toBe(1010);
    });

    it("should decrease price if offer is below market", () => {
      // Current=1000, Offer=800, Q=100.000, Total=1.000.000, K=0.5
      // PriceDiffFactor = (800-1000)/1000 = -0.2
      // Factor = -0.2 * 0.1 * 0.5 = -0.01 (-1%)
      // New Price = 1000 * 0.99 = 990
      const result = calculateSecondaryMarketPrice(
        1000,
        800,
        100000,
        1000000,
        0.5,
      );
      expect(result).toBe(990);
    });
  });

  describe("calculateTertiaryMarketPrice", () => {
    it("should apply delta directly", () => {
      // Delta = 0.03 (3%)
      // New Price = 1000 * 1.03 = 1030
      const result = calculateTertiaryMarketPrice(1000, 0.03);
      expect(result).toBe(1030);
    });

    it("should be capped by safety lock", () => {
      // Delta = 0.10 (10%)
      // Calc Price = 1100
      // Safety Lock = 1050
      const result = calculateTertiaryMarketPrice(1000, 0.1);
      expect(result).toBe(1050);
    });
  });
});
