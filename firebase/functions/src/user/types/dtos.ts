import { FieldValue } from "firebase-admin/firestore";
import { UserProfile, Wallet, WalletTokenPosition } from ".";

export type UserCreateDTO = UserProfile & {
  uid: string;
  createdAt: FieldValue;
};

export type UserProfileDTO = Omit<UserProfile, "wallet"> & {
  wallet: WalletDTO;
};

export type WalletTokenPositionDTO = WalletTokenPosition & {
  currentTokenPriceCents: number;

  currentValueCents: number;
};

export type WalletDTO = Omit<Wallet, "positions"> & {
  positions: WalletTokenPositionDTO[];
};

export type DepositRequestDTO = {
  amountInCents: number;
};
