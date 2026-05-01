// Autor: Allan Giovanni Matias Paes
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { normalizeString } from "../../shared/validation";
import { withCallHandler } from "../../shared/middlewares/errorHandler";
import {
  GetStartupPriceHistoryRequest,
  GetStartupPriceHistoryResponse,
} from "../types/dtos";
import { InvestmentMetricService } from "../shared/investmentMetricService";
import { DEFAULT_RANGE } from "../shared/constants";
import { requireAuthenticatedUser } from "../../shared/auth";

const investmentMetricService = new InvestmentMetricService();

export const getStartupPriceHistory = onCall(
  withCallHandler<
    GetStartupPriceHistoryRequest,
    GetStartupPriceHistoryResponse
  >(async (request) => {
    requireAuthenticatedUser(request);
    const startupId = normalizeString(request.data?.id);
    const { range, interval, limit } = request.data ?? {};

    if (!startupId) {
      throw new HttpsError("invalid-argument", "Informe o id da startup.");
    }

    const history = await investmentMetricService.getStartupPriceHistory(
      startupId,
      range ?? DEFAULT_RANGE,
      interval ?? "monthly",
      limit ?? 50,
    );

    return history;
  }),
);
