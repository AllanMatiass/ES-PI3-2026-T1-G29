// Autor: Allan Giovanni Matias Paes
import { HttpsError } from "firebase-functions/https";
import {
  getStartupById,
  getStartupValuationById,
  getValuationHistory,
  listPublicQuestions,
  userIsInvestor,
} from "../repositories/startupRepository";
import { DEFAULT_RANGE, RETURN_CONFIG, RISK_CONFIG } from "../shared/constants";
import {
  StartupDocument,
  StartupRiskCode,
  StartupRiskLabel,
  StartupStage,
} from "../types";
import {
  ExpectedReturn,
  PriceHistoryInterval,
  PriceHistoryOptions,
} from "../types/dtos";
import { validatePriceHistoryOptions as validateValuationHistoryOptions } from "../../utils/validations";
import { Timestamp } from "firebase-admin/firestore";

const RISK_LABEL_MAP: Record<StartupRiskCode, StartupRiskLabel> = {
  lowRisk: "Risco Baixo",
  mediumRisk: "Risco Médio",
  highRisk: "Risco Alto",
};

const HORIZON_MAP: Record<StartupStage, string> = {
  nova: "Longo prazo",
  em_operacao: "Médio prazo",
  em_expansao: "Curto prazo",
};

export class InvestmentMetricService {
  async getStartupValuation(startupId: string): Promise<number> {
    return (await getStartupValuationById(startupId)) ?? 0;
  }

  async calculateRisk(startupId: string): Promise<number> {
    const startup = await this._fetchStartupOrThrow(startupId);
    return this.calculateRiskFromStartup(startup);
  }

  calculateRiskFromStartup(startup: StartupDocument): number {
    const hasMoreThanOneFounder = startup.founders.length > 1;
    const hasMentors = startup.externalMembers.length > 0;

    const hasComplexTags = startup.tags
      .map((t) => t.toLowerCase())
      .some((t) => ["iot", "healthtech"].includes(t));

    const stageScore = RISK_CONFIG.scores.stage[startup.stage];

    const teamScore = hasMoreThanOneFounder
      ? RISK_CONFIG.scores.team.multipleFounders
      : RISK_CONFIG.scores.team.soloFounder;

    const techScore = hasComplexTags
      ? RISK_CONFIG.scores.tags.complex
      : RISK_CONFIG.scores.tags.simple;

    const mentorsScore = hasMentors
      ? RISK_CONFIG.scores.mentors.hasMentors
      : RISK_CONFIG.scores.mentors.noMentors;

    const risk =
      stageScore * RISK_CONFIG.weights.stage +
      teamScore * RISK_CONFIG.weights.team +
      techScore * RISK_CONFIG.weights.tech +
      mentorsScore * RISK_CONFIG.weights.mentors;

    return Math.round(risk * RISK_CONFIG.scale.max);
  }

  async expectedReturn(startupId: string): Promise<ExpectedReturn> {
    const risk = await this.calculateRisk(startupId);
    return this.calculateExpectedReturnFromRisk(risk);
  }

  calculateExpectedReturnFromRisk(risk: number): ExpectedReturn {
    const profile = this.getRiskProfileCodes(risk);
    const probabilities = RETURN_CONFIG.probabilities[profile];
    const outcome = RETURN_CONFIG.outcome;

    let expected = 0;

    for (let i = 0; i < outcome.length; i++) {
      expected += outcome[i].multiple * probabilities[i];
    }

    const min = outcome[0].multiple;
    const max = outcome[outcome.length - 1].multiple;

    return {
      range: `${min}x a ${max}x`,
      expected: Number(expected.toFixed(2)),
    };
  }

  getRiskProfile(risk: number): StartupRiskLabel {
    const riskProfileCode = this.getRiskProfileCodes(risk);
    return RISK_LABEL_MAP[riskProfileCode];
  }

  getHorizon(stage: StartupStage | undefined): string {
    if (!stage) return "Desconhecido";
    return HORIZON_MAP[stage];
  }

