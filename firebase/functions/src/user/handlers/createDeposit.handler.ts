import { onRequest } from "firebase-functions/v2/https";
import { processDeposit } from "../repositories/userRepository";

export const createDeposit = onRequest(async (req, res) => {
  try {
    const { userId, amount } = req.body; // amount enviado do Flutter (ex: 50.00)

    if (!userId || !amount || amount <= 0) {
      res.status(400).send({ success: false, message: "Dados inválidos." });
      return;
    }

    const amountInCents = Math.round(amount * 100);
    const newBalanceInCents = await processDeposit(userId, amountInCents);

    // Retorna exatamente: id do usuário + nova quantidade de fundos (em Reais)
    res.status(200).send({
      userId: userId,
      newBalance: newBalanceInCents / 100,
    });
  } catch (error: any) {
    res.status(error.code === "not-found" ? 404 : 500).send({
      success: false,
      message: error.message || "Erro ao depositar.",
    });
  }
});
