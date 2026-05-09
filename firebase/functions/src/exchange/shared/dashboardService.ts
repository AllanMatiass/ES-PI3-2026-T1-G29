import { Timestamp } from "firebase-admin/firestore";

import * as transactionRepository from "../repositories/transactionRepository";
import * as startupRepository from "../../startups/repositories/startupRepository";

import {
  DashboardPeriod,
  DashboardDataPoint,
  GetInvestorDashboardResponseDTO,
} from "../types/dtos";

import { Transaction } from "../types";

import { StartupDocumentDTO } from "../../startups/types/dtos";

interface StartupValuationData {
  id: string;
  startup: StartupDocumentDTO | undefined;
  valuations: {
    value: number;
    createdAt: Timestamp;
  }[];
}

export class DashboardService {
  async getDashboardData(
    userId: string,
    period: DashboardPeriod,
  ): Promise<GetInvestorDashboardResponseDTO> {
    const transactions =
      await transactionRepository.getTransactionsByUserId(userId);

    if (transactions.length === 0) {
      return {
        points: [],
        currentTotalValueCents: 0,
        variationCents: 0,
        variationPercent: 0,
      };
    }

    const startupIds = Array.from(
      new Set(transactions.map((t) => t.startupId)),
    );

    const now = new Date();
    const startDate = this.getStartDate(period, now);

    // =========================
    // STARTUPS
    // =========================

    const startups = await startupRepository.getStartupsByIds(startupIds);

    const startupsMap = new Map<string, StartupDocumentDTO>();

    startupIds.forEach((id, index) => {
      const startup = startups[index];

      if (startup) {
        startupsMap.set(id, startup);
      }
    });

    // =========================
    // VALUATIONS
    // =========================

    const startupsData: StartupValuationData[] = await Promise.all(
      startupIds.map(async (id) => {
        const valuations = await startupRepository.getValuationHistory(
          id,
          startDate,
          now,
          100,
        );

        return {
          id,
          startup: startupsMap.get(id),
          valuations,
        };
      }),
    );

    // =========================
    // POINTS
    // =========================

    const points = this.calculatePoints(
      userId,
      transactions,
      startupsData,
      startDate,
      now,
      period,
    );

    const currentTotalValueCents =
      points.length > 0 ? points[points.length - 1].totalValueCents : 0;

    const investedTotalCents = this.calculateInvestedValue(
      userId,
      transactions,
    );

    const variationCents = currentTotalValueCents - investedTotalCents;

    let variationPercent = 0;
    if (investedTotalCents > 0) {
      const calc = (variationCents / investedTotalCents) * 100;
      variationPercent = isNaN(calc) ? 0 : Number(calc.toFixed(2));
    }

    return {
      points,
      currentTotalValueCents: Math.round(currentTotalValueCents) || 0,
      variationCents: Math.round(variationCents) || 0,
      variationPercent,
    };
  }

  // ======================================================
  // INVESTED VALUE
  // ======================================================

  private calculateInvestedValue(
    userId: string,
    transactions: Transaction[],
  ): number {
    let invested = 0;

    for (const t of transactions) {
      if (t.buyer.id === userId) {
        invested += t.totalCents;
      }

      if (t.seller.id === userId) {
        invested -= t.totalCents;
      }
    }

    return invested;
  }

  // ======================================================
  // DATE RANGE
  // ======================================================

  private getStartDate(period: DashboardPeriod, now: Date): Date {
    const date = new Date(now);

    switch (period) {
      case "daily":
        date.setHours(date.getHours() - 24);
        break;

      case "weekly":
        date.setDate(date.getDate() - 7);
        break;

      case "monthly":
        date.setDate(date.getDate() - 30);
        break;

      case "6months":
        date.setMonth(date.getMonth() - 6);
        break;

      case "ytd":
        date.setMonth(0, 1);
        date.setHours(0, 0, 0, 0);
        break;
    }

    return date;
  }

  // ======================================================
  // MAIN GRAPH CALCULATION
  // ======================================================

