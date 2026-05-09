import { HttpsError } from "firebase-functions/v2/https";

import * as transactionRepository from "../repositories/transactionRepository";

import { getStartupById } from "../../startups/repositories/startupRepository";

import { RegisterTransactionRequestDTO } from "../types/dtos";
import { validateTransactionData } from "../utils";
import { db } from "../../firebase";
import {
  Transaction,
  TransactionParticipant,
  TransactionWithId,
} from "../types";

export class TransactionService {
  //
  // =========================
  // CREATE
  // =========================
  //
  async registerTransaction(
    data: RegisterTransactionRequestDTO,
  ): Promise<string> {
    const { startupId, buyer, seller, qtdTokens, tokenPriceCents } = data;

    const { startup } = await validateTransactionData({
      buyerId: buyer.id,
      sellerId: seller?.id,
      startupId,
      qtdTokens,
      tokenPriceCents,
    });

    if (!startup) {
      throw new HttpsError("not-found", "Startup não encontrada.");
    }

    if (seller?.id === buyer.id) {
      throw new HttpsError(
        "invalid-argument",
        "Comprador e vendedor não podem ser iguais.",
      );
    }

    let finalSeller: TransactionParticipant;

    if (!seller) {
      finalSeller = {
        id: startupId,
        name: startup.name,
        type: "STARTUP",
      };
    } else {
      finalSeller = {
        id: seller.id,
        name: seller.name,
        type: "USER",
      };
    }

    const transactionData: Omit<Transaction, "createdAt"> = {
      startupId,

      startupName: startup.name,

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

    return transactionRepository.createTransaction(transactionData);
  }

  //
  // =========================
  // QUERY
  // =========================
  //
  async getStartupTransactions(
    startupId: string,
    limit = 15,
  ): Promise<TransactionWithId[]> {
    if (!startupId) {
      throw new HttpsError("invalid-argument", "Startup ID inválido.");
    }

    if (!Number.isInteger(limit) || limit <= 0 || limit > 50) {
      throw new HttpsError("invalid-argument", "Limit deve ser entre 1 e 50.");
    }

    const startup = await getStartupById(startupId);

    if (!startup) {
      throw new HttpsError("not-found", "Startup não encontrada.");
    }

    return transactionRepository.getTransactionsByStartupId(startupId, limit);
  }

  //
  // =========================
  // FIRESTORE TRANSACTION
  // =========================
  //
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

    tx.set(transactionRef, {
      ...transactionData,

      createdAt: new Date(),
    });

    return transactionRef;
  }
}
