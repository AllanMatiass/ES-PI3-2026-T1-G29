// Autor: Allan Giovanni Matias Paes
import { onCall } from "firebase-functions/v2/https";
import { withCallHandler } from "../../shared/middlewares/errorHandler";
import { requireAuthenticatedUser } from "../../shared/auth";
import {
  GetUserInvestmentsRequestDTO,
  PaginatedInvestmentsResponseDTO,
} from "../types/dtos";
import { UserService } from "../shared/userService";

const userService = new UserService();

export const getUserInvestments = onCall(
  withCallHandler<
    GetUserInvestmentsRequestDTO,
    PaginatedInvestmentsResponseDTO
  >(async (request) => {
    const auth = requireAuthenticatedUser(request);
    return userService.getUserInvestments(auth.uid, request.data || {});
  }),
);
