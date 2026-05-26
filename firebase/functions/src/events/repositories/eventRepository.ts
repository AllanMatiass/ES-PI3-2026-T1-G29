// Autor: Allan Giovanni Matias Paes - 25008211
import { FieldValue } from "firebase-admin/firestore";
import { EventDocument, EventWithId } from "../types";
import { EventRequestDTO } from "../types/dtos/dtos";
import { db } from "../../firebase";
import { listPaginated } from "../../shared/paginatedQueryBuilder";

const eventsCollection = db.collection("events");

export function createEventTx(
  tx: FirebaseFirestore.Transaction,
  data: EventRequestDTO,
): EventWithId {
  const { title, summary, delta, tags, startupId, content } = data;
  const eventRef = eventsCollection.doc();

  // Cria um objeto Event que obrigatoriamente deve ser do tipo EventDocument
  const event = {
    startupId,
    title,
    summary,
    delta,
    tags,
    content,
    createdAt: FieldValue.serverTimestamp(),
  } satisfies EventDocument;

  // Armazena no banco de dados
  tx.set(eventRef, event);

  return { ...event, id: eventRef.id };
}

// Retorna eventos que ajudam o frontend a fazer "infinite loading".
export async function listEvents(
  startupId?: string | undefined,
  limit = 10,
  lastEventId?: string | undefined,
): Promise<{ events: EventWithId[]; lastEventId: string | null }> {
  // Lista de forma paginada (estratégia do infinite loading)
  const { docs, lastDocId } = await listPaginated<EventWithId>(
    eventsCollection,
    startupId,
    limit,
    lastEventId,
  );

  return {
    events: docs,
    lastEventId: lastDocId,
  };
}
