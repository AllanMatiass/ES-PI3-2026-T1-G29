// Autor: Allan Giovanni Matias Paes - 25008211
import { onCall } from "firebase-functions/v2/https";
import { EventService } from "../shared/eventService";
import { EventRequestDTO, EventResponseDTO } from "../types/dtos/dtos";
import { withCallHandler } from "../../shared/middlewares/errorHandler";

const eventService = new EventService();

export const createEvent = onCall(
  withCallHandler<EventRequestDTO, EventResponseDTO>(async (request) => {
    const data = request.data as EventRequestDTO;
    return eventService.add(data);
  }),
);
