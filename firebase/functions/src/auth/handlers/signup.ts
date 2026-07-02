// Autor: Allan Giovanni Matias Paes - 25008211

import { HttpsError, onCall } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import { Timestamp } from "firebase-admin/firestore";
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
  getUserByEmail,
  getUserByPhone,
} from "../../user/repositories/userRepository";

import { withCallHandler } from "../../shared/middlewares/errorHandler";

import { SignupRequestDTO, SignupResponseDTO } from "../types/dtos";

/**
 * Realiza o cadastro de um novo usuário.
 *
 * Fluxo:
 * 1. Valida e normaliza os dados recebidos.
 * 2. Verifica duplicidade de email, CPF e telefone.
 * 3. Cria usuário no Firebase Authentication.
 * 4. Cria perfil complementar no Firestore.
 * 5. Caso ocorra falha após criação no Auth,
 *    realiza rollback removendo o usuário criado.
 */
export const signup = onCall(
  withCallHandler<SignupRequestDTO, SignupResponseDTO>(async (request) => {
    const data = request.data;

    /**
     * Normalização dos dados.
     * Remove espaços desnecessários e padroniza formatos.
     */
    const name = normalizeString(data.name);
    const email = normalizeString(data.email)?.toLowerCase();
    const cpf = normalizeString(data.cpf)?.replace(/\D/g, "");
    const phone = normalizePhone(data.phone);
    const password = data.password;

    /**
     * Validação de campos obrigatórios.
     */
    if (!name || !email || !cpf || !phone || !password) {
      throw new HttpsError(
        "invalid-argument",
        "Todos os campos são obrigatórios: name, email, cpf, phone e password.",
      );
    }

    /**
     * Validação de email.
     */
    if (!isEmailValid(email)) {
      throw new HttpsError("invalid-argument", "E-mail inválido.");
    }

    /**
     * Validação de CPF.
     */
    if (!isCPF(cpf)) {
      throw new HttpsError("invalid-argument", "CPF inválido.");
    }

    /**
     * Validação mínima de senha.
     */
    if (password.length < 6) {
      throw new HttpsError(
        "invalid-argument",
        "A senha deve possuir pelo menos 6 caracteres.",
      );
    }

    /**
     * Executa consultas em paralelo para reduzir latência.
     */
    const [existingUserByEmail, existingUserByCpf, existingUserByPhone] =
      await Promise.all([
        getUserByEmail(email),
        getUserByCpf(cpf),
        getUserByPhone(phone),
      ]);

    /**
     * Verifica duplicidade de email.
     */
    if (existingUserByEmail) {
      throw new HttpsError(
        "already-exists",
        "E-mail já cadastrado no sistema.",
      );
    }

    /**
     * Verifica duplicidade de CPF.
     */
    if (existingUserByCpf) {
      throw new HttpsError("already-exists", "CPF já cadastrado no sistema.");
    }

    /**
     * Verifica duplicidade de telefone.
     */
    if (existingUserByPhone) {
      throw new HttpsError(
        "already-exists",
        "Número de telefone já cadastrado.",
      );
    }

    const now = Timestamp.now();

    /**
     * Variável utilizada para rollback caso
     * ocorra erro após criação no Firebase Auth.
     */
    let createdUserUid: string | null = null;

    try {
      /**
       * Cria usuário no Firebase Authentication.
       */
      const userRecord = await auth.createUser({
        email,
        password,
        phoneNumber: phone,
        displayName: name,
      });

      createdUserUid = userRecord.uid;

      /**
       * Cria perfil complementar no Firestore.
       */
      await createUserProfile({
        uid: userRecord.uid,
        name,
        email,
        phone,
        cpf,

        wallet: {
          balanceInCents: 0,
          totalInvestedCents: 0,
          updatedAt: now,
          positions: [],
        },

        createdAt: now,
      });

      /**
       * Log de sucesso.
       */
      logger.info("Usuário cadastrado com sucesso.", {
        uid: userRecord.uid,
        email,
      });

      /**
       * Retorno da função.
       */
      return {
        uid: userRecord.uid,
        name,
        email,
      };
    } catch (error) {
      /**
       * Rollback:
       * Remove usuário do Auth caso o Firestore falhe.
       */
      if (createdUserUid) {
        try {
          await auth.deleteUser(createdUserUid);

          logger.warn("Rollback realizado após falha no cadastro.", {
            uid: createdUserUid,
          });
        } catch (rollbackError) {
          logger.error("Erro ao realizar rollback do usuário.", rollbackError);
        }
      }

      /**
       * Repassa erro para middleware global.
       */
      throw error;
    }
  }),
);