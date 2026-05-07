// Autor: Allan Giovanni Matias Paes

import { Timestamp } from "firebase-admin/firestore";
import { db } from "../../shared/firebase";
import {
  UpdateWalletParams,
  UserCreateDTO,
  UserProfile,
  Wallet,
  WalletTokenPosition,
} from "../types";

const usersCollection = db.collection("users");

//
// ==========================
// USERS
// ==========================
//

export async function updateUser(
  userId: string,
  data: Partial<UserProfile>,
): Promise<void> {
  const userRef = usersCollection.doc(userId);

  const snapshot = await userRef.get();

  if (!snapshot.exists) {
    throw new Error("Usuário não encontrado.");
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

  return snapshot.data() as UserProfile;
}

//
// ==========================
// WALLET HELPERS
// ==========================
//

//
// ==========================
// POSITION CREATION
// ==========================
//

function createPosition(
  params: Omit<UpdateWalletParams, "userId">,
): WalletTokenPosition {
  const investedCents = params.qtdTokens * params.tokenPriceCents;

  return {
    startupId: params.startupId,
    startupName: params.startupName,

    qtdTokens: params.qtdTokens,
    lockedTokens: 0,

    averagePriceCents: params.tokenPriceCents,
    investedCents,

    updatedAt: Timestamp.now(),
  };
}

//
// ==========================
// POSITION UPDATE
// ==========================
//

function updatePosition(
  position: WalletTokenPosition,
  qtdTokens: number,
  tokenPriceCents: number,
): WalletTokenPosition {
  const totalTokens = position.qtdTokens + qtdTokens;

  const newInvestment = qtdTokens * tokenPriceCents;

  const investedCents = position.investedCents + newInvestment;

  const averagePriceCents = investedCents / totalTokens;

  return {
    ...position,

    qtdTokens: totalTokens,
    investedCents,

    averagePriceCents: Math.round(averagePriceCents),

    updatedAt: Timestamp.now(),
  };
}

//
// ==========================
// WALLET RECALCULATION
// ==========================
//

function recalculateWallet(wallet: Wallet): Wallet {
  const positions = wallet.positions ?? [];

  const totalInvestedCents = positions.reduce(
    (sum, p) => sum + p.investedCents,
    0,
  );

  return {
    ...wallet,

    positions,

    totalInvestedCents,

    updatedAt: Timestamp.now(),
  };
}

//
// ==========================
// WALLET ENTRYPOINT
// ==========================
//

export async function updateWallet({
  userId,
  ...params
}: UpdateWalletParams): Promise<void> {
  const user = await getUserById(userId);

  if (!user) {
    throw new Error("Usuário não encontrado.");
  }

  const positions = [...(user.wallet.positions ?? [])];

  const index = positions.findIndex((p) => p.startupId === params.startupId);

  if (index === -1) {
    positions.push(createPosition(params));
  } else {
    positions[index] = updatePosition(
      positions[index],
      params.qtdTokens,
      params.tokenPriceCents,
    );
  }

  const wallet = recalculateWallet({
    ...user.wallet,
    positions,
  });

  await updateUser(userId, { wallet });
}
