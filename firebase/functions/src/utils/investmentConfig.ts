export const RISK_CONFIG = {
    weights: {
        stage: 0.4,
        team: 0.3,
        tech: 0.2,
        mentors: 0.1
    },

    scores: {
        stage: {
            nova: 1,
            em_operacao: 0.5,
            em_expansao: 0.3
        },
        team: {
            multipleFounders: 0.3,
            soloFounder: 1
        },
        tags: {
            complex: 1,
            simple: 0.5
        },
        mentors: {
            hasMentors: 0.3,
            noMentors: 1
        }
    },

    scale: {
        max: 10
    }
};