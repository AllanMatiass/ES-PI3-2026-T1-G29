// Autor: Allan Giovanni Matias Paes - 25008211
import { db } from "../../shared/firebase";
import { Timestamp } from "firebase-admin/firestore";
import { StartupInvestor } from "../types";

const investorsRef = (startupId: string) =>
  db.collection("startups").doc(startupId).collection("investors");

export async function upsertStartupInvestor(
  tx: FirebaseFirestore.Transaction,
  params: {
    startupId: string;
    startupName: string;
    userId: string;
    userName: string;
    qtdTokens: number;
    tokenPriceCents: number;
  },
  investorSnapshot?: FirebaseFirestore.DocumentSnapshot,
) {
  const now = Timestamp.now();

  const ref = investorsRef(params.startupId).doc(params.userId);

  const snap = investorSnapshot || (await tx.get(ref));

  const investedCents = params.qtdTokens * params.tokenPriceCents;

  // =========================
  // PRIMEIRO INVESTIMENTO
  // =========================
  // seta nos investidores daquela startup
  if (!snap.exists) {
    tx.set(ref, {
      userId: params.userId,
      userName: params.userName,

      startupId: params.startupId,
      startupName: params.startupName,

      totalTokens: params.qtdTokens,
      totalInvestedCents: investedCents,
      averagePriceCents: params.tokenPriceCents,

      firstInvestmentAt: now,
      lastInvestmentAt: now,
      updatedAt: now,
    } satisfies StartupInvestor);

    return;
  }

  // =========================
  // Caso ele já exista, atualiza as informações dele como investidor
  // =========================
  const data = snap.data() as StartupInvestor;

  // calcula o novo total investido, preço médio e o total de tokens
  const currentTokens = Number(data.totalTokens) || 0;
  const currentInvested = Number(data.totalInvestedCents) || 0;

  const totalTokens = currentTokens + params.qtdTokens;

  const totalInvestedCents = currentInvested + investedCents;

  const averagePriceCents =
    totalTokens > 0 ? totalInvestedCents / totalTokens : 0;

  tx.update(ref, {
    totalTokens,
    totalInvestedCents,
    averagePriceCents: Math.round(averagePriceCents),
    lastInvestmentAt: now,
    updatedAt: now,
  });
}
