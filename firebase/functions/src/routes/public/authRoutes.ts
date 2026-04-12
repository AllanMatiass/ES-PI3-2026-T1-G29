import { withErrorHandler } from "../../middlewares/errorHandler";
import { AppError } from "../../errors/AppError";
import { AuthController } from "../../controllers/authController";
import { AuthService } from "../../services/authService";
import * as admin from "firebase-admin";
import { logger } from "firebase-functions";

export const signupFunction = withErrorHandler(async (req, res) => {
  const initialTime = Date.now();

  if (req.method !== "POST") {
    throw new AppError({
      message: "Método HTTP não permitido.",
      statusCode: 405,
    });
  }

  const authController = new AuthController(
    new AuthService(admin.firestore().collection("users")),
  );

  await authController.createUser(req, res);

  const duration = (Date.now() - initialTime) / 1000;
  logger.info(`Done in ${duration}s`);
});
