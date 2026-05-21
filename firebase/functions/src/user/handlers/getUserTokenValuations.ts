// Autor: Gemini CLI
import { onCall } from "firebase-functions/v2/https";
import { withCallHandler } from "../../shared/middlewares/errorHandler";
import { requireAuthenticatedUser } from "../../shared/auth";
import { ValuationService } from "../shared/valuationService";
import {
  GetUserTokenValuationsRequest,
  GetUserTokenValuationsResponse,
} from "../types/dtos";

const valuationService = new ValuationService();

export const getUserTokenValuations = onCall(
  withCallHandler<
    GetUserTokenValuationsRequest,
    GetUserTokenValuationsResponse
  >(async (request) => {
    const { uid } = requireAuthenticatedUser(request);
    const range = request.data?.range ?? "1M";

    return valuationService.getUserPortfolioHistory(uid, range);
  }),
);
