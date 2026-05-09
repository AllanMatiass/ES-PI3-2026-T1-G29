// Autor: Allan Giovanni Matias Paes
import { QuestionVisibility, StartupStage } from "../types";

export const allowedStages: StartupStage[] = [
  "nova",
  "em_operacao",
  "em_expansao",
];

export const allowedVisibilities: QuestionVisibility[] = ["publica", "privada"];

export const RISK_CONFIG = {
  weights: {
    stage: 0.4,
    team: 0.3,
    tech: 0.2,
    mentors: 0.1,
  },

  scores: {
    stage: {
      nova: 1,
      em_operacao: 0.5,
      em_expansao: 0.3,
    },
    team: {
      multipleFounders: 0.3,
      soloFounder: 1,
    },
    tags: {
      complex: 1,
      simple: 0.5,
    },
    mentors: {
      hasMentors: 0.3,
      noMentors: 1,
    },
  },

  scale: {
    max: 10,
  },
};

export const RETURN_CONFIG = {
  outcome: [
    { label: "fail", multiple: 0 },
    { label: "base", multiple: 3 },
    { label: "success", multiple: 10 },
  ],

  probabilities: {
    lowRisk: [0.2, 0.5, 0.3], // 20% falha, 50% médio, 30% sucesso
    mediumRisk: [0.4, 0.4, 0.2],
    highRisk: [0.6, 0.3, 0.1],
  },
};

const now = new Date();

export const DEFAULT_RANGE = {
  from: new Date(new Date().setMonth(now.getMonth() - 12))
    .toISOString()
    .split("T")[0],
  to: now.toISOString().split("T")[0],
};
