// Autor: Allan Giovanni Matias Paes - 25008211
import { FieldValue, Timestamp } from "firebase-admin/firestore";

export type EventDocument = {
  startupId: string;
  delta: number; // (decimal, por exemplo: -1.0 = -100%, 1.0 = +100%);
  title: string;
  summary: string;
  content: string;
  tags?: string[];
  createdAt: Timestamp | FieldValue;
};

export type EventWithId = EventDocument & {
  id: string;
};
