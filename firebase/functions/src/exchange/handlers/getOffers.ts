import { onCall } from "firebase-functions/v2/https";
import { withCallHandler } from "../../shared/middlewares/errorHandler";
import { requireAuthenticatedUser } from "../../shared/auth";
import { GetOffersRequestDTO, PaginatedOffersResponseDTO } from "../types/dtos";
import { OfferService } from "../shared/offerService";

const offerService = new OfferService();

export const getOffers = onCall(
  withCallHandler<GetOffersRequestDTO, PaginatedOffersResponseDTO>(
    async (request) => {
      requireAuthenticatedUser(request);
      return offerService.getOffers(request.data || {});
    },
  ),
);
