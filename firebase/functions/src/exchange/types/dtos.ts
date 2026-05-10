// Autor: Allan Giovanni Matias Paes
import { OfferWithId, TransactionParticipant } from ".";

export const DASHBOARD_PERIODS = [
  "daily",
  "weekly",
  "monthly",
  "6months",
  "ytd",
] as const;

export type DashboardPeriod = (typeof DASHBOARD_PERIODS)[number];

export type IdDTO = {
  id: string;
};

export type RegisterTransactionRequestDTO = {
  startupId: string;
  buyer: TransactionParticipant;
  seller?: TransactionParticipant | null;
  qtdTokens: number;
  tokenPriceCents: number;
};

export type TransactionIdDTO = IdDTO;

export type AcceptOfferResponseDTO = {
  transactionId: string;
  remainingTokens: number;
};

export type OfferIdDTO = IdDTO;

export type GetStartupTransactionsRequestDTO = {
  startupId: string;
  limit?: number;
};

export type CreateOfferRequestDTO = {
  startupId: string;
  qtdTokens: number;
  tokenPriceCents: number;
  expiresAt?: string | null;
};

export type AcceptOfferRequestDTO = {
  offerId: string;
  qtdTokens: number;
};

export type GetOffersRequestDTO = {
  startupId?: string;
  limit?: number;
  lastOfferId?: string;
};

export type GetInvestorDashboardRequestDTO = {
  period?: DashboardPeriod;
};

export type DashboardDataPoint = {
  timestamp: string;
  totalValueCents: number;
};

export type GetInvestorDashboardResponseDTO = {
  points: DashboardDataPoint[];
  currentTotalValueCents: number;
  variationCents: number;
  variationPercent: number;
};

export type PaginatedOffersResponseDTO = {
  offers: OfferWithId[];
  lastOfferId: string | null;
};

export type OfferResponseDTO = OfferWithId;

export type MyOfferDTO = {
  id: string;
  startupId: string;
  startupName: string;
  status: string;
  initialQtdTokens: number;
  remainingQtdTokens: number;
  soldQtdTokens: number;
  tokenPriceCents: number;
  totalEarnedCents: number;
  createdAt: string;
  expiresAt?: string | null;
};

export type GetMyOffersResponseDTO = {
  offers: MyOfferDTO[];
};
