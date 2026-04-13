// Autor: Allan Giovanni Matias Paes
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { AppError } from "../errors/AppError";
import { Request, Response } from "firebase-functions/v1";

/**
 * Middleware para tratamento global de erros e verificação de autenticação.
 * @param handler Função que processa a requisição.
 * @param isAuthenticatedRoute Se true, a rota exigirá um token válido.
 */
export function withErrorHandler(
  handler: (req: Request, res: Response) => Promise<void>,
  isAuthenticatedRoute = false,
) {
  return async (req: Request, res: Response): Promise<void> => {
    const now = new Date().toISOString();

    try {
      // Verifica autenticação apenas se a rota for marcada como protegida
      if (isAuthenticatedRoute) {
        const authHeader = req.headers.authorization;

        if (!authHeader || !authHeader.startsWith("Bearer ")) {
          throw new AppError({
            message: "Não autorizado: Token ausente.",
            statusCode: 401,
          });
        }

        const idToken = authHeader.split("Bearer ")[1];

        try {
          // Apenas valida se o token é legítimo
          await admin.auth().verifyIdToken(idToken);
        } catch (authErr) {
          throw new AppError({
            message: "Sessão inválida ou expirada.",
            statusCode: 401,
          });
        }
      }

      // Executa o controller da rota
      await handler(req, res);
    } catch (err) {
      functions.logger.error("Error caught:", err);

      if (err instanceof AppError) {
        res.status(err.statusCode).json({
          success: false,
          error: {
            status: err.statusCode,
            message: err.message,
            timestamp: now,
            path: req.originalUrl || req.get("host"),
          },
        });
        return;
      }

      res.status(500).json({
        success: false,
        error: {
          status: 500,
          message: "Um erro inesperado ocorreu.",
          timestamp: now,
          path: req.originalUrl || req.get("host"),
        },
      });
    }
  };
}
