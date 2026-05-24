import { FieldValue, Timestamp } from "firebase-admin/firestore";

export type EventDocument = {
  startupId: string;
  delta: number; // decimal (-10 a +10 por exemplo, significa -100% a +100%);
  title: string;
  summary: string;
  content: string;
  tags?: string[];
  createdAt: Timestamp | FieldValue;
};

export type EventWithId = EventDocument & {
  id: string;
};
