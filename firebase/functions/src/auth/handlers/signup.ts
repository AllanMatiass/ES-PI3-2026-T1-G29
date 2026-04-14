import { HttpsError, onCall } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import { isCPF } from "validation-br";
import { auth } from "../../shared/firebase";
import { isEmailValid, normalizeString } from "../../shared/validation";
import {
  createUserProfile,
  getUserByCpf,
} from "../repositories/userRepository";
import { SignupData } from "../types";
import { withCallHandler } from "../../shared/middlewares/errorHandler";

/**
 * Realiza o cadastro de um novo usuario no MesclaInvest.
 *
 * Esta Funcao e callable e deve ser chamada pelo app com:
 * - `name`: Nome completo.
 * - `email`: E-mail valido.
 * - `cpf`: CPF valido (com ou sem mascara).
 * - `password`: Senha para login.
 *
 * A funcao valida os dados, cria o usuario no Firebase Auth e
 * salva o perfil complementar no Firestore (colecao `users`).
 */
export const signup = onCall(
  withCallHandler(async (request) => {
    const data = request.data as SignupData;

    const name = normalizeString(data.name);
    const email = normalizeString(data.email);
    const cpf = normalizeString(data.cpf)?.replace(/\D/g, "");
    const password = data.password;

    if (!name || !email || !cpf || !password) {
      throw new HttpsError(
        "invalid-argument",
        "Todos os campos sao obrigatorios: name, email, cpf, password.",
      );
    }

    if (!isEmailValid(email)) {
      throw new HttpsError("invalid-argument", "E-mail invalido.");
    }

    if (!isCPF(cpf)) {
      throw new HttpsError("invalid-argument", "CPF invalido.");
    }

    if (password.length < 6) {
      throw new HttpsError(
        "invalid-argument",
        "A senha deve ter pelo menos 6 caracteres.",
      );
    }

    // Verifica se CPF ja existe (o Firebase Auth ja cuida do e-mail duplicado)
    const existingUserByCpf = await getUserByCpf(cpf);
    if (existingUserByCpf) {
      throw new HttpsError("already-exists", "CPF ja cadastrado no sistema.");
    }

    try {
      // 1. Criar usuario no Firebase Auth
      const userRecord = await auth.createUser({
        email,
        password,
        displayName: name,
      });

      // 2. Criar perfil no Firestore
      await createUserProfile({
        uid: userRecord.uid,
        name,
        email,
        cpf,
        walletBalance: 0,
        createdAt: new Date(),
      });

      logger.info("Novo usuario cadastrado com sucesso.", {
        uid: userRecord.uid,
        email,
      });

      return {
        data: {
          uid: userRecord.uid,
          name,
          email,
        },
      };
    } catch (error: any) {
      logger.error("Erro ao realizar signup.", error);

      if (error.code === "auth/email-already-exists") {
        throw new HttpsError("already-exists", "E-mail ja cadastrado.");
      }

      throw new HttpsError("internal", "Erro interno ao processar cadastro.");
    }
  }),
);
