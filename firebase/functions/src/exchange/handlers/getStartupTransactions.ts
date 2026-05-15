// Autor: Allan Giovanni Matias Paes
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { withCallHandler } from "../../shared/middlewares/errorHandler";
import { TransactionService } from "../shared/transactionService";
import { GetStartupTransactionsRequestDTO } from "../types/dtos";
import { Transaction } from "../types";
import { requireAuthenticatedUser } from "../../shared/auth";

const transactionService = new TransactionService();

export const getStartupTransactionsHandler = onCall(
  withCallHandler<GetStartupTransactionsRequestDTO, Transaction[]>(
    async (request) => {
      requireAuthenticatedUser(request);
      const { startupId, limit } = request.data;

      if (!startupId) {
        throw new HttpsError("invalid-argument", "Missing startupId");
      }

      return transactionService.getStartupTransactions(startupId, limit ?? 15);
    },
  ),
);
