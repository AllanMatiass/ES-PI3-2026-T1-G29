import { onCall } from "firebase-functions/v2/https";
import { withCallHandler } from "../../shared/middlewares/errorHandler";
import { EventDocument } from "../types";
import { EventService } from "../shared/eventService";

const eventService = new EventService();

export const getEventById = onCall(
  withCallHandler<{ eventId: string }, EventDocument>(async (request) => {
    const { eventId } = request.data;
    return eventService.getEventById(eventId);
  }),
);
