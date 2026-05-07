import { HttpsError } from "firebase-functions/v2/https";
import { getUserById } from "../auth/repositories/userRepository";
import { getStartupById } from "../startups/repositories/startupRepository";

type ValidateTransactionParams = {
  buyerId?: string;
  sellerId?: string;
  startupId: string;
  qtdTokens: number;
  tokenPriceCents: number;
};

export async function validateTransactionData({
  buyerId,
  sellerId,
  startupId,
  qtdTokens,
  tokenPriceCents,
}: ValidateTransactionParams) {
  if (!startupId) {
    throw new HttpsError("invalid-argument", "Startup inválida.");
  }

  if (buyerId && sellerId && buyerId === sellerId) {
    throw new HttpsError(
      "invalid-argument",
      "Buyer e seller não podem ser iguais.",
    );
  }

  if (!Number.isFinite(qtdTokens) || qtdTokens <= 0) {
    throw new HttpsError("invalid-argument", "Quantidade de tokens inválida.");
  }

  if (!Number.isFinite(tokenPriceCents) || tokenPriceCents <= 0) {
    throw new HttpsError("invalid-argument", "Preço do token inválido.");
  }

  const [buyerUser, startup, sellerUser] = await Promise.all([
    buyerId ? getUserById(buyerId) : Promise.resolve(undefined),
    getStartupById(startupId),
    sellerId ? getUserById(sellerId) : Promise.resolve(undefined),
  ]);

  if (buyerId && !buyerUser) {
    throw new HttpsError("not-found", "Comprador não encontrado.");
  }

  if (!startup) {
    throw new HttpsError(
      "not-found",
      `Startup com ID '${startupId}' não encontrada.`,
    );
  }

  if (sellerId && !sellerUser) {
    throw new HttpsError("not-found", "Vendedor não encontrado.");
  }

  return {
    buyerUser,
    sellerUser,
    startup,
  };
}
