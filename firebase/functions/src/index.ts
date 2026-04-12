import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { StartupController } from "./controllers/startupController";
import { StartupService } from "./services/startupService";
import { withErrorHandler } from "./middlewares/errorHandler";
import { AppError } from "./errors/AppError";

const app = admin.initializeApp();
const db = app.firestore();
const startupsCollection = db.collection("startups");

const startupController = new StartupController(
  new StartupService(startupsCollection),
);

export const seedStartups = functions.https.onRequest(
  withErrorHandler(async (req, res) => {
    const initialTime = Date.now();

    if (req.method !== "POST") {
      throw new AppError({
        message: "Method Not Allowed",
        statusCode: 405,
      });
    }

    await startupController.seedStartups(req, res);

    const duration = (Date.now() - initialTime) / 1000;
    functions.logger.info(`Done in ${duration}s`);
  }),
);
