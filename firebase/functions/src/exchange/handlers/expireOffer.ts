import { onCall, HttpsError } from "firebase-functions/v2/https";
import { withCallHandler } from "../../shared/middlewares/errorHandler";
import { ExpireOfferDTO, ExpireOfferResponseDTO } from "../types/dtos";
import { getOfferById, updateOffer } from "../repositories/offerRepository";
import { normalizeString } from "../../shared/validation";
import { Timestamp } from "firebase-admin/firestore";

export const expireOffer = onCall(
  withCallHandler<ExpireOfferDTO, ExpireOfferResponseDTO>(async (request) => {
    const offerId = normalizeString(request.data.offerId);
    const expirationDate = Timestamp.now();
    const isExpired = true;

    if (!offerId || !expirationDate) {
      throw new HttpsError(
        "invalid-argument",
        "offerId e expirationDate devem estar presentes no corpo da requisição.",
      );
    }

    const notExpired = {
      offerId,
      expired: !isExpired,
    };

    const offer = await getOfferById(offerId);
    if (!offer) throw new HttpsError("not-found", "Oferta não encontrada.");
    const expiresAt = offer.expiresAt?.toMillis();

    if (!expiresAt) return notExpired;

    const expired = expiresAt < expirationDate.toMillis();

    if (!expired) return notExpired;

    await updateOffer(offerId, {
      status: "EXPIRED",
    });

    return {
      offerId,
      expired: isExpired,
    };
  }),
);
