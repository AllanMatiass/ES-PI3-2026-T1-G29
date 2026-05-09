import { onCall, HttpsError } from "firebase-functions/v2/https";
import { Timestamp } from "firebase-admin/firestore";

import { withCallHandler } from "../../shared/middlewares/errorHandler";
import { AcceptOfferRequestDTO, AcceptOfferResponseDTO } from "../types/dtos";

import { getOfferById } from "../repositories/offerRepository";
import { getUserById } from "../../auth/repositories/userRepository";

import { normalizeString } from "../../shared/validation";
import { upsertStartupInvestor } from "../../startups/shared/upsertInvestor";

import { db } from "../../shared/firebase";

import { Wallet, WalletTokenPositionDTO } from "../../auth/types";

import { TransactionService } from "../shared/transactionService";
import { Offer } from "../types";

// import { requireAuthenticatedUser } from "../../shared/auth";

const transactionService = new TransactionService();

export const acceptOffer = onCall(
  withCallHandler<AcceptOfferRequestDTO, AcceptOfferResponseDTO>(
    async (request) => {
      // const buyerId = requireAuthenticatedUser(request).uid;
      const buyerId = "mZ7eEGjtx2dXZu3w8lB28sTXGkf2";

      const offerId = normalizeString(request.data?.offerId);
      const qtdTokens = request.data.qtdTokens;

      if (!offerId || !qtdTokens || qtdTokens <= 0) {
        throw new HttpsError(
          "invalid-argument",
          "offerId e qtdTokens > 0 são obrigatórios.",
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

        const freshOffer = offerSnap.data() as Offer;

        if (!freshOffer) {
          throw new HttpsError("not-found", "Oferta inválida.");
        }

        // evita race condition
        if (freshOffer.status !== "OPEN") {
          throw new HttpsError("failed-precondition", "Oferta já processada.");
        }

        if (qtdTokens > freshOffer.qtdTokens) {
          throw new HttpsError(
            "failed-precondition",
            "A quantidade solicitada é maior do que a disponível na oferta.",
          );
        }

        const purchaseTotalCents = qtdTokens * freshOffer.tokenPriceCents;

        const sellerData = sellerSnap.data();
        const buyerData = buyerSnap.data();

        const sellerWallet: Wallet = sellerData?.wallet;
        const buyerWallet: Wallet = buyerData?.wallet;

        sellerWallet.positions ??= [];
        buyerWallet.positions ??= [];

        // ============================
        // Validação saldo comprador
        // ============================

        if (buyerWallet.balanceInCents < purchaseTotalCents) {
          throw new HttpsError("failed-precondition", "Saldo insuficiente.");
        }

        // ============================
        // Busca posição vendedor
        // ============================

        const sellerPosition = sellerWallet.positions.find(
          (p: WalletTokenPositionDTO) => p.startupId === offer.startupId,
        );

        if (!sellerPosition) {
          throw new HttpsError("failed-precondition", "Vendedor sem posição.");
        }

        if (sellerPosition.qtdTokens < qtdTokens) {
          throw new HttpsError(
            "failed-precondition",
            "Tokens totais insuficientes.",
          );
        }

        if (sellerPosition.lockedTokens < qtdTokens) {
          throw new HttpsError(
            "failed-precondition",
            "Tokens bloqueados insuficientes.",
          );
        }

        // ============================
        // Atualiza posição vendedor
        // ============================

        sellerPosition.qtdTokens -= qtdTokens;

        sellerPosition.lockedTokens -= qtdTokens;

        sellerPosition.investedCents =
          sellerPosition.qtdTokens * sellerPosition.averagePriceCents;

        sellerPosition.currentValueCents =
          sellerPosition.qtdTokens * sellerPosition.currentTokenPriceCents;

        sellerPosition.profitCents =
          sellerPosition.currentValueCents - sellerPosition.investedCents;

        sellerPosition.profitPercentage =
          sellerPosition.investedCents <= 0
            ? 0
            : (sellerPosition.profitCents / sellerPosition.investedCents) * 100;

        sellerPosition.updatedAt = now;

        // remove posições zeradas
        sellerWallet.positions = sellerWallet.positions.filter(
          (p: WalletTokenPositionDTO) => p.qtdTokens > 0,
        );

        // ============================
        // Atualiza wallet vendedor
        // ============================

        sellerWallet.balanceInCents += purchaseTotalCents;

        sellerWallet.totalInvestedCents = sellerWallet.positions.reduce(
          (acc, p) => acc + p.investedCents,
          0,
        );

        sellerWallet.updatedAt = now;

        // ============================
        // Atualiza posição comprador
        // ============================

        const existingBuyerPosition = buyerWallet.positions.find(
          (p: WalletTokenPositionDTO) => p.startupId === offer.startupId,
        );

        if (existingBuyerPosition) {
          const newQtdTokens = existingBuyerPosition.qtdTokens + qtdTokens;

          const newInvestedCents =
            existingBuyerPosition.investedCents + purchaseTotalCents;

          existingBuyerPosition.qtdTokens = newQtdTokens;

          existingBuyerPosition.investedCents = newInvestedCents;

          existingBuyerPosition.averagePriceCents = Math.round(
            newInvestedCents / newQtdTokens,
          );

          existingBuyerPosition.currentValueCents =
            newQtdTokens * existingBuyerPosition.currentTokenPriceCents;

          existingBuyerPosition.profitCents =
            existingBuyerPosition.currentValueCents -
            existingBuyerPosition.investedCents;

          existingBuyerPosition.profitPercentage =
            existingBuyerPosition.investedCents <= 0
              ? 0
              : (existingBuyerPosition.profitCents /
                  existingBuyerPosition.investedCents) *
                100;

          existingBuyerPosition.updatedAt = now;
        } else {
          const currentValueCents = qtdTokens * offer.tokenPriceCents;

          buyerWallet.positions.push({
            startupId: offer.startupId,
            startupName: offer.startupName,

            qtdTokens: qtdTokens,
            lockedTokens: 0,

            averagePriceCents: offer.tokenPriceCents,

            investedCents: purchaseTotalCents,

            currentTokenPriceCents: offer.tokenPriceCents,

            currentValueCents,

            profitCents: currentValueCents - purchaseTotalCents,

            profitPercentage: 0,

            updatedAt: now,
          });
        }

        // ============================
        // Atualiza wallet comprador
        // ============================

        buyerWallet.balanceInCents -= purchaseTotalCents;

        buyerWallet.totalInvestedCents = buyerWallet.positions.reduce(
          (acc, p) => acc + p.investedCents,
          0,
        );

        buyerWallet.updatedAt = now;

        // ============================
        // Atualiza investidores startup
        // ============================

        await upsertStartupInvestor(tx, {
          startupId: offer.startupId,
          startupName: offer.startupName,

          userId: buyerId,
          userName: buyerUser.name,

          qtdTokens: qtdTokens,

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
              type: "USER",
            },

            seller: {
              id: sellerId,
              name: offer.seller.name,
              type: "USER",
            },

            qtdTokens: qtdTokens,

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

        const isFullAcceptance = qtdTokens === freshOffer.qtdTokens;

        if (isFullAcceptance) {
          tx.update(offerRef, {
            status: "ACCEPTED",

            acceptedAt: now,

            buyer: {
              id: buyerId,
              name: buyerUser.name,
            },
          });
        } else {
          tx.update(offerRef, {
            qtdTokens: freshOffer.qtdTokens - qtdTokens,
            totalCents:
              (freshOffer.qtdTokens - qtdTokens) * freshOffer.tokenPriceCents,
          });
        }

        return {
          transactionId: transactionRef.id,
          remainingTokens: freshOffer.qtdTokens - qtdTokens,
        };
      });

      return result;
    },
  ),
);
