// Autor: Allan Giovanni Matias Paes

import { FieldValue } from "firebase-admin/firestore";
import { CreateStartupDocumentDTO } from "../startups/types/dtos";

// Dados de startups para serem usados no processo de seed,
// permitindo a criação de dados iniciais no Firestore
// para testes e desenvolvimento.

const DOCUMENTS = {
  "biochip-campus": {
    businessPlan:
      "https://firebasestorage.googleapis.com/v0/b/projeto-integrador-3---g29.firebasestorage.app/o/biochip%2FBioChip_Campus_Plano_de_Negocios.pdf?alt=media&token=b0b14d57-89d9-401e-a716-1db1e29ffd09",
    coverImageUrl:
      "https://firebasestorage.googleapis.com/v0/b/projeto-integrador-3---g29.firebasestorage.app/o/biochip%2FGemini_Generated_Image_56vuma56vuma56vu.png?alt=media&token=381fc1a2-957a-496f-8856-3ca4957092bb",
    demoVideos: ["https://www.youtube.com/watch?v=MIXj36IAyXA"],
    executiveSummary:
      "https://firebasestorage.googleapis.com/v0/b/projeto-integrador-3---g29.firebasestorage.app/o/biochip%2FBioChip_Campus_Executive_Summary.pdf?alt=media&token=3535c661-d920-4be5-8416-8d3dde830242",
    pitchDeckUrl:
      "https://firebasestorage.googleapis.com/v0/b/projeto-integrador-3---g29.firebasestorage.app/o/biochip%2FBioChip%20Campus%20Pitch%20Deck.pdf?alt=media&token=b8e88a7b-09d7-4a75-acf6-b53dcd7a79e7",
  },

  ecotech: {
    businessPlan:
      "https://firebasestorage.googleapis.com/v0/b/projeto-integrador-3---g29.firebasestorage.app/o/PI3-2026-Mobile-MesclaInvest%20(2).pdf?alt=media&token=fc10b029-fd38-4d09-b5bd-d46357dd87be",
    coverImageUrl:
      "https://firebasestorage.googleapis.com/v0/b/projeto-integrador-3---g29.firebasestorage.app/o/ecotech%2FEcoTech_log.png?alt=media&token=b3b12047-aa61-4c1d-bc8b-8711bd1c4553",

    demoVideos: [
      "https://firebasestorage.googleapis.com/v0/b/projeto-integrador-3---g29.firebasestorage.app/o/ecotech%2Fecotech_apresentacao.mp4?alt=media&token=80084fec-e43d-4233-9526-2964047a69e9",
    ],
    executiveSummary:
      "https://firebasestorage.googleapis.com/v0/b/projeto-integrador-3---g29.firebasestorage.app/o/PI3-2026-Mobile-MesclaInvest%20(2).pdf?alt=media&token=fc10b029-fd38-4d09-b5bd-d46357dd87be",
    pitchDeckUrl:
      "https://firebasestorage.googleapis.com/v0/b/projeto-integrador-3---g29.firebasestorage.app/o/PI3-2026-Mobile-MesclaInvest%20(2).pdf?alt=media&token=fc10b029-fd38-4d09-b5bd-d46357dd87be",
  },

  eduverse: {
    businessPlan:
      "https://firebasestorage.googleapis.com/v0/b/projeto-integrador-3---g29.firebasestorage.app/o/stps%2FEduVerse%2FeduVerse_Business_Plan.pdf?alt=media&token=928556e7-1165-4dea-85f5-95f15a81cb49",
    coverImageUrl:
      "https://firebasestorage.googleapis.com/v0/b/projeto-integrador-3---g29.firebasestorage.app/o/stps%2FEduVerse%2Feduverse-log.png?alt=media&token=f5c4cda8-c634-427d-9e0d-b83332f3df7c",
    demoVideos: [
      "https://firebasestorage.googleapis.com/v0/b/projeto-integrador-3---g29.firebasestorage.app/o/stps%2FEduVerse%2Feduverse_apresentacao.mp4?alt=media&token=f1e2b77d-fb65-4388-86fb-9458902f639b",
    ],
    executiveSummary:
      "https://firebasestorage.googleapis.com/v0/b/projeto-integrador-3---g29.firebasestorage.app/o/stps%2FEduVerse%2FeduVerse_Executive_Summary.pdf?alt=media&token=1dda59ad-9c52-44f5-ae78-3fa4f3a0abb6",
    pitchDeckUrl:
      "https://firebasestorage.googleapis.com/v0/b/projeto-integrador-3---g29.firebasestorage.app/o/stps%2FEduVerse%2FeduVerse%20Pitch%20Deck.pdf?alt=media&token=d639ea4a-8dc6-4a8e-90e7-15d65fd4a451",
  },
  finai: {
    businessPlan:
      "https://firebasestorage.googleapis.com/v0/b/projeto-integrador-3---g29.firebasestorage.app/o/stps%2FFinAI%2FFinAI_Business_Plan.pdf?alt=media&token=65b2f8d5-0c9e-4747-85dd-40508403602c",
    coverImageUrl:
      "https://firebasestorage.googleapis.com/v0/b/projeto-integrador-3---g29.firebasestorage.app/o/stps%2FFinAI%2FFinAI_logo.png?alt=media&token=f14c98ef-6aa2-4317-b7b8-6f8f33b6a69a",

    demoVideos: [
      "https://firebasestorage.googleapis.com/v0/b/projeto-integrador-3---g29.firebasestorage.app/o/stps%2FFinAI%2Ffinai_apresentacao.mp4?alt=media&token=b7ceb056-3efa-4337-b6ca-c9b1d4476654",
    ],
    executiveSummary:
      "https://firebasestorage.googleapis.com/v0/b/projeto-integrador-3---g29.firebasestorage.app/o/stps%2FFinAI%2FFinAI_Executive_Summary.pdf?alt=media&token=0cc01ad3-c7dd-4fa6-a1fd-8603bfc5f8d9",
    pitchDeckUrl:
      "https://firebasestorage.googleapis.com/v0/b/projeto-integrador-3---g29.firebasestorage.app/o/stps%2FFinAI%2FFinAI%20Pitch%20Deck.pdf?alt=media&token=2b0f6997-1914-4760-9c45-d1c792584f3c",
  },
  healthtrack: {
    businessPlan:
      "https://firebasestorage.googleapis.com/v0/b/projeto-integrador-3---g29.firebasestorage.app/o/stps%2FLogisSmart%2FHealthTrack_Business_Plan.pdf?alt=media&token=3457eeea-7044-4cd6-9fbb-e882882d390f",
    coverImageUrl:
      "https://firebasestorage.googleapis.com/v0/b/projeto-integrador-3---g29.firebasestorage.app/o/stps%2FLogisSmart%2FhealthTrack_logo.png?alt=media&token=61482885-0696-403b-a6f6-ced6af98c610",
    demoVideos: ["https://example.com/videos/healthtrack-demo"],
    executiveSummary:
      "https://firebasestorage.googleapis.com/v0/b/projeto-integrador-3---g29.firebasestorage.app/o/stps%2FLogisSmart%2FHealthTrack_Executive_Summary.pdf?alt=media&token=15daaf80-6735-4263-82f0-8119ae0fdf28",
    pitchDeckUrl:
      "https://firebasestorage.googleapis.com/v0/b/projeto-integrador-3---g29.firebasestorage.app/o/stps%2FLogisSmart%2FHealthTrack%20Pitch%20Deck.pdf?alt=media&token=22df9e27-5828-41b4-8180-dd375480b7b8",
  },
  mentorai: {
    businessPlan:
      "https://firebasestorage.googleapis.com/v0/b/projeto-integrador-3---g29.firebasestorage.app/o/stps%2FMentorAI%2FMentorAI_Business_Plan.pdf?alt=media&token=9a40a278-a042-444c-a74c-956c0a2b2367",
    coverImageUrl:
      "https://firebasestorage.googleapis.com/v0/b/projeto-integrador-3---g29.firebasestorage.app/o/stps%2FMentorAI%2Fmentorai_logo.png?alt=media&token=69951ca2-a83f-4f53-9a61-faf3114921e8",
    demoVideos: [
      "https://firebasestorage.googleapis.com/v0/b/projeto-integrador-3---g29.firebasestorage.app/o/stps%2FMentorAI%2Fmentorai_apresentacao.mp4?alt=media&token=2fb9df2b-660c-4207-9f53-7634518e2358",
    ],
    executiveSummary:
      "https://firebasestorage.googleapis.com/v0/b/projeto-integrador-3---g29.firebasestorage.app/o/stps%2FMentorAI%2FMentorAI_Executive_Summary.pdf?alt=media&token=f3616346-9a43-41aa-bd8d-c0d5149cb905",
    pitchDeckUrl:
      "https://firebasestorage.googleapis.com/v0/b/projeto-integrador-3---g29.firebasestorage.app/o/stps%2FMentorAI%2FMentorAI%20Pitch%20Deck.pdf?alt=media&token=ec0be930-69f7-43d6-983e-77a4f34e30f9",
  },
  "rota-verde": {
    businessPlan:
      "https://firebasestorage.googleapis.com/v0/b/projeto-integrador-3---g29.firebasestorage.app/o/stps%2FRotaVerde%2FRotaVerde_Business_Plan.pdf?alt=media&token=6855a695-c426-403a-9398-27e73b5ada79",
    coverImageUrl:
      "https://firebasestorage.googleapis.com/v0/b/projeto-integrador-3---g29.firebasestorage.app/o/stps%2FRotaVerde%2FRotaVerde_logo.png?alt=media&token=581514d8-8b6b-44b3-b8e8-a2325ea55b20",
    demoVideos: ["https://example.com/videos/rota-verde-demo"],
    executiveSummary:
      "https://firebasestorage.googleapis.com/v0/b/projeto-integrador-3---g29.firebasestorage.app/o/stps%2FRotaVerde%2FRotaVerde_Executive_Summary.pdf?alt=media&token=cec9542e-f9ea-40fc-ad51-e34a9fcde5c5",
    pitchDeckUrl:
      "https://firebasestorage.googleapis.com/v0/b/projeto-integrador-3---g29.firebasestorage.app/o/stps%2FRotaVerde%2FRotaVerde%20Pitch%20Deck.pdf?alt=media&token=16718fa5-0aab-4f43-9008-493d70b767de",
  },
};

