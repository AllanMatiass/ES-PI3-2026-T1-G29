// Autor: Murilo Rigoni - 25006049
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { processWithdraw } from "../repositories/userRepository";
import { withCallHandler } from "../../shared/middlewares/errorHandler";
import { WithdrawRequestDTO, WithdrawResponseDTO } from "../types/dtos";
import { requireAuthenticatedUser } from "../../shared/auth";

export const createWithdraw = onCall(
  withCallHandler<WithdrawRequestDTO, WithdrawResponseDTO>(async (request) => {
    const userId = requireAuthenticatedUser(request).uid;
    const { amount } = request.data;

    if (!amount || amount <= 0) {
      throw new HttpsError("invalid-argument", "Dados inválidos.");
    }

    const amountInCents = Math.round(amount * 100);
    const newBalanceInCents = await processWithdraw(userId, amountInCents);

    // Retorna exatamente: id do usuário + nova quantidade de fundos (em centavos)
    return {
      userId: userId,
      newBalance: newBalanceInCents,
    };
  }),
);
