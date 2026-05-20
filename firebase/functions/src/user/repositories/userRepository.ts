// Autor: Allan Giovanni Matias Paes

import { Timestamp } from "firebase-admin/firestore";
import { db } from "../../shared/firebase";
import { UpdateWalletParams, UserProfile, Wallet } from "../types";
import { UserCreateDTO, WalletTokenPositionDTO } from "../types/dtos";
import { HttpsError } from "firebase-functions/https";

const usersCollection = db.collection("users");

//
// ==========================
// USER
// ==========================
//

export async function updateUser(
  userId: string,
  data: Partial<UserProfile>,
): Promise<void> {
  const userRef = usersCollection.doc(userId);

  const snapshot = await userRef.get();

  if (!snapshot.exists) {
    throw new HttpsError("not-found", "Usuário não encontrado.");
  }

  await userRef.update(data);
}

export async function createUserProfile(profile: UserCreateDTO): Promise<void> {
  await usersCollection.doc(profile.uid).set(profile);
}

export async function getUserByEmail(
  email: string,
): Promise<UserProfile | undefined> {
  const snapshot = await usersCollection.where("email", "==", email).get();

  if (snapshot.empty) return undefined;

  return snapshot.docs[0].data() as UserProfile;
}

export async function getUserByCpf(
  cpf: string,
): Promise<UserProfile | undefined> {
  const snapshot = await usersCollection.where("cpf", "==", cpf).get();

  if (snapshot.empty) return undefined;

  return snapshot.docs[0].data() as UserProfile;
}

export async function getUserByPhone(
  phone: string,
): Promise<UserProfile | undefined> {
  const snapshot = await usersCollection.where("phone", "==", phone).get();

  if (snapshot.empty) return undefined;

  return snapshot.docs[0].data() as UserProfile;
}

export async function getUserById(
  id: string,
): Promise<UserProfile | undefined> {
  const snapshot = await usersCollection.doc(id).get();

  if (!snapshot.exists) return undefined;

  const data = snapshot.data() as UserProfile;

  if (data.wallet) {
    data.wallet = healWallet(data.wallet);
  }

  return data;
}

function healWallet(wallet: Wallet): Wallet {
  const positions = (wallet.positions ?? []).map(
    (p: WalletTokenPositionDTO) => ({
      startupId: p.startupId || "",
      startupName: p.startupName || "Startup",
      qtdTokens: Number(p.qtdTokens) || 0,
      lockedTokens: Number(p.lockedTokens) || 0,
      averagePriceCents: Number(p.averagePriceCents) || 0,
      investedCents: Number(p.investedCents) || 0,
      currentTokenPriceCents: Number(p.currentTokenPriceCents) || 0,
      currentValueCents: Number(p.currentValueCents) || 0,
      updatedAt: p.updatedAt || Timestamp.now(),
    }),
  );

  const totalInvestedCents = positions.reduce(
    (sum: number, p: WalletTokenPositionDTO) =>
      sum + (Number(p.investedCents) || 0),
    0,
  );

  return {
    ...wallet,
    balanceInCents: Number(wallet.balanceInCents) || 0,
    totalInvestedCents: Number(totalInvestedCents) || 0,
    positions,
    updatedAt: wallet.updatedAt || Timestamp.now(),
  };
}

function createPosition(
  params: Omit<UpdateWalletParams, "userId">,
): WalletTokenPositionDTO {
  const qtdTokens = Number(params.qtdTokens) || 0;
  const tokenPriceCents = Number(params.tokenPriceCents) || 0;
  const currentTokenPriceCents = Number(params.currentTokenPriceCents) || 0;

  const investedCents = qtdTokens * tokenPriceCents;
  const currentValueCents = qtdTokens * currentTokenPriceCents;

  return {
    startupId: params.startupId,
    startupName: params.startupName,

    qtdTokens,
    lockedTokens: 0,

    averagePriceCents: tokenPriceCents,
    investedCents,

    currentTokenPriceCents,
    currentValueCents,

    updatedAt: Timestamp.now(),
  };
}

function updatePosition(
  position: WalletTokenPositionDTO,
  qtdTokensDelta: number,
  tokenPriceCents: number,
  currentTokenPriceCents: number,
): WalletTokenPositionDTO {
  const currentQtd = Number(position.qtdTokens) || 0;
  const currentInvested = Number(position.investedCents) || 0;

  const totalTokens = currentQtd + qtdTokensDelta;

  let investedCents = currentInvested;
  if (qtdTokensDelta > 0) {
    investedCents += qtdTokensDelta * tokenPriceCents;
  } else if (qtdTokensDelta < 0) {
    // Proporcional ao que foi investido (preço médio)
    const avgPrice = currentQtd > 0 ? currentInvested / currentQtd : 0;
    investedCents += qtdTokensDelta * avgPrice;
  }

  // Garante que não fique negativo por arredondamento
  investedCents = Math.max(0, investedCents);

  const averagePriceCents = totalTokens > 0 ? investedCents / totalTokens : 0;

  const currentValueCents = totalTokens * currentTokenPriceCents;

  return {
    ...position,

    qtdTokens: totalTokens,
    investedCents: Math.round(investedCents),

    averagePriceCents: Math.round(averagePriceCents),
    currentTokenPriceCents,
    currentValueCents: Math.round(currentValueCents),
    updatedAt: Timestamp.now(),
  };
}

function recalculateWallet(wallet: Wallet): Wallet {
  const positions = wallet.positions ?? [];

  const totalInvestedCents = positions.reduce(
    (sum, p) => sum + (Number(p.investedCents) || 0),
    0,
  );

  return {
    ...wallet,

    positions,

    totalInvestedCents: Math.round(totalInvestedCents),

    updatedAt: Timestamp.now(),
  };
}

export async function updateWallet({
  userId,
  ...params
}: UpdateWalletParams): Promise<void> {
  const user = await getUserById(userId);

  if (!user) {
    throw new HttpsError("not-found", "Usuário não encontrado.");
  }

  const positions: WalletTokenPositionDTO[] = [
    ...(user.wallet.positions ?? []),
  ];

  const index = positions.findIndex((p) => p.startupId === params.startupId);

  if (index === -1) {
    positions.push(createPosition(params));
  } else {
    positions[index] = updatePosition(
      positions[index],
      params.qtdTokens,
      params.tokenPriceCents,
      params.currentTokenPriceCents,
    );
  }

  const wallet = recalculateWallet({
    ...user.wallet,
    positions,
  });

  await updateUser(userId, { wallet });
}
