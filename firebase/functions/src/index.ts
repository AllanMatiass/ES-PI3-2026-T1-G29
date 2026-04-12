import { db } from "./firebase";
import * as functions from "firebase-functions";
import { StartupController } from "./controllers/startupController";
import { StartupService } from "./services/startupService";
import { withErrorHandler } from "./middlewares/errorHandler";
import { AppError } from "./errors/AppError";
import { signupFunction } from "./routes/public/authRoutes";

export const seedStartups = functions.https.onRequest(
  withErrorHandler(async (req, res) => {
    const initialTime = Date.now();

    if (req.method !== "POST") {
      throw new AppError({
        message: "Método HTTP não permitido.",
        statusCode: 405,
      });
    }

    const startupController = new StartupController(
      new StartupService(db.collection("startups")),
    );

    await startupController.seedStartups(req, res);

    const duration = (Date.now() - initialTime) / 1000;
    functions.logger.info(`Done in ${duration}s`);
  }),
);

export const signup = functions.https.onRequest(async (req, res) => {
  await signupFunction(req, res);
});
