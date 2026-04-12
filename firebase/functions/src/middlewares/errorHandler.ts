// Autor: Allan Giovanni Matias Paes
import * as functions from "firebase-functions";
import { AppError } from "../errors/AppError";
import { Request, Response } from "firebase-functions/v1";

// Middleware para tratamento global de erros
// em todas as rotas, garantindo que erros sejam
// logados e respostas padronizadas sejam enviadas.
export function withErrorHandler(
  handler: (req: Request, res: Response) => Promise<void>,
) {
  return async (req: Request, res: Response): Promise<void> => {
    const now = new Date().toISOString();

    // Tenta executar o handler da rota.
    // Se ocorrer um erro, ele é capturado e tratado.
    try {
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
            path: req.get("host"),
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
          path: req.get("host"),
        },
      });
    }
  };
}
