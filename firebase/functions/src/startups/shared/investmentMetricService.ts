// Autor: Allan Giovanni Matias Paes
import { HttpsError } from "firebase-functions/https";
import {
  getStartupById,
  getStartupValuationById,
  listPublicQuestions,
  userIsInvestor,
} from "../repositories/startupRepository";
import { RETURN_CONFIG, RISK_CONFIG } from "../shared/constants";
import {
  StartupDocument,
  StartupRiskCode,
  StartupRiskLabel,
  StartupStage,
} from "../types";
import { ExpectedReturn } from "../types/dtos";

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

  async getStartupMetrics(startupId: string, userId: string) {
    const startup = await this._fetchStartupOrThrow(startupId);

    // cálculos internos
    const risk = this.calculateRiskFromStartup(startup);
    const expectedReturn = this.calculateExpectedReturnFromRisk(risk);
    const riskLabel = this.getRiskProfile(risk);
    const horizon = this.getHorizon(startup.stage);

    // chamadas paralelas (melhor performance)
    const [valuation, isInvestor, questions] = await Promise.all([
      getStartupValuationById(startupId),
      userIsInvestor(startupId, userId),
      listPublicQuestions(startupId),
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
    };
  }

  getRiskProfileCodes(risk: number): StartupRiskCode {
    if (risk <= 3) return "lowRisk";
    if (risk <= 6) return "mediumRisk";
    return "highRisk";
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
