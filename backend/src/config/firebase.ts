import admin from "firebase-admin";
import serviceAccount from "../../secrets/firebase-service-account.json" with { type: "json" };
import type { Firestore } from "firebase-admin/firestore";

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount as admin.ServiceAccount)
});

export const db: Firestore = admin.firestore();

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