/**
 * @description Serviço responsável pela reconstrução histórica e análise de valorização do portfólio do usuário.
 * Este serviço utiliza algoritmos de "rewind" para calcular o patrimônio em pontos passados do tempo.
 * @author Allan Giovanni Matias Paes - 25008211
 */

import { Timestamp } from "firebase-admin/firestore";
import { getTransactionsByUserId } from "../../exchange/repositories/transactionRepository";
import {
  getValuationHistory,
  getStartupsByIds,
} from "../../startups/repositories/startupRepository";
import { getUserById } from "../repositories/userRepository";
import {
  GetUserTokenValuationsResponse,
  PortfolioRange,
  PortfolioHistoryPoint,
} from "../types/dtos";
import { StartupDocumentDTO } from "../../startups/types/dtos";
import { HttpsError } from "firebase-functions/https";

/**
 * Service que processa o valor de mercado e a performance financeira dos ativos do usuário.
 */
export class ValuationService {
  /**
   * reconstrói o histórico do portfólio do usuário para um determinado período (range).
   *
   * Lógica de Reconstrução Histórica:
   * 1. Obtém o estado ATUAL da carteira e todas as transações passadas.
   * 2. Gera pontos no tempo (timestamps) retroativos baseados no range.
   * 3. Para cada ponto (do presente para o passado), "desfaz" as transações futuras àquele ponto.
   * 4. Multiplica a quantidade de tokens "reconstruída" pelo preço de mercado da época.
   *
   * @param userId UID do investidor.
   * @param range Período de análise (1D, 1W, 1M, 1Y, YTD).
   */
  async getUserPortfolioHistory(
    userId: string,
    range: PortfolioRange,
  ): Promise<GetUserTokenValuationsResponse> {
    // 1. Carga de Dados Base
    const user = await getUserById(userId);
    if (!user) {
      throw new HttpsError("not-found", "Usuário não encontrado.");
    }

    const transactions = await getTransactionsByUserId(userId);
    const timestamps = this.generateTimestamps(range || "1M");

    if (timestamps.length === 0) {
      throw new HttpsError(
        "not-found",
        "Não foi possível gerar pontos no tempo para este período.",
      );
    }

    // 2. Identificação de ativos históricos (Startups que o usuário possui ou já possuiu)
    const startupIds = new Set<string>();
    user.wallet.positions.forEach((p) => {
      if (p.startupId) startupIds.add(p.startupId);
    });
    transactions.forEach((t) => {
      if (t.startupId) startupIds.add(t.startupId);
    });

    const startupIdsArray = Array.from(startupIds);

    // Busca paralela de metadados de startups e seus históricos de valuation
    const [startups, ...valuationsHistory] = await Promise.all([
      getStartupsByIds(startupIdsArray),
      ...startupIdsArray.map((id) =>
        getValuationHistory(
          id,
          timestamps[timestamps.length - 1], // Data mais antiga do range
          timestamps[0], // Data mais recente (hoje)
          1000,
        ),
      ),
    ]);

    const startupsMap = new Map<string, StartupDocumentDTO>();
    startups.forEach((s, index) => {
      if (s) startupsMap.set(startupIdsArray[index], s);
    });

    const valuationsMap = new Map<
      string,
      { value: number; createdAt: Timestamp }[]
    >();

    startupIdsArray.forEach((id, index) => {
      valuationsMap.set(id, valuationsHistory[index]);
    });

    const history: PortfolioHistoryPoint[] = [];

    // 3. Algoritmo de "Rewind" (Reconstrução do passado)
    // Inicializamos com as posses ATUAIS (estado final do banco)
    const currentHoldings = new Map<string, number>();
    user.wallet.positions.forEach((p) => {
      currentHoldings.set(p.startupId, p.qtdTokens);
    });

    // Ordenamos transações decrescentemente (mais recentes primeiro) para desfazê-las uma a uma
    const sortedTransactions = [...transactions].sort(
      (a, b) => b.createdAt.toMillis() - a.createdAt.toMillis(),
    );

    let transactionIndex = 0;

    // Iteramos pelos pontos no tempo (da data atual para a data mais antiga)
    for (const point of timestamps) {
      const pointMillis = point.getTime();

      // "Desfazemos" transações que ocorreram APÓS este ponto no tempo
      while (
        transactionIndex < sortedTransactions.length &&
        sortedTransactions[transactionIndex].createdAt.toMillis() > pointMillis
      ) {
        const tx = sortedTransactions[transactionIndex];
        const isBuyer = tx.buyer.id === userId;
        const isSeller = tx.seller?.id === userId;

        if (isBuyer) {
          // Se o usuário comprou após este ponto, no passado ele tinha MENOS tokens
          const currentQty = currentHoldings.get(tx.startupId) || 0;
          currentHoldings.set(tx.startupId, currentQty - tx.qtdTokens);
        } else if (isSeller) {
          // Se o usuário vendeu após este ponto, no passado ele tinha MAIS tokens
          const currentQty = currentHoldings.get(tx.startupId) || 0;
          currentHoldings.set(tx.startupId, currentQty + tx.qtdTokens);
        }
        transactionIndex++;
      }

      // 4. Cálculo do valor do patrimônio no ponto específico
      let portfolioValue = 0;
      currentHoldings.forEach((qty, startupId) => {
        if (qty <= 0) return;

        const startup = startupsMap.get(startupId);
        if (!startup) return;

        // Recupera o preço do token que estava vigente naquele timestamp
        const price = this.getPriceAtTimestamp(
          point,
          valuationsMap.get(startupId) || [],
          startup,
        );
        portfolioValue += qty * price;
      });

      history.push({
        timestamp: point.toISOString(),
        valueCents: Math.round(portfolioValue),
      });
    }

    // Inverte o histórico para devolver ordem cronológica (antigo -> novo)
    const chronologicalHistory = history.reverse();
    const latestValue =
      chronologicalHistory[chronologicalHistory.length - 1].valueCents;

    /**
     * CÁLCULO DE VALORIZAÇÃO REAL (ROI):
     * Em vez de comparar apenas o início e fim do gráfico, calculamos o lucro real
     * comparando o valor atual dos ativos com o total investido (custo médio ponderado).
     * Isso fornece uma visão real de ganho/perda de capital (PnL).
     */
    const totalInvested = user.wallet.totalInvestedCents;
    const variationCents = latestValue - totalInvested;
    const variationPercent =
      totalInvested === 0
        ? 0
        : Number(((variationCents / totalInvested) * 100).toFixed(2));

    return {
      range,
      currency: "BRL",
      totalValueCents: latestValue,
      variationCents,
      variationPercent,
      history: chronologicalHistory,
    };
  }

