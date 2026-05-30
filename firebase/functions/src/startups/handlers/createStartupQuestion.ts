/**
 * @file createStartupQuestion.ts
 * @description Handler para criação de perguntas direcionadas a startups.
 * @author Vinícius Castro - 25002026
 */

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

/**
 * Function para criar uma nova pergunta para uma startup.
 *
 * Fluxo de execução:
 * 1. Verifica se o usuário está autenticado.
 * 2. Normaliza e valida os dados de entrada (startupId, texto, visibilidade).
 * 3. Verifica a existência da startup.
 * 4. Valida se perguntas privadas são enviadas apenas por investidores da startup.
 * 5. Persiste a pergunta no Firestore.
 * 6. Retorna os detalhes da pergunta criada.
 */
export const createStartupQuestion = onCall(
  withCallHandler<StartupQuestionCreateDTO, QuestionResponseDTO>(
    async (request) => {
      // 1. Requer autenticação do usuário
      const user = requireAuthenticatedUser(request);

      // 2. Extração e normalização dos dados
      const startupId = normalizeString(request.data?.startupId);
      const text = normalizeString(request.data?.text);
      const visibility = (normalizeString(request.data?.visibility) ??
        "publica") as QuestionVisibility;

      // 3. Validação de campos obrigatórios
      if (!startupId || !text) {
        throw new HttpsError("invalid-argument", "Informe startupId e text.");
      }

      // 4. Validação de visibilidade permitida
      if (!allowedVisibilities.includes(visibility as QuestionVisibility)) {
        throw new HttpsError(
          "invalid-argument",
          "Visibilidade invalida. Use publica ou privada.",
        );
      }

      // 5. Verifica se a startup existe no banco
      const startup = await getStartupById(startupId);

      if (!startup) {
        throw new HttpsError("not-found", "Startup nao encontrada.");
      }

      // 6. Regra de Negócio: Perguntas privadas exigem que o usuário seja investidor da startup
      const isInvestor = await userIsInvestor(startupId, user.uid);
      if (visibility === "privada" && !isInvestor) {
        throw new HttpsError(
          "permission-denied",
          "Somente investidores desta startup podem enviar perguntas privadas.",
        );
      }

      // 7. Preparação do objeto de criação
      const question: StartupQuestionCreateDTO = {
        startupId: startupId,
        authorId: user.uid,
        authorEmail: user.email ?? "Desconhecido",
        text,
        visibility: visibility as QuestionVisibility,
        createdAt: Timestamp.now(),
      };

      // 8. Persistência no repositório
      const questionId = await createQuestion(question);

      logger.info("Pergunta criada para startup.", {
        startupId,
        questionId,
        visibility,
      });

      // 9. Retorno formatado de acordo com o DTO de resposta
      return {
        id: questionId,
        authorId: user.uid,
        startupId,
        text,
        visibility,
        answers: [],
        createdAt: question.createdAt,
      };
    },
  ),
);
