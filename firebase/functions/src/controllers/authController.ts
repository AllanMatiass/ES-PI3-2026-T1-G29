import { Request, Response } from "firebase-functions/v1";
import { AuthService } from "../services/authService";
import { AppError } from "../errors/AppError";

export class AuthController {
  private authService: AuthService;

  constructor(authService: AuthService) {
    this.authService = authService;
  }

  async createUser(req: Request, res: Response) {
    const { email, password, name, cpf } = req.body;
    if (!email || !password || !name || !cpf) {
      throw new AppError({
        message:
          "Todos os campos são obrigatórios. (email, password, name, cpf)",
        statusCode: 400,
      });
    }

    const userResponse = await this.authService.createUser({
      email,
      password,
      name,
      cpf,
    });

    return res.status(201).json({
      success: true,
      data: userResponse,
    });
  }
}
