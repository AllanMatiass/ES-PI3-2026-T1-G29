// Autor: Allan Giovanni Matias Paes
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { normalizeString } from "../../shared/validation";
import { withCallHandler } from "../../shared/middlewares/errorHandler";
import {
  GetStartupDetailsRequest,
  GetStartupDetailsResponse,
  StartupDetails,
} from "../types/dtos";
import { InvestmentMetricService } from "../shared/investmentMetricService";
import { requireAuthenticatedUser } from "../../shared/auth";

const investmentMetricService = new InvestmentMetricService();

export const getStartupDetails = onCall(
  withCallHandler<GetStartupDetailsRequest, GetStartupDetailsResponse>(
    async (request) => {
      const user = requireAuthenticatedUser(request);

      const startupId = normalizeString(request.data?.id);

      if (!startupId) {
        throw new HttpsError("invalid-argument", "Informe o id da startup.");
      }

      const {
        startup,
        risk,
        expectedReturn,
        riskLabel,
        horizon,
        valuation,
        isInvestor,
        questions,
      } = await investmentMetricService.getStartupMetrics(startupId, user.uid);

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
