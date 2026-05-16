// Autor: Allan Giovanni Matias Paes
import { onCall } from "firebase-functions/v2/https";
import { withCallHandler } from "../../shared/middlewares/errorHandler";
import { DashboardService } from "../shared/dashboardService";
import {
  GetInvestorDashboardRequestDTO,
  GetInvestorDashboardResponseDTO,
} from "../types/dtos";
import { requireAuthenticatedUser } from "../../shared/auth";

const dashboardService = new DashboardService();

export const getInvestorDashboard = onCall(
  withCallHandler<
    GetInvestorDashboardRequestDTO,
    GetInvestorDashboardResponseDTO
  >(async (request) => {
    const auth = requireAuthenticatedUser(request);
    return dashboardService.getDashboardData(auth.uid, request.data?.period);
  }),
);
