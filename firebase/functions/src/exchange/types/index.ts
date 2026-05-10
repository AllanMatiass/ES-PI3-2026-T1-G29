// Autor: Allan Giovanni Matias Paes
import { Timestamp } from "firebase-admin/firestore";

export type ParticipantType = "USER" | "STARTUP";

export type TransactionParticipant = {
  id: string;
  name: string;
  type: ParticipantType;
};

export type TransactionType = "BUY_FROM_STARTUP" | "USER_TRADE";

export type Transaction = {
  startupId: string;
  startupName: string;
  buyer: TransactionParticipant;
  seller: TransactionParticipant;
  participants: string[];
  qtdTokens: number;
  tokenPriceCents: number;
  totalCents: number;
  transactionType: TransactionType;
  createdAt: Timestamp;
};

export type TransactionWithId = Transaction & {
  id: string;
};

export type OfferStatus = "OPEN" | "ACCEPTED" | "CANCELLED" | "EXPIRED";

export type Offer = Omit<Transaction, "buyer" | "participants"> & {
  initialQtdTokens: number;
  averageAcquisitionPriceCents: number;
  buyer?: TransactionParticipant;
  expiresAt?: Timestamp;
  status: OfferStatus;
  acceptedAt?: Timestamp;
  cancelledAt?: Timestamp;
};

export type OfferWithId = Offer & {
  id: string;
};

export type TransactionAgent = TransactionParticipant;
