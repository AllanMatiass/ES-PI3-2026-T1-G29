// Autor: Allan Giovanni Matias Paes
import { Timestamp } from "firebase-admin/firestore";
import { StartupQuestionCreateInput, Variation } from "./dtos";

/**
 * Representa os estágios de maturidade aceitos para uma startup.
 *
 * Esses valores implementam a classificação descrita no item 5.2:
 *
 * - `nova`: ideia recentemente publicada.
 * - `em_operacao`: projeto já operando ou em validação prática.
 * - `em_expansao`: projeto em crescimento, com maior maturidade simulada.
 *
 * Os valores usam snake_case para facilitar armazenamento, filtros e
 * comparação direta no Firestore e nas chamadas callable.
 */
export type StartupStage = "nova" | "em_operacao" | "em_expansao";

export type StartupRiskLabel = "Risco Baixo" | "Risco Médio" | "Risco Alto";
export type StartupRiskCode = "lowRisk" | "mediumRisk" | "highRisk";

/**
 * Define o nível de visibilidade de uma pergunta enviada à startup.
 *
 * - `publica`: aparece na área pública de perguntas e respostas da startup.
 * - `privada`: fica restrita a investidores, conforme regra do item 5.2.
 */
export type QuestionVisibility = "publica" | "privada";

/**
 * Dados mínimos do usuário autenticado necessários para regras de negócio.
 *
 * Este tipo é derivado do `request.auth` das Callable Functions. Ele evita que
 * os handlers dependam diretamente do formato completo do token Firebase e
 * preserva apenas o que o domínio precisa: UID e e-mail, quando disponível.
 */
export type AuthenticatedUser = {
  uid: string;
  email?: string;
};

/**
 * Representa um sócio, fundador ou participação societária da startup.
 *
 * Este tipo atende ao requisito de exibir estrutura societária e percentual de
 * participação dos sócios. Também permite registrar reservas e pools de
 * incentivo como linhas da composição societária simulada.
 */
export type Founder = {
  name: string;
  role: string;
  equityPercent: number;
  bio?: string;
};

/**
 * Representa conselheiros, mentores ou participantes externos.
 *
 * O item 5.2 pede que a aplicação exiba membros do conselho, mentores ou
 * pessoas externas quando aplicável. Ele modela essas participações sem
 * misturá-las com a estrutura societária.
 */
export type ExternalMember = {
  name: string;
  role: string;
  organization?: string;
};

/**
 * Documento completo de uma startup no Firestore.
 *
 * Este é o contrato principal do catálogo. Ele concentra os dados para
 * listagem, página detalhada, apresentação dos sócios, capital simulado e
 * materiais públicos do projeto.
 */
export type StartupDocument = {
  name: string;
  stage: StartupStage;
  shortDescription: string;
  description: string;
  executiveSummary: string;
  capitalRaisedCents: number;
  totalTokensIssued: number;
  currentTokenPriceCents: number;
  circulatingTokens: number;
  founders: Founder[];
  externalMembers: ExternalMember[];
  demoVideos: string[]; // poderia ser enderecos URLs no Youtube ou firebase storage.
  pitchDeckUrl?: string;
  coverImageUrl?: string;
  lastValuationCents?: number;
  tags: string[];
  updatedAt?: Timestamp;
};

export type StartupQuestionDocument = StartupQuestionCreateInput & {
  answers: StartupQuestionAnswer[];
};

export type StartupQuestionAnswer = {
  answer: string;
  answeredAt: Timestamp;
};
/**
 * Versão resumida de uma startup usada na listagem do catálogo.
 *
 * Este tipo evita enviar todos os dados da startup para telas que precisam
 * apenas de cards ou linhas de lista. A tela detalhada deve usar
 * `StartupDocument`, mas a listagem usa `StartupListItem` para trafegar menos
 * dados e manter o contrato mais claro.
 */
export type StartupListItem = {
  id: string;
  name: string;
  stage: StartupStage;
  shortDescription: string;
  capitalRaisedCents: number;
  totalTokensIssued: number;
  currentTokenPriceCents: number;
  priceVariation?: number | null;
  coverImageUrl?: string | null;
  tags: string[];
  variation: Variation;
};
