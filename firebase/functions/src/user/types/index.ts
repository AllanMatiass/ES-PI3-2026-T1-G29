import { Timestamp } from "firebase-admin/firestore";
import { WalletDTO, WalletTokenPositionDTO } from "./dtos";

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

export type UserProfile = {
  name: string;
  email: string;
  phone: string;
  cpf: string;

  wallet: WalletDTO;

  createdAt: Timestamp;
};

export type UpdateWalletParams = {
  userId: string;

  startupId: string;
  startupName: string;

  qtdTokens: number;

  tokenPriceCents: number;
  currentTokenPriceCents: number;
};

export type UserEntity = UserProfile & {
  createdAt: Timestamp;
};
