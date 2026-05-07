import { onCall, HttpsError } from "firebase-functions/v2/https";
import { withCallHandler } from "../../shared/middlewares/errorHandler";
import { CreateOfferRequestDTO, OfferResponseDTO } from "../types/dtos";
import { validateTransactionData } from "../utils";
import { Timestamp } from "firebase-admin/firestore";
import { Offer } from "../types";
// import { requireAuthenticatedUser } from "../../shared/auth";
import { addOffer } from "../repositories/offerRepository";

/**
 * Cria uma oferta de venda de tokens de uma startup.
 * A oferta pode ser direcionada a um comprador específico ou aberta ao mercado.
 *
 * @param request - Dados da oferta (startupId, sellerId, qtdTokens, tokenPriceCents, buyerId?, expiresAt?)
 * @returns Os dados da oferta criada, incluindo o ID.
 */
export const createOffer = onCall(
  withCallHandler<CreateOfferRequestDTO, OfferResponseDTO>(async (request) => {
    // requireAuthenticatedUser(request);
    const {
      startupId,
      buyerId,
      sellerId,
      qtdTokens,
      tokenPriceCents,
      expiresAt,
    } = request.data;

    if (!startupId || !sellerId || !qtdTokens || !tokenPriceCents) {
      throw new HttpsError(
        "invalid-argument",
        "Dados insuficientes (startupId, sellerId, qtdTokens, tokenPriceCents).",
      );
    }

    const { buyerUser, sellerUser, startup } = await validateTransactionData({
      buyerId,
      sellerId,
      startupId,
      qtdTokens,
      tokenPriceCents,
    });

    const now = Timestamp.now();

    const offerData: Offer = {
      startupId,
      seller: {
        id: sellerId,
        name: sellerUser?.name || startup.name,
        type: sellerUser ? "USER" : "STARTUP",
      },
      qtdTokens,
      tokenPriceCents,
      totalCents: qtdTokens * tokenPriceCents,
      status: "OPEN",
      transactionType: "USER_TRADE",
      createdAt: now,
    };

    if (buyerUser && buyerId) {
      offerData.buyer = {
        id: buyerId,
        name: buyerUser.name,
      };
    }

    if (expiresAt) {
      const expirationDate = new Date(expiresAt);

      if (isNaN(expirationDate.getTime())) {
        throw new HttpsError("invalid-argument", "Data de expiração inválida.");
      }

      offerData.expiresAt = Timestamp.fromDate(expirationDate);
    }

    const offerRef = await addOffer(offerData);

    return {
      id: offerRef.id,
      ...offerData,
    };
  }),
);
