/**
 * @file investmentMetricService.ts
 * @description Serviço central de inteligência analítica. Realiza cálculos complexos de risco,
 * projeções estatísticas de retorno e processamento de séries temporais de preços.
 * @author Allan Giovanni Matias Paes - 25008211
 */

import { HttpsError } from "firebase-functions/https";
import {
  getStartupById,
  getStartupValuationById,
  getValuationHistory,
  listStartupQuestions,
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

/**
 * Mapeamento de códigos de risco para labels legíveis.
 * Utilizado para traduzir a lógica de backend para a interface do usuário.
 */
const RISK_LABEL_MAP: Record<StartupRiskCode, StartupRiskLabel> = {
  lowRisk: "Risco Baixo",
  mediumRisk: "Risco Médio",
  highRisk: "Risco Alto",
};

/**
 * Horizonte de investimento sugerido baseado no ciclo de vida (Stage).
 * Startups 'novas' exigem maturação (Longo Prazo), enquanto 'em expansão'
 * estão mais próximas de um evento de liquidez (Curto Prazo).
 */
const HORIZON_MAP: Record<StartupStage, string> = {
  nova: "Longo prazo",
  em_operacao: "Médio prazo",
  em_expansao: "Curto prazo",
};

/**
 * InvestmentMetricService
 *
 * Este serviço implementa os modelos matemáticos de análise de investimento da plataforma.
 * Ele transforma dados brutos do Firestore em insights acionáveis para o investidor.
 */
export class InvestmentMetricService {
  /**
   * Recupera o Valuation total da startup (Preço do Token * Total de Tokens).
   * @param startupId Identificador único da startup.
   */
  async getStartupValuation(startupId: string): Promise<number> {
    return (await getStartupValuationById(startupId)) ?? 0;
  }

  /**
   * Ponto de entrada para cálculo de risco via ID.
   * Garante a existência da startup antes de processar a lógica.
   */
  async calculateRisk(startupId: string): Promise<number> {
    const startup = await this._fetchStartupOrThrow(startupId);
    return this.calculateRiskFromStartup(startup);
  }

  /**
   * Algoritmo de Pontuação de Risco Ponderado.
   *
   * A fórmula segue o padrão: R = Σ (Score_i * Peso_i)
   * Onde 'i' representa os pilares: Estágio, Time, Tecnologia e Mentoria.
   *
   * Racional de Negócio:
   * - Estágio (40%): O maior fator, pois o índice de falha é drasticamente maior em startups 'novas'.
   * - Time (30%): Mitiga o "Risco de Pessoa Chave". Múltiplos fundadores aumentam a resiliência.
   * - Tecnologia (20%): Setores complexos (DeepTech, HealthTech) têm maior risco de execução.
   * - Mentores (10%): A presença de advisors reduz riscos operacionais e de rede.
   *
   * @param startup Documento completo da startup.
   * @returns Score final normalizado na escala definida (ex: 0-10).
   */
  calculateRiskFromStartup(startup: StartupDocument): number {
    const hasMoreThanOneFounder = startup.founders.length > 1;
    const hasMentors = startup.externalMembers.length > 0;

    // Identificação de setores com alta barreira tecnológica ou regulatória.
    const hasComplexTags = startup.tags
      .map((t) => t.toLowerCase())
      .some((t) => ["iot", "healthtech", "blockchain", "deeptech"].includes(t));

    // Atribuição de scores base baseada nas constantes de configuração.
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

    // Cálculo da soma ponderada.
    const risk =
      stageScore * RISK_CONFIG.weights.stage +
      teamScore * RISK_CONFIG.weights.team +
      techScore * RISK_CONFIG.weights.tech +
      mentorsScore * RISK_CONFIG.weights.mentors;

    // Normalização para a escala 0-10 (arredondado).
    return Math.round(risk * RISK_CONFIG.scale.max);
  }

  /**
   * Projeta o retorno esperado para o investidor.
   * @param startupId ID da startup.
   */
  async expectedReturn(startupId: string): Promise<ExpectedReturn> {
    const risk = await this.calculateRisk(startupId);
    return this.calculateExpectedReturnFromRisk(risk);
  }

  /**
   * Cálculo de Valor Esperado Estatístico (Expected Value - EV).
   *
   * A fórmula utiliza uma matriz de probabilidade baseada no perfil de risco (Low, Medium, High).
   * EV = (P_falha * Mult_falha) + (P_base * Mult_base) + (P_sucesso * Mult_sucesso)
   *
   * Onde os multiplicadores representam o retorno sobre o capital (ex: 10x o valor investido).
   *
   * @param risk Score numérico de risco.
   * @returns Objeto contendo o intervalo (min-max) e o valor esperado ponderado.
   */
  calculateExpectedReturnFromRisk(risk: number): ExpectedReturn {
    const profile = this.getRiskProfileCodes(risk);
    const probabilities = RETURN_CONFIG.probabilities[profile];
    const outcome = RETURN_CONFIG.outcome;

    let expected = 0;

    // Itera sobre os cenários (Falha, Base, Sucesso) ponderando pelas probabilidades do perfil.
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

  /**
   * Traduz o score numérico de risco para uma label legível.
   */
  getRiskProfile(risk: number): StartupRiskLabel {
    const riskProfileCode = this.getRiskProfileCodes(risk);
    return RISK_LABEL_MAP[riskProfileCode];
  }

  /**
   * Retorna a classificação de tempo sugerida para o investimento.
   */
  getHorizon(stage: StartupStage | undefined): string {
    if (!stage) return "Desconhecido";
    return HORIZON_MAP[stage];
  }

  /**
   * Consolidador de Métricas para Visualização (Dashboard/Details).
   *
   * Utiliza paralelismo via Promise.all para reduzir o tempo de resposta total (TTFB),
   * executando consultas independentes ao Firestore e cálculos de forma simultânea.
   *
   * @param startupId ID da startup.
   * @param userId ID do usuário solicitante (para verificar status de investidor).
   * @param options Opções de intervalo e limite para o histórico de preços.
   */
  async getStartupMetrics(
    startupId: string,
    userId: string,
    options: PriceHistoryOptions,
  ) {
    const startup = await this._fetchStartupOrThrow(startupId);

    // Verificações de permissão e perfil
    const isInvestor = await userIsInvestor(startupId, userId);

    // Cálculos síncronos baseados no documento recuperado
    const risk = this.calculateRiskFromStartup(startup);
    const expectedReturn = this.calculateExpectedReturnFromRisk(risk);
    const riskLabel = this.getRiskProfile(risk);
    const horizon = this.getHorizon(startup.stage);

    // Orquestração de chamadas assíncronas paralelas
    const [valuation, questions, priceHistory] = await Promise.all([
      getStartupValuationById(startupId),
      listStartupQuestions(startupId, isInvestor),
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

  /**
   * Mapeia o score (0-10) para categorias discretas de risco.
   * 0-3: Baixo | 4-6: Médio | 7-10: Alto.
   */
  getRiskProfileCodes(risk: number): StartupRiskCode {
    if (risk <= 3) return "lowRisk";
    if (risk <= 6) return "mediumRisk";
    return "highRisk";
  }

  /**
   * Processamento de Séries Temporais de Preços.
   *
   * Transforma snapshots de Valuation em uma série histórica de preços de tokens.
   *
   * Lógica de Derivação de Preço:
   * Preço_Token = (Valuation_Total / Total_Tokens) / 100
   * O divisor '100' é utilizado para normalizar o valor para a escala de exibição da plataforma.
   *
   * @param startupId ID da startup.
   * @param range Intervalo de datas (De/Até).
   * @param interval Periodicidade (diário, mensal, anual).
   * @param limit Número máximo de pontos no gráfico.
   */
  async getStartupPriceHistory(
    startupId: string,
    range: { from: string; to: string },
    interval: PriceHistoryInterval,
    limit: number,
  ) {
    // Validação de segurança dos inputs
    validateValuationHistoryOptions({
      historyRange: range,
      historyLimit: limit,
      historyInterval: interval,
    });

    const startup = await this._fetchStartupOrThrow(startupId);

    const fromDate = new Date(range.from);
    const toDate = new Date(range.to);

    // Recupera todos os snapshots do intervalo
    const rawHistory = await getValuationHistory(
      startupId,
      fromDate,
      toDate,
      null,
    );

    // Executa o agrupamento temporal (Downsampling)
    const grouped = this.groupRawByInterval(rawHistory, interval);

    // Aplica o limite de pontos solicitado (mantendo os mais recentes)
    const historyData = grouped.slice(-limit);

    // Calcula variações nominais e percentuais entre pontos consecutivos
    const history = historyData.map((item, index) => {
      const price = item.value / startup.totalTokensIssued / 100;

      let variation: number | null = null;
      let variationPercent: number | null = null;

      if (index > 0) {
        const prev =
          historyData[index - 1].value / startup.totalTokensIssued / 100;

        variation = Number((price - prev).toFixed(2));

        // Evita divisão por zero caso o histórico esteja inconsistente
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

    // Consolida sumário estatístico do período
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

  /**
   * Algoritmo de Agrupamento Temporal (Bucketing).
   *
   * Agrupa snapshots de dados por chaves temporais (ex: "2023-10" para mensal).
   * Para cada grupo, seleciona o último registro (Last Value), simulando o
   * "Preço de Fechamento" de um mercado financeiro tradicional.
   *
   * @param data Lista de snapshots brutos.
   * @param interval Tipo de agrupamento.
   */
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
        case "daily":
          key = date.toISOString().split("T")[0]; // "YYYY-MM-DD"
          break;

        case "yearly":
          key = `${date.getFullYear()}`; // "YYYY"
          break;

        case "monthly":
          key = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}`; // "YYYY-MM"
          break;

        case "semestrely":
          key = `${date.getFullYear()}-${date.getMonth() < 6 ? "H1" : "H2"}`; // "YYYY-H1"
          break;

        case "ytd": // Year To Date: Apenas dados do ano corrente agrupados por mês
          if (date.getFullYear() !== now.getFullYear()) continue;
          key = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}`;
          break;

        default:
          key = date.toISOString().split("T")[0];
      }

      if (!groups.has(key)) {
        groups.set(key, []);
      }

      groups.get(key)?.push(item);
    }

    // Seleção estratégica do último item de cada bucket (Fechamento do Período)
    return Array.from(groups.values()).map((items) => items[items.length - 1]);
  }

  /**
   * Método auxiliar para garantir integridade referencial ao buscar startups.
   */
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
