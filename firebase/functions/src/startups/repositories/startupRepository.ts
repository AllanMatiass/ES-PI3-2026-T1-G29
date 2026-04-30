// Autor: Allan Giovanni Matias Paes
import { FieldValue } from "firebase-admin/firestore";
import { StartupDocument, StartupListItem } from "../types";
import { db } from "../../shared/firebase";
import { startupsData } from "../../utils/startups";
import {
  StartupDocumentDTO,
  StartupQuestionCreateInput,
  Variation,
} from "../types/dtos";

const startupsCollection = db.collection("startups");

function toListItem(id: string, startup: StartupDocument): StartupListItem {
  const currentValuation =
    startup.currentTokenPriceCents * startup.totalTokensIssued;

  const baseline = startup.lastValuationCents ?? 0;

  let variation: Variation = {
    percentage: 0,
    trend: "stable",
  };

  if (baseline && baseline > 0) {
    const change = ((currentValuation - baseline) / baseline) * 100;

    variation = {
      percentage: Number(change.toFixed(2)),
      trend: change > 0 ? "up" : change < 0 ? "down" : "stable",
    };
  }

  return {
    id,
    name: startup.name,
    stage: startup.stage,
    shortDescription: startup.shortDescription,
    capitalRaisedCents: startup.capitalRaisedCents,
    totalTokensIssued: startup.totalTokensIssued,
    currentTokenPriceCents: startup.currentTokenPriceCents,
    coverImageUrl: startup.coverImageUrl,
    tags: startup.tags,
    variation,
  };
}

export async function listStartupItems(): Promise<StartupListItem[]> {
  const snapshot = await startupsCollection.limit(100).get();

  return snapshot.docs.map((doc) =>
    toListItem(doc.id, doc.data() as StartupDocument),
  );
}

export async function getStartupById(
  startupId: string,
): Promise<StartupDocumentDTO | undefined> {
  const startupSnapshot = await startupsCollection.doc(startupId).get();

  if (!startupSnapshot.exists) {
    return undefined;
  }

  return startupSnapshot.data() as StartupDocumentDTO;
}

export async function userIsInvestor(
  startupId: string,
  uid: string,
): Promise<boolean> {
  const investorSnapshot = await startupsCollection
    .doc(startupId)
    .collection("investors")
    .doc(uid)
    .get();

  return investorSnapshot.exists;
}

export async function listPublicQuestions(startupId: string) {
  const questionsSnapshot = await startupsCollection
    .doc(startupId)
    .collection("questions")
    .where("visibility", "==", "publica")
    .limit(50)
    .get();

  return questionsSnapshot.docs
    .map((doc) => ({
      id: doc.id,
      text: doc.get("text"),
      answer: doc.get("answer") ?? null,
      answeredAt: doc.get("answeredAt")?.toDate().toISOString() ?? null,
      createdAt: doc.get("createdAt")?.toDate().toISOString() ?? null,
    }))
    .sort((left, right) =>
      String(right.createdAt ?? "").localeCompare(String(left.createdAt ?? "")),
    );
}

export async function createQuestion(
  question: StartupQuestionCreateInput,
): Promise<string> {
  const questionRef = await startupsCollection
    .doc(question.startupId)
    .collection("questions")
    .add(question);

  return questionRef.id;
}

export async function seedDemoStartups(): Promise<string[]> {
  const batch = db.batch();

  for (const startup of startupsData) {
    const { id, ...data } = startup;
    const startupRef = startupsCollection.doc(id);

    batch.set(
      startupRef,
      {
        ...data,
        lastValuationCents:
          data.currentTokenPriceCents * data.totalTokensIssued,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  }

  await batch.commit();

  return startupsData.map((startup) => startup.id);
}

export async function getStartupValuationById(
  startupId: string,
): Promise<number | undefined> {
  const startupSnapshot = await startupsCollection.doc(startupId).get();
  if (!startupSnapshot.exists) {
    return undefined;
  }

  const startup = startupSnapshot.data() as StartupDocument;
  return startup.currentTokenPriceCents * startup.totalTokensIssued;
}

export async function getPreviousStartupValuation(
  startupId: string,
): Promise<number | undefined> {
  const snapshot = await startupsCollection
    .doc(startupId)
    .collection("valuations")
    .orderBy("createdAt", "desc")
    .limit(2)
    .get();

  if (snapshot.docs.length < 2) {
    return undefined;
  }

  const previous = snapshot.docs[1].data();

  return previous.value;
}

export async function saveValuationSnapshot(
  startupId: string,
  valuation: number,
) {
  await startupsCollection.doc(startupId).collection("valuations").add({
    value: valuation,
    createdAt: FieldValue.serverTimestamp(),
  });
}

export async function updateStartupValuation(
  startupId: string,
  newTokenPriceCents: number,
) {
  const ref = startupsCollection.doc(startupId);

  const snapshot = await ref.get();
  if (!snapshot.exists) return;

  const startup = snapshot.data() as StartupDocument;

  const currentValuation =
    startup.currentTokenPriceCents * startup.totalTokensIssued;

  const newValuation = newTokenPriceCents * startup.totalTokensIssued;

  await ref.update({
    currentTokenPriceCents: newTokenPriceCents,
    lastValuationCents: currentValuation,
    updatedAt: FieldValue.serverTimestamp(),
  });

  return {
    previous: currentValuation,
    current: newValuation,
  };
}
