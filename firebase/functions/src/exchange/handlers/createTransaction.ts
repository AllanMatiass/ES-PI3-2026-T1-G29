import { onCall, HttpsError } from "firebase-functions/v2/https";
import { withCallHandler } from "../../shared/middlewares/errorHandler";
import { TransactionService } from "../shared/transactionService";
import { RegisterTransactionRequestDTO, TransactionIdDTO } from "../types/dtos";
import { normalizeString } from "../../shared/validation";
import { TransactionAgent } from "../types";
import { requireAuthenticatedUser } from "../../shared/auth";

const transactionService = new TransactionService();

export const createTransaction = onCall(
  withCallHandler<RegisterTransactionRequestDTO, TransactionIdDTO>(
    async (request) => {
      requireAuthenticatedUser(request);
      const { startupId, buyer, seller, qtdTokens, tokenPriceCents } =
        request.data;

      const startupIdNormalized = normalizeString(startupId);

      const buyerId = normalizeString(buyer?.id);
      const buyerName = normalizeString(buyer?.name);

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

      let normalizedSeller: TransactionAgent | undefined;

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

      const transactionId = await transactionService.registerTransaction({
        startupId: startupIdNormalized,
        buyer: {
          id: buyerId,
          name: buyerName,
          type: "USER",
        },
        seller: normalizedSeller,
        qtdTokens,
        tokenPriceCents,
      });

      return { id: transactionId };
    },
  ),
);
