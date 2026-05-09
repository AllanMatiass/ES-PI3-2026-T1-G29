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

export type OfferIdDTO = IdDTO;

export type GetStartupTransactionsRequestDTO = {
  startupId: string;
  limit?: number;
};

export type CreateOfferRequestDTO = {
  startupId: string;
  sellerId: string;
  qtdTokens: number;
  tokenPriceCents: number;
  expiresAt?: string | null;
};

export type AcceptOfferRequestDTO = {
  offerId: string;
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
