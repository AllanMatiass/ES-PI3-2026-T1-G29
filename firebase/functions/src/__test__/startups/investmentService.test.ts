// __tests__/InvestmentMetricService.test.ts

import { InvestmentMetricService } from "../../startups/shared/investmentMetricService";
import * as repo from "../../startups/repositories/startupRepository";

jest.mock("../../startups/repositories/startupRepository");

const mockStartup = (overrides = {}) => ({
  stage: "nova",
  founders: [{}],
  externalMembers: [],
  tags: [],
  ...overrides,
});

test("deve lançar erro se startup não existir", async () => {
  (repo.getStartupById as jest.Mock).mockResolvedValue(null);

  const service = new InvestmentMetricService();

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

  const service = new InvestmentMetricService();
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

  const service = new InvestmentMetricService();
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

  const service = new InvestmentMetricService();
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

  const service = new InvestmentMetricService();
  const result = await service.expectedReturn("1");

  expect(result).toHaveProperty("range");
  expect(result).toHaveProperty("expected");

  expect(result.range).toMatch(/x/);
  expect(typeof result.expected).toBe("number");
});

test("deve classificar corretamente o perfil de risco", () => {
  const service = new InvestmentMetricService();

  expect(service.getRiskProfileCodes(2)).toBe("lowRisk");
  expect(service.getRiskProfileCodes(5)).toBe("mediumRisk");
  expect(service.getRiskProfileCodes(9)).toBe("highRisk");
});