  private calculatePoints(
    userId: string,
    transactions: Transaction[],
    startupsData: StartupValuationData[],
    startDate: Date,
    now: Date,
    period: DashboardPeriod,
  ): DashboardDataPoint[] {
    const points: DashboardDataPoint[] = [];

    const intervals = this.getIntervals(startDate, now, period);

    // timeline de saldo por startup
    const balanceTimelines = this.preprocessBalanceTimelines(
      userId,
      transactions,
    );

    for (const time of intervals) {
      const timeMs = time.getTime();

      let totalValueCents = 0;

      for (const sData of startupsData) {
        if (!sData.startup) {
          continue;
        }

        const timeline = balanceTimelines.get(sData.id) || [];

        const tokensAtTime = this.getTokensAtTime(timeline, timeMs);

        if (tokensAtTime <= 0) {
          continue;
        }

        const priceAtTime = this.getPriceAtTime(sData, timeMs);

        totalValueCents += tokensAtTime * priceAtTime;
      }

      points.push({
        timestamp: time.toISOString(),
        totalValueCents: Math.round(totalValueCents),
      });
    }

    return points;
  }

  // ======================================================
  // BALANCE TIMELINE
  // ======================================================

  private preprocessBalanceTimelines(
    userId: string,
    transactions: Transaction[],
  ): Map<
    string,
    {
      time: number;
      balance: number;
    }[]
  > {
    const timelines = new Map<
      string,
      {
        time: number;
        balance: number;
      }[]
    >();

    // importante:
    // garantir ASC
    const sortedTransactions = [...transactions].sort(
      (a, b) => a.createdAt.toMillis() - b.createdAt.toMillis(),
    );

    for (const t of sortedTransactions) {
      const startupId = t.startupId;

      let timeline = timelines.get(startupId);

      if (!timeline) {
        timeline = [];
        timelines.set(startupId, timeline);
      }

      let balance =
        timeline.length > 0 ? timeline[timeline.length - 1].balance : 0;

      // compra
      if (t.buyer.id === userId) {
        balance += t.qtdTokens;
      }

      // venda
      if (t.seller.id === userId) {
        balance -= t.qtdTokens;
      }

      timeline.push({
        time: t.createdAt.toMillis(),
        balance,
      });
    }

    return timelines;
  }

  // ======================================================
  // TOKEN BALANCE AT TIME
  // ======================================================

  private getTokensAtTime(
    timeline: {
      time: number;
      balance: number;
    }[],
    timeMs: number,
  ): number {
    if (timeline.length === 0) {
      return 0;
    }

    let balance = 0;

    for (const entry of timeline) {
      if (entry.time <= timeMs) {
        balance = entry.balance;
      } else {
        break;
      }
    }

    return balance;
  }

  // ======================================================
  // TOKEN PRICE AT TIME
  // ======================================================

  private getPriceAtTime(sData: StartupValuationData, timeMs: number): number {
    if (!sData.startup) {
      return 0;
    }

    const valuations = [...sData.valuations].sort(
      (a, b) => a.createdAt.toMillis() - b.createdAt.toMillis(),
    );

    // fallback:
    // usa preço atual startup
    let price = sData.startup.currentTokenPriceCents;

    for (const valuation of valuations) {
      if (valuation.createdAt.toMillis() <= timeMs) {
        price = valuation.value / (sData.startup.totalTokensIssued || 1);
      } else {
        break;
      }
    }

    return price;
  }

  // ======================================================
  // GRAPH INTERVALS
  // ======================================================

  private getIntervals(
    startDate: Date,
    now: Date,
    period: DashboardPeriod,
  ): Date[] {
    const intervals: Date[] = [];

    const current = new Date(startDate);

    let stepMs: number;

    switch (period) {
      case "daily":
        stepMs = 1000 * 60 * 60;
        break;

      case "weekly":
      case "monthly":
        stepMs = 1000 * 60 * 60 * 24;
        break;

      case "6months":
      case "ytd":
        stepMs = 1000 * 60 * 60 * 24 * 7;
        break;

      default:
        stepMs = 1000 * 60 * 60 * 24;
    }

    while (current <= now) {
      intervals.push(new Date(current));

      current.setTime(current.getTime() + stepMs);
    }

    // garante último ponto
    if (
      intervals.length === 0 ||
      intervals[intervals.length - 1].getTime() < now.getTime()
    ) {
      intervals.push(new Date(now));
    }

    return intervals;
  }
}
