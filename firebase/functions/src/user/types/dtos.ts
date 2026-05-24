import { FieldValue } from "firebase-admin/firestore";
import { UserProfile, Wallet, WalletTokenPosition, Movement } from ".";

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
  amount: number;
};

export type DepositResponseDTO = {
  userId: string;
  newBalance: number;
};

export type WithdrawRequestDTO = {
  amount: number;
};

export type WithdrawResponseDTO = {
  userId: string;
  newBalance: number;
};

export type GetUserInvestmentsRequestDTO = {
  limit?: number;
  lastStartupId?: string;
};

export type PaginatedInvestmentsResponseDTO = {
  investments: WalletTokenPositionDTO[];
  lastStartupId: string | null;
};

export type PortfolioRange = "1D" | "1W" | "1M" | "1Y" | "YTD";

export type GetUserTokenValuationsRequest = {
  range: PortfolioRange;
};

export type PortfolioHistoryPoint = {
  timestamp: string;
  valueCents: number;
};

export type GetUserTokenValuationsResponse = {
  range: PortfolioRange;
  currency: string;
  totalValueCents: number;
  variationCents: number;
  variationPercent: number;
  history: PortfolioHistoryPoint[];
};

export type GetUserMovementsRequestDTO = {
  limit?: number;
  lastMovementId?: string;
};

export type PaginatedMovementsResponseDTO = {
  movements: (Omit<Movement, "createdAt"> & { createdAt: string })[];
  lastMovementId: string | null;
};
