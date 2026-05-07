import { onCall, HttpsError } from "firebase-functions/v2/https";
import { withCallHandler } from "../../shared/middlewares/errorHandler";
import { CreateOfferRequestDTO, OfferResponseDTO } from "../types/dtos";
import { validateTransactionData } from "../utils";
import { Timestamp } from "firebase-admin/firestore";
import { Offer } from "../types";
import { db } from "../../shared/firebase";
import { WalletTokenPosition } from "../../auth/types";

export const createOffer = onCall(
  withCallHandler<CreateOfferRequestDTO, OfferResponseDTO>(async (request) => {
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

    const offerRef = db.collection("offers").doc();

    const now = Timestamp.now();

    await db.runTransaction(async (tx) => {
      const sellerRef = db.collection("users").doc(sellerId);

      const sellerSnap = await tx.get(sellerRef);

      if (!sellerSnap.exists) {
        throw new HttpsError("not-found", "Vendedor não encontrado.");
      }

      const sellerData = sellerSnap.data();
      const wallet = sellerData?.wallet;

      const position = wallet.positions?.find(
        (p: WalletTokenPosition) => p.startupId === startupId,
      );

      if (!position) {
        throw new HttpsError(
          "failed-precondition",
          "O vendedor não possui tokens desta startup.",
        );
      }

      const availableTokens = position.qtdTokens - position.lockedTokens;

      if (availableTokens < qtdTokens) {
        throw new HttpsError(
          "failed-precondition",
          "Quantidade de tokens insuficiente para criar a oferta.",
        );
      }

      position.lockedTokens += qtdTokens;

      tx.update(sellerRef, {
        wallet,
      });

      // Criar oferta
      const offerData: Offer = {
        startupId,
        startupName: startup.name,

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
          throw new HttpsError(
            "invalid-argument",
            "Data de expiração inválida.",
          );
        }

        offerData.expiresAt = Timestamp.fromDate(expirationDate);
      }

      tx.set(offerRef, offerData);
    });

    const offerSnapshot = await offerRef.get();

    return {
      id: offerRef.id,
      ...(offerSnapshot.data() as Offer),
    };
  }),
);
