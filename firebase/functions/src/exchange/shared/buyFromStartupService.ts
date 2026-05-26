// Autor: Pedro Vinícius Romanato - 25004075

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

/**
 * Serviço responsável por gerenciar a compra direta de tokens de uma startup (Mercado Primário).
 */
export class BuyFromStartupService {
  private tokenPricingService = new TokenPricingService();

  /**
   * Processa a compra de tokens de uma startup por um usuário.
   * Realiza validações rigorosas de entrada, regras de negócio e garante a atomicidade
   * da operação atualizando saldos, posições na carteira e capital da startup em uma única transação.
   * * @param {string} buyerId - O ID do usuário comprador.
   * @param {BuyTokensFromStartupRequestDTO} data - Objeto contendo o ID da startup e a quantidade de tokens desejada.
   * @returns {Promise<BuyTokensFromStartupResponseDTO>} Recibo contendo os dados da transação, como valor total pago e novo saldo.
   * @throws {HttpsError} Lança erros de validação ('invalid-argument'), falta de recursos ('failed-precondition') ou não encontrado ('not-found').
   */
  async buyTokens(
    buyerId: string,
    data: BuyTokensFromStartupRequestDTO,
  ): Promise<BuyTokensFromStartupResponseDTO> {
    // ==========================================
    // 1. Validações de Entrada (Input Validation)
    // ==========================================

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

    // ==========================================
    // 2. Validações de Regras de Negócio (Pré-Transação)
    // ==========================================
    // Buscamos os dados previamente para evitar iniciar uma transação custosa se já soubermos que vai falhar

    const [startup, buyerUser] = await Promise.all([
      getStartupById(startupId),
      userService.get(buyerId),
    ]);

    // Validação do estado e disponibilidade da Startup
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

    // Calcula quantos tokens primários ainda restam para venda
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

    // Validação do perfil e saldo do Comprador
    if (!buyerUser) {
      throw new HttpsError("not-found", "Perfil do comprador não encontrado.");
    }

    if (!buyerUser.wallet) {
      throw new HttpsError(
        "failed-precondition",
        "Carteira do comprador não inicializada.",
      );
    }

    // Calcula o valor total da operação em centavos
    const tokenPriceCents = startup.currentTokenPriceCents;
    const totalCents = qtdTokens * tokenPriceCents;

    if ((buyerUser.wallet.balanceInCents ?? 0) < totalCents) {
      throw new HttpsError(
        "failed-precondition",
        `Saldo insuficiente. Necessário: R$${(totalCents / 100).toFixed(2)}, Disponível: R$${((buyerUser.wallet.balanceInCents ?? 0) / 100).toFixed(2)}.`,
      );
    }

    // ==========================================
    // 3. Transação Atômica (Firestore Transaction)
    // ==========================================
    // Caso algum passo dê erro, o Firebase cancela todo o processo, evitando inconsistências financeiras.

    return db.runTransaction(async (tx) => {
      // Define as referências dos documentos que serão lidos e alterados
      const buyerRef = db.collection("users").doc(buyerId);
      const startupRef = db.collection("startups").doc(startupId);
      const investorRef = db
        .collection("startups")
        .doc(startupId)
        .collection("investors")
        .doc(buyerId);

      // Re-lê os documentos DENTRO da transação. Isso é vital para garantir que
      // concorrência (ex: duas pessoas comprando os últimos tokens ao mesmo tempo) seja tratada corretamente.
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

      // Extrai os dados mais recentes (fresh data) das leituras transacionais
      const freshStartup = startupSnap.data() as StartupDocument;
      const buyerWallet: Wallet = buyerSnap.data()?.wallet;
      buyerWallet.positions ??= [];

      const freshTokenPriceCents = freshStartup.currentTokenPriceCents;
      const freshTotalCents = qtdTokens * freshTokenPriceCents;
      const freshAvailable =
        (freshStartup.totalTokensIssued ?? 0) -
        (freshStartup.circulatingTokens ?? 0);

      // Re-valida o estoque e o saldo com os dados atualizados para evitar over-selling ou over-spending
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

      // ==========================================
      // Atualizações de Estado (Escritas)
      // ==========================================

      // 3.1. Atualiza a carteira do comprador (Adiciona os tokens e recalcula preço médio)
      const existingPos = buyerWallet.positions.find(
        (p: WalletTokenPositionDTO) => p.startupId === startupId,
      );

      if (existingPos) {
        // Se já possui tokens da startup, atualiza a posição (preço médio e quantidade)
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
        // Se for o primeiro investimento na startup, cria uma nova posição
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

      // Debita o valor do saldo em dinheiro (fiat) do usuário e recalcula o total investido
      buyerWallet.balanceInCents =
        (Number(buyerWallet.balanceInCents) || 0) - freshTotalCents;

      buyerWallet.totalInvestedCents = buyerWallet.positions.reduce(
        (acc, p) => acc + (Number(p.investedCents) || 0),
        0,
      );
      buyerWallet.updatedAt = now;

      // 3.2. Atualiza ou cria o registro do usuário como investidor na subcoleção da Startup
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

      // 3.3. Atualiza os dados macro da startup (tokens circulantes e capital levantado)
      tx.update(startupRef, {
        circulatingTokens:
          (Number(freshStartup.circulatingTokens) || 0) + qtdTokens,
        capitalRaisedCents:
          (Number(freshStartup.capitalRaisedCents) || 0) + freshTotalCents,
        updatedAt: now,
      });

      // 3.4. Cria o registro histórico da transação financeira para auditoria e listagens
      const transactionRef = await transactionService.registerTransactionTx(
        tx,
        {
          startupId,
          startupName: freshStartup.name,
          buyer: { id: buyerId, name: buyerUser.name, type: "USER" },
          seller: { id: startupId, name: startup.name, type: "STARTUP" },
          qtdTokens,
          tokenPriceCents: freshTokenPriceCents,
        },
      );

      // 3.5. Persiste as alterações calculadas na carteira do comprador no Firestore
      tx.update(buyerRef, { wallet: buyerWallet });

      // 3.6. Avalia se essa compra (trade primário) causa um impacto/reavaliação no preço do token
      // (Usa os dados recém-lidos na transação para evitar o problema de "read-after-write")
      await this.tokenPricingService.revalueFromPrimaryTradeTx(
        tx,
        startupId,
        qtdTokens,
        freshStartup,
      );

      // Retorna o recibo final se tudo deu certo
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