  /**
   * Gera a lista de marcos temporais retroativos com base no período solicitado.
   */
  private generateTimestamps(range: PortfolioRange): Date[] {
    const points: Date[] = [];
    const now = new Date();

    switch (range) {
      // 24h
      case "1D": {
        for (let i = 0; i <= 24; i++) {
          const d = new Date(now);
          d.setHours(d.getHours() - i);
          points.push(d);
        }
        break;
      }
      // diário
      case "1W": {
        for (let i = 0; i <= 7; i++) {
          const d = new Date(now);
          d.setDate(d.getDate() - i);
          points.push(d);
        }
        break;
      }
      // diário
      case "1M": {
        for (let i = 0; i <= 30; i++) {
          const d = new Date(now);
          d.setDate(d.getDate() - i);
          points.push(d);
        }
        break;
      }
      // Mensal
      case "1Y": {
        for (let i = 0; i <= 12; i++) {
          const d = new Date(now);
          d.setMonth(d.getMonth() - i);
          points.push(d);
        }
        break;
      }
      // Semanal
      case "YTD": {
        const startOfYear = new Date(now.getFullYear(), 0, 1);
        const current = new Date(now);

        while (current >= startOfYear) {
          points.push(new Date(current));
          current.setDate(current.getDate() - 7); // current = hoje - 7 dias
        }

        if (points[points.length - 1] > startOfYear) {
          points.push(startOfYear);
        }
        break;
      }
    }

    return points;
  }

  /**
   * Determina o preço do token em um momento específico do passado.
   * Procura no histórico de valuations a entrada mais próxima (menor ou igual) ao timestamp.
   */
  private getPriceAtTimestamp(
    timestamp: Date,
    history: { value: number; createdAt: Timestamp }[],
    startup: StartupDocumentDTO,
  ): number {
    // pega o tempo em ms
    const tsMillis = timestamp.getTime();

    let lastValuation: number | null = null;

    // Busca a última avaliação registrada ANTES do ponto no tempo
    for (const entry of history) {
      if (entry.createdAt.toMillis() <= tsMillis) {
        lastValuation = entry.value;
      } else {
        break;
      }
    }

    if (lastValuation !== null) {
      return lastValuation / startup.totalTokensIssued;
    }

    // Fallback 1: Se o ponto é muito recente (últimos 5min), usa o preço atual
    const isRecent = Math.abs(new Date().getTime() - tsMillis) < 5 * 60 * 1000;
    if (history.length === 0 || isRecent) {
      return startup.currentTokenPriceCents;
    }

    // Fallback 2: Se o ponto é anterior ao histórico disponível, usa o 'lastValuationCents' da startup
    if (history.length > 0 && history[0].createdAt.toMillis() > tsMillis) {
      if (startup.lastValuationCents && startup.lastValuationCents > 0) {
        return startup.lastValuationCents / startup.totalTokensIssued;
      }
    }

    return startup.currentTokenPriceCents;
  }
}
