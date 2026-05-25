// Autor: Allan Giovanni Matias Paes
import * as logger from "firebase-functions/logger";
import { HttpsError, CallableRequest } from "firebase-functions/v2/https";

/**
 * Wrapper para tratamento de erros em funções onCall (v2).
 * Captura erros, loga e garante que HttpsError seja lançado.
 */
export function withCallHandler<T, R>(
  handler: (request: CallableRequest<T>) => Promise<R>,
) {
  return async (request: CallableRequest<T>): Promise<R> => {
    try {
      return await handler(request);
    } catch (err: unknown) {
      logger.error("Error caught in withCallHandler:", {
        uid: request.auth?.uid,
        data: request.data,
        error: err,
      });

      // Firebase Auth error
      if (typeof err === "object" && err !== null && "code" in err) {
        const code = (err as { code: unknown }).code;

        if (typeof code === "string" && code.startsWith("auth/")) {
          throw new HttpsError("unauthenticated", "Erro de autenticação.", {
            authCode: code,
          });
        }
      }

      // HttpsError
      if (err instanceof HttpsError) {
        throw err;
      }

      logger.error(`Error: ${err}`);

      // fallback
      throw new HttpsError("internal", "Erro interno inesperado.");
    }
  };
}
