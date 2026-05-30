/**
 * @file constants.ts
 * @description Definição de constantes, configurações de risco e projeções de retorno para o módulo de startups.
 * @author Allan Giovanni Matias Paes - 25008211
 */

import { QuestionVisibility, StartupStage } from "../types";

/**
 * Estágios permitidos para uma startup no sistema.
 */
export const allowedStages: StartupStage[] = [
  "nova",
  "em_operacao",
  "em_expansao",
];

/**
 * Visibilidades permitidas para as perguntas enviadas às startups.
 */
export const allowedVisibilities: QuestionVisibility[] = ["publica", "privada"];

/**
 * Configurações para o motor de cálculo de risco.
 * Define pesos para diferentes pilares e pontuações baseadas no estado da startup.
 */
export const RISK_CONFIG = {
  // Pesos de cada pilar no cálculo final do risco (Soma = 1.0)
  weights: {
    stage: 0.4, // Estágio da startup
    team: 0.3, // Composição do time de fundadores
    tech: 0.2, // Complexidade tecnológica (baseada em tags)
    mentors: 0.1, // Presença de membros externos/mentores
  },

  // Pontuações (Scores): Quanto maior o valor, maior o risco percebido.
  scores: {
    stage: {
      nova: 1, // Risco máximo
      em_operacao: 0.5,
      em_expansao: 0.3, // Risco mínimo
    },
    team: {
      multipleFounders: 0.3, // Time diversificado reduz o risco
      soloFounder: 1, // Fundador único aumenta o risco
    },
    tags: {
      complex: 1, // Tags como 'iot', 'blockchain', 'deeptech'
      simple: 0.5, // Tags mais comuns ou menos arriscadas
    },
    mentors: {
      hasMentors: 0.3, // Presença de mentores reduz o risco
      noMentors: 1, // Ausência de mentores aumenta o risco
    },
  },

  // Escala final do score de risco
  scale: {
    max: 10,
  },
};

/**
 * Configurações para projeção de retorno esperado.
 * Define cenários de saída (multiplicadores) e probabilidades baseadas no perfil de risco.
 */
export const RETURN_CONFIG = {
  // Cenários possíveis de retorno sobre o investimento inicial
  outcome: [
    { label: "fail", multiple: 0 }, // Perda total do capital
    { label: "base", multiple: 3 }, // Retorno moderado (3x)
    { label: "success", multiple: 10 }, // Caso de sucesso (10x)
  ],

  // Matriz de probabilidades por perfil de risco [P(fail), P(base), P(success)]
  probabilities: {
    lowRisk: [0.2, 0.5, 0.3], // 20% falha, 50% médio, 30% sucesso
    mediumRisk: [0.4, 0.4, 0.2], // 40% falha, 40% médio, 20% sucesso
    highRisk: [0.6, 0.3, 0.1], // 60% falha, 30% médio, 10% sucesso
  },
};

const now = new Date();

/**
 * Intervalo de tempo padrão para consultas de histórico (últimos 12 meses).
 * Formatado como YYYY-MM-DD para compatibilidade com filtros de banco de dados.
 */
export const DEFAULT_RANGE = {
  from: new Date(new Date().setMonth(now.getMonth() - 12))
    .toISOString()
    .split("T")[0],
  to: now.toISOString().split("T")[0],
};
