// Autor: Allan Giovanni Matias Paes - 25008211

type Collection = FirebaseFirestore.CollectionReference<
  FirebaseFirestore.DocumentData,
  FirebaseFirestore.DocumentData
>;

/**
 *
 * @param collection = Collection reference;
 * @param startupId = string; Startup id caso queira filtrar, irá pegar dentro de cada documento onde tiver o startupId
 * @param limit = number;
 * @param lastDocId = String
 * @returns Promise<{ docs: T[]; lastDocId: string | null }>
 */
export async function listPaginated<T>(
  collection: Collection,
  startupId?: string,
  limit = 10,
  lastDocId?: string,
): Promise<{ docs: T[]; lastDocId: string | null }> {
  let query = collection.orderBy("createdAt", "desc");

  if (startupId) {
    query = query.where("startupId", "==", startupId);
  }

  // Se conter lastDocId, a query vai começar depois do ultimo documento.
  if (lastDocId) {
    const lastDoc = await collection.doc(lastDocId).get();
    if (lastDoc.exists) {
      query = query.startAfter(lastDoc);
    }
  }

  const snapshot = await query.limit(limit).get();
  // transforma numa lista de objetos do tipo generico T.
  const document = snapshot.docs.map((doc) => ({
    id: doc.id,
    ...(doc.data() as T),
  }));

  // pega o ultimo ID
  const lastId =
    document.length > 0 && document.length === limit
      ? document[document.length - 1].id
      : null;

  return { docs: document, lastDocId: lastId };
}
