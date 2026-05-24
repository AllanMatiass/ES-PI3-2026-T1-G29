// Autor: Pedro Romanato & Allan Giovanni Matias Paes

import { HttpsError } from "firebase-functions/v2/https";
import { Timestamp } from "firebase-admin/firestore";
import { db } from "../../shared/firebase";
import { getStartupById } from "../../startups/repositories/startupRepository";
import { upsertStartupInvestor } from "../../startups/shared/upsertInvestor";
import { TransactionService } from "./transactionService";
import { Wallet } from "../../user/types";
import { WalletTokenPositionDTO } from "../../user/types/dtos";
import {
  BuyTokensFromStartupRequestDTO,
  BuyTokensFromStartupResponseDTO,
} from "../types/dtos";
import { TokenPricingService } from "../../shared/tokenPricingService";
import { StartupDocument } from "../../startups/types";
import { UserService } from "../../user/shared/userService";

const transactionService = new TransactionService();
const userService = new UserService();
export class BuyFromStartupService {
  private tokenPricingService = new TokenPricingService();
  async buyTokens(
    buyerId: string,
    data: BuyTokensFromStartupRequestDTO,
  ): Promise<BuyTokensFromStartupResponseDTO> {
    //validacaoes

    if (!data || typeof data !== "object") {
      throw new HttpsError(
        "invalid-argument",
        "Dados da requisição inválidos.",
      );
    }

    const { startupId, qtdTokens } = data;

    if (
      !startupId ||
      typeof startupId !== "string" ||
      startupId.trim() === ""
    ) {
      throw new HttpsError(
        "invalid-argument",
        "startupId é obrigatório e deve ser uma string não vazia.",
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

    //validacao de negocios

    const [startup, buyerUser] = await Promise.all([
      getStartupById(startupId),
      userService.get(buyerId),
    ]);

    //validacao de startup
    if (!startup) {
      throw new HttpsError(
        "not-found",
        `Startup '${startupId}' não encontrada.`,
      );
    }

    if (
      !startup.currentTokenPriceCents ||
      startup.currentTokenPriceCents <= 0
    ) {
      throw new HttpsError(
        "failed-precondition",
        "Startup sem preço de token definido. Compra indisponível.",
      );
    }

    if (!startup.totalTokensIssued || startup.totalTokensIssued <= 0) {
      throw new HttpsError(
        "failed-precondition",
        "Startup sem tokens emitidos. Compra indisponível.",
      );
    }

    const availableTokens =
      (startup.totalTokensIssued ?? 0) - (startup.circulatingTokens ?? 0);

    if (availableTokens <= 0) {
      throw new HttpsError(
        "failed-precondition",
        "Todos os tokens desta startup já foram vendidos.",
      );
    }

    if (availableTokens < qtdTokens) {
      throw new HttpsError(
        "failed-precondition",
        `Tokens insuficientes. Disponível: ${availableTokens}, Solicitado: ${qtdTokens}.`,
      );
    }

    //validacao de comprador
    if (!buyerUser) {
      throw new HttpsError("not-found", "Perfil do comprador não encontrado.");
    }

    if (!buyerUser.wallet) {
      throw new HttpsError(
        "failed-precondition",
        "Carteira do comprador não inicializada.",
      );
    }

    const tokenPriceCents = startup.currentTokenPriceCents;
    const totalCents = qtdTokens * tokenPriceCents;

    if ((buyerUser.wallet.balanceInCents ?? 0) < totalCents) {
      throw new HttpsError(
        "failed-precondition",
        `Saldo insuficiente. Necessário: R$${(totalCents / 100).toFixed(2)}, Disponível: R$${((buyerUser.wallet.balanceInCents ?? 0) / 100).toFixed(2)}.`,
      );
    }

    //Transação atômica(caso algum passo de erro, cancela todo o processo)

    return db.runTransaction(async (tx) => {
      const buyerRef = db.collection("users").doc(buyerId);
      const startupRef = db.collection("startups").doc(startupId);
      const investorRef = db
        .collection("startups")
        .doc(startupId)
        .collection("investors")
        .doc(buyerId);

      // Re-lê dentro da transação para garantir com compras simuntaneas
      const [buyerSnap, startupSnap, investorSnap] = await Promise.all([
        tx.get(buyerRef),
        tx.get(startupRef),
        tx.get(investorRef),
      ]);

      if (!buyerSnap.exists) {
        throw new HttpsError("not-found", "Comprador não encontrado.");
      }
      if (!startupSnap.exists) {
        throw new HttpsError("not-found", "Startup não encontrada.");
      }

      const freshStartup = startupSnap.data() as StartupDocument;
      const buyerWallet: Wallet = buyerSnap.data()?.wallet;
      buyerWallet.positions ??= [];

      const freshTokenPriceCents = freshStartup.currentTokenPriceCents;
      const freshTotalCents = qtdTokens * freshTokenPriceCents;
      const freshAvailable =
        (freshStartup.totalTokensIssued ?? 0) -
        (freshStartup.circulatingTokens ?? 0);

      // Re-valida dentro da transação (estado pode ter mudado)
      if (freshAvailable < qtdTokens) {
        throw new HttpsError(
          "aborted",
          `Tokens reservados por outro comprador. Disponível: ${freshAvailable}. Tente novamente.`,
        );
      }

      if ((buyerWallet.balanceInCents ?? 0) < freshTotalCents) {
        throw new HttpsError("failed-precondition", "Saldo insuficiente.");
      }

      const now = Timestamp.now();

      //Atualiza na carteira do comprador
      const existingPos = buyerWallet.positions.find(
        (p: WalletTokenPositionDTO) => p.startupId === startupId,
      );

      if (existingPos) {
        const newQtd = (Number(existingPos.qtdTokens) || 0) + qtdTokens;
        const newInvested =
          (Number(existingPos.investedCents) || 0) + freshTotalCents;

        existingPos.qtdTokens = newQtd;
        existingPos.investedCents = newInvested;
        existingPos.averagePriceCents =
          newQtd > 0 ? Math.round(newInvested / newQtd) : 0;
        existingPos.currentTokenPriceCents = freshTokenPriceCents;
        existingPos.currentValueCents = Math.round(
          newQtd * freshTokenPriceCents,
        );
        existingPos.updatedAt = now;
      } else {
        buyerWallet.positions.push({
          startupId,
          startupName: freshStartup.name,
          qtdTokens,
          lockedTokens: 0,
          averagePriceCents: freshTokenPriceCents,
          investedCents: freshTotalCents,
          currentTokenPriceCents: freshTokenPriceCents,
          currentValueCents: freshTotalCents,
          updatedAt: now,
        } satisfies WalletTokenPositionDTO);
      }

      buyerWallet.balanceInCents =
        (Number(buyerWallet.balanceInCents) || 0) - freshTotalCents;

      buyerWallet.totalInvestedCents = buyerWallet.positions.reduce(
        (acc, p) => acc + (Number(p.investedCents) || 0),
        0,
      );
      buyerWallet.updatedAt = now;

      //Atualiza registro de investidor da startup
      await upsertStartupInvestor(
        tx,
        {
          startupId,
          startupName: freshStartup.name,
          userId: buyerId,
          userName: buyerUser.name,
          qtdTokens,
          tokenPriceCents: freshTokenPriceCents,
        },
        investorSnap,
      );

      //Atualiza dados da startup
      tx.update(startupRef, {
        circulatingTokens:
          (Number(freshStartup.circulatingTokens) || 0) + qtdTokens,
        capitalRaisedCents:
          (Number(freshStartup.capitalRaisedCents) || 0) + freshTotalCents,
        updatedAt: now,
      });

      //Registra histórico de transação
      const transactionRef = await transactionService.registerTransactionTx(
        tx,
        {
          startupId,
          startupName: freshStartup.name,
          buyer: { id: buyerId, name: buyerUser.name, type: "USER" },
          seller: null,
          qtdTokens,
          tokenPriceCents: freshTokenPriceCents,
        },
      );

      //Persiste carteira do comprador
      tx.update(buyerRef, { wallet: buyerWallet });

      // Aplica revalorização usando o snapshot já carregado para evitar read-after-write
      await this.tokenPricingService.revalueFromPrimaryTradeTx(
        tx,
        startupId,
        qtdTokens,
        freshStartup,
      );

      return {
        transactionId: transactionRef.id,
        qtdTokens,
        tokenPriceCents: freshTokenPriceCents,
        totalCents: freshTotalCents,
        newBalanceCents: buyerWallet.balanceInCents,
      };
    });
  }
}
