// Autor: Allan Giovanni Matias Paes - 25008211
import { onCall } from "firebase-functions/v2/https";
import { withCallHandler } from "../../shared/middlewares/errorHandler";
import { requireAuthenticatedUser } from "../../shared/auth";
import {
  GetUserTransactionsRequestDTO,
  PaginatedTransactionsResponseDTO,
} from "../../exchange/types/dtos";
import { TransactionService } from "../../exchange/shared/transactionService";

const transactionService = new TransactionService();

export const getUserTransactions = onCall(
  withCallHandler<
    GetUserTransactionsRequestDTO,
    PaginatedTransactionsResponseDTO
  >(async (request) => {
    const auth = requireAuthenticatedUser(request);
    return transactionService.getUserTransactions(auth.uid, request.data || {});
  }),
);
