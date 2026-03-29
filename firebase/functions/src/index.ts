import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

const app = admin.initializeApp();
const db = app.firestore();
const collectionUsers = db.collection("users");

export const mockupFunction = functions.https.onRequest(async (req, res) => {
  const user = {
    email: "allangiovannimatias@gmail.com",
    name: "John Doe",
    cpf: "12345678900",
    password: "123456",
    field: 1,

  };

  try {
    const createUser = await admin.auth().createUser({
      email: user.email,
      password: user.password,
      displayName: user.name,
    });
    await collectionUsers.doc(createUser.uid).set({
      cpf: user.cpf, anyField: user.field,
    });
    res.send(`User created with ID: ${createUser.uid}`);
  } catch (e) {
    functions.logger.error("Error creating user:", e);
    res.status(500).send("Error creating user");
  }
});
