/**
 * @file getStartupDetails.ts
 * @description Handler para obtenção de detalhes completos de uma startup, incluindo métricas financeiras e permissões.
 * @author Allan Giovanni Matias Paes - 25008211
 */

import { HttpsError, onCall } from "firebase-functions/v2/https";
import { normalizeString } from "../../shared/validation";
import { withCallHandler } from "../../shared/middlewares/errorHandler";
import {
  GetStartupDetailsResponse,
  StartupDetails,
  GetStartupDetailsRequest,
} from "../types/dtos";
import { InvestmentMetricService } from "../shared/investmentMetricService";
import { requireAuthenticatedUser } from "../../shared/auth";

// Instância do serviço de métricas de investimento
const investmentMetricService = new InvestmentMetricService();

/**
 * Function para obter os detalhes detalhados de uma startup específica.
 *
 * Este handler consolida informações de diversas fontes (repositórios e motores de cálculo)
 * para fornecer uma visão completa ao investidor.
 *
 * Fluxo de execução:
 * 1. Verifica se o solicitante está autenticado.
 * 2. Valida o ID da startup fornecido.
 * 3. Delega ao InvestmentMetricService a consolidação de métricas (risco, retorno, valuation, histórico, perguntas).
 * 4. Formata a resposta separando detalhes estruturais, histórico de preços e permissões de acesso.
 */
export const getStartupDetails = onCall(
  withCallHandler<GetStartupDetailsRequest, GetStartupDetailsResponse>(
    async (request) => {
      // 1. Garante que o usuário esteja logado
      const user = requireAuthenticatedUser(request);

      // 2. Extração e normalização dos parâmetros de entrada
      const startupId = normalizeString(request.data?.id);
      const options = request.data?.options;

      if (!startupId) {
        throw new HttpsError("invalid-argument", "Informe o id da startup.");
      }

      // 3. Recuperação consolidada de métricas via Service
      // Este método retorna dados do Firestore e cálculos em tempo real (Risco/Retorno)
      const {
        startup,
        risk,
        expectedReturn,
        riskLabel,
        horizon,
        valuation,
        isInvestor,
        questions,
        priceHistory,
      } = await investmentMetricService.getStartupMetrics(
        startupId,
        user.uid,
        options ?? {},
      );

      // 4. Construção do objeto de detalhes da startup
      const data: StartupDetails = {
        startup,
        valuation,
        expectedReturn,
        horizon,
        risk: {
          score: risk,
          label: riskLabel,
        },
      };

      // 5. Retorno da resposta formatada conforme o DTO
      return {
        id: startupId,
        details: data,
        priceHistory,
        questions: questions,
        access: {
          isInvestor,
          // Regra: Somente investidores podem negociar tokens ou enviar perguntas privadas
          canTradeTokens: isInvestor,
          canSendPrivateQuestions: isInvestor,
        },
      };
    },
  ),
);
