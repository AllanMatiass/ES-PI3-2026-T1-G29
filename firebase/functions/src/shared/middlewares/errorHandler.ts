import * as logger from "firebase-functions/logger";
import {
  HttpsError,
  FunctionsErrorCode,
  CallableRequest,
} from "firebase-functions/v2/https";
import { ApiResponse } from "../types";

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

export function withCallHandler<T, R>(
  handler: (request: CallableRequest<T>) => Promise<R>,
) {
  return async (request: CallableRequest<T>): Promise<ApiResponse<R>> => {
    try {
      const result = await handler(request);

      return {
        success: true,
        data: result,
      };
    } catch (err: unknown) {
      logger.error("Error caught in withCallHandler:", {
        uid: request.auth?.uid,
        data: request.data,
        error: err,
      });

      //Firebase Auth error
      if (typeof err === "object" && err !== null && "code" in err) {
        const code = (err as { code: string }).code;

        if (code.startsWith("auth/")) {
          return {
            success: false,
            error: {
              code,
              message: "Erro de autenticação.",
              status: 400,
            },
          };
        }
      }

      // HttpsError
      if (err instanceof HttpsError) {
        return {
          success: false,
          error: {
            code: err.code,
            message: err.message,
            status: errorCodeMap[err.code] || 500,
          },
        };
      }

      // fallback
      return {
        success: false,
        error: {
          code: "internal",
          message: "Erro interno inesperado.",
          status: 500,
        },
      };
    }
  };
}
