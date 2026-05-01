// Autor: Allan Giovanni Matias Paes
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import {
  QuestionVisibility,
  StartupDocument,
  StartupQuestionAnswer,
  StartupRiskLabel,
} from ".";

/* =====================================================
  DOCUMENTOS / BANCO
===================================================== */

export type CreateStartupDocumentDTO = StartupDocument & {
  id: string;
  createdAt: FieldValue;
};

export type StartupDocumentDTO = StartupDocument & {
  createdAt: Timestamp;
};

export type StartupQuestionCreateDTO = {
  startupId: string;
  authorId: string;
  authorEmail: string;
  text: string;
  visibility: QuestionVisibility;
  createdAt: Timestamp;
};

export type QuestionResponseDTO = {
  id: string;
  startupId: string;
  authorId: string;
  text: string;
  visibility: QuestionVisibility;
  answers: StartupQuestionAnswer[];
  createdAt: Timestamp | FieldValue;
};

/* =====================================================
  TIPOS DE NEGÓCIO
===================================================== */

export type ListStartupsRequest = {
  stage?: string;
  search?: string;
};

export type GetStartupIdRequest = {
  id: string;
};

export type PriceHistoryOptions = {
  historyRange?: { from: string; to: string };
  historyInterval?: PriceHistoryInterval;
  historyLimit?: number;
};

export type GetStartupDetailsRequest = GetStartupIdRequest & {
  options?: PriceHistoryOptions | null;
};

export type ExpectedReturn = {
  range: string;
  expected: number;
};

export type Risk = {
  score: number;
  label: StartupRiskLabel;
};

export type VariationTrend = "up" | "down" | "stable";

export type Variation = {
  percentage: number;
  trend: VariationTrend;
};

export type StartupDetails = {
  startup: StartupDocument;
  valuation: number;
  risk: Risk;
  expectedReturn: ExpectedReturn;
  horizon: string;
};

/* =====================================================
  
DTOs DE RESPOSTA (API)
===================================================== */

export type AnswerViewDTO = {
  answer: string;
  answeredAt: string; // ISO string
};

export type QuestionViewDTO = {
  id: string;
  startupId: string;
  authorId: string;
  authorEmail: string;
  text: string;
  visibility: QuestionVisibility;
  answers: AnswerViewDTO[];
  createdAt: string;
};

/**
 * Versão pública (sem dados sensíveis)
 */
export type PublicQuestionViewDTO = {
  id: string;
  text: string;
  answers: AnswerViewDTO[];
  createdAt: string;
};

export type GetStartupQuestionsResponse = {
  startupId: string;
  startupName: string;
  isInvestor: boolean;
  questions: QuestionViewDTO[];
};

export type PriceHistoryResponse = {
  history: PriceHistoryItem[];
  summary: PriceHistorySummary;
  meta: PriceHistoryMeta;
};

export type GetStartupDetailsResponse = {
  id: string;
  details: StartupDetails;
  priceHistory: PriceHistoryResponse;
  publicQuestions: PublicQuestionViewDTO[];
  access: {
    isInvestor: boolean;
    canTradeTokens: boolean;
    canSendPrivateQuestions: boolean;
  };
};

/* =====================================================
  HISTÓRICO DE PREÇOS
===================================================== */

export type PriceHistoryInterval = "monthly" | "semestrely" | "yearly" | "ytd";

export type GetStartupPriceHistoryRequest = {
  id: string;
  range: {
    from: string; // ISO date
    to: string; // ISO date
  };
  interval: PriceHistoryInterval;
  limit?: number;
};

export type PriceHistoryItem = {
  timestamp: string; // ISO date
  price: number;
  variation: number | null;
  variationPercent: number | null;
};

export type PriceHistorySummary = {
  currentPrice: number;
  highestPrice: number;
  lowestPrice: number;
  averagePrice: number;
};

export type PriceHistoryMeta = {
  count: number;
  currency: string;
  interval: PriceHistoryInterval;
};

export type GetStartupPriceHistoryResponse = {
  history: PriceHistoryItem[];
  summary: PriceHistorySummary;
  meta: PriceHistoryMeta;
};
