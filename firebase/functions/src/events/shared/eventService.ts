// Autor: Allan Giovanni Matias Paes - 25008211

import { HttpsError } from "firebase-functions/https";
import { createEventTx } from "../repositories/eventRepository";
import { EventRequestDTO, EventResponseDTO } from "../types/dtos/dtos";
import { normalizeString } from "../../shared/validation";
import { db } from "../../firebase";
import { TokenPricingService } from "../../shared/tokenPricingService";
import { StartupDocument } from "../../startups/types";
import { startupsCollection } from "../../startups/repositories/startupRepository";

// Service geral de eventos
export class EventService {
  // Instância do serviço de precificação de tokens
  private tokenPricingService = new TokenPricingService();

  // Método responsável por adicionar um novo evento
  async add(data: EventRequestDTO): Promise<EventResponseDTO> {
    // Se tags for undefined, define como array vazio
    data.tags ??= [];
    const { delta, tags } = data;

    // Normaliza os campos de texto
    const title = normalizeString(data.title);
    const summary = normalizeString(data.summary);
    const startupId = normalizeString(data.startupId);
    const content = normalizeString(data.content);

    // Validação dos campos obrigatórios
    if (!title || !summary || delta === undefined || !startupId || !content) {
      throw new HttpsError(
        "failed-precondition",
        "Verifique se: `title`, `summary`, `delta`, `startupId` e `content` estão sendo enviados corretamente na requisição ",
      );
    }

    // Executa tudo dentro de uma transação do Firestore
    return db.runTransaction(async (tx) => {
      const startupRef = startupsCollection.doc(startupId);

      // Busca os dados da startup
      const startupSnap = await tx.get(startupRef);

      // Verifica se a startup existe
      if (!startupSnap.exists) {
        throw new HttpsError("not-found", "Startup não encontrada");
      }

      // Converte os dados da startup para o tipo correto
      const startupData = startupSnap.data() as StartupDocument;

      // Cria o evento usando a transação
      const event = createEventTx(tx, {
        title,
        summary,
        delta,
        tags,
        startupId,
        content,
      });

      // Recalcula o valor do token baseado no evento
      const pricingResult = await this.tokenPricingService.revalueFromEventTx(
        tx,
        startupId,
        delta,
        startupData,
      );

      // Retorna os dados do evento + novo preço do token
      return {
        ...event,
        newTokenPrice: pricingResult.newPriceCents,
      };
    });
  }
}
