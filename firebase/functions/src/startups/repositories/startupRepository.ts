// Autor: Allan Giovanni Matias Paes - 25008211
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import {
  StartupDocument,
  StartupListItem,
  StartupQuestionAnswer,
} from "../types";
import { db } from "../../shared/firebase";
import { startupsData } from "../../utils/startups";
import {
  QuestionViewDTO,
  StartupDocumentDTO,
  StartupQuestionCreateDTO,
  Variation,
} from "../types/dtos";

export const startupsCollection = db.collection("startups");

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

export async function getStartupsByIds(
  startupIds: string[],
): Promise<(StartupDocumentDTO | undefined)[]> {
  if (startupIds.length === 0) return [];

  const refs = startupIds.map((id) => startupsCollection.doc(id));
  const snapshots = await db.getAll(...refs);

  return snapshots.map((snap) => {
    if (!snap.exists) return undefined;
    return snap.data() as StartupDocumentDTO;
  });
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
    .map((doc) => {
      const answers = doc.get("answers") ?? [];

      return {
        id: doc.id,
        text: doc.get("text"),

        answers: answers.map((a: StartupQuestionAnswer) => ({
          answer: a.answer,
          answeredAt: a.answeredAt?.toDate().toISOString() ?? null,
        })),

        createdAt: doc.get("createdAt")?.toDate().toISOString() ?? null,
      };
    })
    .sort((left, right) =>
      String(right.createdAt ?? "").localeCompare(String(left.createdAt ?? "")),
    );
}

export async function listStartupQuestions(
  startupId: string,
  isInvestor: boolean,
): Promise<QuestionViewDTO[]> {
  const questionsSnapshot = await startupsCollection
    .doc(startupId)
    .collection("questions")
    .limit(100)
    .get();

  const questions = questionsSnapshot.docs
    .map((doc) => {
      const answers = doc.get("answers") ?? [];

      return {
        id: doc.id,
        startupId,
        authorId: doc.get("authorId"),
        authorEmail: doc.get("authorEmail"),
        text: doc.get("text"),
        visibility: doc.get("visibility"),

        answers: answers.map((a: StartupQuestionAnswer) => ({
          answer: a.answer,
          answeredAt: a.answeredAt?.toDate().toISOString() ?? null,
        })),

        createdAt: doc.get("createdAt")?.toDate().toISOString() ?? null,
      };
    })
    .filter((question) => {
      if (question.visibility === "publica") return true;
      if (question.visibility === "privada" && isInvestor) return true;
      return false;
    })
    .sort((left, right) =>
      String(right.createdAt ?? "").localeCompare(String(left.createdAt ?? "")),
    );

  return questions;
}

export async function createQuestion(
  question: StartupQuestionCreateDTO,
): Promise<string> {
  const questionRef = await startupsCollection
    .doc(question.startupId)
    .collection("questions")
    .add({ ...question, answers: [] });

  return questionRef.id;
}

export async function seedDemoStartups(): Promise<string[]> {
  const batch = db.batch();

  const valuationPromises: Promise<void>[] = [];

  for (const startup of startupsData) {
    const { id, ...data } = startup;
    const startupRef = startupsCollection.doc(id);

    const initialValuation =
      data.currentTokenPriceCents * data.totalTokensIssued;

    batch.set(
      startupRef,
      {
        ...data,
        lastValuationCents: initialValuation,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    // Gerar 40 pontos históricos (Meses) com Random Walk
    let currentPrice = data.currentTokenPriceCents;

    // Começa de 40 meses atrás até hoje
    for (let i = 40; i >= 0; i--) {
      const date = new Date();
      date.setMonth(date.getMonth() - i);

      const variance = (Math.random() - 0.48) * 0.25;
      currentPrice = Math.round(currentPrice * (1 + variance));

      const simulatedValuation = currentPrice * data.totalTokensIssued;

      valuationPromises.push(
        saveValuationSnapshot(
          id,
          simulatedValuation,
          currentPrice,
          date,
          "seed",
        ),
      );
    }
  }

  await batch.commit();
  await Promise.all(valuationPromises);

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
  tokenPriceCents?: number,
  createdAt?: Date,
  changeType = "manual",
) {
  await startupsCollection
    .doc(startupId)
    .collection("valuations")
    .add({
      value: valuation,
      tokenPriceCents: tokenPriceCents ?? 0,
      changeType,
      createdAt: createdAt ?? FieldValue.serverTimestamp(),
    });
}

export async function getValuationHistory(
  startupId: string,
  from: Date,
  to: Date,
  limit?: number | null,
) {
  const snapshot = await startupsCollection
    .doc(startupId)
    .collection("valuations")
    .where("createdAt", ">=", from)
    .where("createdAt", "<=", to)
    .orderBy("createdAt", "asc")
    .limit(limit ?? 120)
    .get();

  return snapshot.docs.map((doc) => ({
    value: doc.get("value") as number,
    createdAt: doc.get("createdAt") as Timestamp,
  }));
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
  await saveValuationSnapshot(
    startupId,
    newValuation,
    newTokenPriceCents,
    undefined,
    "event",
  );

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
