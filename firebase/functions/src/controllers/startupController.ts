import { Request, Response } from "firebase-functions/v1";
import * as functions from "firebase-functions";
import { StartupService } from "../services/startupService";

export class StartupController {
  private startupService: StartupService;

  constructor(startupService: StartupService) {
    this.startupService = startupService;
  }

  async seedStartups(req: Request, res: Response) {
    try {
      await this.startupService.seedStartups();
      res.send({ message: "Startups data created successfully" });
    } catch (e) {
      functions.logger.error("Error:", e);
      res.status(500).send("Error creating data");
    }
  }
}
