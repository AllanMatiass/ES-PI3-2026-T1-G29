// Autor: Pedro Vinícius Romanato - 25004075
import { onCall } from "firebase-functions/v2/https";
import { withCallHandler } from "../../shared/middlewares/errorHandler";
import { requireAuthenticatedUser } from "../../shared/auth";
import { OfferIdDTO, CancelOfferResponseDTO } from "../types/dtos";
import { OfferService } from "../shared/offerService";

// Instância do serviço de ofertas reutilizada entre chamadas da função
const offerService = new OfferService();


//Cloud Function para cancelar uma oferta

export const cancelOffer = onCall(
  withCallHandler<OfferIdDTO, CancelOfferResponseDTO>(async (request) => {
    // Garante que apenas usuários autenticados possam cancelar ofertas
    const sellerId = requireAuthenticatedUser(request).uid;

    // Cancela a oferta verificando se ela pertence ao vendedor informado
    return await offerService.cancelOffer(sellerId, request.data);
  }),
);
