
import "express";

declare global {
  namespace Express {
    interface Request {
      uid?: string;
    }
  }
}