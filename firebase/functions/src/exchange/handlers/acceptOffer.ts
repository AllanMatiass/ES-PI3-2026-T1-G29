import { onCall, HttpsError } from "firebase-functions/v2/https";
import { withCallHandler } from "../../shared/middlewares/errorHandler";
import { AcceptOfferRequestDTO, TransactionIdDTO } from "../types/dtos";
import { getOfferById, updateOffer } from "../repositories/offerRepository";
import { getUserById } from "../../auth/repositories/userRepository";
import { TransactionService } from "../shared/transactionService";
import { Timestamp } from "firebase-admin/firestore";

const transactionService = new TransactionService();

/**
 * Aceita uma oferta de tokens existente.
 * Valida se a oferta está aberta, se não expirou e se o comprador é válido.
 * Atualiza o status da oferta para ACCEPTED e registra a transação.
 */
export const acceptOffer = onCall(
  withCallHandler<AcceptOfferRequestDTO, TransactionIdDTO>(async (request) => {
    const { offerId, buyerId } = request.data;

    if (!offerId || !buyerId) {
      throw new HttpsError(
        "invalid-argument",
        "offerId e buyerId são obrigatórios.",
      );
    }

    const [offer, buyerUser] = await Promise.all([
      getOfferById(offerId),
      getUserById(buyerId),
    ]);

    if (!offer) {
      throw new HttpsError("not-found", "Oferta não encontrada.");
    }

    if (!buyerUser) {
      throw new HttpsError("not-found", "Comprador não encontrado.");
    }

    if (offer.status !== "OPEN") {
      throw new HttpsError(
        "failed-precondition",
        "A oferta não está mais aberta.",
      );
    }

    const now = Timestamp.now();
    if (offer.expiresAt && offer.expiresAt.toMillis() < now.toMillis()) {
      throw new HttpsError("failed-precondition", "A oferta expirou.");
    }

    if (offer.seller.id === buyerId) {
      throw new HttpsError(
        "invalid-argument",
        "O comprador não pode ser o mesmo que o vendedor.",
      );
    }

    if (offer.buyer && offer.buyer.id !== buyerId) {
      throw new HttpsError(
        "permission-denied",
        "Esta oferta é reservada para outro comprador.",
      );
    }

    // Atualiza a oferta
    const acceptedAt = now;
    await updateOffer(offerId, {
      status: "ACCEPTED",
      acceptedAt,
      buyer: {
        id: buyerId,
        name: buyerUser.name,
      },
    });

    if (!offer.seller.id) {
      throw new HttpsError("not-found", "ID do vendedor não encontrado");
    }

    // Registra a transação
    const transactionId = await transactionService.registerTransaction({
      startupId: offer.startupId,
      buyer: {
        id: buyerId,
        name: buyerUser.name,
      },
      seller: {
        id: offer.seller.id,
        name: offer.seller.name,
      },
      qtdTokens: offer.qtdTokens,
      tokenPriceCents: offer.tokenPriceCents,
    });

    return { id: transactionId };
  }),
);
