// Autor: Allan Giovanni Matias Paes - 25008211
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

  test("deve calcular evolução do portfólio corretamente", async () => {
    const now = new Date();
    now.setSeconds(0, 0); // Normalizar como o serviço faz

    const twoDaysAgo = new Date(now);
    twoDaysAgo.setDate(now.getDate() - 2);

    const tenDaysAgo = new Date(now);
    tenDaysAgo.setDate(now.getDate() - 10);
    // Mock User
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

    // Mock Transactions
    // Há 2 dias comprou 50 tokens por 500 cents (totalCents = 500)
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

    // Mock Startups
    (startupRepo.getStartupsByIds as jest.Mock).mockResolvedValue([
      {
        id: startupId,
        name: "Startup A",
        totalTokensIssued: 1000,
      },
    ]);

    // Mock Valuations
    // 10 dias atrás: Valuation 100000 -> Preço 100000/1000 = 100 cents/token
    // Hoje: Valuation 200000 -> Preço 200000/1000 = 200 cents/token
    (startupRepo.getValuationHistory as jest.Mock).mockResolvedValue([
      { value: 100000, createdAt: Timestamp.fromDate(tenDaysAgo) },
      { value: 200000, createdAt: Timestamp.fromDate(now) },
    ]);

    const result = await service.getUserPortfolioHistory(userId, "1W");

    expect(result.range).toBe("1W");
    expect(result.history.length).toBeGreaterThan(0);

    // No ponto "Agora" (último do histórico):
    // Tokens = 100, Price = 200. Total = (100 * 200) = 20000 (O service atual não soma balance)
    const latest = result.history[result.history.length - 1];
    expect(latest.valueCents).toBe(20000);

    // No ponto "7 dias atrás":
    // Tokens = 100 - 50 = 50
    // Price = 100 (valuation de 10 dias atrás)
    // Total = (50 * 100) = 5000
    const oldest = result.history[0];
    expect(oldest.valueCents).toBe(5000);

    expect(result.totalValueCents).toBe(20000);
    // Variação = latestValue (20000) - totalInvestedCents (10000) = 10000
    expect(result.variationCents).toBe(10000);
  });

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

    expect(result.totalValueCents).toBe(0); // Sem ativos = 0 (balance não conta)
    expect(result.variationCents).toBe(0);
    expect(result.variationPercent).toBe(0);
    result.history.forEach((point) => {
      expect(point.valueCents).toBe(0);
    });
  });
});
