import { FieldValue } from "firebase-admin/firestore";
import {
  StartupDocument,
  StartupListItem,
  StartupQuestionDocument,
} from "../types";
import { db } from "../../shared/firebase";
import { startupsData } from "../../utils/startups";

const startupsCollection = db.collection("startups");

function toListItem(id: string, startup: StartupDocument): StartupListItem {
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
): Promise<StartupDocument | undefined> {
  const startupSnapshot = await startupsCollection.doc(startupId).get();

  if (!startupSnapshot.exists) {
    return undefined;
  }

  return startupSnapshot.data() as StartupDocument;
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

export async function listStartupQuestions(
  startupId: string,
  isInvestor: boolean,
): Promise<
  Array{
    id: String,
    authorId: String,
    authorEmail: String,
    text: String,
    visibility: String,
    answer?: String,
    answeredAt?: String,
    createdAt: String,
  }
> {
  const questionsSnapshot = await startupsCollection
    .doc(startupId)
    .collection("questions")
    .limit(100)
    .get();

const questions = questionsSnapshot.docs
    .map(doc)=> ({
      id: doc.id,
      authorId: doc.get("authorId"),
      authorEmail: doc.get("authorEmail"),
      text: doc.get("text"),
      visibility: doc.get("visibility"),
      answer: doc.get("answer") ?? null,
      answeredAt: doc.get("answeredAt")?.toDate().toISOString() ?? null,
      createdAt: doc.get("createdAt")?.toDate().toISOString() ?? null,
    }))
    .filter((question) => {
      if (question.visibility === "publica") {
        return true;
      }
      if (question.visibility === "privada" && isInvestor) {
        return true;
      }
      return false;
    });
    .sort((left, right) =>
      String(right.createdAt ?? "").localeCompare(String(left.createdAt ?? "")),
    );

    return questions;
}

export async function createQuestion(
  startupId: string,
  question: StartupQuestionDocument,
): Promise<string> {
  const questionRef = await startupsCollection
    .doc(startupId)
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
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  }

  await batch.commit();

  return startupsData.map((startup) => startup.id);
}
