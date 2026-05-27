// Autor: Allan Giovanni Matias Paes - 25008211
import { onCall } from "firebase-functions/v2/https";
import { listEvents as listEventsRepo } from "../repositories/eventRepository";
import { withCallHandler } from "../../shared/middlewares/errorHandler";
import {
  EventPaginatedRequestDTO,
  EventPaginatedResponseDTO,
} from "../types/dtos/dtos";

export const listEvents = onCall(
  withCallHandler<EventPaginatedRequestDTO, EventPaginatedResponseDTO>(
    async (request) => {
      const { startupId, limit, lastEventId } = request.data;
      return listEventsRepo(startupId, limit, lastEventId);
    },
  ),
);
