/**
 * @file listStartups.ts
 * @description Cloud Function para listar e filtrar startups cadastradas no catálogo.
 * @author Allan Giovanni Matias Paes - 25008211
 */

import { HttpsError, onCall } from "firebase-functions/v2/https";
import { allowedStages } from "../shared/constants";
import { requireAuthenticatedUser } from "../../shared/auth";
import { listStartupItems } from "../repositories/startupRepository";
import { normalizeString } from "../../shared/validation";
import { StartupListItem, StartupStage } from "../types";
import { withCallHandler } from "../../shared/middlewares/errorHandler";
import { ListStartupsRequest, StartupListingResponseDTO } from "../types/dtos";
import { logger } from "firebase-functions";

/**
 * Lista as startups cadastradas no catálogo do MesclaInvest.
 *
 * Esta função é callable e fornece uma lista otimizada para exibição em cards e listagens.
 *
 * Fluxo de execução:
 * 1. Autentica o usuário solicitante.
 * 2. Extrai e normaliza filtros de estágio e texto de busca.
 * 3. Valida se o estágio informado é permitido.
 * 4. Recupera os itens base do repositório.
 * 5. Realiza a filtragem em memória por estágio e busca textual (nome, descrição, tags).
 * 6. Formata a resposta com contagem, metadados dos filtros e a lista mapeada por ID.
 */
export const listStartups = onCall(
  withCallHandler<
    ListStartupsRequest,
    StartupListingResponseDTO<StartupListItem>
  >(async (request) => {
    // 1. Requer autenticação
    requireAuthenticatedUser(request);

    // 2. Normalização dos parâmetros de busca
    const stage = normalizeString(request.data?.stage);
    const search = normalizeString(request.data?.search)?.toLocaleLowerCase(
      "pt-BR",
    );

    // 3. Validação do filtro de estágio
    if (stage && !allowedStages.includes(stage as StartupStage)) {
      throw new HttpsError(
        "invalid-argument",
        "Filtro stage invalido. Use nova, em_operacao ou em_expansao.",
      );
    }

    // 4. Recuperação e Filtragem
    // As startups são recuperadas em lote e filtradas em memória para suportar busca textual flexível
    const startupsArray = (
      (await listStartupItems()) as StartupListItem[]
    ).filter((startup) => {
      // Filtragem por estágio
      if (stage && startup.stage !== stage) {
        return false;
      }

      if (!search) {
        return true;
      }

      // Lógica de busca textual: nome, descrição curta, estágio e tags
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

    // Converte o array em um mapa (Dicionário) indexado pelo ID para facilitar o consumo no frontend
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

    logger.info(`Startups listadas: ${startupsArray.length} encontradas.`);
    return res;
  }),
);
