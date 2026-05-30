// Autor: Allan Giovanni Matias Paes - 25008211
// Pedro Vinícius Romanato - 25004075
import { HttpsError } from "firebase-functions/v2/https";
import { Wallet, WalletTokenPosition } from "../../user/types";
import { db } from "../../firebase";
import { Offer, OfferWithId } from "../types";

const offerCollection = db.collection("offers");

/**
 * Autor: Allan
 * Cria uma nova oferta de tokens dentro de uma transação.
 * Realiza a validação do saldo do vendedor e faz o bloqueio (lock) dos tokens ofertados.
 * * @param {string} sellerId - ID do vendedor.
 * @param {Offer} offerData - Dados da oferta a ser criada.
 * @returns {Promise<string>} O ID da oferta recém-criada no Firestore.
 * @throws {HttpsError} Lança erro caso o vendedor não seja encontrado, não tenha carteira ou não tenha saldo suficiente.
 */
export async function createOfferInTransaction(
  sellerId: string,
  offerData: Offer,
): Promise<string> {
  const offerRef = offerCollection.doc();

  await db.runTransaction(async (tx) => {
    const sellerRef = db.collection("users").doc(sellerId);
    const sellerSnap = await tx.get(sellerRef);

    // Verifica se o usuário/vendedor existe
    if (!sellerSnap.exists) {
      throw new HttpsError("not-found", "Vendedor não encontrado.");
    }

    const sellerData = sellerSnap.data();
    const wallet = sellerData?.wallet;

    // Garante que o vendedor possui uma carteira registrada
    if (!wallet) {
      throw new HttpsError(
        "failed-precondition",
        "Carteira do vendedor não encontrada.",
      );
    }

    // Busca a posição de tokens específica da startup cujos tokens estão sendo ofertados
    const position = wallet.positions?.find(
      (p: WalletTokenPosition) => p.startupId === offerData.startupId,
    );

    if (!position) {
      throw new HttpsError(
        "failed-precondition",
        "O vendedor não possui tokens desta startup.",
      );
    }

    // Calcula os tokens realmente disponíveis (saldo total - saldo já bloqueado em outras ofertas ativas)
    const availableTokens = position.qtdTokens - position.lockedTokens;

    if (availableTokens < offerData.qtdTokens) {
      throw new HttpsError(
        "failed-precondition",
        "Quantidade de tokens insuficiente para criar a oferta.",
      );
    }

    // Bloqueia a quantidade de tokens referente a esta nova oferta
    position.lockedTokens += offerData.qtdTokens;

    // Salva o novo estado da carteira com os tokens bloqueados
    tx.update(sellerRef, {
      wallet,
    });

    // Cria efetivamente o documento da oferta
    tx.set(offerRef, offerData);
  });

  return offerRef.id;
}

/**
 * Autor: Allan
 * Busca os detalhes de uma oferta específica pelo seu ID.
 * * @param {string} id - ID da oferta.
 * @returns {Promise<OfferWithId | null>} Os dados da oferta incluindo seu ID, ou null se não encontrada.
 */
export async function getOfferById(id: string): Promise<OfferWithId | null> {
  const doc = await offerCollection.doc(id).get();
  if (!doc.exists) return null;
  return { id: doc.id, ...(doc.data() as Offer) };
}

/**
 * Autor: Allan
 * Atualiza parcialmente os dados de uma oferta existente.
 * * @param {string} id - ID da oferta a ser atualizada.
 * @param {Partial<Offer>} data - Objeto contendo os campos da oferta que devem ser modificados.
 */
export async function updateOffer(id: string, data: Partial<Offer>) {
  await offerCollection.doc(id).update(data);
}

/**
 * Autor: Pedro
 * Cancela uma oferta ativa utilizando uma transação.
 * Libera os tokens que estavam bloqueados na oferta, retornando-os ao saldo disponível do vendedor.
 * * @param {string} offerId - ID da oferta a ser cancelada.
 * @param {string} sellerId - ID do vendedor que está solicitando o cancelamento.
 * @returns {Promise<boolean>} True se o cancelamento for bem-sucedido.
 * @throws {HttpsError} Lança erro caso a oferta não pertença ao vendedor ou já tenha sido encerrada.
 */
export async function cancelOfferInTransaction(
  offerId: string,
  sellerId: string,
): Promise<boolean> {
  const offerRef = offerCollection.doc(offerId);

  return await db.runTransaction(async (tx) => {
    const offerSnap = await tx.get(offerRef);

    // Valida a existência da oferta
    if (!offerSnap.exists) {
      throw new HttpsError("not-found", "Oferta não encontrada.");
    }

    const offerData = offerSnap.data() as Offer;

    // Garante que apenas o próprio criador da oferta tem permissão para cancelá-la
    if (offerData.seller.id !== sellerId) {
      throw new HttpsError(
        "permission-denied",
        "Apenas o vendedor pode cancelar a própria oferta.",
      );
    }

    // Impede o cancelamento se a oferta já foi concluída, expirada ou cancelada
    if (offerData.status !== "OPEN") {
      throw new HttpsError(
        "failed-precondition",
        `Oferta não pode ser cancelada pois está com status: ${offerData.status}.`,
      );
    }

    const sellerRef = db.collection("users").doc(sellerId);
    const sellerSnap = await tx.get(sellerRef);

    if (!sellerSnap.exists) {
      throw new HttpsError("not-found", "Vendedor não existe.");
    }

    const sellerData = sellerSnap.data();
    const wallet: Wallet = sellerData?.wallet;

    if (!wallet?.positions) {
      throw new HttpsError("not-found", "Carteira do vendedor não existe.");
    }

    // Localiza os tokens específicos na carteira para realizar o desbloqueio
    const positionIndex = wallet.positions.findIndex(
      (p: WalletTokenPosition) => p.startupId === offerData.startupId,
    );

    if (positionIndex !== -1) {
      // Subtrai os tokens da oferta cancelada do total de tokens bloqueados (usa Math.max para evitar números negativos)
      wallet.positions[positionIndex].lockedTokens = Math.max(
        0,
        (wallet.positions[positionIndex].lockedTokens || 0) -
          offerData.qtdTokens,
      );

      // Atualiza a carteira com a trava desfeita
      tx.update(sellerRef, { wallet });
    }

    // Muda o status da oferta e registra a data do cancelamento
    tx.update(offerRef, {
      status: "CANCELLED",
      cancelledAt: new Date(),
    });

    return true;
  });
}

