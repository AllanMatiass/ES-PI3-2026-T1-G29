/**
 * @file valuationService.test.ts
 * @description Testes unitários para o ValuationService, responsável por calcular o valor do portfólio do usuário.
 * @author Allan Giovanni Matias Paes - 25008211
 */

import { ValuationService } from "../../user/shared/valuationService";
import * as userRepo from "../../user/repositories/userRepository";
import * as startupRepo from "../../startups/repositories/startupRepository";
import * as txRepo from "../../exchange/repositories/transactionRepository";
import { Timestamp } from "firebase-admin/firestore";

jest.mock("../../user/repositories/userRepository");
jest.mock("../../startups/repositories/startupRepository");
jest.mock("../../exchange/repositories/transactionRepository");

describe("ValuationService", () => {
  let service: ValuationService;
  const userId = "user-1";
  const startupId = "startup-1";

  beforeEach(() => {
    service = new ValuationService();
    jest.clearAllMocks();
  });

  /**
   * Testa o cálculo da evolução do portfólio ao longo do tempo.
   * O teste simula a posse de tokens, transações passadas e variações no valuation das startups
   * para verificar se o serviço reconstrói o histórico financeiro corretamente.
   */
  test("deve calcular evolução do portfólio corretamente", async () => {
    const now = new Date();
    now.setSeconds(0, 0); // Normalizar como o serviço faz

    const twoDaysAgo = new Date(now);
    twoDaysAgo.setDate(now.getDate() - 2);

    const tenDaysAgo = new Date(now);
    tenDaysAgo.setDate(now.getDate() - 10);

    // Mock do Usuário: Possui 100 tokens de uma startup e investiu 10.000 cents no total.
    (userRepo.getUserById as jest.Mock).mockResolvedValue({
      wallet: {
        balanceInCents: 1000,
        totalInvestedCents: 10000, // Custo total investido para cálculo de variação
        positions: [
          {
            startupId,
            startupName: "Startup A",
            qtdTokens: 100,
          },
        ],
      },
    });

    // Mock de Transações: Comprou 50 tokens há 2 dias por 500 cents.
    // Isso significa que há 7 dias ele tinha apenas 50 tokens (100 atual - 50 comprados depois).
    (txRepo.getTransactionsByUserId as jest.Mock).mockResolvedValue([
      {
        id: "tx-1",
        startupId,
        buyer: { id: userId },
        seller: { id: "startup-id" },
        qtdTokens: 50,
        totalCents: 500,
        createdAt: Timestamp.fromDate(twoDaysAgo),
      },
    ]);

    // Mock da Startup
    (startupRepo.getStartupsByIds as jest.Mock).mockResolvedValue([
      {
        id: startupId,
        name: "Startup A",
        totalTokensIssued: 1000,
      },
    ]);

    // Mock do Histórico de Valuation:
    // 10 dias atrás: Valuation 100k -> Preço do token = 100 cents
    // Hoje: Valuation 200k -> Preço do token = 200 cents
    (startupRepo.getValuationHistory as jest.Mock).mockResolvedValue([
      { value: 100000, createdAt: Timestamp.fromDate(tenDaysAgo) },
      { value: 200000, createdAt: Timestamp.fromDate(now) },
    ]);

    const result = await service.getUserPortfolioHistory(userId, "1W");

    expect(result.range).toBe("1W");
    expect(result.history.length).toBeGreaterThan(0);

    // No ponto "Agora" (último do histórico):
    // Tokens = 100, Preço = 200. Valor Total = (100 * 200) = 20.000 cents
    const latest = result.history[result.history.length - 1];
    expect(latest.valueCents).toBe(20000);

    // No ponto "7 dias atrás" (início do range 1W):
    // Tokens = 100 (atual) - 50 (comprados há 2 dias) = 50 tokens
    // Preço = 100 cents (baseado no valuation de 10 dias atrás)
    // Valor Total = (50 * 100) = 5.000 cents
    const oldest = result.history[0];
    expect(oldest.valueCents).toBe(5000);

    expect(result.totalValueCents).toBe(20000);
    // Variação Nominal = Valor Atual (20.000) - Total Investido (10.000) = 10.000 cents
    expect(result.variationCents).toBe(10000);
  });

  /**
   * Garante que o serviço retorne valores zerados e não quebre quando o usuário não possui investimentos.
   */
  test("deve lidar com usuário sem posições ou transações", async () => {
    (userRepo.getUserById as jest.Mock).mockResolvedValue({
      wallet: {
        balanceInCents: 5000,
        totalInvestedCents: 0,
        positions: [],
      },
    });
    (txRepo.getTransactionsByUserId as jest.Mock).mockResolvedValue([]);

    const result = await service.getUserPortfolioHistory(userId, "1M");

    expect(result.totalValueCents).toBe(0); // Patrimônio em tokens é 0
    expect(result.variationCents).toBe(0);
    expect(result.variationPercent).toBe(0);
    result.history.forEach((point) => {
      expect(point.valueCents).toBe(0);
    });
  });
});
