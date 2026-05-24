import { HttpsError } from "firebase-functions/https";
import { createEventTx } from "../repositories/eventRepository";
import { EventRequestDTO, EventResponseDTO } from "../types/dtos/dtos";
import { normalizeString } from "../../shared/validation";
import { db } from "../../firebase";
import { TokenPricingService } from "../../shared/tokenPricingService";
import { StartupDocument } from "../../startups/types";
import { startupsCollection } from "../../startups/repositories/startupRepository";

export class EventService {
  private tokenPricingService = new TokenPricingService();

  async add(data: EventRequestDTO): Promise<EventResponseDTO> {
    data.tags ??= [];
    const { delta, tags } = data;
    const title = normalizeString(data.title);
    const summary = normalizeString(data.summary);
    const startupId = normalizeString(data.startupId);
    const content = normalizeString(data.content);

    if (!title || !summary || delta === undefined || !startupId || !content) {
      throw new HttpsError(
        "failed-precondition",
        "Verifique se: `title`, `summary`, `delta`, `startupId` e `content` estão sendo enviados corretamente na requisição ",
      );
    }

    return db.runTransaction(async (tx) => {
      const startupRef = startupsCollection.doc(startupId);
      const startupSnap = await tx.get(startupRef);

      if (!startupSnap.exists) {
        throw new HttpsError("not-found", "Startup não encontrada");
      }

      const startupData = startupSnap.data() as StartupDocument;

      const event = createEventTx(tx, {
        title,
        summary,
        delta,
        tags,
        startupId,
        content,
      });

      const pricingResult = await this.tokenPricingService.revalueFromEventTx(
        tx,
        startupId,
        delta,
        startupData,
      );

      return {
        ...event,
        newTokenPrice: pricingResult.newPriceCents,
      };
    });
  }
}
