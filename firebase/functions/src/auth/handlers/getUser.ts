import { HttpsError, onCall } from "firebase-functions/https";
import { withCallHandler } from "../../shared/middlewares/errorHandler";
import { UserProfile } from "../types";
import { requireAuthenticatedUser } from "../../shared/auth";
import { getUserById } from "../repositories/userRepository";

export const getUser = onCall(
  withCallHandler<void, UserProfile>(async (request) => {
    const uid = requireAuthenticatedUser(request).uid;
    const user = await getUserById(uid);
    if (!user) throw new HttpsError("not-found", "Usuário não encontrado");
    return user;
  }),
);
