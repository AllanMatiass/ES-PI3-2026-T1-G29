import { onCall, HttpsError } from "firebase-functions/https";
import { withCallHandler } from "../../shared/middlewares/errorHandler";
import { requireAuthenticatedUser } from "../../shared/auth";
import { updateUser, getUserByPhone } from "../repositories/userRepository";
import { normalizePhone, normalizeString } from "../../shared/validation";

type Req = { phone?: string; email?: string };

export const updateUserProfile = onCall(
  withCallHandler<Req, void>(async (request) => {
    const { uid } = requireAuthenticatedUser(request);
    const email = normalizeString(request.data.email);
    const phone = normalizePhone(request.data.email);

    const firestoreUpdates: Record<string, string> = {};
    if (phone !== undefined) {
      const d = phone.replace(/\D/g, "");
      if (d.length < 10 || d.length > 11)
        throw new HttpsError("invalid-argument", "Telefone inválido.");

      const existing = await getUserByPhone(d);
      if (existing && existing.uid !== uid)
        throw new HttpsError("already-exists", "Telefone já cadastrado.");

      firestoreUpdates.phone = d;
    }

    if (email !== undefined) {
      if (!email.includes("@"))
        throw new HttpsError("invalid-argument", "Email inválido.");
      firestoreUpdates.email = email;
    }

    if (!Object.keys(firestoreUpdates).length)
      throw new HttpsError("invalid-argument", "Nenhum campo informado.");

    await updateUser(uid, firestoreUpdates);
  }),
);
