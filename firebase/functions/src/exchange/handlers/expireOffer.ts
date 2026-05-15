// Autor: Allan Giovanni Matias Paes
import { onCall } from "firebase-functions/v2/https";
import { withCallHandler } from "../../shared/middlewares/errorHandler";
import { ExpireOfferDTO, ExpireOfferResponseDTO } from "../types/dtos";
import { OfferService } from "../shared/offerService";

const offerService = new OfferService();

export const expireOffer = onCall(
  withCallHandler<ExpireOfferDTO, ExpireOfferResponseDTO>(async (request) => {
    return offerService.expireOffer(request.data.offerId);
  }),
);
