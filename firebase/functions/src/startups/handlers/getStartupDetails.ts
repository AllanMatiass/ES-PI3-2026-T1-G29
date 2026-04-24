// Autor: Allan Giovanni Matias Paes
import { HttpsError, onCall } from "firebase-functions/v2/https";
// import { requireAuthenticatedUser } from "../../shared/auth";
import { normalizeString } from "../../shared/validation";
import { withCallHandler } from "../../shared/middlewares/errorHandler";
import {
  GetStartupDetailsRequest,
  GetStartupDetailsResponse,
  StartupDetails,
} from "../types/dtos";
import { InvestmentMetricService } from "../shared/investmentMetricService";

const investmentMetricService = new InvestmentMetricService();

/**
 * Busca os dados completos de uma startup especifica.
 *
 * Esta Funcao e callable e deve ser chamada pelo app com:
 *
 * - `id`: identificador da startup no Firestore.
 *
 * A funcao exige autenticacao e retorna a visao detalhada do item 5.2:
 *
 * - sumario executivo, estrutura societaria, membros externos, videos,
 * - perguntas publicas e flags de acesso para novos investidores.
 */
export const getStartupDetails = onCall(
  withCallHandler<GetStartupDetailsRequest, GetStartupDetailsResponse>(
    async (request) => {
      // const user = requireAuthenticatedUser(request);

      const startupId = normalizeString(request.data?.id);

      if (!startupId) {
        throw new HttpsError("invalid-argument", "Informe o id da startup.");
      }

      const userId = request.auth?.uid ?? "anonymous";

      const {
        startup,
        risk,
        expectedReturn,
        riskLabel,
        horizon,
        valuation,
        isInvestor,
        questions,
      } = await investmentMetricService.getStartupMetrics(startupId, userId);

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

      return {
        id: startupId,
        details: data,
        publicQuestions: questions,
        access: {
          isInvestor,
          canTradeTokens: isInvestor,
          canSendPrivateQuestions: isInvestor,
        },
      };
    },
  ),
);
