// Autor: Allan Giovanni Matias Paes - 25008211
import { HttpsError } from "firebase-functions/v2/https";

import * as transactionRepository from "../repositories/transactionRepository";

import { getStartupById } from "../../startups/repositories/startupRepository";

import {
  GetUserTransactionsRequestDTO,
  PaginatedTransactionsResponseDTO,
  RegisterTransactionRequestDTO,
} from "../types/dtos";
import { validateTransactionData } from "../utils";
import { db } from "../../shared/firebase";
import {
  Transaction,
  TransactionParticipant,
  TransactionWithId,
} from "../types";
import { normalizeString } from "../../shared/validation";

/**
 * Serviço responsável por gerenciar a lógica de negócios das transações (histórico, criação e listagem).
 */
export class TransactionService {
  /**
   * Registra uma nova transação no sistema de forma isolada (fora de uma transação do Firestore).
   * Determina automaticamente se a transação é primária (compra da startup) ou secundária (entre usuários).
   * * @param {RegisterTransactionRequestDTO} data - Objeto contendo os dados do comprador, vendedor (opcional), startup, qtd e preço.
   * @returns {Promise<string>} O ID da transação criada.
   * @throws {HttpsError} Erros de validação (argumentos inválidos, comprador igual ao vendedor, etc).
   */
  async registerTransaction(
    data: RegisterTransactionRequestDTO,
  ): Promise<string> {
    const { startupId, buyer, seller, qtdTokens, tokenPriceCents } = data;

    // Normaliza as strings para evitar problemas com espaços em branco e formatações indesejadas
    const startupIdNormalized = normalizeString(startupId);
    const buyerId = normalizeString(buyer?.id);
    const buyerName = normalizeString(buyer?.name);

    // Verificação básica de campos obrigatórios
    if (
      !startupIdNormalized ||
      !buyerId ||
      !buyerName ||
      !qtdTokens ||
      !tokenPriceCents
    ) {
      throw new HttpsError(
        "invalid-argument",
        "Missing required transaction fields",
      );
    }

    let normalizedSeller: TransactionParticipant | undefined;

    // Se o vendedor foi informado, significa que é uma transação entre usuários (mercado secundário)
    if (seller) {
      const sellerId = normalizeString(seller.id);
      const sellerName = normalizeString(seller.name);

      if (!sellerId || !sellerName) {
        throw new HttpsError("invalid-argument", "Invalid seller");
      }

      normalizedSeller = {
        id: sellerId,
        name: sellerName,
        type: "USER",
      };
    }

    // Chama o utilitário de validação para garantir consistência dos dados com o banco
    const { startup } = await validateTransactionData({
      buyerId,
      sellerId: normalizedSeller?.id,
      startupId: startupIdNormalized,
      qtdTokens,
      tokenPriceCents,
    });

    if (!startup) {
      throw new HttpsError("not-found", "Startup não encontrada.");
    }

    // Regra de negócio vital: um usuário não pode vender tokens para si mesmo
    if (normalizedSeller?.id === buyerId) {
      throw new HttpsError(
        "invalid-argument",
        "Comprador e vendedor não podem ser iguais.",
      );
    }

    let finalSeller: TransactionParticipant;

    // Formata o participante "vendedor" dependendo do tipo da transação
    if (!normalizedSeller) {
      // Se não tem vendedor definido, a própria startup está emitindo/vendendo os tokens
      finalSeller = {
        id: startupIdNormalized,
        name: startup.name,
        type: "STARTUP",
      };
    } else {
      // Caso contrário, é um usuário comum vendendo seus tokens
      finalSeller = {
        id: normalizedSeller.id,
        name: normalizedSeller.name,
        type: "USER",
      };
    }

    // Monta o payload final da transação calculando o valor total em centavos
    const transactionData: Omit<Transaction, "createdAt"> = {
      startupId: startupIdNormalized,
      startupName: startup.name,
      buyer: {
        id: buyerId,
        name: buyerName,
        type: "USER",
      },
      seller: finalSeller,
      // Array auxiliar para facilitar consultas (where array-contains)
      participants: [buyerId, finalSeller.id],
      qtdTokens,
      tokenPriceCents,
      totalCents: qtdTokens * tokenPriceCents,
      transactionType:
        finalSeller.type === "USER" ? "USER_TRADE" : "BUY_FROM_STARTUP",
    };

    // Repassa os dados formatados para a camada de repositório persistir no banco
    return transactionRepository.createTransaction(transactionData);
  }

