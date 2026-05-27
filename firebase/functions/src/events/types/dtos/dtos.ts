// Autor: Allan Giovanni Matias Paes - 25008211
import { EventDocument, EventWithId } from "..";

// DTOs usados nas requisições

export type EventRequestDTO = Omit<EventDocument, "createdAt">;

export type EventResponseDTO = EventRequestDTO & {
  id: string;
  newTokenPrice: number;
};

export type EventPaginatedRequestDTO = {
  startupId?: string | undefined;
  limit?: number | undefined;
  lastEventId?: string | undefined;
};

export type EventPaginatedResponseDTO = {
  events: EventWithId[];
  lastEventId: string | null;
};
