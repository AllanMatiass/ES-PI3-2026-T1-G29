// Autor: Allan Giovanni Matias Paes - 25008211
import { FieldValue } from "firebase-admin/firestore";
import { db } from "./firebase";
import { MarketType, StartupDocument } from "../startups/types";
import {
  calculatePrimaryMarketPrice,
  calculateSecondaryMarketPrice,
  calculateTertiaryMarketPrice,
} from "./pricingEngine";
import { HttpsError } from "firebase-functions/https";
import { PricingUpdateResultDTO } from "../startups/types/dtos";

export class TokenPricingService {
  private startupsCollection = db.collection("startups");

  /**
   * Revalua o token com base em uma compra no Mercado Primário.
   */
  async revalueFromPrimaryTrade(
    startupId: string,
    quantity: number,
  ): Promise<PricingUpdateResultDTO> {
    return db.runTransaction((tx) =>
      this.revalueFromPrimaryTradeTx(tx, startupId, quantity),
    );
  }

  /**
   * Revalua o token com base em uma compra no Mercado Primário dentro de uma transação existente.
   */
  async revalueFromPrimaryTradeTx(
    tx: FirebaseFirestore.Transaction,
    startupId: string,
    quantity: number,
    startupData?: StartupDocument,
  ): Promise<PricingUpdateResultDTO> {
    return this._applyPricingTx(
      tx,
      startupId,
      "primary",
      { quantity },
      startupData,
    );
  }

  /**
   * Revalua o token com base em uma negociação no Mercado Secundário.
   */
  async revalueFromSecondaryTrade(
    startupId: string,
    quantity: number,
    offerPriceCents: number,
  ): Promise<PricingUpdateResultDTO> {
    return db.runTransaction((tx) =>
      this.revalueFromSecondaryTradeTx(
        tx,
        startupId,
        quantity,
        offerPriceCents,
      ),
    );
  }

  /**
   * Revalua o token com base em uma negociação no Mercado Secundário dentro de uma transação existente.
   */
  async revalueFromSecondaryTradeTx(
    tx: FirebaseFirestore.Transaction,
    startupId: string,
    quantity: number,
    offerPriceCents: number,
    startupData?: StartupDocument,
  ): Promise<PricingUpdateResultDTO> {
    return this._applyPricingTx(
      tx,
      startupId,
      "secondary",
      {
        quantity,
        offerPriceCents,
      },
      startupData,
    );
  }

  /**
   * Revalua o token com base em um evento externo (Mercado Terciário).
   */
  async revalueFromEvent(
    startupId: string,
    deltaEvento: number,
  ): Promise<PricingUpdateResultDTO> {
    return db.runTransaction((tx) =>
      this.revalueFromEventTx(tx, startupId, deltaEvento),
    );
  }

  /**
   * Revalua o token com base em um evento externo (Mercado Terciário) dentro de uma transação existente.
   */
  async revalueFromEventTx(
    tx: FirebaseFirestore.Transaction,
    startupId: string,
    deltaEvento: number,
    startupData?: StartupDocument,
  ): Promise<PricingUpdateResultDTO> {
    return this._applyPricingTx(
      tx,
      startupId,
      "event",
      {
        deltaEvent: deltaEvento,
      },
      startupData,
    );
  }

  /**
   * Aplica a alteração de precificação usando a transação fornecida.
   */
  private async _applyPricingTx(
    tx: FirebaseFirestore.Transaction,
    startupId: string,
    type: MarketType,
    params: {
      quantity?: number;
      offerPriceCents?: number;
      deltaEvent?: number;
    },
    startupData?: StartupDocument,
  ): Promise<PricingUpdateResultDTO> {
    const startupRef = this.startupsCollection.doc(startupId);

    let startup: StartupDocument;

    if (startupData) {
      startup = startupData;
    } else {
      const snapshot = await tx.get(startupRef);
      if (!snapshot.exists) {
        throw new HttpsError("not-found", "Startup não encontrada.");
      }
      startup = snapshot.data() as StartupDocument;
    }

    const currentPriceCents = startup.currentTokenPriceCents;
    const totalTokens = startup.totalTokensIssued;

    let newPriceCents = currentPriceCents;

    // 1. Calcular novo preço usando o pricingEngine
    switch (type) {
      case "primary":
        if (!params.quantity) {
          throw new HttpsError(
            "failed-precondition",
            "Para o tipo 'primary', o parâmetro 'quantity' é obrigatório",
          );
        }
        newPriceCents = calculatePrimaryMarketPrice(
          currentPriceCents,
          params.quantity,
          totalTokens,
        );
        break;
      case "secondary":
        if (!params.quantity || !params.offerPriceCents) {
          throw new HttpsError(
            "failed-precondition",
            "Para o tipo 'secondary', os parâmetros 'quantity' e 'offerPriceCents' é obrigatório",
          );
        }
        newPriceCents = calculateSecondaryMarketPrice(
          currentPriceCents,
          params.offerPriceCents,
          params.quantity,
          totalTokens,
        );
        break;
      case "event":
        if (params.deltaEvent === undefined) {
          throw new HttpsError(
            "failed-precondition",
            "Para o tipo 'event', o parâmetro 'deltaEvent' é obrigatório",
          );
        }
        newPriceCents = calculateTertiaryMarketPrice(
          currentPriceCents,
          params.deltaEvent,
        );
        break;
    }

    const previousValuationCents = currentPriceCents * totalTokens;
    const newValuationCents = newPriceCents * totalTokens;

    // 2. Atualizar o documento da Startup
    // Só atualizamos o lastValuationCents se for a primeira transação do dia.
    // Isso permite que a variação (%) no card da startup acumule durante o dia
    // em vez de "zerar" a cada nova pequena mudança de preço.
    const updateData: FirebaseFirestore.UpdateData<StartupDocument> = {
      currentTokenPriceCents: newPriceCents,
      updatedAt: FieldValue.serverTimestamp(),
    };

    const lastUpdate = startup.updatedAt?.toDate() || new Date(0);
    const now = new Date();

    const isDifferentDay =
      lastUpdate.getUTCDate() !== now.getUTCDate() ||
      lastUpdate.getUTCMonth() !== now.getUTCMonth() ||
      lastUpdate.getUTCFullYear() !== now.getUTCFullYear();

    if (isDifferentDay) {
      updateData.lastValuationCents = previousValuationCents;
    }

    tx.update(startupRef, updateData);

    // 3. Gerar snapshot de histórico na subcoleção valuations
    // Aqui sempre salvamos, para o gráfico ter todos os pontos de negociação
    const valuationRef = startupRef.collection("valuations").doc();
    tx.set(valuationRef, {
      value: newValuationCents,
      tokenPriceCents: newPriceCents,
      changeType: type,
      createdAt: FieldValue.serverTimestamp(),
    });

    return {
      previousPriceCents: currentPriceCents,
      newPriceCents,
      previousValuationCents,
      newValuationCents,
    };
  }
}
