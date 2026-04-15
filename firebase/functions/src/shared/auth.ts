// Autor: Allan Giovanni Matias Paes
import { CallableRequest, HttpsError } from "firebase-functions/https";

export type AuthenticatedUser = {
  uid: string;
  email?: string;
};

export function requireAuthenticatedUser(
  request: CallableRequest,
): AuthenticatedUser {
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "Usuario precisa estar autenticado para acessar esta funcao.",
    );
  }

  return {
    uid: request.auth.uid,
    email: request.auth.token.email as string | undefined,
  };
}
