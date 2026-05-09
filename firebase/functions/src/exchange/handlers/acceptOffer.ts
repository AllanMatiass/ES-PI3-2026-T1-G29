import { onCall, HttpsError } from "firebase-functions/v2/https";
import { Timestamp } from "firebase-admin/firestore";
import { withCallHandler } from "../../shared/middlewares/errorHandler";
import { AcceptOfferRequestDTO, TransactionIdDTO } from "../types/dtos";
import { getOfferById } from "../repositories/offerRepository";
import { getUserById } from "../../auth/repositories/userRepository";
import { normalizeString } from "../../shared/validation";
import { upsertStartupInvestor } from "../../startups/shared/upsertInvestor";
import { db } from "../../shared/firebase";
import { Wallet, WalletTokenPosition } from "../../auth/types";
import { TransactionService } from "../shared/transactionService";
import { requireAuthenticatedUser } from "../../shared/auth";

const transactionService = new TransactionService();

export const acceptOffer = onCall(
  withCallHandler<AcceptOfferRequestDTO, TransactionIdDTO>(async (request) => {
    const buyerId = requireAuthenticatedUser(request).uid;

    const offerId = normalizeString(request.data?.offerId);

    if (!offerId) {
      throw new HttpsError("invalid-argument", "offerId é obrigatório.");
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

    const sellerId = offer.seller.id;

    if (!sellerId) {
      throw new HttpsError("failed-precondition", "Vendedor inválido.");
    }

    const result = await db.runTransaction(async (tx) => {
      const sellerRef = db.collection("users").doc(sellerId);
      const buyerRef = db.collection("users").doc(buyerId);
      const offerRef = db.collection("offers").doc(offerId);

      // ============================
      // Leituras transacionais
      // ============================

      const [sellerSnap, buyerSnap, offerSnap] = await Promise.all([
        tx.get(sellerRef),
        tx.get(buyerRef),
        tx.get(offerRef),
      ]);

      if (!sellerSnap.exists) {
        throw new HttpsError("not-found", "Vendedor não encontrado.");
      }

      if (!buyerSnap.exists) {
        throw new HttpsError("not-found", "Comprador não encontrado.");
      }

      if (!offerSnap.exists) {
        throw new HttpsError("not-found", "Oferta não encontrada.");
      }

      const freshOffer = offerSnap.data();

      if (!freshOffer) {
        throw new HttpsError("not-found", "Oferta inválida.");
      }

      // Double-check transacional, evitando race condition
      if (freshOffer.status !== "OPEN") {
        throw new HttpsError("failed-precondition", "Oferta já processada.");
      }

      const sellerData = sellerSnap.data();
      const buyerData = buyerSnap.data();

      const sellerWallet: Wallet = sellerData?.wallet;
      const buyerWallet: Wallet = buyerData?.wallet;

      sellerWallet.positions ??= [];
      buyerWallet.positions ??= [];

      // ============================
      // Validação saldo comprador
      // ============================

      if (buyerWallet.balanceInCents < offer.totalCents) {
        throw new HttpsError("failed-precondition", "Saldo insuficiente.");
      }

      // ============================
      // Busca posição vendedor
      // ============================

      const sellerPosition = sellerWallet.positions.find(
        (p: WalletTokenPosition) => p.startupId === offer.startupId,
      );

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
          "Tokens bloqueados insuficientes.",
        );
      }

      // ============================
      // Atualiza posição vendedor
      // ============================

      sellerPosition.qtdTokens -= offer.qtdTokens;
      sellerPosition.lockedTokens -= offer.qtdTokens;
      sellerPosition.updatedAt = now;

      // Remove posição zerada
      sellerWallet.positions = sellerWallet.positions.filter(
        (p: WalletTokenPosition) => p.qtdTokens > 0,
      );

      // ============================
      // Atualiza wallet vendedor
      // ============================

      sellerWallet.balanceInCents += offer.totalCents;

      const newTotalInvestedCents =
        sellerWallet.totalInvestedCents -
        sellerPosition.averagePriceCents * offer.qtdTokens;
      sellerWallet.totalInvestedCents = Math.max(0, newTotalInvestedCents);

      sellerWallet.updatedAt = now;

      // ============================
      // Atualiza posição do comprador
      // ============================

      const existingBuyerPosition = buyerWallet.positions.find(
        (p: WalletTokenPosition) => p.startupId === offer.startupId,
      );

      if (existingBuyerPosition) {
        const newQtdTokens = existingBuyerPosition.qtdTokens + offer.qtdTokens;

        const newInvestedCents =
          existingBuyerPosition.investedCents + offer.totalCents;

        existingBuyerPosition.qtdTokens = newQtdTokens;

        existingBuyerPosition.investedCents = newInvestedCents;

        existingBuyerPosition.averagePriceCents = Math.round(
          newInvestedCents / newQtdTokens,
        );

        existingBuyerPosition.updatedAt = now;
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

      // ============================
      // Atualiza wallet comprador
      // ============================

      buyerWallet.balanceInCents -= offer.totalCents;

      buyerWallet.totalInvestedCents += offer.totalCents;

      buyerWallet.updatedAt = now;

      // ============================
      // Atualiza investidores startup
      // ============================

      await upsertStartupInvestor(tx, {
        startupId: offer.startupId,
        startupName: offer.startupName,

        userId: buyerId,
        userName: buyerUser.name,

        qtdTokens: offer.qtdTokens,

        tokenPriceCents: offer.tokenPriceCents,
      });

      // ============================
      // Auditoria / histórico
      // ============================

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

      // ============================
      // Escritas finais
      // ============================

      tx.update(sellerRef, {
        wallet: sellerWallet,
      });

      tx.update(buyerRef, {
        wallet: buyerWallet,
      });

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

    return {
      id: result,
    };
  }),
);
