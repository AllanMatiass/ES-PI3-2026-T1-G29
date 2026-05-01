// Autor: Allan Giovanni Matias Paes
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

const investmentMetricService = new InvestmentMetricService();

export const getStartupDetails = onCall(
  withCallHandler<GetStartupDetailsRequest, GetStartupDetailsResponse>(
    async (request) => {
      const user = requireAuthenticatedUser(request);

      const startupId = normalizeString(request.data?.id);
      const options = request.data?.options;

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
        priceHistory,
      } = await investmentMetricService.getStartupMetrics(
        startupId,
        user.uid,
        options ?? {},
      );

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
        priceHistory,
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
