// Autor: Allan Giovanni Matias Paes
import { HttpsError, onCall } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import { isCPF } from "validation-br";
import { auth } from "../../shared/firebase";
import {
  isEmailValid,
  normalizePhone,
  normalizeString,
} from "../../shared/validation";
import {
  createUserProfile,
  getUserByCpf,
  getUserByPhone,
} from "../../user/repositories/userRepository";
import { withCallHandler } from "../../shared/middlewares/errorHandler";
import { Timestamp } from "firebase-admin/firestore";
import { SignupRequestDTO, SignupResponseDTO } from "../types/dtos";

/**
 * Realiza o cadastro de um novo usuario no MesclaInvest.
 *
 * Esta Funcao e callable e deve ser chamada pelo app com:
 * - `name`: Nome completo.
 * - `email`: E-mail valido.
 * - `cpf`: CPF valido (com ou sem mascara).
 * - `phone`: Número de telefone
 * - `password`: Senha para login.
 *
 * A funcao valida os dados, cria o usuario no Firebase Auth e
 * salva o perfil complementar no Firestore (colecao `users`).
 */
export const signup = onCall(
  withCallHandler<SignupRequestDTO, SignupResponseDTO>(async (request) => {
    const data = request.data;

    const name = normalizeString(data.name);
    const email = normalizeString(data.email);
    const cpf = normalizeString(data.cpf)?.replace(/\D/g, "");
    const phone = normalizePhone(data.phone);
    const password = data.password;

    if (!name || !email || !cpf || !phone || !password) {
      throw new HttpsError(
        "invalid-argument",
        "Todos os campos são obrigatorios: name, email, cpf, phone, password.",
      );
    }

    if (!isEmailValid(email)) {
      throw new HttpsError("invalid-argument", "E-mail inválido.");
    }

    if (!isCPF(cpf)) {
      throw new HttpsError("invalid-argument", "CPF inválido.");
    }

    if (password.length < 6) {
      throw new HttpsError(
        "invalid-argument",
        "A senha deve ter pelo menos 6 caracteres.",
      );
    }

    // Verifica se CPF ja existe
    const existingUserByCpf = await getUserByCpf(cpf);
    if (existingUserByCpf) {
      throw new HttpsError("already-exists", "CPF já cadastrado no sistema.");
    }

    // Verifica se o Número já existe
    const existingUserByPhone = await getUserByPhone(phone);
    if (existingUserByPhone) {
      throw new HttpsError(
        "already-exists",
        "Número de telefone já cadastrado",
      );
    }

    // 1. Criar usuario no Firebase Auth
    const userRecord = await auth.createUser({
      email,
      password,
      phoneNumber: phone,
      displayName: name,
    });

    // 2. Criar perfil no Firestore
    await createUserProfile({
      uid: userRecord.uid,
      name,
      email,
      phone,
      cpf,
      wallet: {
        balanceInCents: 0,
        totalInvestedCents: 0,
        updatedAt: Timestamp.now(),
        positions: [],
      },
      createdAt: Timestamp.now(),
    });

    logger.info("Novo usuario cadastrado com sucesso.", {
      uid: userRecord.uid,
      email,
    });

    return {
      uid: userRecord.uid,
      name,
      email,
    };
  }),
);
