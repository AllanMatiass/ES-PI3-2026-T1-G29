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
import {
  GetStartupIdRequest,
  GetStartupQuestionsResponse,
  QuestionViewDTO,
} from "../types/dtos";

export const getStartupQuestions = onCall(
  withCallHandler<GetStartupIdRequest, GetStartupQuestionsResponse>(
    async (request) => {
      const user = requireAuthenticatedUser(request);
      const { id } = request.data;

      const startupId = normalizeString(id);

      if (!startupId) {
        throw new HttpsError("invalid-argument", "Informe o startupId.");
      }

      const startup = await getStartupById(startupId);

      if (!startup) {
        throw new HttpsError("not-found", "Startup não encontrada.");
      }

      const isInvestor = await userIsInvestor(startupId, user.uid);

      const rawQuestions = await listStartupQuestions(startupId, isInvestor);

      const questions: QuestionViewDTO[] = rawQuestions.map((q) => ({
        ...q,
        startupId,
      }));

      logger.info("Perguntas listadas para startup.", {
        startupId,
        userId: user.uid,
        isInvestor,
        questionsCount: questions.length,
      });

      return {
        startupId,
        startupName: startup.name,
        isInvestor,
        questions,
      };
    },
  ),
);
