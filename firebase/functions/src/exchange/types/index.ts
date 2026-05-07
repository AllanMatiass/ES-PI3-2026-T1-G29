import { Timestamp } from "firebase-admin/firestore";

export type TransactionAgent = {
  id: string;
  name: string;
};

export type TransactionSeller = {
  id?: string;
  name: string;
  type: "USER" | "STARTUP";
};

export type TransactionType = "BUY_FROM_STARTUP" | "USER_TRADE";

export type Transaction = {
  startupId: string;
  buyer: TransactionAgent;
  seller: TransactionSeller;
  qtdTokens: number;
  tokenPriceCents: number;
  totalCents: number;
  transactionType: TransactionType;
  createdAt: Timestamp;
};

export type OfferStatus = "OPEN" | "ACCEPTED" | "CANCELLED" | "EXPIRED";

export type Offer = Omit<Transaction, "buyer"> & {
  buyer?: TransactionAgent;
  expiresAt?: Timestamp;
  status: OfferStatus;
  acceptedAt?: Timestamp;
  cancelledAt?: Timestamp;
};

export type OfferWithId = Offer & {
  id: string;
};
