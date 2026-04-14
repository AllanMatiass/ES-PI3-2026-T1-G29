import * as logger from "firebase-functions/logger";
import {
  HttpsError,
  FunctionsErrorCode,
  CallableRequest,
} from "firebase-functions/v2/https";

/**
 * Mapeia códigos de erro do Firebase Functions para Status HTTP.
 */
const errorCodeMap: Record<FunctionsErrorCode, number> = {
  ok: 200,
  cancelled: 499,
  unknown: 500,
  "invalid-argument": 400,
  "deadline-exceeded": 504,
  "not-found": 404,
  "already-exists": 409,
  "permission-denied": 403,
  "resource-exhausted": 429,
  "failed-precondition": 400,
  aborted: 409,
  "out-of-range": 400,
  unimplemented: 501,
  internal: 500,
  unavailable: 503,
  "data-loss": 500,
  unauthenticated: 401,
};

/**
 * Wrapper para tratamento de erros em funções onCall (v2).
 * Captura erros, loga e garante que HttpsError seja retornado.
 */
export function withCallHandler(
  handler: (request: CallableRequest<any>) => Promise<any>,
) {
  return async (request: CallableRequest<any>): Promise<any> => {
    try {
      return await handler(request);
    } catch (err) {
      logger.error("Error caught in withCallHandler:", {
        uid: request.auth?.uid,
        data: request.data,
        error: err,
      });

      if (err instanceof HttpsError) {
        return {
          success: false,
          error: {
            status: errorCodeMap[err.code] || 500,
            code: err.code,
            message: err.message,
          },
        };
      }

      return {
        success: false,
        error: {
          status: 500,
          code: "internal",
          message: "Um erro interno inesperado ocorreu.",
        },
      };
    }
  };
}
