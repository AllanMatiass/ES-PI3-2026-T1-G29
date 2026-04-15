import { HttpsError } from "firebase-functions/https";

export function normalizeString(value: unknown): string | undefined {
  if (typeof value !== "string") {
    return undefined;
  }

  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : undefined;
}

export function isEmailValid(email: string): boolean {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
}

export function normalizePhone(phone: string | undefined): string {
  const normalize = normalizeString(phone);
  if (!normalize) throw new HttpsError("invalid-argument", "Telefone inválido");

  const digits = normalize.replace(/\D/g, "");

  if (!digits.startsWith("55")) {
    return `+55${digits}`;
  }

  return `+${digits}`;
}
