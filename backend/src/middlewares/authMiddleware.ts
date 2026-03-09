import type { Request, Response, NextFunction } from "express";
import admin from "../config/firebase.js";
import { AppError } from "../errors/AppError.js";

export async function authMiddleware(req: Request, res: Response, next: NextFunction){
  try {
    const token = req.headers.authorization?.split(" ")[1];

    if (!token) {
      throw new AppError({
        message: "Token not provided",
        statusCode: 401
      });
    }

    const decodedToken = await admin.auth().verifyIdToken(token);
    req.uid = decodedToken.uid;

    next();
  } catch (error) {
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