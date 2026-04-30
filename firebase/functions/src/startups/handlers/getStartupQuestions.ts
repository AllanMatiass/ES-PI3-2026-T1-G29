import { HttpsError, onCall } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import { requireAuthenticatedUser } from "../../shared/auth";
import { normalizeString } from "../../shared/validation";
import {
  getStartupById,
  listStartupQuestions,
  userIsInvestor,
} from "../repositories/startupRepository";

import { withCallHandler } from "../../shared/middlewares/errorHandler";

export const getStartupQuestions = onCall(
  withCallHandler(async (request) => {
    const user = requireAuthenticatedUser(request);
    const startupId = normalizeString(request.data?.startupId);

    if (!startupId) {
      throw new HttpsError("invalid-argument", "Informe o startupId.");
    }

    const startup = await getStartupById(startupId);
    if (!startup) {
      throw new HttpsError("not-found", "Startup não encontrada.");
    }

    const isInvestor = await userIsInvestor(startupId, user.uid);
    const questions = await listStartupQuestions(startupId, isInvestor);

    logger.info("Perguntas listadas para startup.", {
      startupId,
      userId: user.uid,
      isInvestor,
      questionsCount: questions.length,
    });

    return {
      data: {
        startupId,
        startupName: startup.name,
        isInvestor,
        questions,
      },
    };
  }),
);