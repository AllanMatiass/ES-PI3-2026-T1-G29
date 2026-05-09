import { FieldValue, Timestamp } from "firebase-admin/firestore";

//
// =========================
// PERSISTIDO NO FIRESTORE
// =========================
//

export type WalletTokenPosition = {
  startupId: string;
  startupName: string;

  qtdTokens: number;
  lockedTokens: number;

  averagePriceCents: number;
  investedCents: number;

  updatedAt: Timestamp;
};

export type Wallet = {
  balanceInCents: number;

  totalInvestedCents: number;

  positions: WalletTokenPositionDTO[];

  updatedAt: Timestamp;
};

//
// =========================
// DTO ENRIQUECIDO (RESPONSE)
// =========================
//

export type WalletTokenPositionDTO = WalletTokenPosition & {
  currentTokenPriceCents: number;

  currentValueCents: number;

  profitCents: number;

  profitPercentage: number;
};

export type WalletDTO = Omit<Wallet, "positions"> & {
  positions: WalletTokenPositionDTO[];
};

//
// =========================
// USER
// =========================
//

export type UserProfile = {
  name: string;
  email: string;
  phone: string;
  cpf: string;

  wallet: Wallet;

  createdAt: Timestamp;
};

export type UserProfileDTO = Omit<UserProfile, "wallet"> & {
  wallet: WalletDTO;
};

export type UpdateWalletParams = {
  userId: string;

  startupId: string;
  startupName: string;

  qtdTokens: number;

  tokenPriceCents: number;
  currentTokenPriceCents: number;
};

export type UserCreateDTO = UserProfile & {
  uid: string;
  createdAt: FieldValue;
};

export type UserEntity = UserProfile & {
  createdAt: Timestamp;
};
