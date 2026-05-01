// Autor: Allan Giovanni Matias Paes
import { Timestamp } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import { allowedVisibilities } from "../shared/constants";
import { requireAuthenticatedUser } from "../../shared/auth";
import { normalizeString } from "../../shared/validation";
import {
  createQuestion,
  getStartupById,
  userIsInvestor,
} from "../repositories/startupRepository";
import { QuestionVisibility } from "../types";

import { withCallHandler } from "../../shared/middlewares/errorHandler";
import { QuestionResponseDTO, StartupQuestionCreateDTO } from "../types/dtos";

export const createStartupQuestion = onCall(
  withCallHandler<StartupQuestionCreateDTO, QuestionResponseDTO>(
    async (request) => {
      const user = requireAuthenticatedUser(request);

      const startupId = normalizeString(request.data?.startupId);
      const text = normalizeString(request.data?.text);
      const visibility = (normalizeString(request.data?.visibility) ??
        "publica") as QuestionVisibility;

      if (!startupId || !text) {
        throw new HttpsError("invalid-argument", "Informe startupId e text.");
      }

      if (!allowedVisibilities.includes(visibility as QuestionVisibility)) {
        throw new HttpsError(
          "invalid-argument",
          "Visibilidade invalida. Use publica ou privada.",
        );
      }

      const startup = await getStartupById(startupId);

      if (!startup) {
        throw new HttpsError("not-found", "Startup nao encontrada.");
      }

      if (visibility === "privada") {
        const isInvestor = await userIsInvestor(startupId, user.uid);
        if (!isInvestor) {
          throw new HttpsError(
            "permission-denied",
            "Somente investidores desta startup podem enviar perguntas privadas.",
          );
        }
      }

      const question: StartupQuestionCreateDTO = {
        startupId: startupId,
        authorId: user.uid,
        authorEmail: user.email ?? "Desconhecido",
        text,
        visibility: visibility as QuestionVisibility,
        createdAt: Timestamp.now(),
      };

      const questionId = await createQuestion(question);

      logger.info("Pergunta criada para startup.", {
        startupId,
        questionId,
        visibility,
      });

      return {
        id: questionId,
        authorId: "abc",
        startupId,
        text,
        visibility,
        answers: [],
        createdAt: question.createdAt,
      };
    },
  ),
);
