import { onCall } from "firebase-functions/v2/https";
import { withCallHandler } from "../../shared/middlewares/errorHandler";
import { requireAuthenticatedUser } from "../../shared/auth";
import { listOffers } from "../repositories/offerRepository";
import { GetOffersRequestDTO, PaginatedOffersResponseDTO } from "../types/dtos";
import { normalizeString } from "../../shared/validation";

export const getOffers = onCall(
  withCallHandler<GetOffersRequestDTO, PaginatedOffersResponseDTO>(
    async (request) => {
      requireAuthenticatedUser(request);

      const data = request.data || {};
      const { limit } = data;
      const startupId = normalizeString(data.startupId);
      const lastOfferId = normalizeString(data.lastOfferId);

      const result = await listOffers(startupId, limit, lastOfferId);

      return result;
    },
  ),
);
