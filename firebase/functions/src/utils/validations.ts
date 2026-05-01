import { HttpsError } from "firebase-functions/https";
import { PriceHistoryOptions } from "../startups/types/dtos";

export function validatePriceHistoryOptions(options: PriceHistoryOptions) {
  if (!options) {
    throw new HttpsError("invalid-argument", "Informe as opções (options).");
  }

  const validIntervals = ["monthly", "semestrely", "yearly", "ytd"] as const;

  if (!options.historyInterval) {
    throw new HttpsError(
      "invalid-argument",
      "Informe o intervalo (historyInterval).",
    );
  }

  if (!validIntervals.includes(options.historyInterval)) {
    throw new HttpsError(
      "invalid-argument",
      "Intervalo inválido. Use: monthly, semestrely, yearly ou ytd.",
    );
  }

  // History Range opcional
  if (options.historyRange) {
    const { from, to } = options.historyRange;

    if (!from || !to) {
      throw new HttpsError(
        "invalid-argument",
        "Range inválido. Informe 'from' e 'to'.",
      );
    }

    const fromDate = new Date(from);
    const toDate = new Date(to);

    if (isNaN(fromDate.getTime()) || isNaN(toDate.getTime())) {
      throw new HttpsError("invalid-argument", "Datas inválidas no range.");
    }

    if (fromDate > toDate) {
      throw new HttpsError(
        "invalid-argument",
        "'from' não pode ser maior que 'to'.",
      );
    }
  }

  // limit
  if (options.historyLimit != null) {
    if (typeof options.historyLimit !== "number" || options.historyLimit <= 0) {
      throw new HttpsError(
        "invalid-argument",
        "historyLimit deve ser um número positivo.",
      );
    }
  }
}
