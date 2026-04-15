import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { QuestionVisibility, StartupDocument, StartupQuestionAnswer } from ".";

export type CreateStartupDocumentDTO = StartupDocument & {
  id: string;
  createdAt: FieldValue;
};

export type StartupDocumentDTO = StartupDocument & {
  createdAt: Timestamp;
};

export type ListStartupsRequest = {
  stage?: string;
  search?: string;
};

export type GetStartupDetailsRequest = {
  id: string;
};

export type GetStartupDetailsResponse = {
  id: string;
  // campos do startup
  createdAt: string | null;
  updatedAt: string | null;
  publicQuestions: QuestionResponseDTO[];
  access: {
    isInvestor: boolean;
    canTradeTokens: boolean;
    canSendPrivateQuestions: boolean;
  };
};

/**
 * Documento de pergunta armazenado na subcoleção da startup.
 *
 * As perguntas ficam em `startups/{startupId}/questions/{questionId}` para
 * manter o histórico associado ao projeto. A resposta é opcional porque a
 * pergunta pode ser criada antes de alguém respondê-la.
 */
export type StartupQuestionCreateInput = {
  startupId: string;
  authorId: string;
  text: string;
  visibility: QuestionVisibility;
  createdAt: FieldValue;
};

export type QuestionResponseDTO = {
  id: string;
  text: string;
  answers?: StartupQuestionAnswer[];
  createdAt: Timestamp | FieldValue;
};
