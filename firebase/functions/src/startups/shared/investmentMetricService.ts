// Autor: Allan Giovanni Matias Paes
import { HttpsError } from "firebase-functions/https";
import { getStartupById, getStartupValuationById } from "../repositories/startupRepository";
import { RETURN_CONFIG, RISK_CONFIG } from "../shared/constants";

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
    
    async expectedReturn(startupId: string): Promise<{
        range: string;
        expected: number;
    }> {
        const risk = await this.calculateRisk(startupId);

        const profile = this.getRiskProfile(risk);
        const probabilities = RETURN_CONFIG.probabilities[profile];
        const outcome = RETURN_CONFIG.outcome;

        let expected = 0;

        for (let i = 0; i < outcome.length; i++) {
            expected += outcome[i].multiple * probabilities[i];
        }

        const min = outcome[0].multiple;
        const max = outcome[outcome.length - 1].multiple;

        return {
            range: `${min}x a ${max}x`,
            expected: Number(expected.toFixed(2))
        };
    }

    getRiskProfile(risk: number): 'lowRisk' | 'mediumRisk' | 'highRisk' {
        if (risk <= 3) return 'lowRisk';
        if (risk <= 6) return 'mediumRisk';
        return 'highRisk';
    }
}