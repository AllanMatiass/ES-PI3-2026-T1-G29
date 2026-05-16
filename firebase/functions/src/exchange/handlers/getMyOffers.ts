// Autor: Allan Giovanni Matias Paes
import { onCall } from "firebase-functions/v2/https";
import { withCallHandler } from "../../shared/middlewares/errorHandler";
import { requireAuthenticatedUser } from "../../shared/auth";
import { GetMyOffersResponseDTO } from "../types/dtos";
import { OfferService } from "../shared/offerService";

const offerService = new OfferService();

export const getMyOffers = onCall(
  withCallHandler<void, GetMyOffersResponseDTO>(async (request) => {
    const auth = requireAuthenticatedUser(request);
    return offerService.getMyOffers(auth.uid);
  }),
);
