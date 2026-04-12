import { Timestamp } from "firebase-admin/firestore";

export enum StartupStage {
  NEW,
  OPERATING,
  EXPANDING,
}

export enum StartupStatus {
  ACTIVE,
  INACTIVE,
}

export enum StartupSector {
  AGRIBUSINESS,
  HEALTHCARE,
  EDUCATION,
  FINANCE,
  LOGISTICS,
  OTHER,
}

export interface Partner {
  name: string;
  equityPercentage: number;
  investedCapital: number;
}

export interface CorporateStructure {
  partners: Partner[];
}

export interface Tokens {
  totalSupply: number;
  circulatingSupply: number;
}

export interface ExternalParticipants {
  mentors: string[];
  advisors: string[];
  others: string[];
}

export interface Media {
  demoVideo: string;
}

export interface Documents {
  businessPlan: string | null;
  presentations: string[];
  publicDocuments: string[];
}

export interface Startup {
  name: string;
  description: string;
  executiveSummary: string;
  stage: StartupStage;
  status: StartupStatus;
  sector: StartupSector;
  estimatedValuation: number;

  corporateStructure: CorporateStructure;
  tokens: Tokens;
  externalParticipants: ExternalParticipants;
  media: Media;
  documents: Documents;

  foundationDate: Date;
  createdAt?: Timestamp | null;
  updatedAt?: Timestamp | null;
}
