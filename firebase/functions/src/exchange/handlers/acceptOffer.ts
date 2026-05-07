import { onCall, HttpsError } from "firebase-functions/v2/https";
import { withCallHandler } from "../../shared/middlewares/errorHandler";
import { AcceptOfferRequestDTO, TransactionIdDTO } from "../types/dtos";
import { getOfferById } from "../repositories/offerRepository";
import { getUserById } from "../../auth/repositories/userRepository";
import { Timestamp } from "firebase-admin/firestore";
import { normalizeString } from "../../shared/validation";
import { upsertStartupInvestor } from "../../startups/shared/upsertInvestor";
import { db } from "../../shared/firebase";
import { WalletTokenPosition } from "../../auth/types";
import { TransactionService } from "../shared/transactionService";
import { requireAuthenticatedUser } from "../../shared/auth";

const transactionService = new TransactionService();

export const acceptOffer = onCall(
  withCallHandler<AcceptOfferRequestDTO, TransactionIdDTO>(async (request) => {
    requireAuthenticatedUser(request);
    const offerId = normalizeString(request.data?.offerId);
    const buyerId = normalizeString(request.data?.buyerId);

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

    if (!offer) throw new HttpsError("not-found", "Oferta não encontrada.");
    if (!buyerUser)
      throw new HttpsError("not-found", "Comprador não encontrado.");

    const now = Timestamp.now();

    if (offer.status !== "OPEN") {
      throw new HttpsError("failed-precondition", "Oferta não está aberta.");
    }

    if (offer.expiresAt && offer.expiresAt.toMillis() < now.toMillis()) {
      throw new HttpsError("failed-precondition", "Oferta expirou.");
    }

    if (offer.seller.id === buyerId) {
      throw new HttpsError(
        "invalid-argument",
        "Comprador não pode ser vendedor.",
      );
    }

    if (buyerUser.wallet.balanceInCents < offer.totalCents) {
      throw new HttpsError("failed-precondition", "Saldo insuficiente.");
    }

    const sellerId = offer.seller.id;

    if (!sellerId) {
      throw new HttpsError("not-found", "Vendedor não encontrado");
    }

    const result = await db.runTransaction(async (tx) => {
      const sellerRef = db.collection("users").doc(sellerId);
      const buyerRef = db.collection("users").doc(buyerId);
      const offerRef = db.collection("offers").doc(offerId);

      // ==========================================
      // 1. TODAS AS LEITURAS DIRETAS
      // ==========================================
      const [sellerSnap, buyerSnap] = await Promise.all([
        tx.get(sellerRef),
        tx.get(buyerRef),
      ]);

      if (!sellerSnap.exists) {
        throw new HttpsError("not-found", "Vendedor não encontrado.");
      }

      const sellerData = sellerSnap.data();
      const buyerData = buyerSnap.data();

      const sellerWallet = sellerData?.wallet;
      const buyerWallet = buyerData?.wallet;

      const sellerPosition = sellerWallet.positions?.find(
        (p: WalletTokenPosition) => p.startupId === offer.startupId,
      );

      //Validações

      if (!sellerPosition) {
        throw new HttpsError("failed-precondition", "Vendedor sem posição.");
      }

      if (sellerPosition.qtdTokens < offer.qtdTokens) {
        throw new HttpsError(
          "failed-precondition",
          "Tokens totais insuficientes.",
        );
      }

      if (sellerPosition.lockedTokens < offer.qtdTokens) {
        throw new HttpsError(
          "failed-precondition",
          "Tokens bloqueados insuficientes. A oferta pode estar corrompida.",
        );
      }

      //Cálculos em memória
      sellerPosition.qtdTokens -= offer.qtdTokens;
      sellerPosition.lockedTokens -= offer.qtdTokens;
      sellerPosition.updatedAt = now;

      sellerWallet.positions = sellerWallet.positions?.filter(
        (p: WalletTokenPosition) => p.qtdTokens > 0,
      );

      const existing = buyerWallet.positions?.find(
        (p: WalletTokenPosition) => p.startupId === offer.startupId,
      );

      if (existing) {
        const newTokens = existing.qtdTokens + offer.qtdTokens;
        const newInvested = existing.investedCents + offer.totalCents;

        existing.qtdTokens = newTokens;
        existing.investedCents = newInvested;
        existing.averagePriceCents = newInvested / newTokens;
        existing.updatedAt = now;
      } else {
        buyerWallet.positions.push({
          startupId: offer.startupId,
          startupName: offer.startupName,
          qtdTokens: offer.qtdTokens,
          lockedTokens: 0,
          averagePriceCents: offer.tokenPriceCents,
          investedCents: offer.totalCents,
          updatedAt: now,
        });
      }

      // Funções auxiliares
      await upsertStartupInvestor(tx, {
        startupId: offer.startupId,
        startupName: offer.startupName,
        userId: buyerId,
        userName: buyerUser.name,
        qtdTokens: offer.qtdTokens,
        tokenPriceCents: offer.tokenPriceCents,
      });

      const transactionRef = await transactionService.registerTransactionTx(
        tx,
        {
          startupId: offer.startupId,
          startupName: offer.startupName,
          buyer: {
            id: buyerId,
            name: buyerUser.name,
          },
          seller: {
            id: sellerId,
            name: offer.seller.name,
          },
          qtdTokens: offer.qtdTokens,
          tokenPriceCents: offer.tokenPriceCents,
        },
      );

      // Escritas
      tx.update(sellerRef, { wallet: sellerWallet });
      tx.update(buyerRef, { wallet: buyerWallet });

      tx.update(offerRef, {
        status: "ACCEPTED",
        acceptedAt: now,
        buyer: {
          id: buyerId,
          name: buyerUser.name,
        },
      });

      return transactionRef.id;
    });

    return { id: result };
  }),
);
