/**
 * @file startupRepository.ts
 * @description Repositório para gerenciamento de dados de startups no Firestore.
 * @author Allan Giovanni Matias Paes - 25008211
 */

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

// Referência para a coleção principal de startups
export const startupsCollection = db.collection("startups");

/**
 * Converte um documento de startup do Firestore para o formato de item de listagem (DTO).
 * Calcula a variação de valuation e define a tendência (subida, descida, estável).
 *
 * @param id ID do documento.
 * @param startup Dados brutos do documento.
 */
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

/**
 * Recupera uma lista resumida de startups para exibição em catálogos.
 */
export async function listStartupItems(): Promise<StartupListItem[]> {
  const snapshot = await startupsCollection.limit(100).get();

  return snapshot.docs.map((doc) =>
    toListItem(doc.id, doc.data() as StartupDocument),
  );
}

/**
 * Obtém os detalhes completos de uma startup pelo ID.
 */
export async function getStartupById(
  startupId: string,
): Promise<StartupDocumentDTO | undefined> {
  const startupSnapshot = await startupsCollection.doc(startupId).get();

  if (!startupSnapshot.exists) {
    return undefined;
  }

  return startupSnapshot.data() as StartupDocumentDTO;
}

/**
 * Obtém múltiplas startups de uma vez através de seus IDs (Batch Read).
 */
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

/**
 * Verifica se um usuário específico é investidor de uma determinada startup.
 */
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

/**
 * Lista as perguntas públicas de uma startup.
 */
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

/**
 * Lista perguntas direcionadas a uma startup, filtrando privadas caso o usuário não seja investidor.
 */
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
      // Regra: Público é visível a todos. Privado apenas se isInvestor for true.
      if (question.visibility === "publica") return true;
      if (question.visibility === "privada" && isInvestor) return true;
      return false;
    })
    .sort((left, right) =>
      String(right.createdAt ?? "").localeCompare(String(left.createdAt ?? "")),
    );

  return questions;
}

/**
 * Cria uma nova pergunta para uma startup.
 */
export async function createQuestion(
  question: StartupQuestionCreateDTO,
): Promise<string> {
  const questionRef = await startupsCollection
    .doc(question.startupId)
    .collection("questions")
    .add({ ...question, answers: [] });

  return questionRef.id;
}

/**
 * Popula o banco de dados com startups de demonstração e gera histórico de valuation simulado.
 */
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

    // Gerar 40 pontos históricos (Meses) com Random Walk para simular realidade de mercado
    let currentPrice = data.currentTokenPriceCents;

    for (let i = 40; i >= 0; i--) {
      const date = new Date();
      date.setMonth(date.getMonth() - i);

      // Variância aleatória de até 12% para criar um gráfico dinâmico
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

/**
 * Calcula o valuation atual de uma startup com base no preço do token e total emitido.
 */
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

/**
 * Obtém o valor de valuation imediatamente anterior ao atual (usado para calcular variações).
 */
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

/**
 * Salva um snapshot de valuation na sub-coleção histórica da startup.
 */
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

/**
 * Recupera o histórico de valuation em um intervalo de tempo específico.
 */
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

/**
 * Atualiza o preço do token de uma startup e registra o novo valuation no histórico.
 */
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

  // Registra no histórico antes de atualizar o documento principal
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
