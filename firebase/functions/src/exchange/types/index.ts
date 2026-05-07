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

export type Transaction = {
  startupId: string;
  buyer: TransactionAgent;
  seller: TransactionSeller;
  qtdTokens: number;
  tokenPriceCents: number;
  totalCents: number;
  createdAt: Timestamp;
};

export type OfferStatus = "OPEN" | "ACCEPTED" | "CANCELLED";

export type Offer = Transaction & {
  expiresAt?: Timestamp;
  status: OfferStatus;
};
