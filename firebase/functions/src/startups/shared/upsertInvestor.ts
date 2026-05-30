/**
 * @file upsertInvestor.ts
 * @description Função compartilhada para gerenciar a posição de um investidor dentro de uma startup.
 * Esta função é executada dentro de transações do Firestore para garantir a atomicidade dos saldos.
 * @author Allan Giovanni Matias Paes - 25008211
 */

import { db } from "../../shared/firebase";
import { Timestamp } from "firebase-admin/firestore";
import { StartupInvestor } from "../types";

/**
 * Helper para obter a referência da sub-coleção de investidores de uma startup.
 */
const investorsRef = (startupId: string) =>
  db.collection("startups").doc(startupId).collection("investors");

/**
 * Cria ou atualiza o registro de um investidor em uma startup específica.
 *
 * Esta função gerencia o saldo de tokens e o preço médio de aquisição do investidor
 * no contexto da startup, permitindo rastrear quem são os detentores de tokens.
 *
 * @param tx Objeto de transação do Firestore.
 * @param params Dados da operação (IDs, nomes, quantidade de tokens e preço).
 * @param investorSnapshot Opcional: snapshot do investidor já lido anteriormente para evitar RUs extras.
 */
export async function upsertStartupInvestor(
  tx: FirebaseFirestore.Transaction,
  params: {
    startupId: string;
    startupName: string;
    userId: string;
    userName: string;
    qtdTokens: number;
    tokenPriceCents: number;
  },
  investorSnapshot?: FirebaseFirestore.DocumentSnapshot,
) {
  const now = Timestamp.now();
  const ref = investorsRef(params.startupId).doc(params.userId);

  // Recupera o snapshot atual se não for fornecido via parâmetro
  const snap = investorSnapshot || (await tx.get(ref));

  // Valor total da operação atual em centavos
  const investedCents = params.qtdTokens * params.tokenPriceCents;

  /**
   * CENÁRIO 1: PRIMEIRO INVESTIMENTO
   * Se o documento não existe, inicializamos a posição do investidor na startup.
   */
  if (!snap.exists) {
    tx.set(ref, {
      userId: params.userId,
      userName: params.userName,

      startupId: params.startupId,
      startupName: params.startupName,

      totalTokens: params.qtdTokens,
      totalInvestedCents: investedCents,
      averagePriceCents: params.tokenPriceCents, // Preço médio inicial é o preço da compra

      firstInvestmentAt: now,
      lastInvestmentAt: now,
      updatedAt: now,
    } satisfies StartupInvestor);

    return;
  }

  /**
   * CENÁRIO 2: ATUALIZAÇÃO DE INVESTIMENTO (APORTES ADICIONAIS)
   * Se o investidor já possui tokens, recalculamos os totais e o preço médio ponderado.
   */
  const data = snap.data() as StartupInvestor;

  const currentTokens = Number(data.totalTokens) || 0;
  const currentInvested = Number(data.totalInvestedCents) || 0;

  // Novos totais acumulados
  const totalTokens = currentTokens + params.qtdTokens;
  const totalInvestedCents = currentInvested + investedCents;

  /**
   * Cálculo de Preço Médio Ponderado:
   * Representa o custo médio de cada token na carteira do investidor para esta startup específica.
   */
  const averagePriceCents =
    totalTokens > 0 ? totalInvestedCents / totalTokens : 0;

  // Atualiza apenas os campos necessários preservando o histórico de entrada (firstInvestmentAt)
  tx.update(ref, {
    totalTokens,
    totalInvestedCents,
    averagePriceCents: Math.round(averagePriceCents),
    lastInvestmentAt: now,
    updatedAt: now,
  });
}
