/**
 * @file getStartupQuestions.ts
 * @description Handler para listagem de perguntas (públicas e privadas) de uma startup.
 * @author Vinícius Castro - 25002026
 */

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

/**
 * Cloud Function para listar as perguntas direcionadas a uma startup.
 *
 * O comportamento da listagem varia conforme o perfil do usuário:
 * - Investidores da startup: Veem perguntas públicas e as suas próprias perguntas privadas.
 * - Não-investidores: Veem apenas as perguntas marcadas como públicas.
 *
 * Fluxo de execução:
 * 1. Autentica o usuário solicitante.
 * 2. Valida a existência da startup pelo ID fornecido.
 * 3. Verifica se o usuário é um investidor ativo na startup.
 * 4. Recupera as perguntas do repositório, aplicando filtros de visibilidade conforme o status do usuário.
 * 5. Mapeia e retorna os dados formatados.
 */
export const getStartupQuestions = onCall(
  withCallHandler<GetStartupIdRequest, GetStartupQuestionsResponse>(
    async (request) => {
      // 1. Requer autenticação
      const user = requireAuthenticatedUser(request);
      const { id } = request.data;

      // 2. Normalização e Validação do ID
      const startupId = normalizeString(id);

      if (!startupId) {
        throw new HttpsError("invalid-argument", "Informe o startupId.");
      }

      // 3. Verifica existência da startup
      const startup = await getStartupById(startupId);

      if (!startup) {
        throw new HttpsError("not-found", "Startup não encontrada.");
      }

      // 4. Determina privilégios de acesso
      const isInvestor = await userIsInvestor(startupId, user.uid);

      // 5. Recuperação das perguntas
      // A função listStartupQuestions encapsula a lógica de filtrar perguntas privadas
      const rawQuestions = await listStartupQuestions(startupId, isInvestor);

      // 6. Formatação da Resposta
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
