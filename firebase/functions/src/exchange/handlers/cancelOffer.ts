// Autor: Pedro Vinícius Romanato - 25004075
import { onCall } from "firebase-functions/v2/https";
import { withCallHandler } from "../../shared/middlewares/errorHandler";
import { requireAuthenticatedUser } from "../../shared/auth";
import { OfferIdDTO, CancelOfferResponseDTO } from "../types/dtos";
import { OfferService } from "../shared/offerService";

const offerService = new OfferService();

export const cancelOffer = onCall(
  withCallHandler<OfferIdDTO, CancelOfferResponseDTO>(async (request) => {
    const sellerId = requireAuthenticatedUser(request).uid;
    return await offerService.cancelOffer(sellerId, request.data);
  }),
);
