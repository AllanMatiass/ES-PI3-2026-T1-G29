// Autor: Allan Giovanni Matias Paes - 25008211
import { onCall } from "firebase-functions/v2/https";
import { withCallHandler } from "../../shared/middlewares/errorHandler";
import { BuyTokensRequestDTO, BuyTokensResponseDTO } from "../types/dtos";
import { requireAuthenticatedUser } from "../../shared/auth";
import { OfferService } from "../shared/offerService";

const offerService = new OfferService();

// function para um usuário comprar tokens de outros usuários
export const acceptOffer = onCall(
  withCallHandler<BuyTokensRequestDTO, BuyTokensResponseDTO>(
    async (request) => {
      const buyerId = requireAuthenticatedUser(request).uid;
      return offerService.buyTokens(buyerId, request.data);
    },
  ),
);
