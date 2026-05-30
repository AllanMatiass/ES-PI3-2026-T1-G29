/**
 * @file pricingEngine.test.ts
 * @description Testes unitários para o motor de precificação (Pricing Engine).
 * @author Allan Giovanni Matias Paes - 25008211
 */

import {
  calculatePrimaryMarketPrice,
  calculateSecondaryMarketPrice,
  calculateTertiaryMarketPrice,
  applySafetyLock,
} from "../../shared/pricingEngine";

describe("PricingEngine", () => {
  /**
   * Conjunto de testes para a trava de segurança (Safety Lock).
   * A trava garante que o preço não varie além de uma porcentagem definida em relação ao preço base.
   */
  describe("applySafetyLock", () => {
    /**
     * Verifica se o preço calculado é mantido quando a variação está dentro do limite (5%).
     */
    it("deve retornar o preço calculado se estiver dentro da variação de 5%", () => {
      const result = applySafetyLock(1020, 1000, 0.05);
      expect(result).toBe(1020);
    });

    /**
     * Verifica se o preço é limitado ao teto de +5% quando a variação calculada é superior.
     */
    it("deve limitar o preço em +5% se a variação calculada for superior", () => {
      const result = applySafetyLock(1100, 1000, 0.05);
      expect(result).toBe(1050); // 1000 * 1.05
    });

    /**
     * Verifica se o preço é limitado ao piso de -5% quando a variação calculada é inferior.
     */
    it("deve limitar o preço em -5% se a variação calculada for inferior", () => {
      const result = applySafetyLock(900, 1000, 0.05);
      expect(result).toBe(950); // 1000 * 0.95
    });
  });

  /**
   * Conjunto de testes para o cálculo de preço no Mercado Primário.
   * O preço no mercado primário aumenta conforme a quantidade de tokens comprada.
   */
  describe("calculatePrimaryMarketPrice", () => {
    /**
     * Valida o aumento proporcional do preço com base na quantidade adquirida e na constante de inclinação K.
     */
    it("deve aumentar o preço com base na quantidade de compra", () => {
      // Q=100.000, Total=1.000.000, K=0.1
      // Fator = (100k / 1M) * 0.1 = 0.1 * 0.1 = 0.01 (1%)
      // Novo Preço = 1000 * 1.01 = 1010
      const result = calculatePrimaryMarketPrice(1000, 100000, 1000000, 0.1);
      expect(result).toBe(1010);
    });

    /**
     * Garante que compras de grandes volumes sejam limitadas pela trava de segurança.
     */
    it("deve ser limitado pela trava de segurança em compras grandes", () => {
      // Q=800.000, Total=1.000.000, K=0.1
      // Fator = 0.8 * 0.1 = 0.08 (8%)
      // Preço Calc = 1000 * 1.08 = 1080
      // Trava de Segurança = 1050 (+5%)
      const result = calculatePrimaryMarketPrice(1000, 800000, 1000000, 0.1);
      expect(result).toBe(1050);
    });
  });

  /**
   * Conjunto de testes para o cálculo de preço no Mercado Secundário.
   * O preço é ajustado com base no valor da oferta e na quantidade de tokens envolvida.
   */
  describe("calculateSecondaryMarketPrice", () => {
    /**
     * Valida o ajuste positivo quando a oferta é superior ao preço de mercado atual.
     */
    it("deve ajustar o preço com base no preço da oferta e quantidade", () => {
      // Atual=1000, Oferta=1200, Q=100.000, Total=1.000.000, K=0.5
      // FatorDiffPreco = (1200-1000)/1000 = 0.2
      // FatorQ = 100k/1M = 0.1
      // Fator = 0.2 * 0.1 * 0.5 = 0.01 (1%)
      // Novo Preço = 1000 * 1.01 = 1010
      const result = calculateSecondaryMarketPrice(
        1000,
        1200,
        100000,
        1000000,
        0.5,
      );
      expect(result).toBe(1010);
    });

    /**
     * Valida o ajuste negativo quando a oferta é inferior ao preço de mercado atual.
     */
    it("deve diminuir o preço se a oferta estiver abaixo do mercado", () => {
      // Atual=1000, Oferta=800, Q=100.000 (Quantidade de tokens da oferta), Total=1.000.000, K=0.5
      // FatorDiffPreco = (800-1000)/1000 = -0.2
      // Fator = -0.2 * 0.1 * 0.5 = -0.01 (-1%)
      // Novo Preço = 1000 * 0.99 = 990
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

  /**
   * Conjunto de testes para o cálculo de preço no Mercado Terciário.
   * O preço no mercado terciário é ajustado por um delta (variação direta).
   */
  describe("calculateTertiaryMarketPrice", () => {
    /**
     * Valida a aplicação direta de uma variação (delta) ao preço.
     */
    it("deve aplicar o delta diretamente", () => {
      // Delta = 0.03 (3%)
      // Novo Preço = 1000 * 1.03 = 1030
      const result = calculateTertiaryMarketPrice(1000, 0.03);
      expect(result).toBe(1030);
    });

    /**
     * Garante que variações agressivas no delta sejam limitadas pela trava de segurança.
     */
    it("deve ser limitado pela trava de segurança", () => {
      // Delta = 0.10 (10%)
      // Preço Calc = 1100
      // Trava de Segurança = 1050
      const result = calculateTertiaryMarketPrice(1000, 0.1);
      expect(result).toBe(1050);
    });
  });
});