export const startupsData: CreateStartupDocumentDTO[] = [
  {
    id: "biochip-campus",
    name: "BioChip Campus",
    stage: "nova",
    shortDescription:
      "Sensores portateis para analises laboratoriais didaticas.",
    description:
      "A BioChip Campus simula kits de diagnostico rapido para laboratorios universitarios, conectando sensores de baixo custo a um aplicativo de acompanhamento.",
    executiveSummary: DOCUMENTS["biochip-campus"].executiveSummary,
    capitalRaisedCents: 1850000,
    totalTokensIssued: 100000,
    circulatingTokens: 72000,
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
    demoVideos: DOCUMENTS["biochip-campus"].demoVideos,
    businessPlan: DOCUMENTS["biochip-campus"].businessPlan,
    pitchDeckUrl: DOCUMENTS["biochip-campus"].pitchDeckUrl,
    coverImageUrl: DOCUMENTS["biochip-campus"].coverImageUrl,
    tags: ["healthtech", "iot", "educacao"],
    createdAt: FieldValue.serverTimestamp(),
  },
  {
    id: "rota-verde",
    name: "Rota Verde",
    stage: "em_operacao",
    shortDescription: "Otimizacao de rotas sustentaveis para entregas urbanas.",
    description:
      "A Rota Verde usa dados de distancia, emissao estimada e ocupacao de entregadores para sugerir rotas urbanas com menor impacto ambiental.",
    executiveSummary: DOCUMENTS["rota-verde"].executiveSummary,
    capitalRaisedCents: 7400000,
    totalTokensIssued: 250000,
    circulatingTokens: 185000,
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
    demoVideos: DOCUMENTS["rota-verde"].demoVideos,
    businessPlan: DOCUMENTS["rota-verde"].businessPlan,
    pitchDeckUrl: DOCUMENTS["rota-verde"].pitchDeckUrl,
    coverImageUrl: DOCUMENTS["rota-verde"].coverImageUrl,
    tags: ["logtech", "sustentabilidade", "mobilidade"],
    createdAt: FieldValue.serverTimestamp(),
  },
  {
    id: "mentorai",
    name: "MentorAI",
    stage: "em_expansao",
    shortDescription:
      "Triagem inteligente para programas de mentoria universitarios.",
    description:
      "A MentorAI organiza perfis de estudantes e mentores para recomendar encontros com base em objetivos, disponibilidade e historico de acompanhamento.",
    executiveSummary: DOCUMENTS["mentorai"].executiveSummary,
    capitalRaisedCents: 12350000,
    totalTokensIssued: 500000,
    circulatingTokens: 385000,
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
    demoVideos: DOCUMENTS["mentorai"].demoVideos,
    businessPlan: DOCUMENTS["mentorai"].businessPlan,
    pitchDeckUrl: DOCUMENTS["mentorai"].pitchDeckUrl,
    coverImageUrl: DOCUMENTS["mentorai"].coverImageUrl,
    tags: ["edtech", "ia", "mentoria"],
    createdAt: FieldValue.serverTimestamp(),
  },
  {
    id: "ecotech",
    name: "EcoTech",
    stage: "nova",
    shortDescription: "Soluções sustentáveis para o agro.",
    description:
      "Plataforma para otimização sustentável de recursos agrícolas utilizando IoT e análise de dados.",
    executiveSummary: DOCUMENTS["ecotech"].executiveSummary,
    capitalRaisedCents: 50000000,
    totalTokensIssued: 100000,
    circulatingTokens: 76000,
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
    demoVideos: DOCUMENTS["ecotech"].demoVideos,
    businessPlan: DOCUMENTS["ecotech"].businessPlan,
    pitchDeckUrl: DOCUMENTS["ecotech"].pitchDeckUrl,
    coverImageUrl: DOCUMENTS["ecotech"].coverImageUrl,
    tags: ["agronegocio", "sustentabilidade", "iot"],
    createdAt: FieldValue.serverTimestamp(),
  },
  {
    id: "healthtrack",
    name: "HealthTrack",
    stage: "em_operacao",
    shortDescription: "Monitoramento remoto de pacientes.",
    description:
      "Sistema de telemonitoramento com foco em prevenção de doenças crônicas através de wearables.",
    executiveSummary: DOCUMENTS["healthtrack"].executiveSummary,
    capitalRaisedCents: 200000000,
    totalTokensIssued: 500000,
    circulatingTokens: 412000,
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
    demoVideos: DOCUMENTS["healthtrack"].demoVideos,
    businessPlan: DOCUMENTS["healthtrack"].businessPlan,
    pitchDeckUrl: DOCUMENTS["healthtrack"].pitchDeckUrl,
    coverImageUrl: DOCUMENTS["healthtrack"].coverImageUrl,
    tags: ["healthtech", "monitoramento", "prevencao"],
    createdAt: FieldValue.serverTimestamp(),
  },
  {
    id: "eduverse",
    name: "EduVerse",
    stage: "em_expansao",
    shortDescription: "Realidade virtual para escolas.",
    description:
      "Plataforma educacional imersiva com uso de realidade virtual para simulações científicas e históricas.",
    executiveSummary: DOCUMENTS["eduverse"].executiveSummary,
    capitalRaisedCents: 500000000,
    totalTokensIssued: 1000000,
    circulatingTokens: 780000,
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
    demoVideos: DOCUMENTS["eduverse"].demoVideos,
    businessPlan: DOCUMENTS["eduverse"].businessPlan,
    pitchDeckUrl: DOCUMENTS["eduverse"].pitchDeckUrl,
    coverImageUrl: DOCUMENTS["eduverse"].coverImageUrl,
    tags: ["edtech", "realidade-virtual", "inovacao"],
    createdAt: FieldValue.serverTimestamp(),
  },
  {
    id: "finai",
    name: "FinAI",
    stage: "nova",
    shortDescription: "IA para finanças pessoais universitárias.",
    description:
      "Assistente financeiro com IA para estudantes universitários, ajudando na gestão de bolsas e gastos mensais.",
    executiveSummary: DOCUMENTS["finai"].executiveSummary,
    capitalRaisedCents: 80000000,
    totalTokensIssued: 200000,
    circulatingTokens: 155000,
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
    demoVideos: DOCUMENTS["finai"].demoVideos,
    businessPlan: DOCUMENTS["finai"].businessPlan,
    pitchDeckUrl: DOCUMENTS["finai"].pitchDeckUrl,
    coverImageUrl: DOCUMENTS["finai"].coverImageUrl,
    tags: ["fintech", "ia", "estudantes"],
    createdAt: FieldValue.serverTimestamp(),
  },
];
