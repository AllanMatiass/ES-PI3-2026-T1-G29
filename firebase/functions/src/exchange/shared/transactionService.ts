import * as transactionRepository from "../repositories/transactionRepository";
import { getStartupById } from "../../startups/repositories/startupRepository";
import { HttpsError } from "firebase-functions/v2/https";
import { Transaction } from "../types";
import { RegisterTransactionRequestDTO } from "../types/dtos";
import { validateTransactionData } from "../utils";
import { db } from "../../firebase";

export class TransactionService {
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

    if (seller?.id === buyer.id) {
      throw new HttpsError(
        "invalid-argument",
        "Comprador e Vendedor não podem ser iguais.",
      );
    }

    let finalSeller: Transaction["seller"];

    if (!seller) {
      if (!startup) {
        throw new HttpsError("not-found", "Startup não encontrada.");
      }

      finalSeller = {
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
      buyer,
      seller: finalSeller,
      qtdTokens,
      tokenPriceCents,
      transactionType:
        finalSeller.type == "USER" ? "USER_TRADE" : "BUY_FROM_STARTUP",
      totalCents: qtdTokens * tokenPriceCents,
    };

    return transactionRepository.createTransaction(transactionData);
  }

  async getStartupTransactions(
    startupId: string,
    limit = 15,
  ): Promise<Transaction[]> {
    if (!startupId) {
      throw new HttpsError("invalid-argument", "Startup ID inválido.");
    }

    if (!Number.isInteger(limit) || limit <= 0 || limit > 50) {
      throw new HttpsError(
        "invalid-argument",
        "Limit deve ser um inteiro entre 1 e 50.",
      );
    }

    const startup = await getStartupById(startupId);

    if (!startup) {
      throw new HttpsError("not-found", "Startup não encontrada.");
    }

    return transactionRepository.getTransactionsByStartupId(startupId, limit);
  }

  async registerTransactionTx(
    tx: FirebaseFirestore.Transaction,
    data: { startupName: string } & RegisterTransactionRequestDTO,
  ): Promise<FirebaseFirestore.DocumentReference> {
    const { startupId, buyer, seller, qtdTokens, tokenPriceCents } = data;

    const { startup } = await validateTransactionData({
      buyerId: buyer.id,
      sellerId: seller?.id,
      startupId,
      qtdTokens,
      tokenPriceCents,
    });

    if (seller?.id === buyer.id) {
      throw new HttpsError(
        "invalid-argument",
        "Comprador e Vendedor não podem ser iguais.",
      );
    }

    let finalSeller: Transaction["seller"];

    if (!seller) {
      if (!startup) {
        throw new HttpsError("not-found", "Startup não encontrada.");
      }

      finalSeller = {
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

    const transactionRef = db
      .collection("startups")
      .doc(startupId)
      .collection("transactions")
      .doc();

    const transactionData: Omit<Transaction, "createdAt"> = {
      startupId,
      startupName: startup.name,

      buyer,
      seller: finalSeller,

      qtdTokens,
      tokenPriceCents,

      transactionType:
        finalSeller.type === "USER" ? "USER_TRADE" : "BUY_FROM_STARTUP",

      totalCents: qtdTokens * tokenPriceCents,
    };

    tx.set(transactionRef, {
      ...transactionData,
      createdAt: new Date(),
    });

    return transactionRef;
  }

  //
  // =========================
  // QUERY
  // =========================
  //
  async getStartupTransactionsTx(
    startupId: string,
    limit = 15,
  ): Promise<Transaction[]> {
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
}
