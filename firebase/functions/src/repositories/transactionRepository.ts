import { db } from "../firebase";
import { Transaction } from "../exchange/types";
import { FieldValue, Timestamp } from "firebase-admin/firestore";

const transactionCollection = (startupId: string) =>
  db.collection("startups").doc(startupId).collection("transactions");

export async function createTransaction(
  transaction: Omit<Transaction, "id" | "createdAt">,
): Promise<string> {
  const docRef = await transactionCollection(transaction.startupId).add({
    ...transaction,
    createdAt: FieldValue.serverTimestamp(),
  });

  return docRef.id;
}

export async function getTransactionsByStartupId(
  startupId: string,
  limit = 15,
): Promise<Transaction[]> {
  const snapshot = await transactionCollection(startupId)
    .orderBy("createdAt", "desc")
    .limit(limit)
    .get();

  return snapshot.docs.map((doc) => {
    const data = doc.data() as Omit<Transaction, "id">;

    return {
      id: doc.id,
      ...data,
      createdAt: data.createdAt as Timestamp,
    };
  });
}
