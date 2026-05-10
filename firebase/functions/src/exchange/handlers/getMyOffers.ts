// Autor: Allan Giovanni Matias Paes
import { onCall } from "firebase-functions/v2/https";
import { withCallHandler } from "../../shared/middlewares/errorHandler";
import { requireAuthenticatedUser } from "../../shared/auth";
import { GetMyOffersResponseDTO, MyOfferDTO } from "../types/dtos";
import { getOffersBySellerId } from "../repositories/offerRepository";

export const getMyOffers = onCall(
  withCallHandler<void, GetMyOffersResponseDTO>(async (request) => {
    const auth = requireAuthenticatedUser(request);
    const userId = auth.uid;

    const offers = await getOffersBySellerId(userId);

    const mappedOffers: MyOfferDTO[] = offers.map((offer) => {
      const initialQtd = offer.initialQtdTokens;
      const remainingQtd = offer.qtdTokens;
      const soldQtd = initialQtd - remainingQtd;
      const totalEarned = soldQtd * offer.tokenPriceCents;

      return {
        id: offer.id,
        startupId: offer.startupId,
        startupName: offer.startupName,
        status: offer.status,
        initialQtdTokens: initialQtd ?? offer.qtdTokens,
        remainingQtdTokens: remainingQtd,
        soldQtdTokens: soldQtd,
        tokenPriceCents: offer.tokenPriceCents,
        totalEarnedCents: totalEarned,
        createdAt: offer.createdAt.toDate().toISOString(),
        expiresAt: offer.expiresAt?.toDate().toISOString() || null,
      };
    });

    return {
      offers: mappedOffers,
    };
  }),
);
