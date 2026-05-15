// Autor: Allan Giovanni Matias Paes
import { onCall } from "firebase-functions/v2/https";
import { withCallHandler } from "../../shared/middlewares/errorHandler";
import { TransactionService } from "../shared/transactionService";
import { RegisterTransactionRequestDTO, TransactionIdDTO } from "../types/dtos";
import { requireAuthenticatedUser } from "../../shared/auth";

const transactionService = new TransactionService();

export const createTransaction = onCall(
  withCallHandler<RegisterTransactionRequestDTO, TransactionIdDTO>(
    async (request) => {
      requireAuthenticatedUser(request);
      const transactionId = await transactionService.registerTransaction(
        request.data,
      );
      return { id: transactionId };
    },
  ),
);
