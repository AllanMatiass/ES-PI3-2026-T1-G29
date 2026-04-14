import { HttpsError, onCall } from "firebase-functions/v2/https";
import { requireAuthenticatedUser } from "../../shared/auth";
import { normalizeString } from "../../shared/validation";
import {
  getStartupById,
  listPublicQuestions,
  userIsInvestor,
} from "../repositories/startupRepository";
import { withCallHandler } from "../../shared/middlewares/errorHandler";

/**
 * Busca os dados completos de uma startup especifica.
 *
 * Esta Funcao e callable e deve ser chamada pelo app com:
 *
 * - `id`: identificador da startup no Firestore.
 *
 * A funcao exige autenticacao e retorna a visao detalhada do item 5.2:
 *
 * - sumario executivo, estrutura societaria, membros externos, videos,
 * - perguntas publicas e flags de acesso para novos investidores.
 */
export const getStartupDetails = onCall(
  withCallHandler(async (request) => {
    const user = requireAuthenticatedUser(request);

    const startupId = normalizeString(request.data?.id);

    if (!startupId) {
      throw new HttpsError("invalid-argument", "Informe o id da startup.");
    }

    const startup = await getStartupById(startupId);

    if (!startup) {
      throw new HttpsError("not-found", "Startup nao encontrada.");
    }

    const isInvestor = await userIsInvestor(startupId, user.uid);
    const questions = await listPublicQuestions(startupId);

    return {
      data: {
        id: startupId,
        ...startup,
        createdAt: startup.createdAt?.toDate().toISOString() ?? null,
        updatedAt: startup.updatedAt?.toDate().toISOString() ?? null,
        publicQuestions: questions,
        access: {
          isInvestor,
          canTradeTokens: isInvestor,
          canSendPrivateQuestions: isInvestor,
        },
      },
    };
  }),
);
