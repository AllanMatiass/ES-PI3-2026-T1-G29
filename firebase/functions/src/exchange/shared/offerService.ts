import { HttpsError } from "firebase-functions/v2/https";
import { Timestamp } from "firebase-admin/firestore";
import { db } from "../../shared/firebase";
import { normalizeString } from "../../shared/validation";
import {
  getOfferById,
  getOffersBySellerId,
  listOffers,
  createOfferInTransaction,
  expireOfferInTransaction,
} from "../repositories/offerRepository";
import { getUserById } from "../../auth/repositories/userRepository";
import { upsertStartupInvestor } from "../../startups/shared/upsertInvestor";
import { Wallet, WalletTokenPositionDTO } from "../../auth/types";
import { TransactionService } from "./transactionService";
import { Offer, OfferWithId } from "../types";
import {
  CreateOfferRequestDTO,
  AcceptOfferRequestDTO,
  AcceptOfferResponseDTO,
  ExpireOfferResponseDTO,
  GetMyOffersResponseDTO,
  MyOfferDTO,
  GetOffersRequestDTO,
  PaginatedOffersResponseDTO,
} from "../types/dtos";
import { validateTransactionData } from "../utils";

const transactionService = new TransactionService();

export class OfferService {
  async createOffer(
    sellerId: string,
    data: CreateOfferRequestDTO,
  ): Promise<OfferWithId> {
    const { startupId, qtdTokens, tokenPriceCents, expiresAt } = data;

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

    const maxPrice = startup.currentTokenPriceCents * 1.5; // +50%
    const minPrice = startup.currentTokenPriceCents * 0.5; // -50%

    if (tokenPriceCents > maxPrice || tokenPriceCents < minPrice) {
      throw new HttpsError(
        "invalid-argument",
        "Preço fora da banda permitida de mercado.",
      );
    }

    const now = Timestamp.now();

    const sellerPosition = sellerUser?.wallet?.positions?.find(
      (p) => p.startupId === startupId,
    );
    const averageAcquisitionPriceCents = sellerPosition?.averagePriceCents || 0;

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
  }

  async acceptOffer(
    buyerId: string,
    data: AcceptOfferRequestDTO,
  ): Promise<AcceptOfferResponseDTO> {
    const offerId = normalizeString(data?.offerId);
    const qtdTokens = data.qtdTokens;

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

    return db.runTransaction(async (tx) => {
      const sellerRef = db.collection("users").doc(sellerId);
      const buyerRef = db.collection("users").doc(buyerId);
      const offerRef = db.collection("offers").doc(offerId);

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

      if (buyerWallet.balanceInCents < purchaseTotalCents) {
        throw new HttpsError("failed-precondition", "Saldo insuficiente.");
      }

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

      sellerPosition.qtdTokens =
        (Number(sellerPosition.qtdTokens) || 0) - qtdTokens;

      sellerPosition.lockedTokens =
        (Number(sellerPosition.lockedTokens) || 0) - qtdTokens;

      const sellerAvgPrice = Number(sellerPosition.averagePriceCents) || 0;
      const sellerCurrentPrice =
        Number(sellerPosition.currentTokenPriceCents) || 0;

      sellerPosition.investedCents = Math.round(
        sellerPosition.qtdTokens * sellerAvgPrice,
      );

      sellerPosition.currentValueCents = Math.round(
        sellerPosition.qtdTokens * sellerCurrentPrice,
      );

      sellerPosition.updatedAt = now;

      sellerWallet.positions = sellerWallet.positions.filter(
        (p: WalletTokenPositionDTO) => (Number(p.qtdTokens) || 0) > 0,
      );

      sellerWallet.balanceInCents =
        (Number(sellerWallet.balanceInCents) || 0) + purchaseTotalCents;

      sellerWallet.totalInvestedCents = sellerWallet.positions.reduce(
        (acc, p) => acc + (Number(p.investedCents) || 0),
        0,
      );

      sellerWallet.updatedAt = now;

      const existingBuyerPosition = buyerWallet.positions.find(
        (p: WalletTokenPositionDTO) => p.startupId === offer.startupId,
      );

      if (existingBuyerPosition) {
        const currentBuyerQtd = Number(existingBuyerPosition.qtdTokens) || 0;
        const currentBuyerInvested =
          Number(existingBuyerPosition.investedCents) || 0;
        const currentBuyerPrice =
          Number(existingBuyerPosition.currentTokenPriceCents) ||
          offer.tokenPriceCents;

        const newQtdTokens = currentBuyerQtd + qtdTokens;
        const newInvestedCents = currentBuyerInvested + purchaseTotalCents;

        existingBuyerPosition.qtdTokens = newQtdTokens;
        existingBuyerPosition.investedCents = newInvestedCents;
        existingBuyerPosition.averagePriceCents =
          newQtdTokens > 0 ? Math.round(newInvestedCents / newQtdTokens) : 0;
        existingBuyerPosition.currentTokenPriceCents = currentBuyerPrice;
        existingBuyerPosition.currentValueCents = Math.round(
          newQtdTokens * currentBuyerPrice,
        );
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
          updatedAt: now,
        });
      }

      buyerWallet.balanceInCents =
        (Number(buyerWallet.balanceInCents) || 0) - purchaseTotalCents;

      buyerWallet.totalInvestedCents = buyerWallet.positions.reduce(
        (acc, p) => acc + (Number(p.investedCents) || 0),
        0,
      );

      buyerWallet.updatedAt = now;

      await upsertStartupInvestor(tx, {
        startupId: offer.startupId,
        startupName: offer.startupName,
        userId: buyerId,
        userName: buyerUser.name,
        qtdTokens: qtdTokens,
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
          qtdTokens: 0,
          totalCents: 0,
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
  }

  async expireOffer(offerId: string): Promise<ExpireOfferResponseDTO> {
    const normalizedOfferId = normalizeString(offerId);
    const expirationDate = Timestamp.now();

    if (!normalizedOfferId) {
      throw new HttpsError(
        "invalid-argument",
        "offerId deve estar presente no corpo da requisição.",
      );
    }

    const offer = await getOfferById(normalizedOfferId);
    if (!offer) throw new HttpsError("not-found", "Oferta não encontrada.");

    if (offer.status !== "OPEN") {
      return {
        offerId: normalizedOfferId,
        expired: offer.status === "EXPIRED",
      };
    }

    const expiresAt = offer.expiresAt?.toMillis();

    if (!expiresAt) {
      return {
        offerId: normalizedOfferId,
        expired: false,
      };
    }

    const isExpired = expiresAt < expirationDate.toMillis();

    if (!isExpired) {
      return {
        offerId: normalizedOfferId,
        expired: false,
      };
    }

    const success = await expireOfferInTransaction(normalizedOfferId);

    return {
      offerId: normalizedOfferId,
      expired: success,
    };
  }

  async getMyOffers(userId: string): Promise<GetMyOffersResponseDTO> {
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
  }

  async getOffers(
    data: GetOffersRequestDTO,
  ): Promise<PaginatedOffersResponseDTO> {
    const { limit } = data;
    const startupId = normalizeString(data.startupId);
    const lastOfferId = normalizeString(data.lastOfferId);

    return listOffers(startupId, limit, lastOfferId);
  }
}
