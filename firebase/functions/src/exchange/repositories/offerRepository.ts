import { HttpsError } from "firebase-functions/v2/https";
import { WalletTokenPosition } from "../../auth/types";
import { db } from "../../firebase";
import { Offer, OfferWithId } from "../types";

const offerCollection = db.collection("offers");

export async function addOffer(data: Offer) {
  return await offerCollection.add(data);
}

export async function createOfferInTransaction(
  sellerId: string,
  offerData: Offer,
): Promise<string> {
  const offerRef = offerCollection.doc();

  await db.runTransaction(async (tx) => {
    const sellerRef = db.collection("users").doc(sellerId);
    const sellerSnap = await tx.get(sellerRef);

    if (!sellerSnap.exists) {
      throw new HttpsError("not-found", "Vendedor não encontrado.");
    }

    const sellerData = sellerSnap.data();
    const wallet = sellerData?.wallet;

    if (!wallet) {
      throw new HttpsError(
        "failed-precondition",
        "Carteira do vendedor não encontrada.",
      );
    }

    const position = wallet.positions?.find(
      (p: WalletTokenPosition) => p.startupId === offerData.startupId,
    );

    if (!position) {
      throw new HttpsError(
        "failed-precondition",
        "O vendedor não possui tokens desta startup.",
      );
    }

    const availableTokens = position.qtdTokens - position.lockedTokens;

    if (availableTokens < offerData.qtdTokens) {
      throw new HttpsError(
        "failed-precondition",
        "Quantidade de tokens insuficiente para criar a oferta.",
      );
    }

    position.lockedTokens += offerData.qtdTokens;

    tx.update(sellerRef, {
      wallet,
    });

    tx.set(offerRef, offerData);
  });

  return offerRef.id;
}

export async function getOfferById(id: string): Promise<OfferWithId | null> {
  const doc = await offerCollection.doc(id).get();
  if (!doc.exists) return null;
  return { id: doc.id, ...(doc.data() as Offer) };
}

export async function updateOffer(id: string, data: Partial<Offer>) {
  await offerCollection.doc(id).update(data);
}

export async function getOffersBySellerId(
  sellerId: string,
): Promise<OfferWithId[]> {
  const snapshot = await offerCollection
    .where("seller.id", "==", sellerId)
    .orderBy("createdAt", "desc")
    .get();

  return snapshot.docs.map((doc) => ({
    id: doc.id,
    ...(doc.data() as Offer),
  }));
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
