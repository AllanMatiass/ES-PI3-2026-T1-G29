import { db } from "../../firebase";
import { Offer, OfferWithId } from "../types";

const offerCollection = db.collection("offers");

export async function addOffer(data: Offer) {
  return await offerCollection.add(data);
}

export async function getOfferById(id: string): Promise<OfferWithId | null> {
  const doc = await offerCollection.doc(id).get();
  if (!doc.exists) return null;
  return { id: doc.id, ...(doc.data() as Offer) };
}

export async function updateOffer(id: string, data: Partial<Offer>) {
  await offerCollection.doc(id).update(data);
}

export async function listOffers(
  startupId?: string,
  limit = 20,
  lastOfferId?: string,
): Promise<{ offers: OfferWithId[]; lastOfferId: string | null }> {
  let query = offerCollection
    .where("status", "==", "OPEN")
    .orderBy("createdAt", "desc");

  if (startupId) {
    query = query.where("startupId", "==", startupId);
  }

  if (lastOfferId) {
    const lastOfferDoc = await offerCollection.doc(lastOfferId).get();
    if (lastOfferDoc.exists) {
      query = query.startAfter(lastOfferDoc);
    }
  }

  const snapshot = await query.limit(limit).get();
  const offers = snapshot.docs.map((doc) => ({
    id: doc.id,
    ...(doc.data() as Offer),
  }));

  const lastId =
    offers.length > 0 && offers.length === limit
      ? offers[offers.length - 1].id
      : null;

  return { offers, lastOfferId: lastId };
}
