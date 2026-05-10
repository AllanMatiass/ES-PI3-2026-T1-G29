// Autor: Allan Giovanni Matias Paes
import { FieldValue, Timestamp } from "firebase-admin/firestore";

import { db } from "../../firebase";

import { Transaction, TransactionWithId } from "../types";

const transactionCollection = db.collection("transactions");

export async function createTransaction(
  transaction: Omit<Transaction, "createdAt">,
): Promise<string> {
  const docRef = await transactionCollection.add({
    ...transaction,

    participants: [transaction.buyer.id, transaction.seller.id],

    createdAt: FieldValue.serverTimestamp(),
  });

  return docRef.id;
}

export async function getTransactionsByStartupId(
  startupId: string,
  limit = 15,
): Promise<TransactionWithId[]> {
  const snapshot = await transactionCollection
    .where("startupId", "==", startupId)
    .orderBy("createdAt", "desc")
    .limit(limit)
    .get();

  return snapshot.docs.map((doc) => {
    const data = doc.data() as Omit<Transaction, "createdAt"> & {
      createdAt: Timestamp;
    };

    return {
      id: doc.id,
      ...data,
    };
  });
}

export async function getTransactionsByUserId(
  userId: string,
): Promise<TransactionWithId[]> {
  const snapshot = await transactionCollection
    .where("participants", "array-contains", userId)
    .orderBy("createdAt", "asc")
    .get();

  return snapshot.docs.map((doc) => {
    const data = doc.data() as Omit<Transaction, "createdAt"> & {
      createdAt: Timestamp;
    };

    return {
      id: doc.id,
      ...data,
    };
  });
}
