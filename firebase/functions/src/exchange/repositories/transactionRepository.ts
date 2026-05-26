// Autor: Allan Giovanni Matias Paes - 25008211
import { FieldValue, Timestamp } from "firebase-admin/firestore";

import { db } from "../../firebase";

import { Transaction, TransactionWithId } from "../types";

const transactionCollection = db.collection("transactions");

/**
 * Cria uma nova transação no banco de dados.
 * O campo 'createdAt' é gerado automaticamente pelo servidor para garantir consistência de horário.
 * * @param {Omit<Transaction, "createdAt">} transaction - Dados da transação, omitindo a data de criação.
 * @returns {Promise<string>} O ID do documento da transação recém-criada.
 */
export async function createTransaction(
  transaction: Omit<Transaction, "createdAt">,
): Promise<string> {
  const docRef = await transactionCollection.add({
    ...transaction,

    // Cria um array 'participants' contendo os IDs do comprador e do vendedor.
    // Isso é uma modelagem clássica no Firestore para permitir consultas eficientes
    // buscando todas as transações de um usuário (seja ele comprador ou vendedor) usando 'array-contains'.
    participants: [transaction.buyer.id, transaction.seller.id],

    // Delega a responsabilidade de timestamp para o servidor do Firebase
    createdAt: FieldValue.serverTimestamp(),
  });

  return docRef.id;
}

/**
 * Busca as transações relacionadas a uma startup específica.
 * Retorna as transações mais recentes primeiro.
 * * @param {string} startupId - O ID da startup cujas transações devem ser listadas.
 * @param {number} [limit=15] - Limite máximo de transações retornadas (padrão: 15).
 * @returns {Promise<TransactionWithId[]>} Lista de transações com seus respectivos IDs.
 */
export async function getTransactionsByStartupId(
  startupId: string,
  limit = 15,
): Promise<TransactionWithId[]> {
  const snapshot = await transactionCollection
    .where("startupId", "==", startupId)
    .orderBy("createdAt", "desc")
    .limit(limit)
    .get();

  return snapshot.docs.map((doc) => {
    // Faz o cast forçando a tipagem do 'createdAt' como Timestamp do Firebase
    const data = doc.data() as Omit<Transaction, "createdAt"> & {
      createdAt: Timestamp;
    };

    return {
      id: doc.id,
      ...data,
    };
  });
}

/**
 * Busca todas as transações que envolvem um usuário específico (seja ele comprador ou vendedor).
 * Ordena as transações da mais antiga para a mais recente.
 * * @param {string} userId - O ID do usuário participante da transação.
 * @returns {Promise<TransactionWithId[]>} Lista cronológica (crescente) de transações do usuário.
 */
export async function getTransactionsByUserId(
  userId: string,
): Promise<TransactionWithId[]> {
  // Utiliza o 'array-contains' no array auxiliar 'participants' criado na hora de salvar o documento
  const snapshot = await transactionCollection
    .where("participants", "array-contains", userId)
    .orderBy("createdAt", "asc")
    .get();

  return snapshot.docs.map((doc) => {
    const data = doc.data() as Omit<Transaction, "createdAt"> & {
      createdAt: Timestamp;
    };

    return {
      id: doc.id,
      ...data,
    };
  });
}

/**
 * Lista as transações de um usuário específico com suporte a paginação (cursor-based).
 * Ordena das mais recentes para as mais antigas (descendente).
 * * @param {string} userId - O ID do usuário participante da transação.
 * @param {number} [limit=20] - Quantidade máxima de documentos por página (padrão: 20).
 * @param {string} [lastTransactionId] - (Opcional) ID da última transação da página anterior para usar como cursor.
 * @returns {Promise<{ transactions: TransactionWithId[]; lastTransactionId: string | null }>} Retorna a lista de transações e o ID âncora para a próxima página.
 */
export async function listTransactionsByUserId(
  userId: string,
  limit = 20,
  lastTransactionId?: string,
): Promise<{
  transactions: TransactionWithId[];
  lastTransactionId: string | null;
}> {
  // Inicializa a query filtrando pelo usuário e ordenando da transação mais nova para a mais velha
  let query = transactionCollection
    .where("participants", "array-contains", userId)
    .orderBy("createdAt", "desc");

  // Se houver um ID anterior fornecido, busca esse documento para iniciar a consulta a partir dele (startAfter)
  if (lastTransactionId) {
    const lastDoc = await transactionCollection.doc(lastTransactionId).get();
    if (lastDoc.exists) {
      query = query.startAfter(lastDoc);
    }
  }

  // Executa a busca no Firestore respeitando o limite
  const snapshot = await query.limit(limit).get();

  const transactions = snapshot.docs.map((doc) => {
    const data = doc.data() as Omit<Transaction, "createdAt"> & {
      createdAt: Timestamp;
    };

    return {
      id: doc.id,
      ...data,
    };
  });

  // Calcula o cursor da próxima página: se retornou o número exato do limite, presume-se que há mais resultados
  const lastId =
    transactions.length > 0 && transactions.length === limit
      ? transactions[transactions.length - 1].id
      : null;

  return { transactions, lastTransactionId: lastId };
}