  async getStartupMetrics(
    startupId: string,
    userId: string,
    options: PriceHistoryOptions,
  ) {
    const startup = await this._fetchStartupOrThrow(startupId);

    const risk = this.calculateRiskFromStartup(startup);
    const expectedReturn = this.calculateExpectedReturnFromRisk(risk);
    const riskLabel = this.getRiskProfile(risk);
    const horizon = this.getHorizon(startup.stage);

    const [valuation, isInvestor, questions, priceHistory] = await Promise.all([
      getStartupValuationById(startupId),
      userIsInvestor(startupId, userId),
      listPublicQuestions(startupId),
      this.getStartupPriceHistory(
        startupId,
        options.historyRange ?? DEFAULT_RANGE,
        options.historyInterval ?? "monthly",
        options.historyLimit ?? 50,
      ),
    ]);

    return {
      startup,
      risk,
      expectedReturn,
      riskLabel,
      horizon,
      valuation: valuation ?? 0,
      isInvestor,
      questions,
      priceHistory,
    };
  }

  getRiskProfileCodes(risk: number): StartupRiskCode {
    if (risk <= 3) return "lowRisk";
    if (risk <= 6) return "mediumRisk";
    return "highRisk";
  }

  async getStartupPriceHistory(
    startupId: string,
    range: { from: string; to: string },
    interval: PriceHistoryInterval,
    limit: number,
  ) {
    validateValuationHistoryOptions({
      historyRange: range,
      historyLimit: limit,
      historyInterval: interval,
    });

    const startup = await this._fetchStartupOrThrow(startupId);

    const fromDate = new Date(range.from);
    const toDate = new Date(range.to);

    // 🔥 1. pegar dados SEM limit
    const rawHistory = await getValuationHistory(
      startupId,
      fromDate,
      toDate,
      null, // ⚠️ importante
    );

    // 🔥 2. agrupar corretamente
    const grouped = this.groupRawByInterval(rawHistory, interval);

    // 🔥 3. aplicar limit DEPOIS
    const historyData = grouped.slice(-limit);

    // 🔥 4. mapear
    const history = historyData.map((item, index) => {
      const price = item.value / startup.totalTokensIssued / 100;

      let variation: number | null = null;
      let variationPercent: number | null = null;

      if (index > 0) {
        const prev =
          historyData[index - 1].value / startup.totalTokensIssued / 100;

        variation = Number((price - prev).toFixed(2));

        variationPercent =
          prev === 0 ? null : Number(((variation / prev) * 100).toFixed(2));
      }

      return {
        timestamp: item.createdAt.toDate().toISOString().split("T")[0],
        price: Number(price.toFixed(2)),
        variation,
        variationPercent,
      };
    });

    const prices = history.map((h) => h.price);

    return {
      history,
      summary: {
        currentPrice: prices.length ? prices[prices.length - 1] : 0,
        highestPrice: prices.length ? Math.max(...prices) : 0,
        lowestPrice: prices.length ? Math.min(...prices) : 0,
        averagePrice: prices.length
          ? Number(
              (prices.reduce((a, b) => a + b, 0) / prices.length).toFixed(2),
            )
          : 0,
      },
      meta: {
        count: history.length,
        currency: "BRL",
        interval,
      },
    };
  }

  private groupRawByInterval(
    data: { value: number; createdAt: Timestamp }[],
    interval: PriceHistoryInterval,
  ) {
    const groups = new Map<string, { value: number; createdAt: Timestamp }[]>();
    const now = new Date();

    for (const item of data) {
      const date = item.createdAt.toDate();
      let key: string;

      switch (interval) {
        case "yearly":
          key = `${date.getFullYear()}`;
          break;

        case "monthly":
          key = `${date.getFullYear()}-${date.getMonth()}`;
          break;

        case "semestrely":
          key = `${date.getFullYear()}-${date.getMonth() < 6 ? "H1" : "H2"}`;
          break;

        case "ytd":
          if (date.getFullYear() !== now.getFullYear()) continue;

          key = `${date.getFullYear()}-${date.getMonth()}`;
          break;

        default:
          key = date.toISOString().split("T")[0];
      }

      if (!groups.has(key)) {
        groups.set(key, []);
      }

      groups.get(key)?.push(item);
    }

    // último valor de cada grupo
    return Array.from(groups.values()).map((items) => items[items.length - 1]);
  }

  private async _fetchStartupOrThrow(
    startupId: string,
  ): Promise<StartupDocument> {
    const startup = await getStartupById(startupId);

    if (!startup) {
      throw new HttpsError("not-found", "Startup não encontrada.");
    }

    return startup;
  }
}
