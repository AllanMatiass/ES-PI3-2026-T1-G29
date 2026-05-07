import { onCall, HttpsError } from "firebase-functions/v2/https";
import { withCallHandler } from "../../shared/middlewares/errorHandler";
import { CreateOfferRequestDTO, OfferIdDTO } from "../types/dtos";
import { validateTransactionData } from "../utils";
import { db } from "../../shared/firebase";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { Offer } from "../types";

/**
 * Cria uma oferta de venda de tokens de uma startup para um usuário específico.
 *
 * @param request - Dados da oferta (startupId, buyerId, sellerId, qtdTokens, tokenPriceCents, expiresAt)
 * @returns O ID da oferta criada.
 */
export const createOffer = onCall(
  withCallHandler<CreateOfferRequestDTO, OfferIdDTO>(async (request) => {
    const {
      startupId,
      buyerId,
      sellerId,
      qtdTokens,
      tokenPriceCents,
      expiresAt,
    } = request.data;

    // 1. Verificar autenticação básica
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Usuário não autenticado.");
    }

    // 2. Validar se os dados obrigatórios foram fornecidos
    if (!startupId || !buyerId || !sellerId || !qtdTokens || !tokenPriceCents) {
      throw new HttpsError(
        "invalid-argument",
        "Dados insuficientes para criar a oferta (startupId, buyerId, sellerId, qtdTokens e tokenPriceCents são obrigatórios).",
      );
    }

    // 3. Validação robusta dos dados da transação (existência de usuários e startup)
    const { buyerUser, sellerUser, startup } = await validateTransactionData({
      buyerId,
      sellerId,
      startupId,
      qtdTokens,
      tokenPriceCents,
    });

    // 4. Construção do objeto de Oferta seguindo os tipos definidos em exchange/types
    const offerData: Omit<Offer, "createdAt"> = {
      startupId,
      buyer: {
        id: buyerId,
        name: buyerUser.name,
      },
      seller: {
        id: sellerId,
        name: sellerUser?.name || startup.name,
        type: sellerUser ? "USER" : "STARTUP",
      },
      qtdTokens,
      tokenPriceCents,
      totalCents: qtdTokens * tokenPriceCents,
      status: "OPEN",
    };

    // 5. Tratar data de expiração se fornecida
    if (expiresAt) {
      const expirationDate = new Date(expiresAt);
      if (isNaN(expirationDate.getTime())) {
        throw new HttpsError("invalid-argument", "Data de expiração inválida.");
      }
      offerData.expiresAt = Timestamp.fromDate(expirationDate);
    }

    // 6. Persistência no Firestore
    // As ofertas são armazenadas em uma subcoleção da startup, seguindo o padrão das transações.
    const offerRef = await db
      .collection("startups")
      .doc(startupId)
      .collection("offers")
      .add({
        ...offerData,
        createdAt: FieldValue.serverTimestamp(),
      });

    return { id: offerRef.id };
  }),
);
