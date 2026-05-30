/**
 * @description Handler para atualização dos dados de perfil do usuário, como email e telefone.
 * Inclui validações de formato e unicidade.
 * @author Pedro Vinícius Romanato - 25004075
 */

import { onCall, HttpsError } from "firebase-functions/https";
import { withCallHandler } from "../../shared/middlewares/errorHandler";
import { requireAuthenticatedUser } from "../../shared/auth";
import { updateUser, getUserByPhone } from "../repositories/userRepository";
import {
  isEmailValid,
  normalizePhone,
  normalizeString,
} from "../../shared/validation";

/**
 * DTO para a requisição de atualização de perfil.
 */
type Req = { phone?: string; email?: string };

/**
 * Cloud Function para atualizar informações de perfil do usuário autenticado.
 *
 * Fluxo de execução:
 * 1. Verifica autenticação do usuário.
 * 2. Normaliza e valida o novo telefone (se fornecido), garantindo que não esteja em uso por outro UID.
 * 3. Valida o formato básico do email (se fornecido).
 * 4. Persiste as alterações no repositório de usuários.
 */
export const updateUserProfile = onCall(
  withCallHandler<Req, void>(async (request) => {
    // 1. Requer autenticação
    const { uid } = requireAuthenticatedUser(request);

    // 2. Extração e normalização
    const email = normalizeString(request.data.email);
    const phone = normalizePhone(request.data.phone);

    const firestoreUpdates: Record<string, string> = {};

    // 3. Validação e processamento do Telefone
    if (phone !== undefined) {
      const digitsOnly = phone.replace(/\D/g, "");

      // Valida comprimento (DDD + 8 ou 9 dígitos)
      if (digitsOnly.length < 10 || digitsOnly.length > 11) {
        throw new HttpsError("invalid-argument", "Telefone inválido.");
      }

      // Regra de Negócio: Impede duplicidade de telefone no sistema
      const existing = await getUserByPhone(digitsOnly);
      if (existing && existing.uid !== uid) {
        throw new HttpsError(
          "already-exists",
          "Telefone já cadastrado por outro usuário.",
        );
      }

      firestoreUpdates.phone = digitsOnly;
    }

    // 4. Validação e processamento do Email
    if (email !== undefined) {
      if (!isEmailValid(email)) {
        throw new HttpsError("invalid-argument", "Email inválido.");
      }
      firestoreUpdates.email = email;
    }

    // 5. Verifica se há algo para atualizar
    if (!Object.keys(firestoreUpdates).length) {
      throw new HttpsError(
        "invalid-argument",
        "Nenhum campo informado para atualização.",
      );
    }

    // 6. Persistência
    await updateUser(uid, firestoreUpdates);
  }),
);