/**
 * Autor: Allan
 * Expira uma oferta ativa dentro de uma transação.
 * Geralmente chamado por um serviço ou cronjob. Libera os tokens da oferta expirada de volta à carteira.
 * * @param {string} offerId - ID da oferta que será expirada.
 * @returns {Promise<boolean>} True se expirada com sucesso, false se a oferta não estava aberta.
 * @throws {HttpsError} Lança erro caso a oferta ou a carteira do vendedor não sejam encontradas.
 */
export async function expireOfferInTransaction(
  offerId: string,
): Promise<boolean> {
  const offerRef = offerCollection.doc(offerId);

  return await db.runTransaction(async (tx) => {
    const offerSnap = await tx.get(offerRef);

    if (!offerSnap.exists) {
      throw new HttpsError("not-found", "Oferta não encontrada.");
    }

    const offerData = offerSnap.data() as Offer;

    // Se a oferta não estiver aberta retorna false
    if (offerData.status !== "OPEN") {
      return false;
    }

    const sellerRef = db.collection("users").doc(offerData.seller.id);
    const sellerSnap = await tx.get(sellerRef);

    if (!sellerSnap.exists) {
      throw new HttpsError("not-found", "Vendedor não existe.");
    }

    const sellerData = sellerSnap.data();
    const wallet: Wallet = sellerData?.wallet;
    const positions = wallet.positions;

    if (!wallet || !positions) {
      throw new HttpsError("not-found", "Carteira do vendedor não existe.");
    }

    // Localiza a posição dos tokens da startup e destrava a quantia
    const positionIndex = wallet.positions.findIndex(
      (p: WalletTokenPosition) => p.startupId === offerData.startupId,
    );

    // Se a posição existir
    if (positionIndex !== -1) {
      wallet.positions[positionIndex].lockedTokens = Math.max(
        0,
        (wallet.positions[positionIndex].lockedTokens || 0) -
          offerData.qtdTokens,
      );

      tx.update(sellerRef, { wallet });
    }

    // Muda o status da oferta para expirado
    tx.update(offerRef, {
      status: "EXPIRED",
    });

    return true;
  });
}

/**
 * Autor: Allan
 * Lista todas as ofertas criadas por um vendedor específico.
 * * @param {string} sellerId - ID do vendedor.
 * @returns {Promise<OfferWithId[]>} Lista de ofertas ordenadas das mais recentes para as mais antigas.
 */
export async function getOffersBySellerId(
  sellerId: string,
): Promise<OfferWithId[]> {
  // Query filtrando ofertas onde o ID do vendedor coincide com o solicitado
  const snapshot = await offerCollection
    .where("seller.id", "==", sellerId)
    .orderBy("createdAt", "desc")
    .get();

  return snapshot.docs.map((doc) => ({
    id: doc.id,
    ...(doc.data() as Offer),
  }));
}

/**
 * Autor: Allan
 * Lista as ofertas que estão ativas (OPEN) com suporte a paginação e filtros.
 * * @param {string} [startupId] - (Opcional) ID da startup para buscar apenas as ofertas dela.
 * @param {number} [limit=20] - Limite máximo de documentos retornados por vez. O padrão é 20.
 * @param {string} [lastOfferId] - (Opcional) O ID da última oferta da listagem anterior para fazer paginação baseada em cursor.
 * @returns {Promise<{ offers: OfferWithId[]; lastOfferId: string | null }>} As ofertas e o ID que aponta para a próxima página.
 */
export async function listOffers(
  startupId?: string,
  limit = 20,
  lastOfferId?: string,
): Promise<{ offers: OfferWithId[]; lastOfferId: string | null }> {
  // Inicializa a query buscando apenas ofertas disponíveis e ordenadas por criação (as mais recentes primeiro)
  let query = offerCollection
    .where("status", "==", "OPEN")
    .orderBy("createdAt", "desc");

  // Se for passado um ID de startup, adiciona esta restrição à query
  if (startupId) {
    query = query.where("startupId", "==", startupId);
  }

  // Lógica de paginação: se receber o lastOfferId, busca a partir desse documento (startAfter)
  if (lastOfferId) {
    const lastOfferDoc = await offerCollection.doc(lastOfferId).get();
    if (lastOfferDoc.exists) {
      query = query.startAfter(lastOfferDoc);
    }
  }

  // Executa a busca aplicando o limite imposto
  const snapshot = await query.limit(limit).get();
  const offers = snapshot.docs.map((doc) => ({
    id: doc.id,
    ...(doc.data() as Offer),
  }));

  // Define qual será a âncora da próxima requisição para continuar a paginação.
  // Se o número retornado de fato bateu no limite, assume-se que há mais itens para listar.
  const lastId =
    offers.length > 0 && offers.length === limit
      ? offers[offers.length - 1].id
      : null;

  return { offers, lastOfferId: lastId };
}
