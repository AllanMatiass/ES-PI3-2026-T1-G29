// Autor: Allan Giovanni Matias Paes - 25008211 e Pedro Vinícius Romanato - 25004075
import { OfferWithId, TransactionParticipant, TransactionWithId } from ".";

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

export type OfferIdDTO = IdDTO;
export type TransactionIdDTO = IdDTO;

export type BuyTokensResponseDTO = {
  transactionId: string;
  remainingTokens: number;
};

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

export type BuyTokensRequestDTO = {
  offerId: string;
  qtdTokens: number;
};

export type CancelOfferRequestDTO = {
  id: string;
};

export type CancelOfferResponseDTO = {
  offerId: string;
  cancelled: boolean;
};

export type GetOffersRequestDTO = {
  startupId?: string;
  limit?: number;
  lastOfferId?: string;
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

export type ExpireOfferDTO = {
  offerId: string;
};

export type ExpireOfferResponseDTO = {
  offerId: string;
  expired: boolean;
};

export type BuyTokensFromStartupRequestDTO = {
  startupId: string;
  qtdTokens: number;
};

export type BuyTokensFromStartupResponseDTO = {
  transactionId: string;
  qtdTokens: number;
  tokenPriceCents: number;
  totalCents: number;
  newBalanceCents: number;
};

export type GetUserTransactionsRequestDTO = {
  limit?: number;
  lastTransactionId?: string;
};

export type PaginatedTransactionsResponseDTO = {
  transactions: TransactionWithId[];
  lastTransactionId: string | null;
};
