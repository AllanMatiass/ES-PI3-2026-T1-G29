import { TransactionAgent } from ".";

export type RegisterTransactionRequestDTO = {
  startupId: string;
  buyer: TransactionAgent;
  seller?: TransactionAgent | null | undefined;
  qtdTokens: number;
  tokenPriceCents: number;
};

export type TransactionIdDTO = {
  id: string;
};

export type GetStartupTransactionsRequestDTO = {
  startupId: string;
  limit?: number;
};

export type CreateOfferRequestDTO = {
  startupId: string;
  buyerId: string;
  sellerId: string;
  qtdTokens: number;
  tokenPriceCents: number;
  expiresAt?: string | null;
};

export type OfferIdDTO = {
  id: string;
};
