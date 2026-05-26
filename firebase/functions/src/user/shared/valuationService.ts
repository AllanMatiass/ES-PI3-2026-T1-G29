// Autor: Allan Giovanni Matias Paes - 25008211

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

export class ValuationService {
  async getUserPortfolioHistory(
    userId: string,
    range: PortfolioRange,
  ): Promise<GetUserTokenValuationsResponse> {
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

    // Identificar todas as startups que o usuário já teve ou tem
    const startupIds = new Set<string>();
    user.wallet.positions.forEach((p) => {
      if (p.startupId) startupIds.add(p.startupId);
    });
    transactions.forEach((t) => {
      if (t.startupId) startupIds.add(t.startupId);
    });

    const startupIdsArray = Array.from(startupIds);
    const [startups, ...valuationsHistory] = await Promise.all([
      getStartupsByIds(startupIdsArray),
      ...startupIdsArray.map((id) =>
        getValuationHistory(
          id,
          timestamps[timestamps.length - 1],
          timestamps[0],
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

    // Reconstruir do presente para o passado
    const currentHoldings = new Map<string, number>();
    user.wallet.positions.forEach((p) => {
      currentHoldings.set(p.startupId, p.qtdTokens);
    });

    // Ordenar transações decrescentemente por data para o "rewind"
    const sortedTransactions = [...transactions].sort(
      (a, b) => b.createdAt.toMillis() - a.createdAt.toMillis(),
    );

    let transactionIndex = 0;

    for (const point of timestamps) {
      const pointMillis = point.getTime();

      // "Desfazer" transações que ocorreram após este ponto
      while (
        transactionIndex < sortedTransactions.length &&
        sortedTransactions[transactionIndex].createdAt.toMillis() > pointMillis
      ) {
        const tx = sortedTransactions[transactionIndex];
        const isBuyer = tx.buyer.id === userId;
        const isSeller = tx.seller?.id === userId;

        if (isBuyer) {
          const currentQty = currentHoldings.get(tx.startupId) || 0;
          currentHoldings.set(tx.startupId, currentQty - tx.qtdTokens);
        } else if (isSeller) {
          const currentQty = currentHoldings.get(tx.startupId) || 0;
          currentHoldings.set(tx.startupId, currentQty + tx.qtdTokens);
        }
        transactionIndex++;
      }

      // Calcular valor do portfólio neste ponto (apenas ativos)
      let portfolioValue = 0;
      currentHoldings.forEach((qty, startupId) => {
        if (qty <= 0) return;

        const startup = startupsMap.get(startupId);
        if (!startup) return;

        const price = this.getPriceAtTimestamp(
          startupId,
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

    // A resposta espera ordem cronológica (antigo para novo)
    const chronologicalHistory = history.reverse();
    const latestValue =
      chronologicalHistory[chronologicalHistory.length - 1].valueCents;

    // CÁLCULO DE VALORIZAÇÃO REAL (ROI):
    // Em vez de comparar apenas o início e fim do gráfico (que pode ser 0 se a compra foi recente),
    // calculamos o lucro real comparando o valor atual dos ativos com o total investido (custo médio).
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

  private generateTimestamps(range: PortfolioRange): Date[] {
    const points: Date[] = [];
    const now = new Date();

    switch (range) {
      case "1D": {
        for (let i = 0; i <= 24; i++) {
          const d = new Date(now);
          d.setHours(d.getHours() - i);
          points.push(d);
        }
        break;
      }
      case "1W": {
        for (let i = 0; i <= 7; i++) {
          const d = new Date(now);
          d.setDate(d.getDate() - i);
          points.push(d);
        }
        break;
      }
      case "1M": {
        for (let i = 0; i <= 30; i++) {
          const d = new Date(now);
          d.setDate(d.getDate() - i);
          points.push(d);
        }
        break;
      }
      case "1Y": {
        for (let i = 0; i <= 12; i++) {
          const d = new Date(now);
          d.setMonth(d.getMonth() - i);
          points.push(d);
        }
        break;
      }
      case "YTD": {
        const startOfYear = new Date(now.getFullYear(), 0, 1);
        const current = new Date(now);
        while (current >= startOfYear) {
          points.push(new Date(current));
          current.setDate(current.getDate() - 7);
        }
        if (points[points.length - 1] > startOfYear) {
          points.push(startOfYear);
        }
        break;
      }
    }

    return points;
  }

  private getPriceAtTimestamp(
    startupId: string,
    timestamp: Date,
    history: { value: number; createdAt: Timestamp }[],
    startup: StartupDocumentDTO,
  ): number {
    const tsMillis = timestamp.getTime();

    // Encontrar a última avaliação antes ou no timestamp
    let lastValuation: number | null = null;

    for (const entry of history) {
      if (entry.createdAt.toMillis() <= tsMillis) {
        lastValuation = entry.value;
      } else {
        // Como o history está ordenado ASC, o primeiro que for depois do timestamp
        // significa que os anteriores eram válidos.
        break;
      }
    }

    if (lastValuation !== null) {
      return lastValuation / startup.totalTokensIssued;
    }

    // Se não houver histórico NO RANGE, mas o timestamp for o presente ou próximo dele,
    // usamos o preço atual da startup para evitar mostrar valores defasados.
    const isRecent = Math.abs(new Date().getTime() - tsMillis) < 5 * 60 * 1000; // 5 minutos
    if (history.length === 0 || isRecent) {
      return startup.currentTokenPriceCents;
    }

    // Fallback: Se o timestamp for anterior à primeira avaliação do range,
    // tentamos usar o lastValuationCents (valor anterior à última mudança registrada)
    if (history.length > 0 && history[0].createdAt.toMillis() > tsMillis) {
      if (startup.lastValuationCents && startup.lastValuationCents > 0) {
        return startup.lastValuationCents / startup.totalTokensIssued;
      }
    }

    return startup.currentTokenPriceCents;
  }
}
