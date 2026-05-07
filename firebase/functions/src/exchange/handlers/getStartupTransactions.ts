import { onCall } from "firebase-functions/v2/https";
import { withCallHandler } from "../../shared/middlewares/errorHandler";
import { TransactionService } from "../shared/transactionService";
import { HttpsError } from "firebase-functions/v2/https";
import { GetStartupTransactionsRequestDTO } from "../types/dtos";
import { Transaction } from "../types";

const transactionService = new TransactionService();

export const getStartupTransactionsHandler = onCall(
  withCallHandler<GetStartupTransactionsRequestDTO, Transaction[]>(
    async (request) => {
      const { startupId, limit } = request.data;

      if (!startupId) {
        throw new HttpsError("invalid-argument", "Missing startupId");
      }

      const transactions = await transactionService.getStartupTransactions(
        startupId,
        limit ?? 15,
      );

      return transactions;
    },
  ),
);
