/**
 * @file userRepository.ts
 * @description Repositório para gerenciamento de perfis de usuário, carteiras (wallets) e movimentações financeiras no Firestore.
 * @author Allan Giovanni Matias Paes - 25008211
 * @author Murilo Rigoni - 25006049
 * @author Pedro Vinícius Romanato - 25004075
 */

import { Timestamp } from "firebase-admin/firestore";
import { db } from "../../shared/firebase";
import { UserProfile, Wallet, MovementWithId } from "../types";
import {
  UserCreateDTO,
  WalletTokenPositionDTO,
  PaginatedMovementsResponseDTO,
} from "../types/dtos";
import { HttpsError } from "firebase-functions/https";
import { listPaginated } from "../../shared/paginatedQueryBuilder";

// Referência para a coleção principal de usuários
const usersCollection = db.collection("users");

/**
 * Atualiza dados parciais do perfil de um usuário.
 * @param userId UID do usuário.
 * @param data Campos a serem atualizados.
 */
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

/**
 * Cria um novo perfil de usuário no Firestore.
 */
export async function createUserProfile(profile: UserCreateDTO): Promise<void> {
  await usersCollection.doc(profile.uid).set(profile);
}

/**
 * Busca um usuário pelo email.
 */
export async function getUserByEmail(
  email: string,
): Promise<UserProfile | undefined> {
  const snapshot = await usersCollection.where("email", "==", email).get();
  if (snapshot.empty) return undefined;
  return snapshot.docs[0].data() as UserProfile;
}

/**
 * Busca um usuário pelo CPF.
 */
export async function getUserByCpf(
  cpf: string,
): Promise<UserProfile | undefined> {
  const snapshot = await usersCollection.where("cpf", "==", cpf).get();
  if (snapshot.empty) return undefined;
  return snapshot.docs[0].data() as UserProfile;
}

/**
 * Busca um usuário pelo telefone (formato apenas números).
 */
export async function getUserByPhone(
  phone: string,
): Promise<UserProfile | undefined> {
  const snapshot = await usersCollection.where("phone", "==", phone).get();
  if (snapshot.empty) return undefined;
  return snapshot.docs[0].data() as UserProfile;
}

/**
 * Obtém o perfil completo do usuário pelo ID e aplica a "cura" na carteira.
 */
export async function getUserById(
  id: string,
): Promise<UserProfile | undefined> {
  const snapshot = await usersCollection.doc(id).get();

  if (!snapshot.exists) return undefined;

  const data = snapshot.data() as UserProfile;

  // Garante que a carteira possua todos os campos e cálculos consistentes ao carregar
  if (data.wallet) {
    data.wallet = healWallet(data.wallet);
  }

  return data;
}

/**
 * Lógica de "Cura" (Heal): Garante a integridade dos dados da carteira,
 * convertendo tipos, tratando nulos e recalculando o total investido com base nas posições.
 */
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

/**
 * Processa um depósito na conta do usuário e registra na sub-coleção de movimentações.
 */
export async function processDeposit(
  userId: string,
  amountInCents: number,
): Promise<number> {
  const user = await getUserById(userId);
  if (!user) {
    throw new HttpsError("not-found", "Usuário não encontrado.");
  }

  const currentWallet = user.wallet;
  const newBalanceInCents =
    (Number(currentWallet?.balanceInCents) || 0) + amountInCents;

  const wallet = {
    ...currentWallet,
    balanceInCents: newBalanceInCents,
    updatedAt: Timestamp.now(),
  };

  // Registro da movimentação para extrato
  await usersCollection.doc(userId).collection("movements").add({
    type: "DEPOSIT",
    amountInCents: amountInCents,
    createdAt: Timestamp.now(),
  });

  await updateUser(userId, { wallet });
  return newBalanceInCents;
}

/**
 * Processa um saque da conta do usuário, validando se há saldo suficiente.
 */
export async function processWithdraw(
  userId: string,
  amountInCents: number,
): Promise<number> {
  const user = await getUserById(userId);
  if (!user) {
    throw new HttpsError("not-found", "Usuário não encontrado.");
  }

  const currentWallet = user.wallet;
  const currentBalance = Number(currentWallet?.balanceInCents) || 0;

  // Validação Crítica: Impede saque descoberto
  if (currentBalance < amountInCents) {
    throw new HttpsError(
      "failed-precondition",
      "Saldo insuficiente para realizar o saque.",
    );
  }

  const newBalanceInCents = currentBalance - amountInCents;

  const wallet = {
    ...currentWallet,
    balanceInCents: newBalanceInCents,
    updatedAt: Timestamp.now(),
  };

  // Registro da movimentação
  await usersCollection.doc(userId).collection("movements").add({
    type: "WITHDRAW",
    amountInCents: amountInCents,
    createdAt: Timestamp.now(),
  });

  await updateUser(userId, { wallet });
  return newBalanceInCents;
}

/**
 * Obtém todas as movimentações de um usuário de forma sequencial (não paginada).
 */
export async function getMovementsByUserId(userId: string): Promise<
  {
    type: "DEPOSIT" | "WITHDRAW";
    amountInCents: number;
    createdAt: Timestamp;
  }[]
> {
  const snapshot = await usersCollection
    .doc(userId)
    .collection("movements")
    .orderBy("createdAt", "asc")
    .get();

  return snapshot.docs.map(
    (doc) =>
      doc.data() as {
        type: "DEPOSIT" | "WITHDRAW";
        amountInCents: number;
        createdAt: Timestamp;
      },
  );
}

/**
 * Lista movimentações com paginação, ideal para telas de extrato com scroll infinito.
 */
export async function listMovementsByUserId(
  userId: string,
  limit = 10,
  lastMovementId?: string,
): Promise<PaginatedMovementsResponseDTO> {
  const collection = usersCollection.doc(userId).collection("movements");

  const { docs, lastDocId } = await listPaginated<MovementWithId>(
    collection,
    undefined,
    limit,
    lastMovementId,
  );

  const movements = docs.map((doc) => ({
    id: doc.id,
    type: doc.type,
    amountInCents: doc.amountInCents,
    createdAt: doc.createdAt.toDate().toISOString(),
  }));

  return {
    movements,
    lastMovementId: lastDocId,
  };
}
