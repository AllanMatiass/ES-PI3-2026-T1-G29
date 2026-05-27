// Autor: Allan Giovanni Matias Paes - 25008211
import { onCall } from "firebase-functions/v2/https";
import { withCallHandler } from "../../shared/middlewares/errorHandler";
import { requireAuthenticatedUser } from "../../shared/auth";
import { CreateOfferRequestDTO, OfferResponseDTO } from "../types/dtos";
import { OfferService } from "../shared/offerService";

const offerService = new OfferService();

export const createOffer = onCall(
  withCallHandler<CreateOfferRequestDTO, OfferResponseDTO>(async (request) => {
    const sellerId = requireAuthenticatedUser(request).uid;
    return await offerService.createOffer(sellerId, request.data);
  }),
);
