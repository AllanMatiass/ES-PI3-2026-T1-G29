import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { StartupController } from "./controllers/startupController";
import { StartupService } from "./services/startupService";

const app = admin.initializeApp();
const db = app.firestore();
const startupsCollection = db.collection("startups");

const startupController = new StartupController(
  new StartupService(startupsCollection),
);

export const seedStartups = functions.https.onRequest(async (req, res) => {
  const initialTime = Date.now();
  functions.logger.info("Seeding startups data...");

  if (req.method !== "POST") {
    res.status(405).send("Method Not Allowed");
    return;
  }

  await startupController.seedStartups(req, res);

  const endTime = Date.now();
  const duration = (endTime - initialTime) / 1000;
  functions.logger.info(`Data seeding completed in ${duration} seconds`);
});
