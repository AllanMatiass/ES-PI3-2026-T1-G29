// Autor: Allan Giovanni Matias Paes
import { FieldValue } from "firebase-admin/firestore";
import { EventDocument, EventWithId } from "../types";
import { EventRequestDTO } from "../types/dtos/dtos";
import { HttpsError } from "firebase-functions/https";
import { db } from "../../firebase";
import { listPaginated } from "../../shared/paginatedQueryBuilder";

const eventsCollection = db.collection("events");

export function createEventTx(
  tx: FirebaseFirestore.Transaction,
  data: EventRequestDTO,
): EventWithId {
  const { title, summary, delta, tags, startupId, content } = data;
  const eventRef = eventsCollection.doc();

  const event = {
    startupId,
    title,
    summary,
    delta,
    tags,
    content,
    createdAt: FieldValue.serverTimestamp(),
  } satisfies EventDocument;

  tx.set(eventRef, event);

  return { ...event, id: eventRef.id };
}

export async function listEvents(
  startupId?: string | undefined,
  limit = 10,
  lastEventId?: string | undefined,
): Promise<{ events: EventWithId[]; lastEventId: string | null }> {
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

export async function getEventByIdRepo(
  eventId: string,
): Promise<EventDocument> {
  const snapshot = await eventsCollection.doc(eventId).get();
  if (!snapshot.exists) {
    throw new HttpsError("not-found", "Evento não encontrado");
  }

  const document = { ...snapshot.data() } as EventDocument;
  return document;
}
