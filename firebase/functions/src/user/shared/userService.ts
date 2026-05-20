import { HttpsError } from "firebase-functions/https";
import { UserProfile } from "../types";
import { getUserById, listInvestments } from "../repositories/userRepository";
import {
  GetUserInvestmentsRequestDTO,
  PaginatedInvestmentsResponseDTO,
} from "../types/dtos";

export class UserService {
  async get(uid: string): Promise<UserProfile> {
    const user = await getUserById(uid);
    if (!user) throw new HttpsError("not-found", "Usuário não encontrado");
    return user;
  }

  async getUserInvestments(
    userId: string,
    data: GetUserInvestmentsRequestDTO,
  ): Promise<PaginatedInvestmentsResponseDTO> {
    const { limit, lastStartupId } = data;

    const normalizedLimit =
      limit && Number.isInteger(limit) && limit > 0 && limit <= 50 ? limit : 20;

    return listInvestments(userId, normalizedLimit, lastStartupId);
  }
}
