// Autor: Allan Giovanni Matias Paes - 25008211
import { HttpsError } from "firebase-functions/https";
import { UserProfile } from "../types";
import { getUserById } from "../repositories/userRepository";
import { auth } from "../../shared/firebase";

export class UserService {
  async get(uid: string): Promise<UserProfile> {
    const user = await getUserById(uid);
    if (!user) {
      // se isso aconteceu, é por que não tem registro no firestore mas tem no auth, então deletamos.
      await auth.deleteUser(uid);
      throw new HttpsError("not-found", "Usuário não encontrado");
    }
    return user;
  }
}
