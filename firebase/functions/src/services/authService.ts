// Autor: Allan Giovanni Matias Paes

import { isCPF } from "validation-br";
import { CreateUserDTO } from "../models/userModels";
import * as admin from "firebase-admin";
import { AppError } from "../errors/AppError";
import { isEmailValid } from "../validations/authValidations";
import { logger } from "firebase-functions";

export class AuthService {
  private usersCollection: FirebaseFirestore.CollectionReference;

  constructor(usersCollection: FirebaseFirestore.CollectionReference) {
    this.usersCollection = usersCollection;
  }

  // Método para criar um novo usuário
  async createUser(dto: CreateUserDTO) {
    const { email, password, name, cpf } = dto;
    const normalizedCpf = cpf.replace(/\D/g, ""); // Remove caracteres não numéricos

    if (!isCPF(normalizedCpf)) {
      throw new AppError({
        message: "CPF inválido",
        statusCode: 400,
      });
    }

    if (!isEmailValid(email)) {
      throw new AppError({
        message: "Email inválido",
        statusCode: 400,
      });
    }

    const userRecord = await admin.auth().createUser({
      email,
      password,
      displayName: name,
    });

    await this.usersCollection.doc(userRecord.uid).set({
      name,
      email,
      cpf: normalizedCpf,
      walletBalance: 0,
      createdAt: new Date(),
    });

    logger.info(`User created with UID: ${userRecord.uid}`);
    return {
      id: userRecord.uid,
      name,
      email,
      cpf: normalizedCpf,
    };
  }
}
