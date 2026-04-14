import { FieldValue } from "firebase-admin/firestore";
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
import { QuestionVisibility, StartupQuestionDocument } from "../types";

import { withCallHandler } from "../../shared/middlewares/errorHandler";

/**
 * Cria uma pergunta para uma startup.
...
 * - `visibility`: visibilidade opcional (`publica` ou `privada`).
 *
 * Perguntas publicas podem ser enviadas por qualquer usuario autenticado.
 * Perguntas privadas exigem que o usuario tenha um documento em:
 * `startups/{startupId}/investors/{uid}`.
 */
export const createStartupQuestion = onCall(
  withCallHandler(async (request) => {
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

    const question: StartupQuestionDocument = {
      authorId: user.uid,
      authorEmail: user.email,
      text,
      visibility: visibility as QuestionVisibility,
      createdAt: FieldValue.serverTimestamp(),
    };

    const questionId = await createQuestion(startupId, question);

    logger.info("Pergunta criada para startup.", {
      startupId,
      questionId,
      visibility,
    });

    return {
      data: {
        id: questionId,
        startupId,
        visibility,
      },
    };
  }),
);
