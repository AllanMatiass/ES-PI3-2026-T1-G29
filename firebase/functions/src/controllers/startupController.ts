// Autor: Allan Giovanni Matias Paes
import { Request, Response } from "firebase-functions/v1";
import { StartupService } from "../services/startupService";

export class StartupController {
  private startupService: StartupService;

  constructor(startupService: StartupService) {
    this.startupService = startupService;
  }

  async seedStartups(req: Request, res: Response) {
    await this.startupService.seedStartups();

    res.send({
      success: true,
      message: "Startups data created successfully",
    });
  }

  async getAllStartups(req: Request, res: Response) {
    const startups = await this.startupService.getAllStartups();

    res.send({
      success: true,
      data: startups,
    });
  }
}
