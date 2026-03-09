// Autor: Allan Giovanni Matias Paes
import type { Request, Response, NextFunction } from "express";
import admin from "../config/firebase.js";
import { AppError } from "../errors/AppError.js";

// Função pra ver quem está autenticado e suas autorizações
export async function authMiddleware(req: Request, res: Response, next: NextFunction){
  try {
    const token = req.headers.authorization?.split(" ")[1];


    // Se não tiver mandado um bearer token, lança erro
    if (!token) {
      throw new AppError({
        message: "Token not provided",
        statusCode: 401
      });
    }

    // Caso esteja correto, o firebase verifica o token e retorna o uid de quem está autenticado.
    const decodedToken = await admin.auth().verifyIdToken(token);
    req.uid = decodedToken.uid;

    next();
  } catch (error) {
    // Se for um erro customizado (AppError) lançado em qualquer situação 
    // no código acima, ele retorna um body e um statusCode que está definido no momento do lançamento do erro.
    if (error instanceof AppError) {
      return res.status(error.statusCode).json({
        success: false,
        error: {
          status: error.statusCode,
          message: error.message,
          timestamp: new Date().toISOString(),
          path: req.path
        }
      });
    }

    // Se não for um erro customizado, assumimos que o token está expirado.
    res.status(401).json({
      success: false,
      error: {
        status: 401,
        message: "Invalid or expired token",
        timestamp: new Date().toISOString(),
        path: req.path
      }
    });
  }
}