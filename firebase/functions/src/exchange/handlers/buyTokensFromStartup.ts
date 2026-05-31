// Autor: Pedro Vinícius Romanato - 25004075

import { onCall } from "firebase-functions/v2/https";
import { withCallHandler } from "../../shared/middlewares/errorHandler";
import { requireAuthenticatedUser } from "../../shared/auth";
import { BuyFromStartupService } from "../shared/buyFromStartupService";
import {
  BuyTokensFromStartupRequestDTO,
  BuyTokensFromStartupResponseDTO,
} from "../types/dtos";

// Instância do serviço de compra direta (Mercado Primário) reutilizada entre chamadas
const buyFromStartupService = new BuyFromStartupService();


//Cloud Function que processa a compra direta de tokens de uma startup

export const buyTokensFromStartup = onCall(
  withCallHandler<
    BuyTokensFromStartupRequestDTO,
    BuyTokensFromStartupResponseDTO
  >(async (request) => {
    // Garante que apenas usuários autenticados possam adquirir tokens
    const { uid } = requireAuthenticatedUser(request);

    // Executa a compra e retorna o recibo com os detalhes da transação
    return buyFromStartupService.buyTokens(uid, request.data);
  }),
);
