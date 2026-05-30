/**
 * @file getStartupPriceHistory.ts
 * @description Handler para obtenção do histórico de preços de tokens de uma startup específica.
 * @author Allan Giovanni Matias Paes - 25008211
 */

import { HttpsError, onCall } from "firebase-functions/v2/https";
import { normalizeString } from "../../shared/validation";
import { withCallHandler } from "../../shared/middlewares/errorHandler";
import {
  GetStartupPriceHistoryRequest,
  GetStartupPriceHistoryResponse,
} from "../types/dtos";
import { InvestmentMetricService } from "../shared/investmentMetricService";
import { DEFAULT_RANGE } from "../shared/constants";
import { logger } from "firebase-functions";
import { requireAuthenticatedUser } from "../../shared/auth";

// Instância do serviço de métricas de investimento
const investmentMetricService = new InvestmentMetricService();

/**
 * Function para recuperar o histórico de preços de uma startup.
 *
 * Permite visualizar a evolução do valor dos tokens em diferentes intervalos temporais
 * para auxiliar na tomada de decisão do investidor.
 *
 * Fluxo de execução:
 * 1. Verifica a autenticação do usuário.
 * 2. Extrai o ID da startup e parâmetros de filtragem (range, intervalo, limite).
 * 3. Valida a presença do ID da startup.
 * 4. Chama o serviço de métricas para calcular o histórico com base nos parâmetros fornecidos.
 * 5. Retorna o objeto de histórico completo.
 */
export const getStartupPriceHistory = onCall(
  withCallHandler<
    GetStartupPriceHistoryRequest,
    GetStartupPriceHistoryResponse
  >(async (request) => {
    // 1. Requer autenticação
    requireAuthenticatedUser(request);

    // 2. Extração de parâmetros
    const startupId = normalizeString(request.data?.id);
    const { range, interval, limit } = request.data ?? {};

    logger.info("Solicitação de histórico de preços", {
      range,
      interval,
      limit,
    });

    // 3. Validação básica
    if (!startupId) {
      throw new HttpsError("invalid-argument", "Informe o id da startup.");
    }

    // 4. Recuperação do histórico via Service
    // O service trata a lógica de agrupamento (mensal, anual, etc) e cálculos de variação
    const history = await investmentMetricService.getStartupPriceHistory(
      startupId,
      range ?? DEFAULT_RANGE,
      interval ?? "monthly",
      limit ?? 50,
    );

    // 5. Retorno dos dados calculados
    return history;
  }),
);
