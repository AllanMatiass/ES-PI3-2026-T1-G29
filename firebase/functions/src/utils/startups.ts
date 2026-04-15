// Autor: Allan Giovanni Matias Paes

import { StartupDocument } from "../startups/types";

// Dados de startups para serem usados no processo de seed,
// permitindo a criação de dados iniciais no Firestore
// para testes e desenvolvimento.

export const startupsData: (StartupDocument & { id: string })[] = [
  {
    id: "biochip-campus",
    name: "BioChip Campus",
    stage: "nova",
    shortDescription:
      "Sensores portateis para analises laboratoriais didaticas.",
    description:
      "A BioChip Campus simula kits de diagnostico rapido para laboratorios universitarios, conectando sensores de baixo custo a um aplicativo de acompanhamento.",
    executiveSummary:
      "Startup em fase de ideacao com foco em prototipagem de sensores educacionais e validacao com cursos da area de saude.",
    capitalRaisedCents: 1850000,
    totalTokensIssued: 100000,
    currentTokenPriceCents: 125,
    founders: [
      {
        name: "Ana Ribeiro",
        role: "CEO",
        equityPercent: 48,
        bio: "Responsavel por estrategia e parcerias academicas.",
      },
      {
        name: "Lucas Moreira",
        role: "CTO",
        equityPercent: 37,
        bio: "Responsavel por hardware e integracao mobile.",
      },
      {
        name: "Mescla Labs",
        role: "Reserva estrategica",
        equityPercent: 15,
      },
    ],
    externalMembers: [
      {
        name: "Dra. Helena Costa",
        role: "Mentora",
        organization: "PUC-Campinas",
      },
    ],
    demoVideos: ["https://example.com/videos/biochip-campus-demo"],
    pitchDeckUrl: "https://example.com/decks/biochip-campus.pdf",
    coverImageUrl:
      "https://images.unsplash.com/photo-1581093458791-9d15482442f6",
    tags: ["healthtech", "iot", "educacao"],
  },
  {
    id: "rota-verde",
    name: "Rota Verde",
    stage: "em_operacao",
    shortDescription: "Otimizacao de rotas sustentaveis para entregas urbanas.",
    description:
      "A Rota Verde usa dados de distancia, emissao estimada e ocupacao de entregadores para sugerir rotas urbanas com menor impacto ambiental.",
    executiveSummary:
      "Startup em operacao piloto com pequenos comercios locais e validacao de indicadores de economia de combustivel.",
    capitalRaisedCents: 7400000,
    totalTokensIssued: 250000,
    currentTokenPriceCents: 310,
    founders: [
      { name: "Beatriz Santos", role: "CEO", equityPercent: 42 },
      { name: "Rafael Almeida", role: "COO", equityPercent: 28 },
      { name: "Carla Nogueira", role: "CTO", equityPercent: 20 },
      { name: "Reserva de incentivos", role: "Pool", equityPercent: 10 },
    ],
    externalMembers: [
      { name: "Marcos Lima", role: "Conselheiro", organization: "Mescla" },
      {
        name: "Patricia Gomes",
        role: "Mentora",
        organization: "Rede de Logistica",
      },
    ],
    demoVideos: ["https://example.com/videos/rota-verde-demo"],
    pitchDeckUrl: "https://example.com/decks/rota-verde.pdf",
    coverImageUrl:
      "https://images.unsplash.com/photo-1500530855697-b586d89ba3ee",
    tags: ["logtech", "sustentabilidade", "mobilidade"],
  },
  {
    id: "mentorai",
    name: "MentorAI",
    stage: "em_expansao",
    shortDescription:
      "Triagem inteligente para programas de mentoria universitarios.",
    description:
      "A MentorAI organiza perfis de estudantes e mentores para recomendar encontros com base em objetivos, disponibilidade e historico de acompanhamento.",
    executiveSummary:
      "Startup em expansao com uso simulado em programas de pre-aceleracao e potencial de integracao a plataformas educacionais.",
    capitalRaisedCents: 12350000,
    totalTokensIssued: 500000,
    currentTokenPriceCents: 525,
    founders: [
      { name: "Diego Martins", role: "CEO", equityPercent: 36 },
      { name: "Juliana Vieira", role: "CPO", equityPercent: 24 },
      { name: "Felipe Andrade", role: "CTO", equityPercent: 25 },
      {
        name: "Investidores simulados",
        role: "Participacao externa",
        equityPercent: 15,
      },
    ],
    externalMembers: [
      {
        name: "Sofia Pereira",
        role: "Conselheira",
        organization: "Ecossistema Mescla",
      },
    ],
    demoVideos: ["https://example.com/videos/mentorai-demo"],
    pitchDeckUrl: "https://example.com/decks/mentorai.pdf",
    coverImageUrl: "https://images.unsplash.com/photo-1552664730-d307ca884978",
    tags: ["edtech", "ia", "mentoria"],
  },
  {
    id: "ecotech",
    name: "EcoTech",
    stage: "nova",
    shortDescription: "Soluções sustentáveis para o agro.",
    description:
      "Plataforma para otimização sustentável de recursos agrícolas utilizando IoT e análise de dados.",
    executiveSummary:
      "Focada em reduzir o desperdício de água e defensivos em pequenas e médias propriedades.",
    capitalRaisedCents: 50000000,
    totalTokensIssued: 100000,
    currentTokenPriceCents: 500,
    founders: [
      {
        name: "João Silva",
        role: "CEO",
        equityPercent: 50,
        bio: "Especialista em agronomia sustentável.",
      },
      {
        name: "Maria Rita",
        role: "COO",
        equityPercent: 50,
        bio: "Gestora de operações com foco em sustentabilidade.",
      },
    ],
    externalMembers: [
      { name: "Prof. Carlos", role: "Mentor", organization: "AgroTech Hub" },
    ],
    demoVideos: ["https://example.com/videos/ecotech-demo"],
    coverImageUrl:
      "https://images.unsplash.com/photo-1464226184884-fa280b87c399",
    tags: ["agronegocio", "sustentabilidade", "iot"],
  },
  {
    id: "healthtrack",
    name: "HealthTrack",
    stage: "em_operacao",
    shortDescription: "Monitoramento remoto de pacientes.",
    description:
      "Sistema de telemonitoramento com foco em prevenção de doenças crônicas através de wearables.",
    executiveSummary:
      "Reduzindo reinternações hospitalares através de acompanhamento contínuo e preventivo.",
    capitalRaisedCents: 200000000,
    totalTokensIssued: 500000,
    currentTokenPriceCents: 400,
    founders: [
      {
        name: "Pedro Alves",
        role: "CEO",
        equityPercent: 100,
        bio: "Médico com visão tecnológica.",
      },
    ],
    externalMembers: [
      {
        name: "Dra. Ana Gomes",
        role: "Mentora",
        organization: "Health Innovation Lab",
      },
    ],
    demoVideos: ["https://example.com/videos/healthtrack-demo"],
    coverImageUrl:
      "https://images.unsplash.com/photo-1576091160550-2173dba999ef",
    tags: ["healthtech", "monitoramento", "prevencao"],
  },
  {
    id: "eduverse",
    name: "EduVerse",
    stage: "em_expansao",
    shortDescription: "Realidade virtual para escolas.",
    description:
      "Plataforma educacional imersiva com uso de realidade virtual para simulações científicas e históricas.",
    executiveSummary:
      "Transformando a educação básica com laboratórios virtuais de alto impacto visual e didático.",
    capitalRaisedCents: 500000000,
    totalTokensIssued: 1000000,
    currentTokenPriceCents: 500,
    founders: [
      {
        name: "Lucas",
        role: "CTO",
        equityPercent: 60,
        bio: "Desenvolvedor de engines 3D.",
      },
      {
        name: "Sofia",
        role: "CEO",
        equityPercent: 40,
        bio: "Pedagoga especialista em tecnologia.",
      },
    ],
    externalMembers: [
      { name: "Marcos", role: "Adviser", organization: "VR Association" },
    ],
    demoVideos: ["https://example.com/videos/eduverse-demo"],
    coverImageUrl:
      "https://images.unsplash.com/photo-1478479405421-ce83c92fb3ba",
    tags: ["edtech", "realidade-virtual", "inovacao"],
  },
  {
    id: "finai",
    name: "FinAI",
    stage: "nova",
    shortDescription: "IA para finanças pessoais universitárias.",
    description:
      "Assistente financeiro com IA para estudantes universitários, ajudando na gestão de bolsas e gastos mensais.",
    executiveSummary:
      "Democratizando o planejamento financeiro para a nova geração de universitários.",
    capitalRaisedCents: 80000000,
    totalTokensIssued: 200000,
    currentTokenPriceCents: 400,
    founders: [
      {
        name: "Julia",
        role: "CEO",
        equityPercent: 70,
        bio: "Ex-gestora de investimentos.",
      },
      {
        name: "Rafael",
        role: "CTO",
        equityPercent: 30,
        bio: "Engenheiro de dados.",
      },
    ],
    externalMembers: [
      { name: "Prof. Roberto", role: "Mentor", organization: "Finance School" },
    ],
    demoVideos: ["https://example.com/videos/finai-demo"],
    coverImageUrl: "https://images.unsplash.com/photo-1551288049-bebda4e38f71",
    tags: ["fintech", "ia", "estudantes"],
  },
  {
    id: "logissmart",
    name: "LogisSmart",
    stage: "em_operacao",
    shortDescription: "Otimização de rotas de entrega.",
    description:
      "Sistema inteligente de roteirização logística que otimiza o 'last mile' para pequenos e-commerces.",
    executiveSummary:
      "Reduzindo o tempo de entrega e o custo de frete em até 30% através de algoritmos genéticos.",
    capitalRaisedCents: 300000000,
    totalTokensIssued: 800000,
    currentTokenPriceCents: 375,
    founders: [
      {
        name: "Thiago Neves",
        role: "CEO",
        equityPercent: 100,
        bio: "Logístico com 15 anos de mercado.",
      },
    ],
    externalMembers: [],
    demoVideos: ["https://example.com/videos/logissmart-demo"],
    coverImageUrl:
      "https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d",
    tags: ["logtech", "otimizacao", "entrega"],
  },
];
