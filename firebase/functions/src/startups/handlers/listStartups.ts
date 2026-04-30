// Autor: Allan Giovanni Matias Paes
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { allowedStages } from "../shared/constants";
import { requireAuthenticatedUser } from "../../shared/auth";
import { listStartupItems } from "../repositories/startupRepository";
import { normalizeString } from "../../shared/validation";
import { StartupListItem, StartupStage } from "../types";
import { withCallHandler } from "../../shared/middlewares/errorHandler";
import { ListStartupsRequest } from "../types/dtos";
import { RecordFunctionResponse } from "../../shared/types";
import { logger } from "firebase-functions";

/**
 * Lista as startups cadastradas no catalogo do MesclaInvest.
 *
 * Esta Funcao e callable porque sera consumida diretamente pelo app mobile.
 * O app pode enviar, em `data`, os campos:
 *
 * - `stage`: filtro opcional por estagio.
 * - `search`: texto opcional para buscar no catalogo.
 *
 * A funcao exige usuario autenticado e retorna um objeto com:
 *
 * - `count`: quantidade de startups retornadas.
 * - `filters`: filtros aplicados e estagios disponiveis.
 * - `data`: lista resumida de startups para uso em telas de catalogo.
 */
export const listStartups = onCall(
  withCallHandler<ListStartupsRequest, RecordFunctionResponse<StartupListItem>>(
    async (request) => {
      requireAuthenticatedUser(request);

      const stage = normalizeString(request.data?.stage);
      const search = normalizeString(request.data?.search)?.toLocaleLowerCase(
        "pt-BR",
      );

      if (stage && !allowedStages.includes(stage as StartupStage)) {
        throw new HttpsError(
          "invalid-argument",
          "Filtro stage invalido. Use nova, em_operacao ou em_expansao.",
        );
      }

      const startupsArray = (
        (await listStartupItems()) as StartupListItem[]
      ).filter((startup) => {
        if (stage && startup.stage !== stage) {
          return false;
        }

        if (!search) {
          return true;
        }

        const searchable = [
          startup.name,
          startup.shortDescription,
          startup.stage,
          ...startup.tags,
        ]
          .join(" ")
          .toLocaleLowerCase("pt-BR");

        return searchable.includes(search);
      });
      const startups = Object.fromEntries(startupsArray.map((s) => [s.id, s]));

      const res = {
        count: startupsArray.length,
        filters: {
          availableStages: allowedStages,
          stage: stage ?? null,
          search: search ?? null,
        },
        data: startups,
      };
      logger.info(`Startups: ${JSON.stringify(startups)}`);
      return res;
    },
  ),
);
