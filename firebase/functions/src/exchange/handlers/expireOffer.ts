import { onCall, HttpsError } from "firebase-functions/v2/https";
import { withCallHandler } from "../../shared/middlewares/errorHandler";
import { ExpireOfferDTO, ExpireOfferResponseDTO } from "../types/dtos";
import {
  getOfferById,
  expireOfferInTransaction,
} from "../repositories/offerRepository";
import { normalizeString } from "../../shared/validation";
import { Timestamp } from "firebase-admin/firestore";

export const expireOffer = onCall(
  withCallHandler<ExpireOfferDTO, ExpireOfferResponseDTO>(async (request) => {
    const offerId = normalizeString(request.data.offerId);
    const expirationDate = Timestamp.now();

    if (!offerId) {
      throw new HttpsError(
        "invalid-argument",
        "offerId deve estar presente no corpo da requisição.",
      );
    }

    const offer = await getOfferById(offerId);
    if (!offer) throw new HttpsError("not-found", "Oferta não encontrada.");

    if (offer.status !== "OPEN") {
      return {
        offerId,
        expired: offer.status === "EXPIRED",
      };
    }

    const expiresAt = offer.expiresAt?.toMillis();

    if (!expiresAt) {
      return {
        offerId,
        expired: false,
      };
    }

    const isExpired = expiresAt < expirationDate.toMillis();

    if (!isExpired) {
      return {
        offerId,
        expired: false,
      };
    }

    const success = await expireOfferInTransaction(offerId);

    return {
      offerId,
      expired: success,
    };
  }),
);
