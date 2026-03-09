import type { NextFunction, Request, Response } from "express";
import { AppError } from "../errors/AppError.js";
import type { ApiErrorResponse, ApiResponse } from "../types/http.js";


export function errorHandler(
  err: Error,
  req: Request,
  res: Response,
  _next: NextFunction
) {
  const now = new Date().toISOString();
  if (err instanceof AppError) {
    const error = {
      status: err.statusCode,
      message: err.message,
      timestamp: now,
      path: req.originalUrl
    } as ApiErrorResponse;

    const body = {
      success: false,
      error
    } as ApiResponse<void>;

    

    return res.status(err.statusCode).json(body);
  }

  const internalError = {
    status: 500,
    message: "An unexpected error occurred",
    timestamp: now,
    path: req.originalUrl
  } as ApiErrorResponse;

  console.log(err.message);
  return res.status(500).json({
    success: false,
    error: internalError
  } as ApiResponse<void>);
}