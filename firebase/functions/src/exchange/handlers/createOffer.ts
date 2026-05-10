// Autor: Allan Giovanni Matias Paes
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { withCallHandler } from "../../shared/middlewares/errorHandler";
import { requireAuthenticatedUser } from "../../shared/auth";
import { CreateOfferRequestDTO, OfferResponseDTO } from "../types/dtos";
import { validateTransactionData } from "../utils";
import { Timestamp } from "firebase-admin/firestore";
import { Offer } from "../types";
import {
  createOfferInTransaction,
  getOfferById,
} from "../repositories/offerRepository";

export const createOffer = onCall(
  withCallHandler<CreateOfferRequestDTO, OfferResponseDTO>(async (request) => {
    const sellerId = requireAuthenticatedUser(request).uid;
    const { startupId, qtdTokens, tokenPriceCents, expiresAt } = request.data;

    if (!startupId || !qtdTokens || !tokenPriceCents) {
      throw new HttpsError(
        "invalid-argument",
        "Dados insuficientes (startupId, qtdTokens, tokenPriceCents).",
      );
    }

    const { sellerUser, startup } = await validateTransactionData({
      sellerId,
      startupId,
      qtdTokens,
      tokenPriceCents,
    });

    const now = Timestamp.now();

    const sellerPosition = sellerUser?.wallet?.positions?.find(
      (p) => p.startupId === startupId,
    );
    const averageAcquisitionPriceCents = sellerPosition?.averagePriceCents || 0;

    // Criar oferta data
    const offerData: Offer = {
      startupId,
      startupName: startup.name,

      seller: {
        id: sellerId,
        name: sellerUser?.name || startup.name,
        type: sellerUser ? "USER" : "STARTUP",
      },

      qtdTokens,
      initialQtdTokens: qtdTokens,
      averageAcquisitionPriceCents,
      tokenPriceCents,
      totalCents: qtdTokens * tokenPriceCents,

      status: "OPEN",
      transactionType: "USER_TRADE",

      createdAt: now,
    };

    if (expiresAt) {
      const expirationDate = new Date(expiresAt);

      if (isNaN(expirationDate.getTime())) {
        throw new HttpsError("invalid-argument", "Data de expiração inválida.");
      }

      offerData.expiresAt = Timestamp.fromDate(expirationDate);
    }

    const offerId = await createOfferInTransaction(sellerId, offerData);

    const offer = await getOfferById(offerId);

    if (!offer) {
      throw new HttpsError("internal", "Erro ao recuperar oferta criada.");
    }

    return offer;
  }),
);
