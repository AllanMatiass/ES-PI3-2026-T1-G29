import { onCall } from "firebase-functions/v2/https";
import { withCallHandler } from "../../shared/middlewares/errorHandler";
import { requireAuthenticatedUser } from "../../shared/auth";
import {
  GetUserMovementsRequestDTO,
  PaginatedMovementsResponseDTO,
} from "../types/dtos";
import * as userRepository from "../repositories/userRepository";

export const getUserMovements = onCall(
  withCallHandler<GetUserMovementsRequestDTO, PaginatedMovementsResponseDTO>(
    async (request) => {
      const auth = requireAuthenticatedUser(request);

      const { limit, lastMovementId } = request.data || {};

      return userRepository.listMovementsByUserId(
        auth.uid,
        limit,
        lastMovementId,
      );
    },
  ),
);
