// __tests__/InvestmentMetricService.test.ts

import { InvestmentMetricService } from "../../startups/shared/investmentMetricService";
import * as repo from "../../startups/repositories/startupRepository";
import { Timestamp } from "firebase-admin/firestore";

jest.mock("../../startups/repositories/startupRepository");

const mockStartup = (overrides = {}) => ({
  stage: "nova",
  founders: [{}],
  externalMembers: [],
  tags: [],
  totalTokensIssued: 1000,
  ...overrides,
});

describe("InvestmentMetricService", () => {
  let service: InvestmentMetricService;

  beforeEach(() => {
    service = new InvestmentMetricService();
    jest.clearAllMocks();
  });

  test("deve lançar erro se startup não existir", async () => {
    (repo.getStartupById as jest.Mock).mockResolvedValue(null);

    await expect(service.calculateRisk("1")).rejects.toThrow(
      "Startup não encontrada.",
    );
  });

  test("deve calcular risco corretamente para startup simples", async () => {
    (repo.getStartupById as jest.Mock).mockResolvedValue(
      mockStartup({
        stage: "nova",
        founders: [{}],
        externalMembers: [],
        tags: [],
      }),
    );

    const risk = await service.calculateRisk("1");

    expect(typeof risk).toBe("number");
    expect(risk).toBeGreaterThanOrEqual(0);
  });

  test("deve aumentar risco com tags complexas e founder solo", async () => {
    (repo.getStartupById as jest.Mock).mockResolvedValue(
      mockStartup({
        stage: "nova",
        founders: [{}],
        externalMembers: [],
        tags: ["iot"],
      }),
    );

    const risk = await service.calculateRisk("1");

    expect(risk).toBeGreaterThan(5);
  });

  test("deve reduzir risco com múltiplos founders e mentores", async () => {
    (repo.getStartupById as jest.Mock).mockResolvedValue(
      mockStartup({
        stage: "em_expansao",
        founders: [{}, {}],
        externalMembers: [{}],
        tags: [],
      }),
    );

    const risk = await service.calculateRisk("1");

    expect(risk).toBeLessThanOrEqual(5);
  });

  test("deve calcular retorno esperado corretamente", async () => {
    (repo.getStartupById as jest.Mock).mockResolvedValue(
      mockStartup({
        stage: "nova",
        founders: [{}],
        externalMembers: [],
        tags: ["iot"],
      }),
    );

    const result = await service.expectedReturn("1");

    expect(result).toHaveProperty("range");
    expect(result).toHaveProperty("expected");

    expect(result.range).toMatch(/x/);
    expect(typeof result.expected).toBe("number");
  });

  test("deve classificar corretamente o perfil de risco", () => {
    expect(service.getRiskProfileCodes(2)).toBe("lowRisk");
    expect(service.getRiskProfileCodes(5)).toBe("mediumRisk");
    expect(service.getRiskProfileCodes(9)).toBe("highRisk");
  });

  test("deve retornar o label do perfil de risco", () => {
    expect(service.getRiskProfile(2)).toBe("Risco Baixo");
    expect(service.getRiskProfile(5)).toBe("Risco Médio");
    expect(service.getRiskProfile(9)).toBe("Risco Alto");
  });

  test("deve retornar o horizonte de investimento baseado no estágio", () => {
    expect(service.getHorizon("nova")).toBe("Longo prazo");
    expect(service.getHorizon("em_operacao")).toBe("Médio prazo");
    expect(service.getHorizon("em_expansao")).toBe("Curto prazo");
    expect(service.getHorizon(undefined)).toBe("Desconhecido");
  });

  test("deve obter valuation da startup", async () => {
    (repo.getStartupValuationById as jest.Mock).mockResolvedValue(1500000);
    const valuation = await service.getStartupValuation("1");
    expect(valuation).toBe(1500000);
  });

  test("deve retornar 0 se valuation não existir", async () => {
    (repo.getStartupValuationById as jest.Mock).mockResolvedValue(null);
    const valuation = await service.getStartupValuation("1");
    expect(valuation).toBe(0);
  });

  test("deve obter métricas completas da startup", async () => {
    const startup = mockStartup({ id: "1", stage: "em_operacao" });
    (repo.getStartupById as jest.Mock).mockResolvedValue(startup);
    (repo.getStartupValuationById as jest.Mock).mockResolvedValue(2000000);
    (repo.userIsInvestor as jest.Mock).mockResolvedValue(true);
    (repo.listPublicQuestions as jest.Mock).mockResolvedValue([]);
    (repo.getValuationHistory as jest.Mock).mockResolvedValue([
      { value: 2000000, createdAt: Timestamp.fromDate(new Date()) },
    ]);

    const metrics = await service.getStartupMetrics("1", "user1", {
      historyRange: { from: "2023-01-01", to: "2023-12-31" },
      historyInterval: "monthly",
    });

    expect(metrics).toHaveProperty("startup");
    expect(metrics).toHaveProperty("risk");
    expect(metrics).toHaveProperty("expectedReturn");
    expect(metrics).toHaveProperty("riskLabel");
    expect(metrics).toHaveProperty("horizon");
    expect(metrics).toHaveProperty("valuation", 2000000);
    expect(metrics).toHaveProperty("isInvestor", true);
    expect(metrics.priceHistory.history).toHaveLength(1);
  });

  test("deve calcular histórico de preços corretamente", async () => {
    const startup = mockStartup({ totalTokensIssued: 1000 });
    (repo.getStartupById as jest.Mock).mockResolvedValue(startup);

    const date1 = new Date("2023-01-01");
    const date2 = new Date("2023-02-01");

    (repo.getValuationHistory as jest.Mock).mockResolvedValue([
      { value: 100000, createdAt: Timestamp.fromDate(date1) }, // price = 100000 / 1000 / 100 = 1.00
      { value: 150000, createdAt: Timestamp.fromDate(date2) }, // price = 150000 / 1000 / 100 = 1.50
    ]);

    const result = await service.getStartupPriceHistory(
      "1",
      { from: "2023-01-01", to: "2023-03-01" },
      "monthly",
      10,
    );

    expect(result.history).toHaveLength(2);
    expect(result.history[0].price).toBe(1);
    expect(result.history[1].price).toBe(1.5);
    expect(result.history[1].variation).toBe(0.5);
    expect(result.history[1].variationPercent).toBe(50);

    expect(result.summary.currentPrice).toBe(1.5);
    expect(result.summary.highestPrice).toBe(1.5);
    expect(result.summary.lowestPrice).toBe(1);
    expect(result.summary.averagePrice).toBe(1.25);
  });

  test("deve agrupar histórico por intervalo anual", async () => {
    const startup = mockStartup({ totalTokensIssued: 1000 });
    (repo.getStartupById as jest.Mock).mockResolvedValue(startup);

    // Usando datas explicitas em UTC para evitar problemas de fuso horário em diferentes ambientes
    (repo.getValuationHistory as jest.Mock).mockResolvedValue([
      {
        value: 100000,
        createdAt: Timestamp.fromDate(new Date("2022-01-01T12:00:00Z")),
      },
      {
        value: 150000,
        createdAt: Timestamp.fromDate(new Date("2022-12-31T12:00:00Z")),
      },
      {
        value: 200000,
        createdAt: Timestamp.fromDate(new Date("2023-06-01T12:00:00Z")),
      },
    ]);

    const result = await service.getStartupPriceHistory(
      "1",
      { from: "2022-01-01", to: "2023-12-31" },
      "yearly",
      10,
    );

    // Deve ter 2 entradas: o último de 2022 (1.5) e o único de 2023 (2.0)
    expect(result.history).toHaveLength(2);
    expect(result.history[0].price).toBe(1.5);
    expect(result.history[1].price).toBe(2);
  });
});
