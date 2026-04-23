// Autor: Allan Giovanni Matias Paes
import { HttpsError } from "firebase-functions/https";
import { getStartupById, getStartupValuationById } from "../repositories/startupRepository";
import { RISK_CONFIG } from "../../utils/investmentConfig";

export class InvestmentMetricService {
    async getStartupValuation(startupId: string): Promise<number> {
        return await getStartupValuationById(startupId) ?? 0;
    }

    async calculateRisk(startupId: string): Promise<number> {
        const startup = await getStartupById(startupId);

        if (!startup) {
            throw new HttpsError('not-found', 'Startup não encontrada.');
        }

        const hasMoreThanOneFounder = startup.founders.length > 1;
        const hasMentors = startup.externalMembers.length > 0;

        const hasComplexTags = startup.tags
            .map(t => t.toLowerCase())
            .some(t => ['iot', 'healthtech'].includes(t));

        const stageScore = RISK_CONFIG.scores.stage[startup.stage];

        const teamScore = hasMoreThanOneFounder
            ? RISK_CONFIG.scores.team.multipleFounders
            : RISK_CONFIG.scores.team.soloFounder;

        const techScore = hasComplexTags
            ? RISK_CONFIG.scores.tags.complex
            : RISK_CONFIG.scores.tags.simple;

        const mentorsScore = hasMentors
            ? RISK_CONFIG.scores.mentors.hasMentors
            : RISK_CONFIG.scores.mentors.noMentors;

        const risk =
            stageScore * RISK_CONFIG.weights.stage +
            teamScore * RISK_CONFIG.weights.team +
            techScore * RISK_CONFIG.weights.tech +
            mentorsScore * RISK_CONFIG.weights.mentors;

        return Math.round(risk * RISK_CONFIG.scale.max);
    }
}