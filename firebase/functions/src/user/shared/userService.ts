import { HttpsError } from "firebase-functions/https";
import { UserProfile } from "../types";
import { getUserById } from "../repositories/userRepository";

export class UserService {
    async get(uid: string): Promise<UserProfile> {
        const user = await getUserById(uid);
        if (!user) throw new HttpsError("not-found", "Usuário não encontrado");
        return user;
    }
}