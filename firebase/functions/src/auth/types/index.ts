// Autor: Allan Giovanni Matias Paes
import { FieldValue, Timestamp } from "firebase-admin/firestore";

export type UserProfile = {
  uid: string;
  name: string;
  email: string;
  cpf: string;
  walletBalance: number;
};

export type UserCreateDTO = UserProfile & {
  createdAt: FieldValue;
};

export type UserEntity = UserProfile & {
  createdAt: Timestamp;
};

export type SignupData = {
  name: string;
  email: string;
  cpf: string;
  phone: string;
  password?: string; // OPCIONAL se for login social, mas obrigatorio para email/pass
};

export type SignupResponse = {
  uid: string;
  name: string;
  email: string;
};
