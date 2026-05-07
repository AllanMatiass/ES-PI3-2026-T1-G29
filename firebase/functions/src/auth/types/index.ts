// Autor: Allan Giovanni Matias Paes
import { FieldValue, Timestamp } from "firebase-admin/firestore";

export type WalletTokenPosition = {
  startupId: string;
  startupName: string;

  qtdTokens: number;
  averagePriceCents: number;
  investedCents: number;

  lockedTokens: number;

  updatedAt: Timestamp;
};

export type Wallet = {
  balanceInCents: number;

  totalInvestedCents: number;

  positions: WalletTokenPosition[];

  updatedAt: Timestamp;
};

export type UpdateWalletParams = {
  userId: string;

  startupId: string;
  startupName: string;

  qtdTokens: number;

  tokenPriceCents: number;
  currentTokenPriceCents: number;
};

export type UserProfile = {
  name: string;
  email: string;
  phone: string;
  cpf: string;
  wallet: Wallet;
  createdAt: Timestamp;
};

export type UserCreateDTO = UserProfile & {
  uid: string;
  createdAt: FieldValue;
};

export type UserEntity = UserProfile & {
  createdAt: Timestamp;
};

export type SignupData = {
  name: string;
  email: string;
  cpf: string;
  phone: string;
  password?: string; // OPCIONAL se for login social, mas obrigatorio para email/pass
};

export type SignupResponse = {
  uid: string;
  name: string;
  email: string;
};
