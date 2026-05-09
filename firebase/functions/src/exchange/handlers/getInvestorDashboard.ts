import { onCall, HttpsError } from "firebase-functions/v2/https";

import { withCallHandler } from "../../shared/middlewares/errorHandler";
import { DashboardService } from "../shared/dashboardService";

import {
  DashboardPeriod,
  GetInvestorDashboardRequestDTO,
  GetInvestorDashboardResponseDTO,
} from "../types/dtos";

// import { requireAuthenticatedUser } from "../../shared/auth";
import { normalizeString } from "../../shared/validation";

const dashboardService = new DashboardService();

const validPeriods = ["daily", "weekly", "monthly", "6months", "ytd"] as const;

function isDashboardPeriod(value: string): value is DashboardPeriod {
  return validPeriods.includes(value as DashboardPeriod);
}

export const getInvestorDashboard = onCall(
  withCallHandler<
    GetInvestorDashboardRequestDTO,
    GetInvestorDashboardResponseDTO
  >(async (request) => {
    // const auth = requireAuthenticatedUser(request);
    const auth = {
      uid: "mZ7eEGjtx2dXZu3w8lB28sTXGkf2",
    };

    const rawPeriod = normalizeString(request.data?.period)?.toLowerCase();

    if (!rawPeriod || !isDashboardPeriod(rawPeriod)) {
      throw new HttpsError(
        "invalid-argument",
        "Período inválido. Use: daily, weekly, monthly, 6months ou ytd.",
      );
    }

    return dashboardService.getDashboardData(auth.uid, rawPeriod);
  }),
);
