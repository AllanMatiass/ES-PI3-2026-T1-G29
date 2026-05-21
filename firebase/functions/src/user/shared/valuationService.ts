// Autor: Gemini CLI
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
    let currentBalance = user.wallet.balanceInCents;
    const currentHoldings = new Map<string, number>();
    user.wallet.positions.forEach((p) => {
      currentHoldings.set(p.startupId, p.qtdTokens);
    });

    // Ordenar transações decrescentemente por data para facilitar o "rewind"
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
          currentBalance += tx.totalCents;
          const currentQty = currentHoldings.get(tx.startupId) || 0;
          currentHoldings.set(tx.startupId, currentQty - tx.qtdTokens);
        } else if (isSeller) {
          currentBalance -= tx.totalCents;
          const currentQty = currentHoldings.get(tx.startupId) || 0;
          currentHoldings.set(tx.startupId, currentQty + tx.qtdTokens);
        }
        transactionIndex++;
      }

      // Calcular valor do portfólio neste ponto
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
        valueCents: Math.round(currentBalance + portfolioValue),
      });
    }

    // A resposta espera ordem cronológica (antigo para novo)
    const chronologicalHistory = history.reverse();
    const latestValue =
      chronologicalHistory[chronologicalHistory.length - 1].valueCents;
    const firstValue = chronologicalHistory[0].valueCents;
    const variationCents = latestValue - firstValue;
    const variationPercent =
      firstValue === 0
        ? 0
        : Number(((variationCents / firstValue) * 100).toFixed(2));

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
    // Normalizar para o início do minuto/hora para consistência
    now.setSeconds(0, 0);

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
        continue;
      }
      // Como o history está ordenado ASC, o primeiro que for depois do timestamp
      // significa que os anteriores eram válidos.
      break;
    }

    if (lastValuation === null) {
      // Se não houver histórico antes, usa o preço inicial se a startup já existia
      // Ou 0 se a startup foi criada depois
      if (startup.createdAt && startup.createdAt.toMillis() <= tsMillis) {
        // Precisamos do tokenPriceCents. Se não gravamos no histórico,
        // estimamos pelo totalTokensIssued.
        // No startupRepository, saveValuationSnapshot grava o 'value' (valuation total).
        return (startup.lastValuationCents || 0) / startup.totalTokensIssued;
      }
      return 0;
    }

    return lastValuation / startup.totalTokensIssued;
  }
}
