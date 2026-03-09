// Autor: Allan Giovanni Matias Paes
import admin from "firebase-admin";
import serviceAccount from "../../secrets/firebase-service-account.json" with { type: "json" };
import type { Firestore } from "firebase-admin/firestore";

// Inicialização default do firebase, consumindo o firebase-service-account.json colocado em /secrets.
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount as admin.ServiceAccount)
});

// Instância padrão de db
export const db: Firestore = admin.firestore();

// Função para verificar se o firebase está conectado corretamente
export const firebaseTest = async () => {
  const ref = db.collection('firebasetest').doc('connection');

  await ref.set({
    message: 'Firebase connected successfully',
    createdAt: new Date()
  });
  
  const doc = await ref.get();
  console.log("Saved document:", doc.data());

  return doc.data();

}

export default admin;