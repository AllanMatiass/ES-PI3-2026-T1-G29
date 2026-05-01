// Autor: Allan Giovanni Matias Paes
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import {
  QuestionVisibility,
  StartupDocument,
  StartupQuestionAnswer,
  StartupRiskLabel,
} from ".";

/* =====================================================
   📦 DOCUMENTOS / BANCO
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
  answers: StartupQuestionAnswer[]; // 🔥 múltiplas respostas
  createdAt: Timestamp | FieldValue;
};

/* =====================================================
   🧠 TIPOS DE NEGÓCIO
===================================================== */

export type ListStartupsRequest = {
  stage?: string;
  search?: string;
};

export type GetStartupIdRequest = {
  id: string;
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
   🌐 DTOs DE RESPOSTA (API)
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
  answers: AnswerViewDTO[]; // 🔥 padrão correto
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

export type GetStartupDetailsResponse = {
  id: string;
  details: StartupDetails;
  publicQuestions: PublicQuestionViewDTO[]; // 🔥 corrigido
  access: {
    isInvestor: boolean;
    canTradeTokens: boolean;
    canSendPrivateQuestions: boolean;
  };
};
