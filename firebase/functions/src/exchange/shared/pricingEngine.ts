/**
 * Motor de Precificação (Pure Math Functions)
 *
 * Este arquivo contém apenas lógica matemática pura, sem efeitos colaterais.
 * Todos os valores monetários são tratados como inteiros (centavos).
 */

import { PRICING_CONFIG } from "./constants";

/**
 * Aplica a trava de segurança de variação máxima permitida.
 *
 * @param newPriceCents Preço calculado pela fórmula
 * @param currentPriceCents Preço atual do token
 * @param maxDelta Variação máxima permitida (ex: 0.05 para 5%)
 * @returns Preço limitado pelo piso ou teto matemático
 */
export function applySafetyLock(
  newPriceCents: number,
  currentPriceCents: number,
  maxDelta: number = PRICING_CONFIG.deltaMax,
): number {
  const maxPrice = currentPriceCents * (1 + maxDelta);
  const minPrice = currentPriceCents * (1 - maxDelta);

  if (newPriceCents > maxPrice) return maxPrice;
  if (newPriceCents < minPrice) return minPrice;

  return newPriceCents;
}

/**
 * Mercado Primário: Compra direta da startup.
 * Formula: P_novo = P_atual * (1 + (Q_tokens / TotalTokens * K_primario))
 */
export function calculatePrimaryMarketPrice(
  currentPriceCents: number,
  quantity: number,
  totalTokens: number,
  kPrimario: number = PRICING_CONFIG.kPrimario,
): number {
  if (totalTokens === 0) return currentPriceCents;

  const factor = (quantity / totalTokens) * kPrimario;
  const newPrice = currentPriceCents * (1 + factor);

  return applySafetyLock(newPrice, currentPriceCents);
}

/**
 * Mercado Secundário: Troca entre investidores.
 * Formula: P_novo = P_atual * (1 + ((P_oferta - P_atual) / P_atual * Q_tokens / TotalTokens * K_secundario))
 */
export function calculateSecondaryMarketPrice(
  currentPriceCents: number,
  offerPriceCents: number,
  quantity: number,
  totalTokens: number,
  kSecundario: number = PRICING_CONFIG.kSecundario,
): number {
  if (totalTokens === 0 || currentPriceCents === 0) return currentPriceCents;

  const priceDiffFactor =
    (offerPriceCents - currentPriceCents) / currentPriceCents;
  const quantityFactor = quantity / totalTokens;

  const factor = priceDiffFactor * quantityFactor * kSecundario;
  const newPrice = currentPriceCents * (1 + factor);

  return applySafetyLock(newPrice, currentPriceCents);
}

/**
 * Mercado Terciário: Eventos externos.
 * Formula: P_novo = P_atual * (1 + Delta_evento)
 */
export function calculateTertiaryMarketPrice(
  currentPriceCents: number,
  deltaEvent: number,
): number {
  const newPrice = currentPriceCents * (1 + deltaEvent);

  return applySafetyLock(newPrice, currentPriceCents);
}
