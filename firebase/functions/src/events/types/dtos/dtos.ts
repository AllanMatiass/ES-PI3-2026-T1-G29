import { EventDocument, EventWithId } from "..";

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
