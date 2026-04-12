import {
  StartupStatus,
  Startup,
  StartupSector,
  StartupStage,
} from "../@types/startupTypes";

export const startupsData: Startup[] = [
  {
    name: "EcoTech",
    description: "Soluções sustentáveis para o agro",
    executiveSummary:
      "Plataforma para otimização sustentável de recursos agrícolas",
    stage: StartupStage.NEW,
    status: StartupStatus.ACTIVE,
    sector: StartupSector.AGRIBUSINESS,
    foundationDate: new Date("2026-01-10"),
    estimatedValuation: 500000,

    corporateStructure: {
      partners: [
        { name: "João Silva", equityPercentage: 50, investedCapital: 0 },
        { name: "Maria Rita", equityPercentage: 50, investedCapital: 0 },
      ],
    },

    tokens: {
      totalSupply: 100000,
      circulatingSupply: 50000,
    },

    externalParticipants: {
      mentors: ["Prof. Carlos"],
      advisors: [],
      others: [],
    },

    media: {
      demoVideo: "link.com/eco",
    },

    documents: {
      businessPlan: null,
      presentations: [],
      publicDocuments: [],
    },
  },

  {
    name: "HealthTrack",
    description: "Monitoramento remoto de pacientes",
    executiveSummary:
      "Sistema de telemonitoramento com foco em prevenção de doenças",
    stage: StartupStage.OPERATING,
    status: StartupStatus.ACTIVE,
    sector: StartupSector.HEALTHCARE,
    foundationDate: new Date("2025-11-03"),
    estimatedValuation: 2000000,

    corporateStructure: {
      partners: [
        { name: "Pedro Alves", equityPercentage: 100, investedCapital: 50000 },
      ],
    },

    tokens: {
      totalSupply: 500000,
      circulatingSupply: 200000,
    },

    externalParticipants: {
      mentors: ["Dra. Ana Gomes"],
      advisors: [],
      others: [],
    },

    media: {
      demoVideo: "link.com/health",
    },

    documents: {
      businessPlan: null,
      presentations: [],
      publicDocuments: [],
    },
  },

  {
    name: "EduVerse",
    description: "Realidade virtual para escolas",
    executiveSummary: "Plataforma educacional imersiva com uso de VR",
    stage: StartupStage.EXPANDING,
    status: StartupStatus.ACTIVE,
    sector: StartupSector.EDUCATION,
    foundationDate: new Date("2025-08-21"),
    estimatedValuation: 5000000,

    corporateStructure: {
      partners: [
        { name: "Lucas", equityPercentage: 60, investedCapital: 75000 },
        { name: "Sofia", equityPercentage: 40, investedCapital: 75000 },
      ],
    },

    tokens: {
      totalSupply: 1000000,
      circulatingSupply: 400000,
    },

    externalParticipants: {
      mentors: [],
      advisors: ["Marcos"],
      others: [],
    },

    media: {
      demoVideo: "link.com/edu",
    },

    documents: {
      businessPlan: null,
      presentations: [],
      publicDocuments: [],
    },
  },

  {
    name: "FinAI",
    description: "IA para finanças pessoais universitárias",
    executiveSummary: "Assistente financeiro com IA para estudantes",
    stage: StartupStage.NEW,
    status: StartupStatus.ACTIVE,
    sector: StartupSector.FINANCE,
    foundationDate: new Date("2026-02-05"),
    estimatedValuation: 800000,

    corporateStructure: {
      partners: [
        { name: "Julia", equityPercentage: 70, investedCapital: 7000 },
        { name: "Rafael", equityPercentage: 30, investedCapital: 3000 },
      ],
    },

    tokens: {
      totalSupply: 200000,
      circulatingSupply: 50000,
    },

    externalParticipants: {
      mentors: ["Prof. Roberto"],
      advisors: [],
      others: [],
    },

    media: {
      demoVideo: "link.com/fin",
    },

    documents: {
      businessPlan: null,
      presentations: [],
      publicDocuments: [],
    },
  },

  {
    name: "LogisSmart",
    description: "Otimização de rotas de entrega",
    executiveSummary: "Sistema inteligente de roteirização logística",
    stage: StartupStage.OPERATING,
    status: StartupStatus.ACTIVE,
    sector: StartupSector.LOGISTICS,
    foundationDate: new Date("2025-10-12"),
    estimatedValuation: 3000000,

    corporateStructure: {
      partners: [
        { name: "Thiago Neves", equityPercentage: 100, investedCapital: 80000 },
      ],
    },

    tokens: {
      totalSupply: 800000,
      circulatingSupply: 300000,
    },

    externalParticipants: {
      mentors: [],
      advisors: [],
      others: [],
    },

    media: {
      demoVideo: "link.com/logis",
    },

    documents: {
      businessPlan: null,
      presentations: [],
      publicDocuments: [],
    },
  },
];
