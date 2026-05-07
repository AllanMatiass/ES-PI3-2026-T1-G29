import { db } from "../../firebase";
import { Offer, OfferWithId } from "../types";

const offerCollection = db.collection("offer");

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
