// firebase/functions/src/exchange/shared/buyFromUserService.ts

import { HttpsError } from "firebase-functions/v2/https";
import { Timestamp } from "firebase-admin/firestore";
import { db } from "../../shared/firebase";
import { getUserById } from "../../auth/repositories/userRepository";
import { getOfferById } from "../repositories/offerRepository";
import { upsertStartupInvestor } from "../../startups/shared/upsertInvestor";
import { TransactionService } from "./transactionService";
import { Wallet, WalletTokenPositionDTO } from "../../auth/types";
import { Offer } from "../types";
import {
  BuyTokensFromUserRequestDTO,
  BuyTokensFromUserResponseDTO,
} from "../types/dtos";

const transactionService = new TransactionService();

export class BuyFromUserService {
  async buyTokens(
    buyerId: string,
    data: BuyTokensFromUserRequestDTO,
  ): Promise<BuyTokensFromUserResponseDTO> {
    //Validação dos dados de entrada

    if (!data || typeof data !== "object") {
      throw new HttpsError(
        "invalid-argument",
        "Dados da requisição inválidos.",
      );
    }

    const { offerId, qtdTokens } = data;

    if (!offerId || typeof offerId !== "string" || offerId.trim() === "") {
      throw new HttpsError(
        "invalid-argument",
        "offerId é obrigatório e deve ser uma string não vazia.",
      );
    }

    if (qtdTokens === undefined || qtdTokens === null) {
      throw new HttpsError("invalid-argument", "qtdTokens é obrigatório.");
    }

    if (typeof qtdTokens !== "number" || !Number.isFinite(qtdTokens)) {
      throw new HttpsError(
        "invalid-argument",
        "qtdTokens deve ser um número válido.",
      );
    }

    if (!Number.isInteger(qtdTokens) || qtdTokens <= 0) {
      throw new HttpsError(
        "invalid-argument",
        "qtdTokens deve ser um inteiro maior que zero.",
      );
    }

    // Validação de negócio

    const [offer, buyerUser] = await Promise.all([
      getOfferById(offerId),
      getUserById(buyerId),
    ]);

    //validação de Oferta
    if (!offer) {
      throw new HttpsError("not-found", `Oferta '${offerId}' não encontrada.`);
    }

    if (offer.status === "ACCEPTED") {
      throw new HttpsError(
        "failed-precondition",
        "Esta oferta já foi totalmente aceita por outro comprador.",
      );
    }

    if (offer.status === "CANCELLED") {
      throw new HttpsError(
        "failed-precondition",
        "Esta oferta foi cancelada pelo vendedor.",
      );
    }

    if (offer.status === "EXPIRED") {
      throw new HttpsError(
        "failed-precondition",
        "Esta oferta expirou e não está mais disponível.",
      );
    }

    if (offer.status !== "OPEN") {
      throw new HttpsError(
        "failed-precondition",
        "Esta oferta não está disponível para compra.",
      );
    }

    // Verificação de expiração por tempo mesmo que o status ainda não tenha sido atualizado
    const now = Timestamp.now();
    if (offer.expiresAt && offer.expiresAt.toMillis() < now.toMillis()) {
      throw new HttpsError(
        "failed-precondition",
        "Esta oferta expirou. Por favor, atualize a lista de ofertas.",
      );
    }

    if (!offer.seller?.id) {
      throw new HttpsError(
        "internal",
        "Oferta com vendedor inválido. Entre em contato com o suporte.",
      );
    }

    //Comprador não pode ser o mesmo que o vendedor
    if (offer.seller.id === buyerId) {
      throw new HttpsError(
        "permission-denied",
        "Você não pode comprar sua própria oferta.",
      );
    }

    //Quantidade disponível
    if (qtdTokens > offer.qtdTokens) {
      throw new HttpsError(
        "failed-precondition",
        `Quantidade solicitada (${qtdTokens}) maior do que a disponível na oferta (${offer.qtdTokens}).`,
      );
    }

    // validação Comprador
    if (!buyerUser) {
      throw new HttpsError("not-found", "Perfil do comprador não encontrado.");
    }

    if (!buyerUser.wallet) {
      throw new HttpsError(
        "failed-precondition",
        "Carteira do comprador não inicializada.",
      );
    }

    const purchaseTotalCents = qtdTokens * offer.tokenPriceCents;

    if ((buyerUser.wallet.balanceInCents ?? 0) < purchaseTotalCents) {
      throw new HttpsError(
        "failed-precondition",
        `Saldo insuficiente. Necessário: R$${(purchaseTotalCents / 100).toFixed(2)}, Disponível: R$${((buyerUser.wallet.balanceInCents ?? 0) / 100).toFixed(2)}.`,
      );
    }

    const sellerId = offer.seller.id;

    // Transação atômica (se ocorrer qualquer erro cancela todos as etapas)

    return db.runTransaction(async (tx) => {
      const buyerRef = db.collection("users").doc(buyerId);
      const sellerRef = db.collection("users").doc(sellerId);
      const offerRef = db.collection("offers").doc(offerId);

      // Re-lê tudo dentro da transação
      const [buyerSnap, sellerSnap, offerSnap] = await Promise.all([
        tx.get(buyerRef),
        tx.get(sellerRef),
        tx.get(offerRef),
      ]);

      //Re-valida existência
      if (!buyerSnap.exists) {
        throw new HttpsError("not-found", "Comprador não encontrado.");
      }
      if (!sellerSnap.exists) {
        throw new HttpsError("not-found", "Vendedor não encontrado.");
      }
      if (!offerSnap.exists) {
        throw new HttpsError("not-found", "Oferta não encontrada.");
      }

      const freshOffer = offerSnap.data() as Offer;

      //Re-valida estado da oferta
      if (freshOffer.status !== "OPEN") {
        throw new HttpsError(
          "aborted",
          "Oferta foi processada por outro comprador. Tente novamente.",
        );
      }

      if (
        freshOffer.expiresAt &&
        freshOffer.expiresAt.toMillis() < Timestamp.now().toMillis()
      ) {
        throw new HttpsError("aborted", "Oferta expirou durante o processamento.");
      }

      if (qtdTokens > freshOffer.qtdTokens) {
        throw new HttpsError(
          "aborted",
          `Tokens insuficientes. Disponível agora: ${freshOffer.qtdTokens}. Tente novamente.`,
        );
      }

      //Carteiras
      const buyerWallet: Wallet = buyerSnap.data()!.wallet;
      const sellerWallet: Wallet = sellerSnap.data()!.wallet;
      buyerWallet.positions ??= [];
      sellerWallet.positions ??= [];

      const freshTotalCents = qtdTokens * freshOffer.tokenPriceCents;

      if ((buyerWallet.balanceInCents ?? 0) < freshTotalCents) {
        throw new HttpsError("failed-precondition", "Saldo insuficiente.");
      }

      //Valida posição do vendedor
      const sellerPosition = sellerWallet.positions.find(
        (p: WalletTokenPositionDTO) => p.startupId === freshOffer.startupId,
      );

      if (!sellerPosition) {
        throw new HttpsError(
          "failed-precondition",
          "Vendedor não possui posição nesta startup.",
        );
      }

      if ((sellerPosition.qtdTokens ?? 0) < qtdTokens) {
        throw new HttpsError(
          "failed-precondition",
          "Vendedor sem tokens suficientes para esta venda.",
        );
      }

      if ((sellerPosition.lockedTokens ?? 0) < qtdTokens) {
        throw new HttpsError(
          "failed-precondition",
          "Tokens do vendedor não estão devidamente reservados.",
        );
      }

      const txNow = Timestamp.now();

      //Atualiza carteira do vendedor
      const sellerAvgPrice = Number(sellerPosition.averagePriceCents) || 0;
      const sellerCurrentPrice =
        Number(sellerPosition.currentTokenPriceCents) || freshOffer.tokenPriceCents;

      sellerPosition.qtdTokens =
        (Number(sellerPosition.qtdTokens) || 0) - qtdTokens;
      sellerPosition.lockedTokens =
        (Number(sellerPosition.lockedTokens) || 0) - qtdTokens;
      sellerPosition.investedCents = Math.round(
        sellerPosition.qtdTokens * sellerAvgPrice,
      );
      sellerPosition.currentValueCents = Math.round(
        sellerPosition.qtdTokens * sellerCurrentPrice,
      );
      sellerPosition.updatedAt = txNow;

      // Remove posição se zerar
      sellerWallet.positions = sellerWallet.positions.filter(
        (p: WalletTokenPositionDTO) => (Number(p.qtdTokens) || 0) > 0,
      );

      sellerWallet.balanceInCents =
        (Number(sellerWallet.balanceInCents) || 0) + freshTotalCents;
      sellerWallet.totalInvestedCents = sellerWallet.positions.reduce(
        (acc, p) => acc + (Number(p.investedCents) || 0),
        0,
      );
      sellerWallet.updatedAt = txNow;

      //Atualiza carteira do comprador
      const existingBuyerPos = buyerWallet.positions.find(
        (p: WalletTokenPositionDTO) => p.startupId === freshOffer.startupId,
      );

      if (existingBuyerPos) {
        const newQtd =
          (Number(existingBuyerPos.qtdTokens) || 0) + qtdTokens;
        const newInvested =
          (Number(existingBuyerPos.investedCents) || 0) + freshTotalCents;
        const currentPrice =
          Number(existingBuyerPos.currentTokenPriceCents) ||
          freshOffer.tokenPriceCents;

        existingBuyerPos.qtdTokens = newQtd;
        existingBuyerPos.investedCents = newInvested;
        existingBuyerPos.averagePriceCents =
          newQtd > 0 ? Math.round(newInvested / newQtd) : 0;
        existingBuyerPos.currentTokenPriceCents = currentPrice;
        existingBuyerPos.currentValueCents = Math.round(newQtd * currentPrice);
        existingBuyerPos.updatedAt = txNow;
      } else {
        buyerWallet.positions.push({
          startupId: freshOffer.startupId,
          startupName: freshOffer.startupName,
          qtdTokens,
          lockedTokens: 0,
          averagePriceCents: freshOffer.tokenPriceCents,
          investedCents: freshTotalCents,
          currentTokenPriceCents: freshOffer.tokenPriceCents,
          currentValueCents: freshTotalCents,
          updatedAt: txNow,
        } satisfies WalletTokenPositionDTO);
      }

      buyerWallet.balanceInCents =
        (Number(buyerWallet.balanceInCents) || 0) - freshTotalCents;
      buyerWallet.totalInvestedCents = buyerWallet.positions.reduce(
        (acc, p) => acc + (Number(p.investedCents) || 0),
        0,
      );
      buyerWallet.updatedAt = txNow;

      //Atualiza a oferta
      const isFullPurchase = qtdTokens === freshOffer.qtdTokens;

      if (isFullPurchase) {
        tx.update(offerRef, {
          status: "ACCEPTED",
          qtdTokens: 0,
          totalCents: 0,
          acceptedAt: txNow,
          buyer: { id: buyerId, name: buyerUser.name },
        });
      } else {
        // Compra parcial: reduz a quantidade restante da oferta
        tx.update(offerRef, {
          qtdTokens: freshOffer.qtdTokens - qtdTokens,
          totalCents:
            (freshOffer.qtdTokens - qtdTokens) * freshOffer.tokenPriceCents,
        });
      }

      //Registra histórico de transação
      const transactionRef = await transactionService.registerTransactionTx(tx, {
        startupId: freshOffer.startupId,
        startupName: freshOffer.startupName,
        buyer: { id: buyerId, name: buyerUser.name, type: "USER" },
        seller: {
          id: sellerId,
          name: freshOffer.seller.name,
          type: "USER",
        },
        qtdTokens,
        tokenPriceCents: freshOffer.tokenPriceCents,
      });

      //Atualiza registro de investidor da startup
      await upsertStartupInvestor(tx, {
        startupId: freshOffer.startupId,
        startupName: freshOffer.startupName,
        userId: buyerId,
        userName: buyerUser.name,
        qtdTokens,
        tokenPriceCents: freshOffer.tokenPriceCents,
      });

      // Atuliza as duas carteiras
      tx.update(sellerRef, { wallet: sellerWallet });
      tx.update(buyerRef, { wallet: buyerWallet });

      return {
        transactionId: transactionRef.id,
        offerId,
        qtdTokens,
        tokenPriceCents: freshOffer.tokenPriceCents,
        totalCents: freshTotalCents,
        remainingOfferTokens: freshOffer.qtdTokens - qtdTokens,
        newBalanceCents: buyerWallet.balanceInCents,
        isOfferFullyAccepted: isFullPurchase,
      };
    });
  }
}
