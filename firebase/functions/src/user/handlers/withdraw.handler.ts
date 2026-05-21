import { onRequest } from "firebase-functions/v2/https";
import { processWithdraw } from "../repositories/userRepository";

export const createWithdraw = onRequest(async (req, res) => {
  try {
    const { userId, amount } = req.body;

    if (!userId || !amount || amount <= 0) {
      res.status(400).send({ success: false, message: "Dados inválidos." });
      return;
    }

    const amountInCents = Math.round(amount * 100);
    const newBalanceInCents = await processWithdraw(userId, amountInCents);

    // Retorna exatamente: id do usuário + nova quantidade de fundos
    res.status(200).send({
      userId: userId,
      newBalance: newBalanceInCents / 100,
    });
  } catch (error: any) {
    // Se cair no erro de "Saldo insuficiente" (failed-precondition), retorna status 400
    const statusCode = error.code === "failed-precondition" ? 400 : 500;
    res.status(statusCode).send({
      success: false,
      message: error.message || "Erro ao sacar.",
    });
  }
});
