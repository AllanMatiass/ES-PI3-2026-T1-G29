// Autor: Allan Giovanni Matias Paes - 25008211
import { HttpsError } from "firebase-functions/https";

/**
 * Normaliza um valor garantindo que seja uma string válida e sem espaços em branco nas extremidades.
 * Muito útil para sanitizar inputs de formulários antes de salvar no Firestore, evitando strings vazias fantasmas ("   ").
 * * @param {unknown} value - O valor recebido, tipado como unknown para permitir validação de payloads brutos.
 * @returns {string | undefined} A string sanitizada, ou undefined caso não seja string ou seja vazia.
 */
export function normalizeString(value: unknown): string | undefined {
  // Primeiramente, bloqueia qualquer tipo que não seja texto (números, objetos, nulos)
  if (typeof value !== "string") {
    return undefined;
  }

  // Remove espaços no início e no fim da string
  const trimmed = value.trim();

  // Retorna o texto caso tenha sobrado algum caractere válido, senão descarta (undefined)
  return trimmed.length > 0 ? trimmed : undefined;
}

/**
 * Verifica se uma string possui o formato válido de um endereço de e-mail.
 * * @param {string} email - O endereço de e-mail a ser validado.
 * @returns {boolean} True se for um e-mail válido, False caso contrário.
 */
export function isEmailValid(email: string): boolean {
  // Regex básico para validação:
  // Exige que haja caracteres sem espaços antes do @, depois do @ e depois do ponto.
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
}

/**
 * Normaliza um número de telefone, extraindo apenas os números e garantindo o padrão internacional (E.164).
 * Por padrão, se o usuário não inserir um DDI, assume-se que é um número do Brasil (+55).
 * * @param {string | undefined} phone - O telefone cru (pode vir com parênteses, traços, etc).
 * @returns {string} O telefone padronizado (ex: +5511999999999).
 * @throws {HttpsError} Lança erro de argumento inválido se não houver um input utilizável.
 */
export function normalizePhone(phone: string | undefined): string {
  // Reaproveita a função de normalização para limpar a string inicial
  const normalize = normalizeString(phone);

  if (!normalize) throw new HttpsError("invalid-argument", "Telefone inválido");

  // Utiliza Regex (\D) para remover TUDO o que não for um dígito numérico
  const digits = normalize.replace(/\D/g, "");

  // Se o número limpo não começa com o DDI do Brasil (55), adiciona ele automaticamente
  if (!digits.startsWith("55")) {
    return `+55${digits}`;
  }

  // Se já possuir o 55, apenas injeta o sinal de mais (+) exigido por serviços de mensageria (como Twilio/WhatsApp)
  return `+${digits}`;
}