  /**
   * Busca as transações mais recentes envolvendo uma startup específica.
   * * @param {string} startupId - ID da startup.
   * @param {number} [limit=15] - Limite de transações a retornar (entre 1 e 50).
   * @returns {Promise<TransactionWithId[]>} Lista de transações da startup.
   * @throws {HttpsError} Lança erro caso o limite seja inválido ou a startup não exista.
   */
  async getStartupTransactions(
    startupId: string,
    limit = 15,
  ): Promise<TransactionWithId[]> {
    if (!startupId) {
      throw new HttpsError("invalid-argument", "Startup ID inválido.");
    }

    // Proteção contra consultas abusivas no Firestore
    if (!Number.isInteger(limit) || limit <= 0 || limit > 50) {
      throw new HttpsError("invalid-argument", "Limit deve ser entre 1 e 50.");
    }

    // Verifica a existência da startup antes de consultar a subcoleção/transações
    const startup = await getStartupById(startupId);

    if (!startup) {
      throw new HttpsError("not-found", "Startup não encontrada.");
    }

    return transactionRepository.getTransactionsByStartupId(startupId, limit);
  }

  /**
   * Busca o histórico de transações de um usuário com suporte a paginação.
   * * @param {string} userId - ID do usuário.
   * @param {GetUserTransactionsRequestDTO} data - Dados de paginação contendo limite e o último ID visualizado (cursor).
   * @returns {Promise<PaginatedTransactionsResponseDTO>} Transações e o ID cursor para a próxima página.
   */
  async getUserTransactions(
    userId: string,
    data: GetUserTransactionsRequestDTO,
  ): Promise<PaginatedTransactionsResponseDTO> {
    const { limit, lastTransactionId } = data;

    // Garante um limite seguro e padronizado (fallback para 20 se vier inválido/vazio)
    const normalizedLimit =
      limit && Number.isInteger(limit) && limit > 0 && limit <= 50 ? limit : 20;

    return transactionRepository.listTransactionsByUserId(
      userId,
      normalizedLimit,
      lastTransactionId,
    );
  }

  /**
   * Registra uma transação financeira *dentro* de uma transação atômica do Firestore já em andamento.
   * Útil para operações complexas (ex: comprar tokens) onde saldo e registro devem falhar ou ter sucesso juntos.
   * * @param {FirebaseFirestore.Transaction} tx - A instância da transação do Firestore em execução.
   * @param {RegisterTransactionRequestDTO & { startupName: string }} data - Dados completos da transação.
   * @returns {Promise<FirebaseFirestore.DocumentReference>} A referência do documento da transação que será criado.
   * @throws {HttpsError} Se houver tentativa de auto-negociação (self-trade).
   */
  async registerTransactionTx(
    tx: FirebaseFirestore.Transaction,
    data: RegisterTransactionRequestDTO & {
      startupName: string;
    },
  ): Promise<FirebaseFirestore.DocumentReference> {
    const {
      startupId,
      startupName,
      buyer,
      seller,
      qtdTokens,
      tokenPriceCents,
    } = data;

    if (seller?.id === buyer.id) {
      throw new HttpsError(
        "invalid-argument",
        "Comprador e vendedor não podem ser iguais.",
      );
    }

    let finalSeller: TransactionParticipant;

    // Define o agente vendedor: Startup (primário) ou Usuário (secundário)
    if (!seller) {
      finalSeller = {
        id: startupId,
        name: startupName,
        type: "STARTUP",
      };
    } else {
      finalSeller = {
        id: seller.id,
        name: seller.name,
        type: "USER",
      };
    }

    // Prepara a referência do novo documento antes mesmo de salvá-lo
    const transactionRef = db.collection("transactions").doc();

    const transactionData: Omit<Transaction, "createdAt"> = {
      startupId,
      startupName,
      buyer: {
        id: buyer.id,
        name: buyer.name,
        type: "USER",
      },
      seller: finalSeller,
      participants: [buyer.id, finalSeller.id],
      qtdTokens,
      tokenPriceCents,
      totalCents: qtdTokens * tokenPriceCents,
      transactionType:
        finalSeller.type === "USER" ? "USER_TRADE" : "BUY_FROM_STARTUP",
    };

    // Empilha a operação de escrita na transação do Firestore (NÃO executa imediatamente)
    // Usamos new Date() localmente pois FieldValue.serverTimestamp() pode gerar atrasos ou
    // incompatibilidades de leitura durante uma transação em andamento
    tx.set(transactionRef, {
      ...transactionData,
      createdAt: new Date(),
    });

    return transactionRef;
  }
}
