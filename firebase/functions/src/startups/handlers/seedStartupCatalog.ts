import { onCall } from "firebase-functions/v2/https";
import { seedDemoStartups } from "../repositories/startupRepository";
import { withCallHandler } from "../../shared/middlewares/errorHandler";

/**
 * Popula o catalogo com startups demonstrativas.
 *
 * Esta Funcao e callable para facilitar a execucao pelo app ou pelo
 * emulador durante desenvolvimento.
 *
 * A trava de segurança de seedKey foi removida para facilitar testes iniciais
 * em producao/homologacao.
 *
 * A funcao retorna a quantidade de startups gravadas e os ids dos documentos.
 */
export const seedStartupCatalog = onCall(
  withCallHandler(async () => {
    const startupIds = await seedDemoStartups();

    return {
      count: startupIds.length,
      ids: startupIds,
    };
  }),
);
