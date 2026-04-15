// Autor: Allan Giovanni Matias Paes
import * as admin from "firebase-admin";
const app = admin.initializeApp();
export const db = app.firestore();
