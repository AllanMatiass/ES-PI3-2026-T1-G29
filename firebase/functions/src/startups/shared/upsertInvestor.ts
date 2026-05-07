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
) {
  const now = Timestamp.now();

  const ref = investorsRef(params.startupId).doc(params.userId);

  const snap = await tx.get(ref);

  const investedCents = params.qtdTokens * params.tokenPriceCents;

  // =========================
  // FIRST INVESTMENT
  // =========================
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
  // UPDATE INVESTOR
  // =========================
  const data = snap.data() as StartupInvestor;

  const totalTokens = data.totalTokens + params.qtdTokens;

  const totalInvestedCents = data.totalInvestedCents + investedCents;

  const averagePriceCents = totalInvestedCents / totalTokens;

  tx.update(ref, {
    totalTokens,
    totalInvestedCents,
    averagePriceCents,
    lastInvestmentAt: now,
    updatedAt: now,
  });
}
