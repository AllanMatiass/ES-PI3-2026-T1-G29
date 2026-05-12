import { onCall } from "firebase-functions/v2/https";
import { withCallHandler } from "../../shared/middlewares/errorHandler";
import { AcceptOfferRequestDTO, AcceptOfferResponseDTO } from "../types/dtos";
import { requireAuthenticatedUser } from "../../shared/auth";
import { OfferService } from "../shared/offerService";

const offerService = new OfferService();

export const acceptOffer = onCall(
  withCallHandler<AcceptOfferRequestDTO, AcceptOfferResponseDTO>(
    async (request) => {
      const buyerId = requireAuthenticatedUser(request).uid;
      return offerService.acceptOffer(buyerId, request.data);
    },
  ),
);
