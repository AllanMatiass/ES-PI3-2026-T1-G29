// Autor: Murilo Rigoni
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { processDeposit } from "../repositories/userRepository";
import { withCallHandler } from "../../shared/middlewares/errorHandler";
import { DepositRequestDTO, DepositResponseDTO } from "../types/dtos";
import { requireAuthenticatedUser } from "../../shared/auth";

export const createDeposit = onCall(
  withCallHandler<DepositRequestDTO, DepositResponseDTO>(async (request) => {
    const userId = requireAuthenticatedUser(request).uid;
    const { amount } = request.data; // amount enviado do Flutter (ex: 50.00)

    if (!amount || amount <= 0) {
      throw new HttpsError(
        "failed-precondition",
        "O body deve conter userId e amount > 0",
      );
    }

    const amountInCents = Math.round(amount * 100);
    const newBalanceInCents = await processDeposit(userId, amountInCents);

    // Retorna exatamente: id do usuário + nova quantidade de fundos (em Centavos)
    return {
      userId,
      newBalance: newBalanceInCents,
    };
  }),
);
